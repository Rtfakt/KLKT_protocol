import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/fdi.dart';
import '../../domain/entities/pathology.dart';
import '../../domain/entities/selected_pathology.dart';
import '../../domain/entities/study_type.dart';
import '../../domain/repositories/pathology_repository.dart';
import 'protocol_event.dart';
import 'protocol_state.dart';

/// Одноразовое уведомление для SnackBar.
/// [undoable] — показать действие «Отменить» (LastCommitUndone).
class ProtocolNotice {
  const ProtocolNotice(this.message, {this.undoable = false});

  final String message;
  final bool undoable;
}

class ProtocolBloc extends Bloc<ProtocolEvent, ProtocolState> {
  ProtocolBloc({required this.catalog, this.studyType = StudyType.cbct})
    : super(const ProtocolState()) {
    on<ToothSelectionToggled>(_onToothSelectionToggled);
    on<ExtractedToggled>(_onExtractedToggled);
    on<PathologySelected>(_onPathologySelected);
    on<DraftCommitted>(_onDraftCommitted);
    on<DraftDiscarded>(_onDraftDiscarded);
    on<FindingRemoved>(_onFindingRemoved);
    on<FindingEditRequested>(_onFindingEditRequested);
    on<TeethRestored>(_onTeethRestored);
    on<LastCommitUndone>(_onLastCommitUndone);
    on<SizeCountChanged>(_onSizeCountChanged);
    on<MeasurementsChanged>(_onMeasurementsChanged);
    on<SideChanged>(_onSideChanged);
    on<DirectionChanged>(_onDirectionChanged);
    on<AdjacentChanged>(_onAdjacentChanged);
    on<SkeletonToggled>(_onSkeletonToggled);
    on<Cleared>(_onCleared);
  }

  final PathologyRepository catalog;

  /// Тип исследования вкладки: на КЛКТ показывает переключатель фразы ВНЧС.
  final StudyType studyType;

  /// Одноразовые уведомления для SnackBar (не часть состояния).
  final StreamController<ProtocolNotice> _notices =
      StreamController.broadcast();
  Stream<ProtocolNotice> get notices => _notices.stream;

  int _uidCounter = 0;
  String _nextUid() => 'f${++_uidCounter}';

  @override
  Future<void> close() async {
    await _notices.close();
    return super.close();
  }

  void _onToothSelectionToggled(
    ToothSelectionToggled event,
    Emitter<ProtocolState> emit,
  ) {
    final selected = {...state.selectedFdis};
    selected.contains(event.fdi)
        ? selected.remove(event.fdi)
        : selected.add(event.fdi);
    emit(
      state.copyWith(
        selectedFdis: selected,
        drafts: _draftsWithValidAdjacent(state.drafts, selected),
      ),
    );
  }

  void _onExtractedToggled(
    ExtractedToggled event,
    Emitter<ProtocolState> emit,
  ) {
    final extracted = {...state.extractedFdis};
    extracted.contains(event.fdi)
        ? extracted.remove(event.fdi)
        : extracted.add(event.fdi);
    emit(state.copyWith(extractedFdis: extracted));
  }

  void _onPathologySelected(
    PathologySelected event,
    Emitter<ProtocolState> emit,
  ) {
    final pathology = catalog.byId(event.pathologyId);
    if (pathology == null) return;

    if (state.isEditing) {
      // В правке — только замена патологии; повторный клик игнорируется.
      if (state.draftPathologyIds.contains(pathology.id)) return;
      emit(state.copyWith(drafts: [_newDraft(pathology)]));
      return;
    }

    final index = state.drafts.indexWhere((d) => d.pathologyId == pathology.id);
    if (index >= 0) {
      emit(
        state.copyWith(
          drafts: [
            for (var i = 0; i < state.drafts.length; i++)
              if (i != index) state.drafts[i],
          ],
        ),
      );
      return;
    }

    emit(state.copyWith(drafts: [...state.drafts, _newDraft(pathology)]));
  }

  void _onDraftCommitted(DraftCommitted event, Emitter<ProtocolState> emit) {
    if (state.drafts.isEmpty) return;

    final resolved = <({SelectedPathology draft, Pathology pathology})>[];
    for (final draft in state.drafts) {
      final pathology = catalog.byId(draft.pathologyId);
      if (pathology == null) return;
      resolved.add((draft: draft, pathology: pathology));
    }

    final needsTeeth = resolved.any(
      (r) => r.pathology.scope == PathologyScope.tooth,
    );
    if (needsTeeth && state.selectedFdis.isEmpty) {
      _notices.add(const ProtocolNotice('Выберите зубы в формуле'));
      return;
    }

    final neighbors = neighboringFdis(state.selectedFdis).toSet();
    for (final item in resolved) {
      if (!item.draft.isCompleteFor(item.pathology)) {
        _notices.add(const ProtocolNotice('Заполните обязательные поля'));
        return;
      }
      if (item.pathology.requiresAdjacentTooth &&
          !neighbors.contains(item.draft.adjacentFdi)) {
        _notices.add(const ProtocolNotice('Выберите соседний зуб'));
        return;
      }
    }

    final editing = state.isEditing;
    if (editing) {
      final item = resolved.first;
      final uid = state.editingUid!;
      final finding = _findingFrom(item.draft, item.pathology, uid);
      emit(
        state.copyWith(
          findings: [
            for (final f in state.findings) f.uid == uid ? finding : f,
          ],
          selectedFdis: const {},
          drafts: const [],
          editingUid: () => null,
          lastCommittedFdis: finding.toothFdis.isNotEmpty
              ? finding.toothFdis.toSet()
              : null,
        ),
      );
      final teethLabel = finding.toothFdis.isEmpty
          ? ''
          : '${formatFdis(finding.toothFdis)} — ';
      _notices.add(
        ProtocolNotice('Сохранено: $teethLabel${item.pathology.name}'),
      );
      return;
    }

    final newFindings = [
      for (final item in resolved)
        _findingFrom(item.draft, item.pathology, _nextUid()),
    ];
    final toothFdis = {for (final f in newFindings) ...f.toothFdis};

    emit(
      state.copyWith(
        findings: [...state.findings, ...newFindings],
        selectedFdis: const {},
        drafts: const [],
        editingUid: () => null,
        lastCommittedFdis: toothFdis.isNotEmpty ? toothFdis : null,
        lastCommittedUids: [for (final f in newFindings) f.uid],
      ),
    );

    _notices.add(
      ProtocolNotice(
        _addedMessage(newFindings, resolved.map((r) => r.pathology)),
        undoable: true,
      ),
    );
  }

  void _onDraftDiscarded(DraftDiscarded event, Emitter<ProtocolState> emit) {
    emit(
      state.copyWith(
        selectedFdis: const {},
        drafts: const [],
        editingUid: () => null,
      ),
    );
  }

  void _onFindingRemoved(FindingRemoved event, Emitter<ProtocolState> emit) {
    final editingThis = state.editingUid == event.uid;
    emit(
      state.copyWith(
        findings: state.findings.where((f) => f.uid != event.uid).toList(),
        editingUid: () => editingThis ? null : state.editingUid,
        lastCommittedUids: [
          for (final uid in state.lastCommittedUids)
            if (uid != event.uid) uid,
        ],
        drafts: editingThis ? const [] : state.drafts,
      ),
    );
  }

  void _onFindingEditRequested(
    FindingEditRequested event,
    Emitter<ProtocolState> emit,
  ) {
    final finding = _findingByUid(event.uid);
    if (finding == null) return;

    final teeth = finding.toothFdis.toSet();
    emit(
      state.copyWith(
        selectedFdis: teeth,
        drafts: _draftsWithValidAdjacent([_draftFromFinding(finding)], teeth),
        editingUid: () => event.uid,
      ),
    );
  }

  void _onTeethRestored(TeethRestored event, Emitter<ProtocolState> emit) {
    if (state.lastCommittedFdis.isEmpty) return;
    final selected = {...state.lastCommittedFdis};
    emit(
      state.copyWith(
        selectedFdis: selected,
        drafts: _draftsWithValidAdjacent(state.drafts, selected),
      ),
    );
  }

  void _onLastCommitUndone(
    LastCommitUndone event,
    Emitter<ProtocolState> emit,
  ) {
    if (state.lastCommittedUids.isEmpty) return;
    final uids = state.lastCommittedUids.toSet();
    final restored = [
      for (final f in state.findings)
        if (uids.contains(f.uid)) f,
    ];
    if (restored.isEmpty) return;

    final teeth = {for (final f in restored) ...f.toothFdis};
    final drafts = [for (final f in restored) _draftFromFinding(f)];

    emit(
      state.copyWith(
        findings: state.findings.where((f) => !uids.contains(f.uid)).toList(),
        selectedFdis: teeth,
        drafts: _draftsWithValidAdjacent(drafts, teeth),
        editingUid: () => null,
        lastCommittedUids: const [],
      ),
    );
  }

  void _onSizeCountChanged(
    SizeCountChanged event,
    Emitter<ProtocolState> emit,
  ) {
    _updateDraft(
      emit,
      (f) => f.copyWith(
        measurements: (f.measurements ?? const Measurements()).copyWith(
          count: event.count,
        ),
      ),
      pathologyId: event.pathologyId,
    );
  }

  void _onMeasurementsChanged(
    MeasurementsChanged event,
    Emitter<ProtocolState> emit,
  ) {
    _updateDraft(
      emit,
      (f) => f.copyWith(
        measurements: (f.measurements ?? const Measurements()).copyWith(
          x: event.x,
          y: event.y,
          z: event.z,
        ),
      ),
      pathologyId: event.pathologyId,
    );
  }

  void _onSideChanged(SideChanged event, Emitter<ProtocolState> emit) {
    _updateDraft(
      emit,
      (f) => f.copyWith(side: event.side),
      pathologyId: event.pathologyId,
    );
  }

  void _onDirectionChanged(
    DirectionChanged event,
    Emitter<ProtocolState> emit,
  ) {
    _updateDraft(
      emit,
      (f) => f.copyWith(direction: event.direction),
      pathologyId: event.pathologyId,
    );
  }

  void _onAdjacentChanged(AdjacentChanged event, Emitter<ProtocolState> emit) {
    if (!neighboringFdis(state.selectedFdis).contains(event.fdi)) return;
    _updateDraft(
      emit,
      (f) => f.copyWith(adjacentFdi: event.fdi),
      pathologyId: event.pathologyId,
    );
  }

  /// Сбрасывает соседний зуб, если он больше не контактирует с [selected].
  List<SelectedPathology> _draftsWithValidAdjacent(
    List<SelectedPathology> drafts,
    Set<int> selected,
  ) {
    final allowed = neighboringFdis(selected).toSet();
    var changed = false;
    final next = <SelectedPathology>[];
    for (final draft in drafts) {
      final adjacent = draft.adjacentFdi;
      if (adjacent != null && !allowed.contains(adjacent)) {
        next.add(draft.copyWith(clearAdjacentFdi: true));
        changed = true;
      } else {
        next.add(draft);
      }
    }
    return changed ? next : drafts;
  }

  void _onSkeletonToggled(SkeletonToggled event, Emitter<ProtocolState> emit) {
    emit(state.copyWith(includeTmjNorm: !state.includeTmjNorm));
  }

  void _onCleared(Cleared event, Emitter<ProtocolState> emit) {
    // Фраза ВНЧС — настройка каркаса, очистка её не сбрасывает.
    emit(ProtocolState(includeTmjNorm: state.includeTmjNorm));
  }

  SelectedPathology _newDraft(Pathology pathology) => SelectedPathology(
    uid: ProtocolState.draftUid,
    pathologyId: pathology.id,
    measurements: pathology.requiresSize
        ? Measurements(count: pathology.defaultSizeCount)
        : null,
  );

  SelectedPathology _draftFromFinding(SelectedPathology finding) =>
      SelectedPathology(
        uid: ProtocolState.draftUid,
        pathologyId: finding.pathologyId,
        measurements: finding.measurements,
        side: finding.side,
        direction: finding.direction,
        adjacentFdi: finding.adjacentFdi,
      );

  SelectedPathology _findingFrom(
    SelectedPathology draft,
    Pathology pathology,
    String uid,
  ) {
    final isTooth = pathology.scope == PathologyScope.tooth;
    final teeth = isTooth ? sortFdis(state.selectedFdis) : const <int>[];
    return SelectedPathology(
      uid: uid,
      pathologyId: draft.pathologyId,
      toothFdis: teeth,
      measurements: draft.measurements,
      side: draft.side,
      direction: draft.direction,
      adjacentFdi: draft.adjacentFdi,
    );
  }

  String _addedMessage(
    List<SelectedPathology> findings,
    Iterable<Pathology> pathologies,
  ) {
    final toothFdis = [for (final f in findings) ...f.toothFdis];
    final uniqueTeeth = sortFdis({...toothFdis});
    final teethLabel = uniqueTeeth.isEmpty
        ? ''
        : '${formatFdis(uniqueTeeth)} — ';
    if (findings.length == 1) {
      return 'Добавлено: $teethLabel${pathologies.first.name}';
    }
    return 'Добавлено: $teethLabel${_findingsCountLabel(findings.length)}';
  }

  SelectedPathology? _findingByUid(String uid) {
    for (final f in state.findings) {
      if (f.uid == uid) return f;
    }
    return null;
  }

  void _updateDraft(
    Emitter<ProtocolState> emit,
    SelectedPathology Function(SelectedPathology) update, {
    String? pathologyId,
  }) {
    if (state.drafts.isEmpty) return;
    final index = pathologyId == null
        ? (state.drafts.length == 1 ? 0 : -1)
        : state.drafts.indexWhere((d) => d.pathologyId == pathologyId);
    if (index < 0) return;
    emit(
      state.copyWith(
        drafts: [
          for (var i = 0; i < state.drafts.length; i++)
            i == index ? update(state.drafts[i]) : state.drafts[i],
        ],
      ),
    );
  }
}

String _findingsCountLabel(int count) {
  final n10 = count % 10;
  final n100 = count % 100;
  final word = (n10 == 1 && n100 != 11)
      ? 'находка'
      : (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14))
      ? 'находки'
      : 'находок';
  return '$count $word';
}
