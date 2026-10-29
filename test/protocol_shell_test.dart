import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/features/protocol/presentation/pages/protocol_shell.dart';

void _setDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('вкладка ОПГ: шаблон нормы, находка, независимость сессий', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: ProtocolShell()));
    await tester.pumpAndSettle();

    // Обе вкладки на месте, по умолчанию активна КЛКТ:
    // каркас есть, фразы ВНЧС нет.
    expect(find.text('КЛКТ'), findsOneWidget);
    expect(find.text('ОПГ'), findsOneWidget);
    expect(find.textContaining('Зубная формула:'), findsOneWidget);
    expect(find.textContaining('ВНЧС без структурных изменений'), findsNothing);

    // Переключение на ОПГ: пустой протокол — полный шаблон нормы.
    await tester.tap(find.text('ОПГ'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('На ортопантомограмме определяется:'),
      findsOneWidget,
    );
    expect(find.textContaining('Адентия: нет.'), findsOneWidget);
    // Переключатель «ВНЧС» на ОПГ скрыт.
    expect(find.text('ВНЧС'), findsNothing);

    // Находка ОПГ: зуб 3.8 + «Ретинирован, дистопирован», Enter.
    await tester.tap(find.text('3.8'));
    await tester.pump();
    await tester.tap(find.text('Ретинирован, дистопирован'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ретенция и дистопия: 3.8.'), findsOneWidget);

    // КЛКТ-сессия не затронута: каркас на месте, находки ОПГ нет.
    await tester.tap(find.text('КЛКТ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Зубная формула:'), findsOneWidget);
    expect(find.textContaining('ВНЧС без структурных изменений'), findsNothing);
    expect(find.text('ВНЧС'), findsOneWidget);
    expect(find.textContaining('Ретенция и дистопия'), findsNothing);

    // Находка ОПГ сохранилась при возврате на вкладку.
    await tester.tap(find.text('ОПГ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ретенция и дистопия: 3.8.'), findsOneWidget);
  });

  testWidgets('переключатель «ВНЧС» добавляет фразу ВНЧС', (tester) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: ProtocolShell()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Зубная формула:'), findsOneWidget);
    expect(find.textContaining('ВНЧС без структурных изменений'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ВНЧС без структурных изменений.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('ВНЧС без структурных изменений'), findsNothing);
    expect(find.textContaining('Зубная формула:'), findsOneWidget);
  });

  testWidgets('тотальное и субтотальное заполнение — две кнопки в одном ряду', (
    tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: ProtocolShell()));
    await tester.pumpAndSettle();

    final group = find.text('7. ЛОР-патология: гайморовы пазухи');
    await tester.scrollUntilVisible(
      group,
      300,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(group);
    await tester.pumpAndSettle();

    final total = find.text('Тотальное заполнение мягкотканым компонентом');
    final subtotal = find.text(
      'Субтотальное заполнение мягкотканым компонентом',
    );
    expect(total, findsOneWidget);
    expect(subtotal, findsOneWidget);
    expect(find.textContaining('Тотальное / субтотальное'), findsNothing);

    final totalBox = tester.getRect(total);
    final subtotalBox = tester.getRect(subtotal);
    expect(subtotalBox.left, greaterThan(totalBox.right - 1));
    expect((totalBox.center.dy - subtotalBox.center.dy).abs(), lessThan(12));
  });

  testWidgets('соседний зуб — только контактирующие номера', (tester) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(const MaterialApp(home: ProtocolShell()));
    await tester.pumpAndSettle();

    final contact = find.text('Полость на контакте с … зубом');
    await tester.scrollUntilVisible(
      contact,
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(contact);
    await tester.pumpAndSettle();

    expect(find.text('Сначала зуб'), findsOneWidget);

    await tester.tap(find.text('1.6'));
    await tester.pumpAndSettle();
    expect(find.text('Сначала зуб'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(_dropdownValues(tester), [15, 17]);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1.7'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(_dropdownValues(tester), [15, 18]);
  });
}

List<int?> _dropdownValues(WidgetTester tester) {
  return tester
      .widgetList<DropdownMenuItem<int>>(find.byType(DropdownMenuItem<int>))
      .map((item) => item.value)
      .toList();
}
