import '../entities/selected_pathology.dart';

/// Результат генерации: описательная часть и заключение.
class ReportText {
  const ReportText({required this.description, required this.conclusion});

  final String description;
  final String conclusion;

  bool get isEmpty => description.isEmpty && conclusion.isEmpty;

  /// Единый plain-text для копирования в буфер обмена.
  /// Заголовки блоков («ОПИСАТЕЛЬНАЯ ЧАСТЬ», «ЗАКЛЮЧЕНИЕ») не включаются:
  /// в буфер уходят только сами тексты, разделённые пустой строкой.
  String asPlainText() => [
    if (description.isNotEmpty) description,
    if (conclusion.isNotEmpty) conclusion,
  ].join('\n\n');
}

/// Контракт генератора протокола: КЛКТ и ОПГ реализуют его по-своему.
abstract class ProtocolReportGenerator {
  /// [includeSkeleton] — каркас протокола (формула, нормы, замыкающие фразы).
  /// Генератор ОПГ всегда строит полный шаблон и флаги игнорирует.
  /// [includeTmjNorm] — фраза «ВНЧС без структурных изменений» внутри каркаса
  /// КЛКТ; без [includeSkeleton] не действует.
  ReportText generate({
    required List<SelectedPathology> findings,
    required Set<int> extractedFdis,
    required bool includeSkeleton,
    bool includeTmjNorm = false,
  });
}
