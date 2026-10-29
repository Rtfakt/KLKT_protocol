import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/core/constants/fdi.dart';

void main() {
  group('formatFdi', () {
    test('квадрант.зуб: 18 → 1.8, 23 → 2.3', () {
      expect(formatFdi(18), '1.8');
      expect(formatFdi(23), '2.3');
      expect(formatFdi(11), '1.1');
      expect(formatFdi(48), '4.8');
    });
  });

  group('formatFdis', () {
    test('список через запятую', () {
      expect(formatFdis([12, 24, 36]), '1.2, 2.4, 3.6');
    });
  });

  group('sortFdis', () {
    test('по возрастанию номера: 1.4, 1.5, 2.1, 3.6', () {
      expect(sortFdis([15, 14, 36, 21]), [14, 15, 21, 36]);
    });

    test('внутри квадранта — по возрастанию, квадранты 1→4', () {
      expect(sortFdis([48, 11, 31, 28, 18]), [11, 18, 28, 31, 48]);
    });
  });

  group('formatFdiRanges', () {
    test('3 и более подряд сворачиваются в диапазон', () {
      expect(
        formatFdiRanges([14, 15, 24, 25, 26, 45]),
        '1.4, 1.5, 2.4–2.6, 4.5',
      );
    });

    test('ровно 3 подряд', () {
      expect(formatFdiRanges([24, 25, 26]), '2.4–2.6');
    });

    test('2 подряд не сворачиваются', () {
      expect(formatFdiRanges([14, 15]), '1.4, 1.5');
    });

    test('серия не пересекает границу квадранта', () {
      expect(formatFdiRanges([16, 17, 18, 21]), '1.6–1.8, 2.1');
    });

    test('несортированный вход сортируется', () {
      expect(formatFdiRanges([26, 24, 25]), '2.4–2.6');
    });
  });

  group('neighboringFdis', () {
    test('у зуба в ряду два соседа', () {
      expect(neighboringFdis([16]), [15, 17]);
    });

    test('центральные резцы соседствуют через среднюю линию', () {
      expect(neighboringFdis([11]), [12, 21]);
      expect(neighboringFdis([21]), [11, 22]);
      expect(neighboringFdis([41]), [31, 42]);
      expect(neighboringFdis([31]), [32, 41]);
    });

    test('зуб мудрости — один сосед', () {
      expect(neighboringFdis([18]), [17]);
      expect(neighboringFdis([28]), [27]);
      expect(neighboringFdis([38]), [37]);
      expect(neighboringFdis([48]), [47]);
    });

    test('выбранные зубы в список не входят', () {
      expect(neighboringFdis([16, 17]), [15, 18]);
    });

    test('соседи каждой челюсти, если выбраны зубы сверху и снизу', () {
      expect(neighboringFdis([16, 46]), [15, 17, 45, 47]);
    });

    test('без выбранных зубов список пуст', () {
      expect(neighboringFdis(const []), isEmpty);
    });
  });
}
