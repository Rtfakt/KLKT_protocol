import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../bloc/protocol_state.dart';

/// Аккордеон групп патологий. Внутри группы — чипы,
/// отсортированные по убыванию частоты (★).
class PathologyPanel extends StatelessWidget {
  const PathologyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = context.read<PathologyRepository>().groups;
    return BlocBuilder<ProtocolBloc, ProtocolState>(
      buildWhen: (prev, curr) => prev.findings != curr.findings,
      builder: (context, state) {
        final usedPathologyIds =
            state.findings.map((f) => f.pathologyId).toSet();

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final group = groups[index];
            final activeCount = group.items
                .where((p) => usedPathologyIds.contains(p.id))
                .length;
            return _GroupTile(
              group: group,
              usedPathologyIds: usedPathologyIds,
              activeCount: activeCount,
              initiallyExpanded: index == 0,
            );
          },
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.usedPathologyIds,
    required this.activeCount,
    required this.initiallyExpanded,
  });

  final PathologyGroup group;
  final Set<String> usedPathologyIds;
  final int activeCount;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey(group.id),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (activeCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                ),
              ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final pathology in group.items)
                  _PathologyChip(
                    pathology: pathology,
                    isUsed: usedPathologyIds.contains(pathology.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathologyChip extends StatelessWidget {
  const _PathologyChip({required this.pathology, required this.isUsed});

  final Pathology pathology;
  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: [
        '★' * pathology.frequency,
        if (pathology.scope == PathologyScope.tooth)
          'Привязана к зубам — сначала выберите зубы в формуле'
        else
          'Общая патология (без привязки к зубам)',
      ].join('\n'),
      waitDuration: const Duration(milliseconds: 700),
      child: FilterChip(
        label: Text(
          pathology.name,
          style: const TextStyle(fontSize: 12.5),
        ),
        selected: isUsed,
        showCheckmark: true,
        avatar: pathology.scope == PathologyScope.general && !isUsed
            ? Icon(Icons.public, size: 14, color: scheme.outline)
            : null,
        onSelected: (_) => context
            .read<ProtocolBloc>()
            .add(PathologyToggled(pathology.id)),
      ),
    );
  }
}
