import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Временный зонд зависания UI. Stdout + файл в tmp песочницы, без сети.
///
/// Файл: `<Directory.systemTemp>/klkt_hang.log`
/// Читаем строки `HANG`:
/// - `beat` пропал на время колеса → заморожен Dart isolate;
/// - `pointer` сразу, `event` с задержкой → жест дошёл, bloc нет;
/// - `event` сразу, `slow-frame` или beat с фазой не idle → кадр / семантика;
/// - beat идёт, фаза idle, `pointer` нет → блокировка AppKit вне Dart.
class HangProbe {
  HangProbe._();

  static int? _lastEventMs;
  static bool _started = false;
  static RandomAccessFile? _file;

  static void start() {
    if (_started) return;
    _started = true;
    _openFile();
    Bloc.observer = _HangBlocObserver();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    Timer.periodic(const Duration(milliseconds: 250), (_) {
      _log('beat phase=${SchedulerBinding.instance.schedulerPhase}');
    });
    _log('started');
  }

  static void _openFile() {
    try {
      final path = '${Directory.systemTemp.path}/klkt_hang.log';
      _file = File(path).openSync(mode: FileMode.write);
      debugPrint('HANG file $path');
    } catch (error) {
      debugPrint('HANG file-open-failed $error');
    }
  }

  static void pointerDown(PointerDownEvent event) {
    _log(
      'pointer ${event.buttons} @ '
      '${event.position.dx.toStringAsFixed(0)},'
      '${event.position.dy.toStringAsFixed(0)}',
    );
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final build = t.buildDuration.inMilliseconds;
      final raster = t.rasterDuration.inMilliseconds;
      final total = t.totalSpan.inMilliseconds;
      if (total < 32 && build < 32) continue;
      _log('slow-frame total=${total}ms build=${build}ms raster=${raster}ms');
    }
  }

  static void _log(String message) {
    final line = 'HANG ${DateTime.now().millisecondsSinceEpoch} $message';
    debugPrint(line);
    try {
      _file
        ?..writeStringSync('$line\n')
        ..flushSync();
    } catch (_) {}
  }
}

class _HangBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final gap = HangProbe._lastEventMs == null
        ? 0
        : now - HangProbe._lastEventMs!;
    HangProbe._lastEventMs = now;
    HangProbe._log('event ${event.runtimeType} gap=${gap}ms');
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    HangProbe._log('emit ${change.nextState.runtimeType}');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    HangProbe._log('bloc-error $error');
    super.onError(bloc, error, stackTrace);
  }
}
