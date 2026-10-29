import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/fdi.dart';
import '../../domain/entities/pathology.dart';
import '../../domain/entities/selected_pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../bloc/protocol_state.dart';

/// Редактор черновиков находок: статус (зубы + патологии), уточнения
/// (размеры, сторона, направление, соседний зуб) и кнопки
/// «Добавить в протокол» / «Сохранить изменения» + «Отмена».
///
/// Показывается, когда есть черновики или выбраны зубы.
/// Enter — зафиксировать черновики.
class FindingComposer extends StatelessWidget {
  const FindingComposer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProtocolBloc, ProtocolState>(
      buildWhen: (prev, curr) =>
          prev.drafts != curr.drafts ||
          prev.selectedFdis != curr.selectedFdis ||
          prev.editingUid != curr.editingUid,
      builder: (context, state) {
        if (!state.hasDrafts && state.selectedFdis.isEmpty) {
          return const SizedBox.shrink();
        }

        final bloc = context.read<ProtocolBloc>();
        final catalog = context.read<PathologyRepository>();
        final resolved = <({SelectedPathology draft, Pathology pathology})>[
          for (final draft in state.drafts)
            if (catalog.byId(draft.pathologyId) case final pathology?)
              (draft: draft, pathology: pathology),
        ];
        final scheme = Theme.of(context).colorScheme;

        final hasTooth = resolved.any(
          (r) => r.pathology.scope == PathologyScope.tooth,
        );
        final needsTeeth = hasTooth && state.selectedFdis.isEmpty;
        final neighbors = neighboringFdis(state.selectedFdis).toSet();
        final fieldsIncomplete = resolved.any(
          (r) =>
              !r.draft.isCompleteFor(r.pathology) ||
              (r.pathology.requiresAdjacentTooth &&
                  !neighbors.contains(r.draft.adjacentFdi)),
        );
        final canCommit =
            resolved.isNotEmpty && !needsTeeth && !fieldsIncomplete;

        final String? disabledHint;
        if (resolved.isEmpty) {
          disabledHint = 'Выберите патологии из списка ниже';
        } else if (needsTeeth) {
          disabledHint = 'Выберите зубы в формуле';
        } else if (fieldsIncomplete) {
          disabledHint = 'Заполните обязательные поля';
        } else {
          disabledHint = null;
        }

        final fieldGroups = [
          for (final item in resolved)
            if (item.pathology.hasDynamicFields) item,
        ];

        return FocusTraversalGroup(
          child: Card(
            color: scheme.secondaryContainer.withValues(alpha: 0.35),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ComposerHeader(
                    state: state,
                    pathologies: [for (final r in resolved) r.pathology],
                  ),
                  for (final item in fieldGroups) ...[
                    const SizedBox(height: 10),
                    if (resolved.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          item.pathology.name,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.primary),
                        ),
                      ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.pathology.requiresSize)
                          _SizeFields(draft: item.draft),
                        if (item.pathology.requiresSide)
                          _SideSelector(draft: item.draft),
                        if (item.pathology.requiresDirection)
                          _DirectionSelector(draft: item.draft),
                        if (item.pathology.requiresAdjacentTooth)
                          _AdjacentSelector(
                            draft: item.draft,
                            selectedFdis: state.selectedFdis,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: canCommit
                            ? () => bloc.add(const DraftCommitted())
                            : null,
                        icon: Icon(
                          state.isEditing ? Icons.check : Icons.add,
                          size: 18,
                        ),
                        label: Text(
                          state.isEditing
                              ? 'Сохранить изменения'
                              : 'Добавить в протокол',
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => bloc.add(const DraftDiscarded()),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      if (disabledHint != null)
                        Expanded(
                          child: Text(
                            disabledHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.outline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            'Enter — добавить, Esc — отмена',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.outline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Строка статуса черновика: зубы, патологии, режим правки.
class _ComposerHeader extends StatelessWidget {
  const _ComposerHeader({required this.state, required this.pathologies});

  final ProtocolState state;
  final List<Pathology> pathologies;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allGeneral =
        pathologies.isNotEmpty &&
        pathologies.every((p) => p.scope == PathologyScope.general);

    final names = pathologies.isEmpty
        ? 'Выберите патологии'
        : pathologies.map((p) => p.name).join(' · ');
    final parts = <String>[
      if (!allGeneral)
        state.selectedFdis.isEmpty
            ? 'Зубы: не выбраны'
            : 'Зубы: ${formatFdis(sortFdis(state.selectedFdis))}',
      names,
    ];

    return Row(
      children: [
        Icon(
          state.isEditing ? Icons.edit_outlined : Icons.tune,
          size: 16,
          color: scheme.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (state.isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Правка находки',
              style: TextStyle(fontSize: 11, color: scheme.onTertiaryContainer),
            ),
          ),
      ],
    );
  }
}

class _SizeFields extends StatelessWidget {
  const _SizeFields({required this.draft});

  final SelectedPathology draft;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    final m = draft.measurements ?? const Measurements();
    final id = draft.pathologyId;

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: const [
            ButtonSegment(value: 1, label: Text('1 размер')),
            ButtonSegment(value: 2, label: Text('2 размера')),
            ButtonSegment(value: 3, label: Text('3 размера')),
          ],
          selected: {m.count},
          onSelectionChanged: (s) =>
              bloc.add(SizeCountChanged(s.first, pathologyId: id)),
        ),
        _MmField(
          key: ValueKey('${id}_x'),
          label: m.count == 1 ? 'до, мм' : 'X, мм',
          initial: m.x,
          onChanged: (v) =>
              bloc.add(MeasurementsChanged(pathologyId: id, x: v)),
        ),
        if (m.count >= 2)
          _MmField(
            key: ValueKey('${id}_y'),
            label: 'Y, мм',
            initial: m.y,
            onChanged: (v) =>
                bloc.add(MeasurementsChanged(pathologyId: id, y: v)),
          ),
        if (m.count >= 3)
          _MmField(
            key: ValueKey('${id}_z'),
            label: 'Z, мм',
            initial: m.z,
            onChanged: (v) =>
                bloc.add(MeasurementsChanged(pathologyId: id, z: v)),
          ),
      ],
    );
  }
}

class _MmField extends StatelessWidget {
  const _MmField({
    super.key,
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    return SizedBox(
      width: 90,
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        onFieldSubmitted: (_) => bloc.add(const DraftCommitted()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _SideSelector extends StatelessWidget {
  const _SideSelector({required this.draft});

  final SelectedPathology draft;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    return SegmentedButton<Side>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final side in Side.values)
          ButtonSegment(value: side, label: Text(side.label)),
      ],
      selected: {if (draft.side != null) draft.side!},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) {
          bloc.add(SideChanged(s.first, pathologyId: draft.pathologyId));
        }
      },
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({required this.draft});

  final SelectedPathology draft;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    return SegmentedButton<Direction>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: [
        for (final d in Direction.values)
          ButtonSegment(value: d, label: Text(d.label)),
      ],
      selected: {if (draft.direction != null) draft.direction!},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) {
          bloc.add(DirectionChanged(s.first, pathologyId: draft.pathologyId));
        }
      },
    );
  }
}

class _AdjacentSelector extends StatelessWidget {
  const _AdjacentSelector({required this.draft, required this.selectedFdis});

  final SelectedPathology draft;
  final Set<int> selectedFdis;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    final options = neighboringFdis(selectedFdis);
    final value = options.contains(draft.adjacentFdi)
        ? draft.adjacentFdi
        : null;

    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<int>(
        key: ValueKey('adjacent-${draft.pathologyId}-${options.join(',')}'),
        initialValue: value,
        isDense: true,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Соседний зуб',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        hint: const Text('Выберите', overflow: TextOverflow.ellipsis),
        disabledHint: const Text(
          'Сначала зуб',
          overflow: TextOverflow.ellipsis,
        ),
        items: [
          for (final fdi in options)
            DropdownMenuItem(value: fdi, child: Text(formatFdi(fdi))),
        ],
        onChanged: options.isEmpty
            ? null
            : (fdi) {
                if (fdi != null) {
                  bloc.add(
                    AdjacentChanged(fdi, pathologyId: draft.pathologyId),
                  );
                }
              },
      ),
    );
  }
}
