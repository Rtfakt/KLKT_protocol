import 'package:flutter/material.dart';

/// Тема приложения: спокойная медицинская палитра, компактная плотность
/// для широких экранов.
class AppTheme {
  AppTheme._();

  /// Отступ плавающего уведомления от краёв окна.
  ///
  /// Снизу 64 dp — чтобы полоса не закрывала ряд «Копировать в буфер» /
  /// «PDF/DOCX»: отступ рабочей области 12, высота кнопки 40, зазор 12.
  static const EdgeInsets snackBarMargin = EdgeInsets.fromLTRB(16, 8, 16, 64);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00696D));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: const ChipThemeData(
        labelPadding: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: scheme.primary,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: snackBarMargin,
      ),
    );
  }
}
