import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/selected_pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import '../../domain/services/report_generator.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../bloc/protocol_state.dart';

/// Левая зона: живой текст протокола + управление находками и экспорт.
class LivePreview extends StatelessWidget {
  const LivePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final generator = context.read<ReportGenerator>();
    return BlocBuilder<ProtocolBloc, ProtocolState>(
      buildWhen: (prev, curr) =>
          prev.findings != curr.findings ||
          prev.extractedFdis != curr.extractedFdis ||
          prev.activeFindingUid != curr.activeFindingUid,
      builder: (context, state) {
        final report = generator.generate(
          findings: state.findings,
          extractedFdis: state.extractedFdis,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReportCard(
                      title: 'ОПИСАТЕЛЬНАЯ ЧАСТЬ',
                      text: report.description,
                      placeholder:
                          'Выберите зубы и патологии — текст появится здесь.',
                    ),
                    const SizedBox(height: 10),
                    _ReportCard(
                      title: 'ЗАКЛЮЧЕНИЕ',
                      text: report.conclusion,
                      placeholder: 'Заключение формируется автоматически.',
                    ),
                    const SizedBox(height: 10),
                    _FindingsList(state: state),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: report.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                                ClipboardData(text: report.asPlainText()));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Протокол скопирован в буфер')),
                              );
                            }
                          },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Копировать в буфер'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Экспорт в PDF/DOCX — в разработке')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF/DOCX'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.text,
    required this.placeholder,
  });

  final String title;
  final String text;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEmpty = text.isEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.1,
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              isEmpty ? placeholder : text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: isEmpty ? scheme.outline : scheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Чипы добавленных находок: активация для правки и удаление.
class _FindingsList extends StatelessWidget {
  const _FindingsList({required this.state});

  final ProtocolState state;

  @override
  Widget build(BuildContext context) {
    if (state.findings.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ProtocolBloc>();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'НАХОДКИ (${state.findings.length})',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.1,
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => bloc.add(const Cleared()),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Очистить всё'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final finding in state.findings)
                  _FindingChip(
                    finding: finding,
                    isActive: finding.uid == state.activeFindingUid,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingChip extends StatelessWidget {
  const _FindingChip({required this.finding, required this.isActive});

  final SelectedPathology finding;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ProtocolBloc>();
    final pathology =
        context.read<PathologyRepository>().byId(finding.pathologyId);
    if (pathology == null) return const SizedBox.shrink();

    final incomplete = !finding.isCompleteFor(pathology);
    final teeth =
        finding.toothFdis.isEmpty ? '' : '${finding.toothFdis.join(", ")}: ';

    return Tooltip(
      message: incomplete
          ? 'Не заполнены обязательные поля — нажмите, чтобы дозаполнить'
          : 'Нажмите, чтобы редактировать уточнения',
      waitDuration: const Duration(milliseconds: 700),
      child: InputChip(
        label: Text(
          '$teeth${pathology.name}',
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        avatar: incomplete
            ? Icon(Icons.warning_amber_rounded, size: 15, color: scheme.error)
            : null,
        selected: isActive,
        side: incomplete ? BorderSide(color: scheme.error) : null,
        onPressed: () => bloc.add(FindingActivated(finding.uid)),
        onDeleted: () => bloc.add(FindingRemoved(finding.uid)),
      ),
    );
  }
}
