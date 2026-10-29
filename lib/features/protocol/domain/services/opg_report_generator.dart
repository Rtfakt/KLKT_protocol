import '../../../../core/constants/fdi.dart';
import '../../data/catalog/opg_report_boilerplate.dart' as boilerplate;
import '../entities/pathology.dart';
import '../entities/selected_pathology.dart';
import '../repositories/pathology_repository.dart';
import 'report_text.dart';

/// Генератор шаблонного протокола ОПГ.
///
/// Описание — каркас шаблона (шапка, адентия, тесное положение, ретенция),
/// затем зубные находки как в КЛКТ: строки «1.6 зуб — находка; находка.»
/// по возрастанию номера зуба, находки одного набора зубов сливаются
/// через «; ». Дальше нормы разделов без находок и общие находки.
/// Норма кариеса, периапикальных изменений, пародонта, канала и ВНЧС
/// печатается только если в разделе нет находок.
/// Каркас включён всегда — [includeSkeleton] и [includeTmjNorm] игнорируются,
/// пустой протокол без находок и удалённых зубов валиден (полная норма).
///
/// Заключение — без шапки «КТ-картина:», в порядке шаблона: адентия
/// (автоматически из удалённых зубов) → находки в порядке справочника.
/// Если находок и удалённых зубов нет — «Без видимой патологии.»
/// Номера зубов попадают в заключение только при наличии {teeth} в шаблоне.
class OpgReportGenerator implements ProtocolReportGenerator {
  const OpgReportGenerator({required this.catalog});

  final PathologyRepository catalog;

  /// «области/зуба/зубов/:» перед {teeth} — подставляются только номера.
  static final _numbersOnlyBefore = RegExp(
    r'(?:области|зуба|зубов|:)\s*\{teeth\}',
  );
  static final _teethPlaceholder = RegExp(r'\s*\{teeth\}');
  static final _unresolvedPlaceholders = RegExp(
    r'\s*\{(?:size|adjacent|direction|side)\}',
  );
  static final _extraSpaces = RegExp(r'\s{2,}');

  @override
  ReportText generate({
    required List<SelectedPathology> findings,
    required Set<int> extractedFdis,
    bool includeSkeleton = true,
    bool includeTmjNorm = false,
  }) {
    final segments = _mergedSegments(findings);
    return ReportText(
      description: _buildDescription(findings, segments, extractedFdis),
      conclusion: _buildConclusion(segments, extractedFdis),
    );
  }

  // --- Свёртка находок -------------------------------------------------------

  /// Полные находки, свёрнутые по патологии и уточнениям: одинаковая патология
  /// с одинаковыми уточнениями на разных зубах — один сегмент с объединённым
  /// списком зубов. Порядок — по справочнику.
  List<_OpgSegment> _mergedSegments(List<SelectedPathology> findings) {
    final rank = _catalogRanks();
    final byKey = <String, _OpgSegment>{};
    var order = 0;
    for (final finding in findings) {
      final pathology = catalog.byId(finding.pathologyId);
      if (pathology == null || !finding.isCompleteFor(pathology)) continue;

      final key = [
        pathology.id,
        finding.side,
        finding.direction,
        finding.adjacentFdi,
        finding.measurements?.isComplete == true
            ? finding.measurements!.render()
            : '',
      ].join('|');

      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = _OpgSegment(
          pathology,
          finding,
          sortFdis(finding.toothFdis),
          order: order++,
        );
      } else {
        existing.fdis
          ..addAll(finding.toothFdis.where((f) => !existing.fdis.contains(f)))
          ..sort();
      }
    }

    final segments = byKey.values.toList()
      ..sort((a, b) {
        final byRank = (rank[a.pathology.id] ?? 999).compareTo(
          rank[b.pathology.id] ?? 999,
        );
        if (byRank != 0) return byRank;
        return a.order.compareTo(b.order);
      });
    return segments;
  }

  Map<String, int> _catalogRanks() {
    final ranks = <String, int>{};
    var i = 0;
    for (final g in catalog.groups) {
      for (final p in g.items) {
        ranks[p.id] = i++;
      }
    }
    return ranks;
  }

  // --- Описание --------------------------------------------------------------

  String _buildDescription(
    List<SelectedPathology> findings,
    List<_OpgSegment> segments,
    Set<int> extracted,
  ) {
    List<_OpgSegment> byGroup(String groupId) => [
      for (final s in segments)
        if (s.pathology.groupId == groupId) s,
    ];
    List<_OpgSegment> byId(String id) => [
      for (final s in segments)
        if (s.pathology.id == id) s,
    ];

    final crowding = byId('opg_crowding');
    final retention = byId('opg_retention');
    final caries = byGroup('og3');
    final periapical = byGroup('og5');
    final perio = byGroup('og6');
    final perioGeneral = [
      for (final s in perio)
        if (s.pathology.scope == PathologyScope.general) s,
    ];
    final canal = byId('opg_mandibular_canal');
    final tmj = byId('opg_tmj');
    final extras = [...byGroup('og7'), ...byId('opg_sinus_opacity')];

    final lines = <String>[
      boilerplate.opgHeader,
      boilerplate.opgProjectionNote,
      _adentiaLine(extracted),
      _crowdingLine(crowding),
      _retentionLine(retention),
      ..._toothLines(findings, extracted),
      if (caries.isEmpty) boilerplate.cariesNorm,
      if (periapical.isEmpty) boilerplate.periapicalNorm,
      if (perio.isEmpty)
        boilerplate.perioNorm
      else
        for (final s in perioGeneral) _sentence(s),
      if (canal.isEmpty)
        boilerplate.mandibularCanalNorm
      else
        for (final s in canal) _sentence(s),
      if (tmj.isEmpty)
        boilerplate.tmjNorm
      else
        for (final s in tmj) _sentence(s),
      for (final s in extras) _sentence(s),
    ];
    return lines.join('\n');
  }

  /// Зубные находки, кроме тесного положения и ретенции: одна строка
  /// на набор зубов, префикс как в КЛКТ, тела через «; ».
  List<String> _toothLines(
    List<SelectedPathology> findings,
    Set<int> extracted,
  ) {
    const excluded = {'opg_crowding', 'opg_retention'};
    final rank = _catalogRanks();
    final segments = <_ToothSeg>[];
    for (final finding in findings) {
      final pathology = catalog.byId(finding.pathologyId);
      if (pathology == null || !finding.isCompleteFor(pathology)) continue;
      if (pathology.scope != PathologyScope.tooth) continue;
      if (excluded.contains(pathology.id)) continue;

      final sorted = sortFdis(finding.toothFdis);
      final present = sorted.where((f) => !extracted.contains(f)).toList();
      final gone = sorted.where(extracted.contains).toList();
      if (present.isNotEmpty) {
        segments.add(_ToothSeg(pathology, finding, present, extracted: false));
      }
      if (gone.isNotEmpty) {
        segments.add(_ToothSeg(pathology, finding, gone, extracted: true));
      }
    }

    final groups = <String, List<_ToothSeg>>{};
    for (final s in segments) {
      groups.putIfAbsent(s.teethKey, () => []).add(s);
    }

    final lines = <_ToothLine>[];
    var index = 0;
    for (final group in groups.values) {
      group.sort(
        (a, b) => (rank[a.pathology.id] ?? 999).compareTo(
          rank[b.pathology.id] ?? 999,
        ),
      );
      final bodies = [for (final s in group) _descriptionBody(s)];
      lines.add(
        _ToothLine(
          primary: group.first.fdis.first,
          secondary: index++,
          text: '${_descriptionPrefix(group.first)}${bodies.join('; ')}.',
        ),
      );
    }
    lines.sort();
    return [for (final l in lines) l.text];
  }

  String _descriptionPrefix(_ToothSeg segment) {
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

  String _descriptionBody(_ToothSeg segment) {
    final template = segment.extracted
        ? (segment.pathology.extractedTemplate ??
              segment.pathology.descriptionTemplate)
        : segment.pathology.descriptionTemplate;
    return _render(template, segment.finding);
  }

  /// «Адентия: нет.» / «Адентия: отсутствует зуб 3.6.» / «Адентия: полная.»
  String _adentiaLine(Set<int> extracted) {
    if (extracted.isEmpty) {
      return '${boilerplate.adentiaPrefix}${boilerplate.adentiaNone}.';
    }
    if (extracted.length >= allFdis.length) {
      return '${boilerplate.adentiaPrefix}${boilerplate.adentiaFull}.';
    }
    final sorted = sortFdis(extracted);
    final noun = sorted.length == 1 ? 'отсутствует зуб' : 'отсутствуют зубы';
    return '${boilerplate.adentiaPrefix}$noun ${formatFdis(sorted)}.';
  }

  /// «Тесное положение зубов: нет.» / «… 1, 2 сегментов.»
  String _crowdingLine(List<_OpgSegment> crowding) {
    if (crowding.isEmpty) {
      return '${boilerplate.crowdingPrefix}${boilerplate.crowdingNone}.';
    }
    final quadrants = <int>{
      for (final s in crowding)
        for (final fdi in s.fdis) fdiQuadrant(fdi),
    }.toList()..sort();
    final noun = quadrants.length == 1 ? 'сегмента' : 'сегментов';
    return '${boilerplate.crowdingPrefix}${quadrants.join(', ')} $noun.';
  }

  /// «Ретенция и дистопия: нет.» / «… 3.8, 4.8.»
  String _retentionLine(List<_OpgSegment> retention) {
    if (retention.isEmpty) {
      return '${boilerplate.retentionPrefix}${boilerplate.retentionNone}.';
    }
    final teeth = sortFdis({for (final s in retention) ...s.fdis});
    return '${boilerplate.retentionPrefix}${formatFdis(teeth)}.';
  }

  /// Предложение описания из сегмента: шаблон + зубы + уточнения + точка.
  String _sentence(_OpgSegment s) {
    var text = _render(s.pathology.descriptionTemplate, s.finding);
    text = _substituteTeeth(text, s, numbers: formatFdis(s.fdis));
    return '${_capitalize(text)}.';
  }

  // --- Заключение --------------------------------------------------------------

  String _buildConclusion(List<_OpgSegment> segments, Set<int> extracted) {
    final lines = <String>[];

    if (extracted.isNotEmpty) {
      lines.add(
        extracted.length >= allFdis.length
            ? boilerplate.conclusionFullAdentia
            : boilerplate.conclusionPartialAdentia,
      );
    }

    final seen = <String>{};
    for (final s in segments) {
      if (s.pathology.omitFromConclusion) continue;
      var text = _render(
        s.pathology.conclusionTemplate,
        s.finding,
        forConclusion: true,
      );
      // Номера зубов — только при явном {teeth} в шаблоне
      // («пародонтальные карманы (смотрите описание)» зубы не повторяет).
      text = _substituteTeeth(text, s, numbers: formatFdiRanges(s.fdis));
      final line = '${_capitalize(text)}.';
      if (seen.add(line)) lines.add(line);
    }

    // Норма — нет ни строк заключения, ни находок (в том числе тех,
    // что в заключение не выносятся: тесное положение, ретейнер).
    if (lines.isEmpty && segments.isEmpty) {
      return boilerplate.conclusionNoPathology;
    }
    return lines.join('\n');
  }

  // --- Подстановки --------------------------------------------------------------

  /// Заменяет {teeth}: после «области/зуба/зубов/:» — только номера,
  /// для area-стиля — «в области N», иначе «зуба N» / «зубов N».
  /// Без зубов плейсхолдер вырезается.
  String _substituteTeeth(
    String text,
    _OpgSegment s, {
    required String numbers,
  }) {
    if (!text.contains('{teeth}')) return text;
    if (s.fdis.isEmpty) {
      return text
          .replaceAll(_teethPlaceholder, '')
          .replaceAll(_extraSpaces, ' ')
          .trim();
    }
    if (_numbersOnlyBefore.hasMatch(text)) {
      return text.replaceAll('{teeth}', numbers);
    }
    final ref = s.pathology.refStyle == ToothRefStyle.area
        ? 'в области $numbers'
        : (s.fdis.length == 1 ? 'зуба $numbers' : 'зубов $numbers');
    return text.replaceAll('{teeth}', ref);
  }

  /// Заменяет {size}, {side}, {direction}, {adjacent}; в заключении размер
  /// не подставляется. Незаполненные плейсхолдеры вырезаются.
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
}

/// Свёрнутая находка ОПГ: патология + объединённые зубы.
class _OpgSegment {
  _OpgSegment(this.pathology, this.finding, this.fdis, {required this.order});

  final Pathology pathology;
  final SelectedPathology finding;

  /// Отсортированные по возрастанию номера зубов (пусто для general).
  final List<int> fdis;

  /// Порядок первого появления — для стабильной сортировки.
  final int order;
}

/// Зубная находка описания: один набор зубов, без свёртки между наборами.
class _ToothSeg {
  _ToothSeg(this.pathology, this.finding, this.fdis, {required this.extracted});

  final Pathology pathology;
  final SelectedPathology finding;
  final List<int> fdis;
  final bool extracted;

  String get teethKey => '${fdis.join(',')}|$extracted';
}

/// Строка описания с ключами сортировки по номеру зуба.
class _ToothLine implements Comparable<_ToothLine> {
  const _ToothLine({
    required this.primary,
    required this.secondary,
    required this.text,
  });

  final int primary;
  final int secondary;
  final String text;

  @override
  int compareTo(_ToothLine other) {
    final byPrimary = primary.compareTo(other.primary);
    if (byPrimary != 0) return byPrimary;
    return secondary.compareTo(other.secondary);
  }
}
