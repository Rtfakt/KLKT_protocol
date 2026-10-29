import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/core/theme/app_theme.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/study_type.dart';
import 'package:klkt_protocol/features/protocol/domain/services/finding_validator.dart';
import 'package:klkt_protocol/features/protocol/domain/services/report_generator.dart';
import 'package:klkt_protocol/features/protocol/presentation/pages/protocol_shell.dart';

import 'fixtures/fake_pathology_repository.dart';

Widget _app({ThemeData? theme}) {
  final catalog = FakePathologyRepository();
  return MaterialApp(
    theme: theme,
    home: ProtocolShell(
      studies: [
        StudyConfig(
          type: StudyType.cbct,
          label: 'КЛКТ',
          catalog: catalog,
          generator: ReportGenerator(catalog: catalog),
          validator: FindingValidator(catalog: catalog),
        ),
      ],
    ),
  );
}

void _setDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Enter добавляет находку после клика по зубу и чипу патологии', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1.6'));
    await tester.pump();
    await tester.tap(find.text('Зубная без уточнений'));
    await tester.pump();

    expect(find.text('Добавить в протокол'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('1.6: Зубная без уточнений'), findsOneWidget);
    expect(find.text('Добавить в протокол'), findsNothing);
  });

  testWidgets('уведомление «Добавлено» не перекрывает кнопки экспорта', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(_app(theme: AppTheme.light()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1.6'));
    await tester.pump();
    await tester.tap(find.text('Зубная без уточнений'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final bar = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    Rect buttonRect(String label) {
      return tester.getRect(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      );
    }

    final copy = buttonRect('Копировать в буфер');
    final pdf = buttonRect('PDF/DOCX');

    expect(bar.width, greaterThan(400));
    expect(bar.overlaps(copy), isFalse);
    expect(bar.overlaps(pdf), isFalse);
  });

  testWidgets('Enter добавляет две находки после выбора двух чипов патологий', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1.6'));
    await tester.pump();
    await tester.tap(find.text('Зубная без уточнений'));
    await tester.pump();
    await tester.tap(find.text('Зубная с шаблоном удаления'));
    await tester.pump();

    expect(find.text('Добавить в протокол'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('1.6: Зубная без уточнений'), findsOneWidget);
    expect(find.text('1.6: Зубная с шаблоном удаления'), findsOneWidget);
    expect(find.text('Добавить в протокол'), findsNothing);
  });

  testWidgets('Escape сбрасывает черновик', (tester) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1.6'));
    await tester.pump();
    await tester.tap(find.text('Зубная без уточнений'));
    await tester.pump();

    expect(find.text('Добавить в протокол'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.text('Добавить в протокол'), findsNothing);
    expect(find.text('1.6: Зубная без уточнений'), findsNothing);
  });

  testWidgets('после «Добавить в протокол» группы патологий сворачиваются', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Зубная без уточнений').hitTestable(), findsOneWidget);

    await tester.tap(find.text('1.6'));
    await tester.pump();
    await tester.tap(find.text('Зубная без уточнений'));
    await tester.pump();
    await tester.tap(find.text('Добавить в протокол'));
    await tester.pumpAndSettle();

    expect(find.text('1.6: Зубная без уточнений'), findsOneWidget);
    expect(find.text('Зубная без уточнений').hitTestable(), findsNothing);
  });
}
