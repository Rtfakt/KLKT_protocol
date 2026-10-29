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

/// Зубы, соседние с [fdis] по дуге: ближайший мезиально и дистально.
/// Сами [fdis] в список не входят. 16 → 15 и 17, 11 → 12 и 21, 18 → только 17.
/// Верхняя и нижняя челюсти друг другу не соседствуют.
/// Порядок — по возрастанию номера FDI.
List<int> neighboringFdis(Iterable<int> fdis) {
  final selected = fdis.toSet();
  final neighbors = <int>{};
  for (final fdi in selected) {
    final arch = upperArchFdis.contains(fdi)
        ? upperArchFdis
        : lowerArchFdis.contains(fdi)
        ? lowerArchFdis
        : null;
    if (arch == null) continue;
    final index = arch.indexOf(fdi);
    if (index > 0) neighbors.add(arch[index - 1]);
    if (index + 1 < arch.length) neighbors.add(arch[index + 1]);
  }
  neighbors.removeAll(selected);
  return neighbors.toList()..sort();
}

/// Сортирует номера FDI по возрастанию: 1.1 … 1.8, 2.1 … 2.8, 3.1 … 4.8.
List<int> sortFdis(Iterable<int> fdis) => fdis.toList()..sort();

/// Квадрант (сегмент) зуба: 16 → 1, 36 → 3.
int fdiQuadrant(int fdi) => fdi ~/ 10;

/// Отображение FDI с точкой: 18 → «1.8», 23 → «2.3».
String formatFdi(int fdi) => '${fdi ~/ 10}.${fdi % 10}';

/// Список FDI через запятую в точечной записи.
String formatFdis(Iterable<int> fdis) => fdis.map(formatFdi).join(', ');

/// Список FDI с диапазонами: 3 и более подряд идущих зуба одного квадранта
/// сворачиваются в «2.4–2.6», остальные перечисляются через запятую.
String formatFdiRanges(Iterable<int> fdis) {
  final sorted = sortFdis(fdis);
  final parts = <String>[];
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    // Расширяем серию: следующий номер и тот же квадрант.
    while (j + 1 < sorted.length &&
        sorted[j + 1] == sorted[j] + 1 &&
        sorted[j + 1] ~/ 10 == sorted[j] ~/ 10) {
      j++;
    }
    if (j - i >= 2) {
      parts.add('${formatFdi(sorted[i])}–${formatFdi(sorted[j])}');
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(formatFdi(sorted[k]));
      }
    }
    i = j + 1;
  }
  return parts.join(', ');
}
