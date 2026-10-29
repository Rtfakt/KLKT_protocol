import 'package:equatable/equatable.dart';

import '../../../../core/constants/fdi.dart';
import '../entities/pathology.dart';
import '../entities/selected_pathology.dart';
import '../repositories/pathology_repository.dart';

/// Серьёзность противоречия.
enum IssueSeverity { warning, error }

/// Противоречие между находками или находками и зубной формулой.
class ValidationIssue extends Equatable {
  const ValidationIssue({
    required this.severity,
    required this.message,
    this.relatedUids = const [],
  });

  final IssueSeverity severity;
  final String message;

  /// Uid находок, к которым относится противоречие, — для подсветки чипов.
  final List<String> relatedUids;

  @override
  List<Object?> get props => [severity, message, relatedUids];
}

/// Проверка находок на клинические противоречия. Чистая функция:
/// текст протокола не режет, решение остаётся за врачом.
///
/// Идентификаторы конфликтующих патологий — профиль справочника:
/// по умолчанию КЛКТ, [FindingValidator.opg] — профиль ОПГ (адентия там
/// не чип, а пометка зуба как удалённого, поэтому проверки адентии нет).
class FindingValidator {
  const FindingValidator({
    required this.catalog,
    this.fullAdentiaId = 'g6_full_adentia',
    this.partialAdentiaId = 'g6_partial_adentia',
    this.endoDoneId = 'g4_endo_homogeneous',
    this.canalConflictIds = const {'g4_no_filling', 'g4_partial_obturation'},
  });

  const FindingValidator.opg({required this.catalog})
      : fullAdentiaId = null,
        partialAdentiaId = null,
        endoDoneId = 'opg_endo_treated',
        canalConflictIds = const {'opg_endo_partial'};

  final PathologyRepository catalog;

  /// Патология «полная адентия»; null — проверка отключена.
  final String? fullAdentiaId;
  final String? partialAdentiaId;

  /// Патология «эндодонтическое лечение завершено»; null — отключено.
  final String? endoDoneId;

  /// Патологии необтурированных каналов, конфликтующие с [endoDoneId].
  final Set<String> canalConflictIds;

  List<ValidationIssue> validate({
    required List<SelectedPathology> findings,
    required Set<int> extractedFdis,
  }) {
    final issues = <ValidationIssue>[
      ..._fullAdentiaIssues(findings, extractedFdis),
      ..._canalConflictIssues(findings),
      ..._duplicateIssues(findings),
    ];
    return issues;
  }

  /// Полная адентия против сохранённых зубов и частичной адентии.
  List<ValidationIssue> _fullAdentiaIssues(
    List<SelectedPathology> findings,
    Set<int> extractedFdis,
  ) {
    if (fullAdentiaId == null) return const [];
    final fullAdentia =
        findings.where((f) => f.pathologyId == fullAdentiaId).toList();
    if (fullAdentia.isEmpty) return const [];

    final issues = <ValidationIssue>[];
    final adentiaUids = [for (final f in fullAdentia) f.uid];

    final conflictTeeth = <int>{};
    final conflictUids = <String>{...adentiaUids};
    for (final f in findings) {
      final pathology = catalog.byId(f.pathologyId);
      if (pathology == null || pathology.scope != PathologyScope.tooth) {
        continue;
      }
      final present = f.toothFdis.where((t) => !extractedFdis.contains(t));
      if (present.isNotEmpty) {
        conflictTeeth.addAll(present);
        conflictUids.add(f.uid);
      }
    }

    if (conflictTeeth.isNotEmpty) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          message:
              'Полная адентия несовместима с находками на сохранённых зубах '
              '(${formatFdis(sortFdis(conflictTeeth))}). Уберите находки или '
              'пометьте зубы как удалённые.',
          relatedUids: conflictUids.toList(),
        ),
      );
    } else if (extractedFdis.length < allFdis.length) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          message:
              'Полная адентия: в зубной формуле остались непомеченные зубы — '
              'отметьте все зубы как удалённые.',
          relatedUids: adentiaUids,
        ),
      );
    }

    final partialUids = [
      for (final f in findings)
        if (f.pathologyId == partialAdentiaId) f.uid,
    ];
    if (partialUids.isNotEmpty) {
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.error,
          message:
              'Полная и частичная адентия взаимоисключающие — оставьте одну.',
          relatedUids: [...adentiaUids, ...partialUids],
        ),
      );
    }

    return issues;
  }

  /// «Признаки эндодонтического лечения» и необтурированные каналы
  /// на одном зубе — взаимоисключающие состояния канала.
  List<ValidationIssue> _canalConflictIssues(
    List<SelectedPathology> findings,
  ) {
    if (endoDoneId == null) return const [];
    final endoTeeth = <int, Set<String>>{};
    for (final f in findings) {
      if (f.pathologyId != endoDoneId) continue;
      for (final t in f.toothFdis) {
        endoTeeth.putIfAbsent(t, () => {}).add(f.uid);
      }
    }
    if (endoTeeth.isEmpty) return const [];

    final conflictTeeth = <int>{};
    final uids = <String>{};
    for (final f in findings) {
      if (!canalConflictIds.contains(f.pathologyId)) continue;
      for (final t in f.toothFdis) {
        final endoUids = endoTeeth[t];
        if (endoUids != null) {
          conflictTeeth.add(t);
          uids
            ..addAll(endoUids)
            ..add(f.uid);
        }
      }
    }
    if (conflictTeeth.isEmpty) return const [];

    return [
      ValidationIssue(
        severity: IssueSeverity.warning,
        message:
            'На ${formatFdis(sortFdis(conflictTeeth))} одновременно отмечены '
            'признаки эндодонтического лечения и необтурированные каналы — '
            'состояния взаимоисключающие.',
        relatedUids: uids.toList(),
      ),
    ];
  }

  /// Одна и та же патология дважды на одном зубе.
  List<ValidationIssue> _duplicateIssues(List<SelectedPathology> findings) {
    final byPathologyTooth = <String, Map<int, Set<String>>>{};
    for (final f in findings) {
      for (final t in f.toothFdis) {
        byPathologyTooth
            .putIfAbsent(f.pathologyId, () => {})
            .putIfAbsent(t, () => {})
            .add(f.uid);
      }
    }

    final issues = <ValidationIssue>[];
    for (final entry in byPathologyTooth.entries) {
      final dupTeeth = <int>[];
      final uids = <String>{};
      for (final toothEntry in entry.value.entries) {
        if (toothEntry.value.length > 1) {
          dupTeeth.add(toothEntry.key);
          uids.addAll(toothEntry.value);
        }
      }
      if (dupTeeth.isEmpty) continue;
      final name = catalog.byId(entry.key)?.name ?? entry.key;
      issues.add(
        ValidationIssue(
          severity: IssueSeverity.warning,
          message:
              '«$name» указана несколько раз для '
              '${formatFdis(sortFdis(dupTeeth))} — объедините или удалите дубль.',
          relatedUids: uids.toList(),
        ),
      );
    }
    return issues;
  }
}
