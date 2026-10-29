import 'package:equatable/equatable.dart';

import '../../domain/entities/selected_pathology.dart';

/// Состояние протокола в Bloc. Иммутабельно.
class ProtocolState extends Equatable {
  const ProtocolState({
    this.extractedFdis = const {},
    this.selectedFdis = const {},
    this.findings = const [],
    this.drafts = const [],
    this.editingUid,
    this.lastCommittedFdis = const {},
    this.lastCommittedUids = const [],
    this.includeTmjNorm = false,
  });

  /// Служебный uid черновика (пока находка не добавлена в протокол).
  static const draftUid = 'draft';

  /// Зубы, помеченные как удалённые/отсутствующие.
  final Set<int> extractedFdis;

  /// Мультивыбор зубов в формуле.
  final Set<int> selectedFdis;

  /// Находки в порядке добавления (порядок = порядок в тексте).
  final List<SelectedPathology> findings;

  /// Черновики находок: выбранные патологии + уточнения.
  /// Зубы черновиков — текущий [selectedFdis], фиксируются при коммите.
  /// Пустой список — нет черновика.
  final List<SelectedPathology> drafts;

  /// Uid находки из [findings], которую сейчас правим через черновик.
  /// null — черновики создают новые находки.
  final String? editingUid;

  /// Набор зубов последней добавленной находки — для кнопки «Вернуть зубы».
  final Set<int> lastCommittedFdis;

  /// Uid находок последнего коммита — для undo из SnackBar.
  final List<String> lastCommittedUids;

  /// Фраза «ВНЧС без структурных изменений» в каркасе КЛКТ.
  /// Сам каркас (формула, нормы, замыкающие фразы) включён всегда.
  final bool includeTmjNorm;

  bool get isEditing => editingUid != null;

  bool get hasDrafts => drafts.isNotEmpty;

  Set<String> get draftPathologyIds => {for (final d in drafts) d.pathologyId};

  ProtocolState copyWith({
    Set<int>? extractedFdis,
    Set<int>? selectedFdis,
    List<SelectedPathology>? findings,
    List<SelectedPathology>? drafts,
    String? Function()? editingUid,
    Set<int>? lastCommittedFdis,
    List<String>? lastCommittedUids,
    bool? includeTmjNorm,
  }) => ProtocolState(
    extractedFdis: extractedFdis ?? this.extractedFdis,
    selectedFdis: selectedFdis ?? this.selectedFdis,
    findings: findings ?? this.findings,
    drafts: drafts ?? this.drafts,
    editingUid: editingUid != null ? editingUid() : this.editingUid,
    lastCommittedFdis: lastCommittedFdis ?? this.lastCommittedFdis,
    lastCommittedUids: lastCommittedUids ?? this.lastCommittedUids,
    includeTmjNorm: includeTmjNorm ?? this.includeTmjNorm,
  );

  @override
  List<Object?> get props => [
    extractedFdis,
    selectedFdis,
    findings,
    drafts,
    editingUid,
    lastCommittedFdis,
    lastCommittedUids,
    includeTmjNorm,
  ];
}
