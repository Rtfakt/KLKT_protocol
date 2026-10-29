import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/fdi.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../bloc/protocol_state.dart';

/// Интерактивная зубная формула FDI (11–48).
///
/// - Клик — toggle мультивыбора (обводка основным цветом).
/// - ПКМ или долгое нажатие — toggle статуса «удален»
///   (серый фон + значок «X», зуб остаётся кликабельным).
class DentalFormulaGrid extends StatelessWidget {
  const DentalFormulaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProtocolBloc, ProtocolState>(
      buildWhen: (prev, curr) =>
          prev.selectedFdis != curr.selectedFdis ||
          prev.extractedFdis != curr.extractedFdis ||
          prev.lastCommittedFdis != curr.lastCommittedFdis,
      builder: (context, state) {
        final bloc = context.read<ProtocolBloc>();
        final canRestore =
            state.selectedFdis.isEmpty && state.lastCommittedFdis.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArchRow(fdis: upperArchFdis, state: state),
            const SizedBox(height: 6),
            _ArchRow(fdis: lowerArchFdis, state: state),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Клик — выбрать зуб (мультивыбор). '
                    'ПКМ или долгое нажатие — пометить как удалённый. '
                    'Выбор сбрасывается после добавления находки.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
                if (canRestore)
                  TextButton.icon(
                    onPressed: () => bloc.add(const TeethRestored()),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(
                      'Вернуть ${formatFdis(sortFdis(state.lastCommittedFdis))}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                if (state.selectedFdis.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      for (final fdi in {...state.selectedFdis}) {
                        bloc.add(ToothSelectionToggled(fdi));
                      }
                    },
                    icon: const Icon(Icons.deselect, size: 16),
                    label: const Text(
                      'Снять выбор',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ArchRow extends StatelessWidget {
  const _ArchRow({required this.fdis, required this.state});

  final List<int> fdis;
  final ProtocolState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < fdis.length; i++) ...[
          // Средняя линия между квадрантами.
          if (i == 8)
            Container(
              width: 1.5,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          Expanded(
            child: _ToothCell(
              fdi: fdis[i],
              isSelected: state.selectedFdis.contains(fdis[i]),
              isExtracted: state.extractedFdis.contains(fdis[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToothCell extends StatelessWidget {
  const _ToothCell({
    required this.fdi,
    required this.isSelected,
    required this.isExtracted,
  });

  final int fdi;
  final bool isSelected;
  final bool isExtracted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ProtocolBloc>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message: isExtracted
            ? 'Зуб ${formatFdi(fdi)} (удален)'
            : 'Зуб ${formatFdi(fdi)}',
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onSecondaryTap: () => bloc.add(ExtractedToggled(fdi)),
          onLongPress: () => bloc.add(ExtractedToggled(fdi)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => bloc.add(ToothSelectionToggled(fdi)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 44,
              decoration: BoxDecoration(
                color: isExtracted
                    ? scheme.surfaceContainerHighest
                    : isSelected
                        ? scheme.primaryContainer
                        : scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    formatFdi(fdi),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isExtracted
                          ? scheme.outline
                          : isSelected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                    ),
                  ),
                  if (isExtracted)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(Icons.close,
                          size: 12, color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
