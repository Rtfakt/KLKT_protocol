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

/// Панель уточнений активной находки: размеры (1–3), сторона,
/// направление, соседний зуб. Показывается только когда активная
/// находка требует хотя бы одно поле.
class DynamicFieldsPanel extends StatelessWidget {
  const DynamicFieldsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProtocolBloc, ProtocolState>(
      buildWhen: (prev, curr) =>
          prev.activeFindingUid != curr.activeFindingUid ||
          prev.findings != curr.findings,
      builder: (context, state) {
        final finding = state.activeFinding;
        final pathology = finding == null
            ? null
            : context.read<PathologyRepository>().byId(finding.pathologyId);
        if (finding == null ||
            pathology == null ||
            !pathology.hasDynamicFields) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: scheme.secondaryContainer.withValues(alpha: 0.35),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Уточнения: ${pathology.name}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!finding.isCompleteFor(pathology))
                      Tooltip(
                        message: 'Заполните обязательные поля — '
                            'иначе находка не попадёт в текст',
                        child: Icon(Icons.warning_amber_rounded,
                            size: 18, color: scheme.error),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (pathology.requiresSize) _SizeFields(finding: finding),
                    if (pathology.requiresSide) _SideSelector(finding: finding),
                    if (pathology.requiresDirection)
                      _DirectionSelector(finding: finding),
                    if (pathology.requiresAdjacentTooth)
                      _AdjacentSelector(finding: finding),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SizeFields extends StatelessWidget {
  const _SizeFields({required this.finding});

  final SelectedPathology finding;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    final m = finding.measurements ?? const Measurements();

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
          onSelectionChanged: (s) => bloc.add(SizeCountChanged(s.first)),
        ),
        _MmField(
          key: ValueKey('${finding.uid}_x'),
          label: m.count == 1 ? 'до, мм' : 'X, мм',
          initial: m.x,
          onChanged: (v) => bloc.add(MeasurementsChanged(x: v)),
        ),
        if (m.count >= 2)
          _MmField(
            key: ValueKey('${finding.uid}_y'),
            label: 'Y, мм',
            initial: m.y,
            onChanged: (v) => bloc.add(MeasurementsChanged(y: v)),
          ),
        if (m.count >= 3)
          _MmField(
            key: ValueKey('${finding.uid}_z'),
            label: 'Z, мм',
            initial: m.z,
            onChanged: (v) => bloc.add(MeasurementsChanged(z: v)),
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
    return SizedBox(
      width: 90,
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class _SideSelector extends StatelessWidget {
  const _SideSelector({required this.finding});

  final SelectedPathology finding;

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
      selected: {if (finding.side != null) finding.side!},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) bloc.add(SideChanged(s.first));
      },
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  const _DirectionSelector({required this.finding});

  final SelectedPathology finding;

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
      selected: {if (finding.direction != null) finding.direction!},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) bloc.add(DirectionChanged(s.first));
      },
    );
  }
}

class _AdjacentSelector extends StatelessWidget {
  const _AdjacentSelector({required this.finding});

  final SelectedPathology finding;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProtocolBloc>();
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        initialValue: finding.adjacentFdi,
        isDense: true,
        decoration: const InputDecoration(
          labelText: 'Соседний зуб',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: [
          for (final fdi in allFdis)
            DropdownMenuItem(value: fdi, child: Text('$fdi')),
        ],
        onChanged: (fdi) {
          if (fdi != null) bloc.add(AdjacentChanged(fdi));
        },
      ),
    );
  }
}
