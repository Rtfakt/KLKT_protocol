import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/fdi.dart';
import '../../domain/entities/pathology.dart';
import '../../domain/entities/selected_pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import 'protocol_event.dart';
import 'protocol_state.dart';

class ProtocolBloc extends Bloc<ProtocolEvent, ProtocolState> {
  ProtocolBloc({required this.catalog}) : super(const ProtocolState()) {
    on<ToothSelectionToggled>(_onToothSelectionToggled);
    on<ExtractedToggled>(_onExtractedToggled);
    on<PathologyToggled>(_onPathologyToggled);
    on<FindingRemoved>(_onFindingRemoved);
    on<FindingActivated>(_onFindingActivated);
    on<SizeCountChanged>(_onSizeCountChanged);
    on<MeasurementsChanged>(_onMeasurementsChanged);
    on<SideChanged>(_onSideChanged);
    on<DirectionChanged>(_onDirectionChanged);
    on<AdjacentChanged>(_onAdjacentChanged);
    on<Cleared>(_onCleared);
  }

  final PathologyRepository catalog;

  /// Одноразовые уведомления для SnackBar (не часть состояния).
  final StreamController<String> _notices = StreamController.broadcast();
  Stream<String> get notices => _notices.stream;

  int _uidCounter = 0;
  String _nextUid() => 'f${++_uidCounter}';

  @override
  Future<void> close() async {
    await _notices.close();
    return super.close();
  }

  void _onToothSelectionToggled(
      ToothSelectionToggled event, Emitter<ProtocolState> emit) {
    final selected = {...state.selectedFdis};
    selected.contains(event.fdi)
        ? selected.remove(event.fdi)
        : selected.add(event.fdi);
    emit(state.copyWith(selectedFdis: selected));
  }

  void _onExtractedToggled(
      ExtractedToggled event, Emitter<ProtocolState> emit) {
    final extracted = {...state.extractedFdis};
    extracted.contains(event.fdi)
        ? extracted.remove(event.fdi)
        : extracted.add(event.fdi);
    emit(state.copyWith(extractedFdis: extracted));
  }

  void _onPathologyToggled(
      PathologyToggled event, Emitter<ProtocolState> emit) {
    final pathology = catalog.byId(event.pathologyId);
    if (pathology == null) return;

    if (pathology.scope == PathologyScope.tooth) {
      if (state.selectedFdis.isEmpty) {
        _notices.add('Сначала выберите зубы в формуле');
        return;
      }
      final teeth = sortAnatomically(state.selectedFdis);

      // Повторный клик той же патологией по тем же зубам — снятие находки.
      final existing = state.findings.where((f) =>
          f.pathologyId == pathology.id &&
          f.toothFdis.length == teeth.length &&
          f.toothFdis.toSet().containsAll(teeth));
      if (existing.isNotEmpty) {
        final uid = existing.first.uid;
        emit(state.copyWith(
          findings: state.findings.where((f) => f.uid != uid).toList(),
          activeFindingUid: () =>
              state.activeFindingUid == uid ? null : state.activeFindingUid,
        ));
        return;
      }

      final finding = SelectedPathology(
        uid: _nextUid(),
        pathologyId: pathology.id,
        toothFdis: teeth,
        measurements: pathology.requiresSize ? const Measurements() : null,
      );
      emit(state.copyWith(
        findings: [...state.findings, finding],
        activeFindingUid: () =>
            pathology.hasDynamicFields ? finding.uid : state.activeFindingUid,
      ));
      return;
    }

    // Общая патология: toggle по наличию.
    final existing =
        state.findings.where((f) => f.pathologyId == pathology.id);
    if (existing.isNotEmpty) {
      final uid = existing.first.uid;
      emit(state.copyWith(
        findings: state.findings.where((f) => f.uid != uid).toList(),
        activeFindingUid: () =>
            state.activeFindingUid == uid ? null : state.activeFindingUid,
      ));
      return;
    }

    final finding = SelectedPathology(
      uid: _nextUid(),
      pathologyId: pathology.id,
      measurements: pathology.requiresSize ? const Measurements() : null,
    );
    emit(state.copyWith(
      findings: [...state.findings, finding],
      activeFindingUid: () =>
          pathology.hasDynamicFields ? finding.uid : state.activeFindingUid,
    ));
  }

  void _onFindingRemoved(FindingRemoved event, Emitter<ProtocolState> emit) {
    emit(state.copyWith(
      findings: state.findings.where((f) => f.uid != event.uid).toList(),
      activeFindingUid: () =>
          state.activeFindingUid == event.uid ? null : state.activeFindingUid,
    ));
  }

  void _onFindingActivated(
      FindingActivated event, Emitter<ProtocolState> emit) {
    emit(state.copyWith(activeFindingUid: () => event.uid));
  }

  void _onSizeCountChanged(
      SizeCountChanged event, Emitter<ProtocolState> emit) {
    _updateActive(
      emit,
      (f) => f.copyWith(
        measurements:
            (f.measurements ?? const Measurements()).copyWith(count: event.count),
      ),
    );
  }

  void _onMeasurementsChanged(
      MeasurementsChanged event, Emitter<ProtocolState> emit) {
    _updateActive(
      emit,
      (f) => f.copyWith(
        measurements: (f.measurements ?? const Measurements())
            .copyWith(x: event.x, y: event.y, z: event.z),
      ),
    );
  }

  void _onSideChanged(SideChanged event, Emitter<ProtocolState> emit) {
    _updateActive(emit, (f) => f.copyWith(side: event.side));
  }

  void _onDirectionChanged(
      DirectionChanged event, Emitter<ProtocolState> emit) {
    _updateActive(emit, (f) => f.copyWith(direction: event.direction));
  }

  void _onAdjacentChanged(AdjacentChanged event, Emitter<ProtocolState> emit) {
    _updateActive(emit, (f) => f.copyWith(adjacentFdi: event.fdi));
  }

  void _onCleared(Cleared event, Emitter<ProtocolState> emit) {
    emit(const ProtocolState());
  }

  void _updateActive(
    Emitter<ProtocolState> emit,
    SelectedPathology Function(SelectedPathology) update,
  ) {
    final uid = state.activeFindingUid;
    if (uid == null) return;
    emit(state.copyWith(
      findings: [
        for (final f in state.findings) f.uid == uid ? update(f) : f,
      ],
    ));
  }
}
