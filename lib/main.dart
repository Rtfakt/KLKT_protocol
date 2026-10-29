import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'debug/hang_probe.dart';

/// Flutter шлёт одиночный synthesized KeyUp для Caps Lock, если он включён
/// на старте. В debug-сессии отладчик останавливается на этом assert до
/// показа первого кадра, и окно остаётся чёрным.
bool _isCapsLockStartupAssert(Object error) {
  final message = error.toString();
  return message.contains('physical key is not pressed') &&
      message.contains('Caps Lock');
}

void main() {
  runZonedGuarded(_start, (error, stack) {
    if (_isCapsLockStartupAssert(error)) return;
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  });
}

void _start() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, stack) {
    return _isCapsLockStartupAssert(error);
  };
  HangProbe.start();
  runApp(const KlktProtocolApp());
}
