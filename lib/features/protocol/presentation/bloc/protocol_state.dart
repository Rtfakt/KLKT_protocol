import 'package:equatable/equatable.dart';

import '../../domain/entities/selected_pathology.dart';

/// Состояние протокола в Bloc. Иммутабельно.
class ProtocolState extends Equatable {
  const ProtocolState({
    this.extractedFdis = const {},
    this.selectedFdis = const {},
    this.findings = const [],
    this.activeFindingUid,
  });

  /// Зубы, помеченные как удалённые/отсутствующие.
  final Set<int> extractedFdis;

  /// Мультивыбор зубов в формуле.
  final Set<int> selectedFdis;

  /// Находки в порядке добавления (порядок = порядок в тексте).
  final List<SelectedPathology> findings;

  /// Находка, чьи динамические поля сейчас редактируются.
  final String? activeFindingUid;

  SelectedPathology? get activeFinding {
    for (final f in findings) {
      if (f.uid == activeFindingUid) return f;
    }
    return null;
  }

  ProtocolState copyWith({
    Set<int>? extractedFdis,
    Set<int>? selectedFdis,
    List<SelectedPathology>? findings,
    String? Function()? activeFindingUid,
  }) =>
      ProtocolState(
        extractedFdis: extractedFdis ?? this.extractedFdis,
        selectedFdis: selectedFdis ?? this.selectedFdis,
        findings: findings ?? this.findings,
        activeFindingUid:
            activeFindingUid != null ? activeFindingUid() : this.activeFindingUid,
      );

  @override
  List<Object?> get props =>
      [extractedFdis, selectedFdis, findings, activeFindingUid];
}
