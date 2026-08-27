import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/pathology_repository.dart';
import '../bloc/protocol_bloc.dart';
import '../widgets/dental_formula_grid.dart';
import '../widgets/dynamic_fields_panel.dart';
import '../widgets/live_preview.dart';
import '../widgets/pathology_panel.dart';

/// Главный экран: слева Live Preview (40%), справа панель управления (60%).
class ProtocolPage extends StatelessWidget {
  const ProtocolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProtocolBloc(catalog: context.read<PathologyRepository>()),
      child: _NoticeListener(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Протокол КЛКТ челюстно-лицевой области'),
            centerTitle: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Левая зона — Live Preview (40%).
                const Expanded(
                  flex: 4,
                  child: LivePreview(),
                ),
                const SizedBox(width: 12),
                // Правая зона — панель управления (60%).
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: const DentalFormulaGrid(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const DynamicFieldsPanel(),
                      const SizedBox(height: 10),
                      const Expanded(child: PathologyPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Показывает SnackBar на одноразовые уведомления из [ProtocolBloc.notices].
class _NoticeListener extends StatefulWidget {
  const _NoticeListener({required this.child});

  final Widget child;

  @override
  State<_NoticeListener> createState() => _NoticeListenerState();
}

class _NoticeListenerState extends State<_NoticeListener> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<ProtocolBloc>().notices.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
