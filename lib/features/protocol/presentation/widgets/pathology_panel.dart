import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../bloc/protocol_state.dart';

/// Аккордеон групп патологий. Внутри группы — чипы,
/// отсортированные по убыванию частоты (★).
///
/// Подсвечены чипы патологий в черновике. У патологий,
/// уже добавленных в протокол, показывается счётчик находок.
///
/// После успешного добавления или сохранения находки все группы
/// сворачиваются. КЛКТ и ОПГ используют эту же панель.
class PathologyPanel extends StatefulWidget {
  const PathologyPanel({super.key});

  @override
  State<PathologyPanel> createState() => _PathologyPanelState();
}

class _PathologyPanelState extends State<PathologyPanel> {
  /// Поколение ключей [ExpansionTile]. Растёт после фиксации черновика,
  /// чтобы сбросить сохранённое в [PageStorage] раскрытие групп.
  var _expansionEpoch = 0;

  bool _draftWasCommitted(ProtocolState prev, ProtocolState curr) {
    return prev.drafts.isNotEmpty &&
        curr.drafts.isEmpty &&
        prev.findings != curr.findings;
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.read<PathologyRepository>().groups;
    return BlocListener<ProtocolBloc, ProtocolState>(
      listenWhen: _draftWasCommitted,
      listener: (context, state) => setState(() => _expansionEpoch++),
      child: BlocBuilder<ProtocolBloc, ProtocolState>(
        buildWhen: (prev, curr) =>
            prev.findings != curr.findings || prev.drafts != curr.drafts,
        builder: (context, state) {
          final usedCounts = <String, int>{};
          for (final f in state.findings) {
            usedCounts[f.pathologyId] = (usedCounts[f.pathologyId] ?? 0) + 1;
          }
          final draftPathologyIds = state.draftPathologyIds;

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final group = groups[index];
              final usedCount = group.items
                  .where((p) => usedCounts.containsKey(p.id))
                  .length;
              return _GroupTile(
                group: group,
                usedCounts: usedCounts,
                draftPathologyIds: draftPathologyIds,
                usedCount: usedCount,
                initiallyExpanded: _expansionEpoch == 0 && index == 0,
                expansionEpoch: _expansionEpoch,
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.usedCounts,
    required this.draftPathologyIds,
    required this.usedCount,
    required this.initiallyExpanded,
    required this.expansionEpoch,
  });

  final PathologyGroup group;
  final Map<String, int> usedCounts;
  final Set<String> draftPathologyIds;
  final int usedCount;
  final bool initiallyExpanded;
  final int expansionEpoch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey('${group.id}#$expansionEpoch'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (usedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$usedCount',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                ),
              ),
          ],
        ),
        children: [
          _GroupChips(
            items: group.items,
            usedCounts: usedCounts,
            draftPathologyIds: draftPathologyIds,
          ),
        ],
      ),
    );
  }
}

/// Чипы группы. Патологии с общим [Pathology.chipGroup] — одна строка
/// кнопок равной ширины, остальные — обычный перенос.
class _GroupChips extends StatelessWidget {
  const _GroupChips({
    required this.items,
    required this.usedCounts,
    required this.draftPathologyIds,
  });

  final List<Pathology> items;
  final Map<String, int> usedCounts;
  final Set<String> draftPathologyIds;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final loose = <Widget>[];
    final seenGroups = <String>{};

    void flushLoose() {
      if (loose.isEmpty) return;
      blocks.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 6, runSpacing: 6, children: [...loose]),
        ),
      );
      loose.clear();
    }

    for (var i = 0; i < items.length; i++) {
      final pathology = items[i];
      final chipGroup = pathology.chipGroup;
      if (chipGroup == null) {
        loose.add(_chip(pathology));
        continue;
      }
      if (!seenGroups.add(chipGroup)) continue;
      flushLoose();
      final row = [
        for (final item in items)
          if (item.chipGroup == chipGroup) item,
      ];
      blocks.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var k = 0; k < row.length; k++) ...[
              if (k > 0) const SizedBox(width: 6),
              Expanded(child: _chip(row[k], expanded: true)),
            ],
          ],
        ),
      );
    }
    flushLoose();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          blocks[i],
        ],
      ],
    );
  }

  Widget _chip(Pathology pathology, {bool expanded = false}) {
    return _PathologyChip(
      pathology: pathology,
      isDraft: draftPathologyIds.contains(pathology.id),
      usedCount: usedCounts[pathology.id] ?? 0,
      expanded: expanded,
    );
  }
}

class _PathologyChip extends StatelessWidget {
  const _PathologyChip({
    required this.pathology,
    required this.isDraft,
    required this.usedCount,
    this.expanded = false,
  });

  final Pathology pathology;

  /// Патология сейчас в черновике — чип подсвечен.
  final bool isDraft;

  /// Сколько находок с этой патологией уже в протоколе.
  final int usedCount;

  /// Кнопка на всю ширину ячейки: текст переносится, а не обрезается.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = usedCount > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$usedCount',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          )
        : null;
    final name = Text(
      pathology.name,
      textAlign: expanded ? TextAlign.center : TextAlign.start,
      style: const TextStyle(fontSize: 12.5),
      maxLines: expanded ? null : 1,
      overflow: expanded ? TextOverflow.clip : TextOverflow.ellipsis,
    );
    return Tooltip(
      message: [
        '★' * pathology.frequency,
        if (pathology.scope == PathologyScope.tooth)
          'Привязана к зубам — выберите зубы в формуле'
        else
          'Общая патология (без привязки к зубам)',
        if (usedCount > 0) 'В протоколе: $usedCount',
      ].join('\n'),
      waitDuration: const Duration(milliseconds: 700),
      child: FilterChip(
        label: expanded
            ? Row(
                children: [
                  Expanded(child: name),
                  if (badge != null) ...[const SizedBox(width: 5), badge],
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: name),
                  if (badge != null) ...[const SizedBox(width: 5), badge],
                ],
              ),
        selected: isDraft,
        showCheckmark: true,
        avatar: pathology.scope == PathologyScope.general && !isDraft
            ? Icon(Icons.public, size: 14, color: scheme.outline)
            : null,
        onSelected: (_) =>
            context.read<ProtocolBloc>().add(PathologySelected(pathology.id)),
      ),
    );
  }
}
