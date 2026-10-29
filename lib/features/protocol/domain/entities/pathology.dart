import 'package:equatable/equatable.dart';

/// Привязка патологии: к конкретным зубам или общая (ЛОР, ВНЧС и т.п.).
enum PathologyScope { tooth, general }

/// Стиль ссылки на зубы в тексте: «3.6 зуб — …» или «В области 1.1, 2.1 — …».
/// [area] — для имплантатов, Radix, лунок и прочих объектов, которые
/// грамматически не являются зубами.
enum ToothRefStyle { tooth, area }

/// Сторона поражения для ЛОР-патологий и ВНЧС.
///
/// Порядок значений — порядок кнопок выбора: справа, слева, двустороннее.
enum Side { right, left, bilateral }

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
    required this.conclusionTemplate,
    required this.frequency,
    required this.scope,
    this.extractedTemplate,
    this.refStyle = ToothRefStyle.tooth,
    this.significance = 3,
    this.omitFromConclusion = false,
    this.requiresSize = false,
    this.defaultSizeCount = 1,
    this.requiresSide = false,
    this.requiresDirection = false,
    this.requiresAdjacentTooth = false,
    this.chipGroup,
  });

  final String id;
  final String groupId;

  /// Название для чипа в UI (как в справочнике).
  final String name;

  /// Шаблон описательной части. Плейсхолдеры: {size}, {side}, {direction},
  /// {adjacent}. Для tooth-scope подставляется после «[N] зуб — ».
  final String descriptionTemplate;

  /// Специальный шаблон для удалённого зуба (например, Radix).
  final String? extractedTemplate;

  /// Нозологическая формулировка для заключения: именительный падеж,
  /// находка впереди. Плейсхолдер {teeth} — место номеров зубов
  /// («…на апексы {teeth}» → «…на апексы зуба 3.6»); {fdi} — только
  /// номера, без «зуба» («…деструкция {fdi}» → «…деструкция 4.3»).
  /// Если плейсхолдера нет, номера дописываются в конец.
  /// Размер ({size}) в заключение не попадает.
  final String conclusionTemplate;

  /// Стиль ссылки на зубы: [ToothRefStyle.area] — «в области 1.1, 2.1»
  /// без слова «зуб» (имплантаты, Radix, лунки).
  final ToothRefStyle refStyle;

  /// Клиническая значимость 1–5: порядок строк заключения по убыванию.
  final int significance;

  /// Не выносить в заключение (интактные/«нормальные» состояния).
  final bool omitFromConclusion;

  /// Частота использования 1–5 (★), сортировка внутри группы по убыванию.
  final int frequency;

  final PathologyScope scope;
  final bool requiresSize;

  /// Сколько измерений открыто сразу: 1, 2 или 3. Врач может переключить.
  final int defaultSizeCount;

  final bool requiresSide;
  final bool requiresDirection;
  final bool requiresAdjacentTooth;

  /// Чипы с одним и тем же [chipGroup] рисуются одной строкой кнопок.
  /// Для парных вариантов одной находки, которые нужно выбирать отдельно.
  final String? chipGroup;

  bool get hasDynamicFields =>
      requiresSize ||
      requiresSide ||
      requiresDirection ||
      requiresAdjacentTooth;

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
