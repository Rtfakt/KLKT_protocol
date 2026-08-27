/// Константы зубной формулы FDI (постоянный прикус, 11–48).
library;

/// Верхняя челюсть: правая сторона от 18 к 11, затем левая от 21 к 28.
const List<int> upperArchFdis = [
  18, 17, 16, 15, 14, 13, 12, 11, //
  21, 22, 23, 24, 25, 26, 27, 28,
];

/// Нижняя челюсть: правая сторона от 48 к 41, затем левая от 31 к 38.
const List<int> lowerArchFdis = [
  48, 47, 46, 45, 44, 43, 42, 41, //
  31, 32, 33, 34, 35, 36, 37, 38,
];

/// Все зубы в анатомическом порядке обхода (верх слева-направо, затем низ).
final List<int> allFdis = [...upperArchFdis, ...lowerArchFdis];

/// Позиция зуба в анатомическом порядке — для стабильной сортировки номеров
/// в тексте протокола.
final Map<int, int> anatomicalIndex = {
  for (var i = 0; i < allFdis.length; i++) allFdis[i]: i,
};

/// Сортирует номера FDI в анатомическом порядке.
List<int> sortAnatomically(Iterable<int> fdis) {
  final list = fdis.toList();
  list.sort((a, b) => (anatomicalIndex[a] ?? 99).compareTo(anatomicalIndex[b] ?? 99));
  return list;
}
