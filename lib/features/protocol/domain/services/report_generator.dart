import '../../../../core/constants/fdi.dart';
import '../../data/catalog/report_boilerplate.dart' as boilerplate;
import '../entities/pathology.dart';
import '../entities/selected_pathology.dart';
import '../repositories/pathology_repository.dart';
import 'report_text.dart';

export 'report_text.dart';

/// Чистый генератор текста протокола КЛКТ из находок.
///
/// Описание — «что видно»: строки по возрастанию номера зуба, находки
/// одного набора зубов сливаются в одну строку через «; », размеры
/// и уточнения остаются здесь. Общие находки (ЛОР, ВНЧС, адентия) идут
/// отдельным блоком после зубных, в порядке групп справочника.
///
/// Заключение — «что это значит»: нозологические формулировки
/// ([Pathology.conclusionTemplate]) по убыванию клинической значимости.
/// Одинаковые патологии на разных зубах сворачиваются в одну строку
/// с объединённым списком зубов, разные патологии одного набора зубов —
/// в одно предложение. Размеры в заключение не попадают.
/// Если находок нет и зубной ряд сохранён, при включённом каркасе
/// заключение — «КТ-картина:» и «Без видимой патологии.»
///
/// Находки с незаполненными обязательными полями в текст не попадают.
class ReportGenerator implements ProtocolReportGenerator {
  const ReportGenerator({required this.catalog});

  final PathologyRepository catalog;

  /// Шапка заключения — ровно один раз, первой строкой.
  static const conclusionHeader = 'КТ-картина:';

  static final _teethPlaceholder = RegExp(r'\s*(?:в области\s+)?\{teeth\}');
  static final _fdiPlaceholder = RegExp(r'\s*\{fdi\}');
  static final _areaBeforeTeeth = RegExp(r'области\s+\{teeth\}');
  static final _unresolvedPlaceholders = RegExp(
    r'\s*\{(?:size|adjacent|direction|side)\}',
  );
  static final _extraSpaces = RegExp(r'\s{2,}');

  @override
  ReportText generate({
    required List<SelectedPathology> findings,
    required Set<int> extractedFdis,
    bool includeSkeleton = false,
    bool includeTmjNorm = false,
  }) {
    // Разбор находок на сегменты: зубные делятся на «присутствующие»
    // и «удалённые», общие идут отдельным списком.
    final toothSegments = <_Segment>[];
    final generalSegments = <_Segment>[];

    for (final finding in findings) {
      final pathology = catalog.byId(finding.pathologyId);
      if (pathology == null || !finding.isCompleteFor(pathology)) continue;

      if (pathology.scope == PathologyScope.general) {
        generalSegments.add(
          _Segment(pathology, finding, const [], extracted: false),
        );
        continue;
      }

      final sorted = sortFdis(finding.toothFdis);
      final present = sorted.where((f) => !extractedFdis.contains(f)).toList();
      final extracted = sorted.where(extractedFdis.contains).toList();
      if (present.isNotEmpty) {
        toothSegments.add(
          _Segment(pathology, finding, present, extracted: false),
        );
      }
      if (extracted.isNotEmpty) {
        toothSegments.add(
          _Segment(pathology, finding, extracted, extracted: true),
        );
      }
    }

    final order = _catalogOrder();

    return ReportText(
      description: _buildDescription(
        toothSegments,
        generalSegments,
        order,
        extractedFdis: extractedFdis,
        includeSkeleton: includeSkeleton,
        includeTmjNorm: includeTmjNorm,
      ),
      conclusion: _buildConclusion(
        toothSegments,
        generalSegments,
        order,
        includeSkeleton: includeSkeleton,
        extractedFdis: extractedFdis,
      ),
    );
  }

  // --- Описание ------------------------------------------------------------

  String _buildDescription(
    List<_Segment> toothSegments,
    List<_Segment> generalSegments,
    _CatalogOrder order, {
    required Set<int> extractedFdis,
    required bool includeSkeleton,
    required bool includeTmjNorm,
  }) {
    // Группировка по набору зубов: находки одного набора — одна строка.
    final groups = <String, List<_Segment>>{};
    for (final s in toothSegments) {
      groups.putIfAbsent(s.teethKey, () => []).add(s);
    }

    final toothLines = <_SortableLine>[];
    var index = 0;
    for (final group in groups.values) {
      group.sort(
        (a, b) => order.rank(a.pathology).compareTo(order.rank(b.pathology)),
      );
      final bodies = [
        for (final s in group) _render(s.descriptionTemplate, s.finding),
      ];
      toothLines.add(
        _SortableLine(
          primary: group.first.fdis.first,
          secondary: index++,
          text: '${_descriptionPrefix(group.first)}${bodies.join('; ')}.',
        ),
      );
    }
    toothLines.sort();

    // Общие находки — отдельным блоком, в порядке групп справочника.
    final generalLines = <_SortableLine>[];
    index = 0;
    for (final s in generalSegments) {
      final body = _render(s.pathology.descriptionTemplate, s.finding);
      generalLines.add(
        _SortableLine(
          primary: order.groupOrder(s.pathology),
          secondary: index++,
          text: '${_capitalize(body)}.',
        ),
      );
    }
    generalLines.sort();

    final lines = <String>[
      if (includeSkeleton)
        _formulaLine(extractedFdis, _implantFdis(toothSegments)),
      for (final l in toothLines) l.text,
      if (includeSkeleton) boilerplate.remainingTeethNorm,
      for (final l in generalLines) l.text,
      if (includeSkeleton)
        ..._sectionNorms([
          ...toothSegments,
          ...generalSegments,
        ], includeTmjNorm: includeTmjNorm),
    ];
    return lines.join('\n');
  }

  String _descriptionPrefix(_Segment segment) {
    final numbers = formatFdis(segment.fdis);
    if (segment.pathology.refStyle == ToothRefStyle.area) {
      return 'В области $numbers — ';
    }
    final noun = segment.fdis.length == 1 ? 'зуб' : 'зубы';
    final marker = segment.extracted
        ? (segment.fdis.length == 1 ? ' (удален)' : ' (удалены)')
        : '';
    return '$numbers $noun$marker — ';
  }

  // --- Каркас протокола ----------------------------------------------------

  /// Зубы с имплантатами — для строки зубной формулы.
  List<int> _implantFdis(List<_Segment> toothSegments) => sortFdis({
    for (final s in toothSegments)
      if (s.pathology.id == 'g9_implants_ok' ||
          s.pathology.id == 'g9_implant_bone_loss')
        ...s.fdis,
  });

  String _formulaLine(Set<int> extractedFdis, List<int> implantFdis) {
    final parts = <String>[
      if (extractedFdis.isNotEmpty)
        'отсутствуют ${formatFdis(sortFdis(extractedFdis))}',
      if (implantFdis.isNotEmpty)
        'в области ${formatFdis(implantFdis)} — дентальные имплантаты',
    ];
    final body = parts.isEmpty ? boilerplate.formulaIntact : parts.join('; ');
    return '${boilerplate.formulaPrefix}$body.';
  }

  /// Нормы по разделам — только если в разделе нет ни одной находки.
  /// Фраза ВНЧС добавляется отдельно, переключателем каркаса.
  List<String> _sectionNorms(
    List<_Segment> segments, {
    required bool includeTmjNorm,
  }) {
    final groupIds = {for (final s in segments) s.pathology.groupId};
    final pathologyIds = {for (final s in segments) s.pathology.id};
    return [
      if (!groupIds.contains('g5')) boilerplate.periodontiumNorm,
      if (!groupIds.contains('g7') && !groupIds.contains('g8'))
        boilerplate.sinusNorm,
      if (includeTmjNorm && !pathologyIds.contains('g10_tmj'))
        boilerplate.tmjNorm,
    ];
  }

  // --- Заключение ----------------------------------------------------------

  String _buildConclusion(
    List<_Segment> toothSegments,
    List<_Segment> generalSegments,
    _CatalogOrder order, {
    required bool includeSkeleton,
    required Set<int> extractedFdis,
  }) {
    // Шаг 1: свёртка по патологии — одинаковая патология с одинаковыми
    // уточнениями на разных зубах даёт одну клаузу с объединением зубов.
    final byPathology = <String, _Segment>{};
    for (final s in toothSegments) {
      if (s.pathology.omitFromConclusion) continue;
      final key = [
        s.pathology.id,
        s.finding.side,
        s.finding.direction,
        s.finding.adjacentFdi,
        s.extracted,
      ].join('|');
      final existing = byPathology[key];
      if (existing == null) {
        byPathology[key] = _Segment(s.pathology, s.finding, [
          ...s.fdis,
        ], extracted: s.extracted);
      } else {
        existing.fdis
          ..addAll(s.fdis.where((f) => !existing.fdis.contains(f)))
          ..sort();
      }
    }

    // Шаг 2: свёртка по набору зубов — разные патологии одного набора
    // объединяются в одно предложение; номера зубов только в первой клаузе.
    final byTeeth = <String, List<_Segment>>{};
    for (final s in byPathology.values) {
      byTeeth.putIfAbsent(s.teethKey, () => []).add(s);
    }

    final lines = <_SortableLine>[];
    for (final clauses in byTeeth.values) {
      clauses.sort((a, b) {
        final bySignificance = b.pathology.significance.compareTo(
          a.pathology.significance,
        );
        if (bySignificance != 0) return bySignificance;
        return order.rank(a.pathology).compareTo(order.rank(b.pathology));
      });
      final texts = [
        for (var i = 0; i < clauses.length; i++)
          _conclusionClause(clauses[i], withTeeth: i == 0),
      ];
      lines.add(
        _SortableLine(
          // Убывание значимости → инвертируем знак для общего компаратора.
          primary: -clauses.first.pathology.significance,
          secondary: -clauses.length,
          tertiary: clauses.first.fdis.first,
          text: '${_capitalize(texts.join('; '))}.',
        ),
      );
    }

    // Общие находки: каждая — отдельная строка, дубли схлопываются.
    final seenGeneral = <String>{};
    for (final s in generalSegments) {
      if (s.pathology.omitFromConclusion) continue;
      final body = _render(
        s.pathology.conclusionTemplate,
        s.finding,
        forConclusion: true,
      );
      if (!seenGeneral.add(body)) continue;
      lines.add(
        _SortableLine(
          primary: -s.pathology.significance,
          secondary: 0,
          // Общие находки при равной значимости идут после зубных.
          tertiary: 1000 + order.groupOrder(s.pathology),
          text: '${_capitalize(body)}.',
        ),
      );
    }

    if (lines.isEmpty) {
      final hasFindings =
          toothSegments.isNotEmpty || generalSegments.isNotEmpty;
      // Фраза только для нормы: каркас включён, зубы на месте, находок нет.
      // Удалённые зубы и любые находки эту формулировку исключают.
      if (!includeSkeleton || extractedFdis.isNotEmpty || hasFindings) {
        return '';
      }
      return '$conclusionHeader\n${boilerplate.conclusionNoPathology}';
    }
    lines.sort();
    return [conclusionHeader, for (final l in lines) l.text].join('\n');
  }

  /// Клауза заключения: нозологическая формулировка с номерами зубов
  /// ([withTeeth]) или без них (вторая и последующие клаузы строки).
  String _conclusionClause(_Segment segment, {required bool withTeeth}) {
    var text = _render(
      segment.pathology.conclusionTemplate,
      segment.finding,
      forConclusion: true,
    );

    if (!withTeeth) {
      return text
          .replaceAll(_teethPlaceholder, '')
          .replaceAll(_fdiPlaceholder, '')
          .replaceAll(_extraSpaces, ' ')
          .trim();
    }

    final numbers = formatFdiRanges(segment.fdis);
    final asArea =
        segment.extracted || segment.pathology.refStyle == ToothRefStyle.area;
    final ref = asArea
        ? 'в области $numbers'
        : (segment.fdis.length == 1 ? 'зуба $numbers' : 'зубов $numbers');

    // {fdi} — только номера: «периапикальная деструкция 4.3», без «зуба».
    if (text.contains('{fdi}')) {
      return text.replaceAll('{fdi}', numbers);
    }

    if (text.contains('{teeth}')) {
      // Если перед {teeth} уже стоит «… области» («в области {teeth}»,
      // «в апикальной области {teeth}»), вставляем только номера,
      // чтобы не получить «в области в области 1.4».
      if (asArea && _areaBeforeTeeth.hasMatch(text)) {
        return text.replaceAll('{teeth}', numbers);
      }
      return text.replaceAll('{teeth}', ref);
    }
    return '$text $ref';
  }

  // --- Подстановка переменных ---------------------------------------------

  /// Заменяет плейсхолдеры {size}, {adjacent}, {direction}, {side}.
  /// Если сторона/направление/размер заданы, а плейсхолдера в шаблоне нет —
  /// значение добавляется в конец фразы. В заключении ([forConclusion])
  /// размер не подставляется вовсе. Незаполненные плейсхолдеры вырезаются.
  /// {teeth} и {fdi} не трогаются — их обрабатывает [_conclusionClause].
  String _render(
    String template,
    SelectedPathology finding, {
    bool forConclusion = false,
  }) {
    var text = template;

    final size = finding.measurements;
    if (!forConclusion && size != null && size.isComplete) {
      text = text.contains('{size}')
          ? text.replaceAll('{size}', size.render())
          : '$text ${size.render()}';
    }

    final adjacent = finding.adjacentFdi;
    if (adjacent != null) {
      text = text.replaceAll('{adjacent}', formatFdi(adjacent));
    }

    final direction = finding.direction;
    if (direction != null) {
      text = text.contains('{direction}')
          ? text.replaceAll('{direction}', direction.reportText)
          : '$text ${direction.reportText}';
    }

    final side = finding.side;
    if (side != null) {
      text = text.contains('{side}')
          ? text.replaceAll('{side}', side.reportText)
          : '$text ${side.reportText}';
    }

    return text
        .replaceAll(_unresolvedPlaceholders, '')
        .replaceAll(_extraSpaces, ' ')
        .trim();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  _CatalogOrder _catalogOrder() {
    final ranks = <String, int>{};
    final groupOrders = <String, int>{};
    var i = 0;
    for (final g in catalog.groups) {
      groupOrders[g.id] = g.order;
      for (final p in g.items) {
        ranks[p.id] = i++;
      }
    }
    return _CatalogOrder(ranks, groupOrders);
  }
}

/// Порядок патологий и групп в справочнике — для стабильной сортировки.
class _CatalogOrder {
  const _CatalogOrder(this._ranks, this._groupOrders);

  final Map<String, int> _ranks;
  final Map<String, int> _groupOrders;

  int rank(Pathology p) => _ranks[p.id] ?? 999;
  int groupOrder(Pathology p) => _groupOrders[p.groupId] ?? 999;
}

/// Находка, привязанная к конкретному набору зубов
/// (или без зубов — для общих патологий).
class _Segment {
  _Segment(this.pathology, this.finding, this.fdis, {required this.extracted});

  final Pathology pathology;
  final SelectedPathology finding;

  /// Отсортированные по возрастанию номера зубов.
  final List<int> fdis;
  final bool extracted;

  String get teethKey => '${fdis.join(',')}|$extracted';

  /// Шаблон описания: для удалённых зубов — специальный, если задан.
  String get descriptionTemplate => extracted
      ? (pathology.extractedTemplate ?? pathology.descriptionTemplate)
      : pathology.descriptionTemplate;
}

/// Строка текста с ключами сортировки (primary, secondary, tertiary).
class _SortableLine implements Comparable<_SortableLine> {
  const _SortableLine({
    required this.primary,
    required this.secondary,
    this.tertiary = 0,
    required this.text,
  });

  final int primary;
  final int secondary;
  final int tertiary;
  final String text;

  @override
  int compareTo(_SortableLine other) {
    final byPrimary = primary.compareTo(other.primary);
    if (byPrimary != 0) return byPrimary;
    final bySecondary = secondary.compareTo(other.secondary);
    if (bySecondary != 0) return bySecondary;
    return tertiary.compareTo(other.tertiary);
  }
}
