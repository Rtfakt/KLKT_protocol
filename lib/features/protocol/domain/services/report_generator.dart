import '../../../../core/constants/fdi.dart';
import '../entities/pathology.dart';
import '../entities/selected_pathology.dart';
import '../repositories/pathology_repository.dart';

/// Результат генерации: описательная часть и заключение.
class ReportText {
  const ReportText({required this.description, required this.conclusion});

  final String description;
  final String conclusion;

  bool get isEmpty => description.isEmpty && conclusion.isEmpty;

  /// Единый plain-text для копирования в буфер обмена.
  String asPlainText() => [
        'ОПИСАТЕЛЬНАЯ ЧАСТЬ:',
        description,
        '',
        'ЗАКЛЮЧЕНИЕ:',
        conclusion,
      ].join('\n');
}

/// Чистый генератор текста протокола из находок.
///
/// Правила:
/// 1. Зубочелюстные патологии: зубы находки делятся на «присутствующие» и
///    «удалённые»; для каждой подгруппы — своя строка описания и заключения.
/// 2. Общие патологии (ЛОР, ВНЧС): одна строка, сторона/направление
///    подставляются в шаблон или добавляются в конец.
/// 3. Находки с незаполненными обязательными полями в текст не попадают.
class ReportGenerator {
  const ReportGenerator({required this.catalog});

  final PathologyRepository catalog;

  ReportText generate({
    required List<SelectedPathology> findings,
    required Set<int> extractedFdis,
  }) {
    final descriptionLines = <String>[];
    final conclusionLines = <String>[];

    for (final finding in findings) {
      final pathology = catalog.byId(finding.pathologyId);
      if (pathology == null || !finding.isCompleteFor(pathology)) continue;

      if (pathology.scope == PathologyScope.general) {
        descriptionLines.add(_generalDescription(pathology, finding));
        conclusionLines.add(_generalConclusion(pathology, finding));
        continue;
      }

      final sorted = sortAnatomically(finding.toothFdis);
      final present =
          sorted.where((f) => !extractedFdis.contains(f)).toList();
      final extracted =
          sorted.where(extractedFdis.contains).toList();

      if (present.isNotEmpty) {
        descriptionLines.add(_toothDescription(pathology, finding, present,
            extracted: false));
        conclusionLines.add(_toothConclusion(pathology, finding, present,
            extracted: false));
      }
      if (extracted.isNotEmpty) {
        descriptionLines.add(_toothDescription(pathology, finding, extracted,
            extracted: true));
        conclusionLines.add(_toothConclusion(pathology, finding, extracted,
            extracted: true));
      }
    }

    return ReportText(
      description: descriptionLines.join('\n'),
      conclusion: conclusionLines.join('\n'),
    );
  }

  // --- Зубочелюстные патологии -------------------------------------------

  String _toothDescription(
    Pathology pathology,
    SelectedPathology finding,
    List<int> fdis, {
    required bool extracted,
  }) {
    final template = extracted
        ? (pathology.extractedTemplate ?? pathology.descriptionTemplate)
        : pathology.descriptionTemplate;
    final body = _render(template, finding);
    final numbers = fdis.join(', ');
    final noun = fdis.length == 1 ? 'зуб' : 'зубы';
    final marker = extracted
        ? (fdis.length == 1 ? ' (удален)' : ' (удалены)')
        : '';
    return '$numbers $noun$marker - $body.';
  }

  String _toothConclusion(
    Pathology pathology,
    SelectedPathology finding,
    List<int> fdis, {
    required bool extracted,
  }) {
    final name = _render(pathology.conclusionText, finding, appendSize: false);
    final numbers = fdis.join(', ');
    if (extracted) {
      final noun = fdis.length == 1 ? 'зуба' : 'зубов';
      return 'КТ-картина соответствует $name в области $numbers $noun.';
    }
    final noun = fdis.length == 1 ? 'зубе' : 'зубах';
    return 'КТ-картина соответствует $name в $numbers $noun.';
  }

  // --- Общие патологии -----------------------------------------------------

  String _generalDescription(Pathology pathology, SelectedPathology finding) {
    final body = _render(pathology.descriptionTemplate, finding);
    return '${_capitalize(body)}.';
  }

  String _generalConclusion(Pathology pathology, SelectedPathology finding) {
    final name = _render(pathology.conclusionText, finding, appendSize: false);
    return 'КТ-картина соответствует $name.';
  }

  // --- Подстановка переменных ---------------------------------------------

  /// Заменяет плейсхолдеры {size}, {adjacent}, {direction}, {side}.
  /// Если сторона/размер заданы, а плейсхолдера в шаблоне нет —
  /// значение добавляется в конец фразы. В заключениях размер
  /// не добавляется без явного плейсхолдера ([appendSize] = false).
  String _render(
    String template,
    SelectedPathology finding, {
    bool appendSize = true,
  }) {
    var text = template;

    final size = finding.measurements;
    if (size != null && size.isComplete) {
      if (text.contains('{size}')) {
        text = text.replaceAll('{size}', size.render());
      } else if (appendSize) {
        text = '$text ${size.render()}';
      }
    }

    final adjacent = finding.adjacentFdi;
    if (adjacent != null) {
      text = text.replaceAll('{adjacent}', '$adjacent');
    }

    final direction = finding.direction;
    if (direction != null) {
      if (text.contains('{direction}')) {
        text = text.replaceAll('{direction}', direction.reportText);
      } else {
        text = '$text ${direction.reportText}';
      }
    }

    final side = finding.side;
    if (side != null) {
      if (text.contains('{side}')) {
        text = text.replaceAll('{side}', side.reportText);
      } else {
        text = '$text ${side.reportText}';
      }
    }

    return text;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
