import 'package:equatable/equatable.dart';

/// Привязка патологии: к конкретным зубам или общая (ЛОР, ВНЧС и т.п.).
enum PathologyScope { tooth, general }

/// Сторона поражения для ЛОР-патологий и ВНЧС.
enum Side { left, right, bilateral }

/// Направление (для шипов перегородки и искривлений).
enum Direction { toRight, toLeft }

extension SideText on Side {
  String get label => switch (this) {
        Side.left => 'Слева',
        Side.right => 'Справа',
        Side.bilateral => 'Двустороннее',
      };

  /// Форма для вставки в текст протокола.
  String get reportText => switch (this) {
        Side.left => 'слева',
        Side.right => 'справа',
        Side.bilateral => 'с двух сторон',
      };
}

extension DirectionText on Direction {
  String get label => switch (this) {
        Direction.toRight => 'Вправо',
        Direction.toLeft => 'Влево',
      };

  String get reportText => switch (this) {
        Direction.toRight => 'вправо',
        Direction.toLeft => 'влево',
      };
}

/// Элемент справочника патологий.
class Pathology extends Equatable {
  const Pathology({
    required this.id,
    required this.groupId,
    required this.name,
    required this.descriptionTemplate,
    required this.conclusionText,
    required this.frequency,
    required this.scope,
    this.extractedTemplate,
    this.requiresSize = false,
    this.requiresSide = false,
    this.requiresDirection = false,
    this.requiresAdjacentTooth = false,
  });

  final String id;
  final String groupId;

  /// Название для чипа в UI (как в справочнике).
  final String name;

  /// Шаблон описательной части. Плейсхолдеры: {size}, {side}, {direction},
  /// {adjacent}. Для tooth-scope подставляется после «[N] зуб - ».
  final String descriptionTemplate;

  /// Специальный шаблон для удалённого зуба (например, Radix).
  final String? extractedTemplate;

  /// Фраза для заключения в дательном падеже
  /// («КТ-картина соответствует …»).
  final String conclusionText;

  /// Частота использования 1–5 (★), сортировка внутри группы по убыванию.
  final int frequency;

  final PathologyScope scope;
  final bool requiresSize;
  final bool requiresSide;
  final bool requiresDirection;
  final bool requiresAdjacentTooth;

  bool get hasDynamicFields =>
      requiresSize || requiresSide || requiresDirection || requiresAdjacentTooth;

  @override
  List<Object?> get props => [id];
}

/// Группа патологий справочника.
class PathologyGroup extends Equatable {
  const PathologyGroup({
    required this.id,
    required this.title,
    required this.order,
    required this.items,
  });

  final String id;
  final String title;
  final int order;

  /// Патологии, отсортированные по убыванию частоты.
  final List<Pathology> items;

  @override
  List<Object?> get props => [id];
}
