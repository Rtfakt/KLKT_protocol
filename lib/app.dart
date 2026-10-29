import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'debug/hang_probe.dart';
import 'features/protocol/presentation/pages/protocol_shell.dart';

class KlktProtocolApp extends StatelessWidget {
  const KlktProtocolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Протокол челюстно-лицевой области',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: HangProbe.pointerDown,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const ProtocolShell(),
    );
  }
}
