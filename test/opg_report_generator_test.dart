import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/features/protocol/data/catalog/opg_pathology_catalog.dart';
import 'package:klkt_protocol/features/protocol/data/catalog/static_pathology_repository.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/selected_pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/services/opg_report_generator.dart';

void main() {
  const generator = OpgReportGenerator(
    catalog: StaticPathologyRepository.opg(),
  );

  group('Каталог ОПГ', () {
    test('группы не пустые, id уникальны', () {
      expect(OpgPathologyCatalog.groups, isNotEmpty);
      final ids = <String>[];
      for (final g in OpgPathologyCatalog.groups) {
        expect(g.items, isNotEmpty, reason: 'Группа ${g.id} пуста');
        ids.addAll([for (final p in g.items) p.id]);
      }
      expect(ids.toSet().length, ids.length, reason: 'Дубли id патологий');
      expect(OpgPathologyCatalog.byId.length, ids.length);
    });
  });

  group('OpgReportGenerator: нормальный протокол', () {
    test('без находок и удалённых зубов — полный шаблон нормы', () {
      final report = generator.generate(
        findings: const [],
        extractedFdis: const {},
      );
      expect(
        report.description,
        'На ортопантомограмме определяется:\n'
        '- проекционное снижение информативности в области корней '
        'фронтальной группы верхней челюсти.\n'
        'Адентия: нет.\n'
        'Тесное положение зубов: нет.\n'
        'Ретенция и дистопия: нет.\n'
        'Признаки кариеса: не визуализируются.\n'
        'Периапикальные изменения: не визуализируются.\n'
        'Пародонт: без изменений.\n'
        'Нижнечелюстные каналы с обеих сторон прослеживаются, '
        'диаметр не изменен.\n'
        'Височно-нижнечелюстной сустав: головки в суставных ямках, '
        'шаровидные, контур четкий, ровный.',
      );
      expect(report.conclusion, 'Без видимой патологии.');
      expect(report.isEmpty, isFalse);
    });

    test('без шапки «КТ-картина:» в заключении', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_caries_dentin',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.conclusion.contains('КТ-картина'), isFalse);
      expect(report.conclusion, 'Признаки кариеса зуба 1.6.');
    });
  });

  group('OpgReportGenerator: адентия из формулы', () {
    test('удалённые зубы: строка адентии без перечня сохранённых', () {
      final report = generator.generate(
        findings: const [],
        extractedFdis: const {36, 46},
      );
      expect(
        report.description,
        contains('Адентия: отсутствуют зубы 3.6, 4.6.'),
      );
      expect(report.description, isNot(contains('1.1,')));
      expect(report.conclusion, 'Частичная вторичная адентия.');
    });

    test('один удалённый зуб — единственное число', () {
      final report = generator.generate(
        findings: const [],
        extractedFdis: const {36},
      );
      expect(report.description, contains('Адентия: отсутствует зуб 3.6.'));
    });

    test('все зубы удалены — полная адентия без перечня', () {
      final all = {
        for (var q = 1; q <= 4; q++)
          for (var i = 1; i <= 8; i++) q * 10 + i,
      };
      final report = generator.generate(findings: const [], extractedFdis: all);
      expect(report.description, contains('Адентия: полная.'));
      expect(report.description, isNot(contains('1.1')));
      expect(report.conclusion, 'Полная вторичная адентия.');
    });
  });

  group('OpgReportGenerator: разделы вместо норм', () {
    test('кариес: фраза с зубом вытесняет «не визуализируются»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_caries_dentin',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          '1.6 зуб — в коронковой части участок просветления '
          'в проекции дентина.',
        ),
      );
      expect(report.description, isNot(contains('Признаки кариеса: не')));
    });

    test('удалённый зуб помечается в префиксе', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_caries_dentin',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {36},
      );
      expect(
        report.description,
        contains(
          '3.6 зуб (удален) — в коронковой части участок просветления '
          'в проекции дентина.',
        ),
      );
    });

    test('одинаковая патология на разных зубах — отдельные строки', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_endo_partial',
            toothFdis: [26],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'opg_endo_partial',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          '2.6 зуб — неполная обтурация корневых каналов.\n'
          '3.6 зуб — неполная обтурация корневых каналов.',
        ),
      );
      expect(
        report.conclusion,
        'Неполная обтурация корневых каналов зубов 2.6, 3.6.',
      );
    });

    test('разные патологии одного зуба сливаются через «; »', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_apical_lucency',
            toothFdis: [27],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'opg_endo_treated',
            toothFdis: [27],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          '2.7 зуб — признаки эндодонтического лечения; '
          'участок просветления апикально — не исключается '
          'наличие апикальной кисты, расширения периодонтальной щели.',
        ),
      );
      expect(
        report.description,
        isNot(contains('Периапикальные изменения: не визуализируются.')),
      );
    });

    test('эндодонтия: номер зуба, затем патология', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_endo_treated',
            toothFdis: [16, 26],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains('1.6, 2.6 зубы — признаки эндодонтического лечения.'),
      );
      expect(
        report.conclusion,
        'Состояние после эндодонтического лечения зубов 1.6, 2.6.',
      );
    });

    test('периапикально: просветление апикально у зуба', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_apical_lucency',
            toothFdis: [27],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          '2.7 зуб — участок просветления апикально — не исключается '
          'наличие апикальной кисты, расширения периодонтальной щели.',
        ),
      );
      expect(
        report.description,
        isNot(contains('Периапикальные изменения: не визуализируются.')),
      );
      expect(report.conclusion, 'Признаки периодонтита зуба 2.7.');
    });

    test('пародонт: снижение альвеолярных гребней вместо «без изменений»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'opg_ridge_reduction'),
        ],
        extractedFdis: const {},
      );
      expect(report.description, isNot(contains('Пародонт: без изменений.')));
      expect(report.description, contains('Снижение альвеолярных гребней.'));
      expect(report.conclusion, 'Снижение альвеолярных гребней.');
    });

    test('пародонт: рецессия + карманы вместо «без изменений»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'opg_recession_cervical'),
          SelectedPathology(
            uid: '2',
            pathologyId: 'opg_pockets',
            toothFdis: [17, 21, 27, 36, 47],
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, isNot(contains('Пародонт: без изменений.')));
      expect(
        report.description,
        contains('Рецессия генерализованная до уровня шейки.'),
      );
      expect(
        report.description,
        contains('В области 1.7, 2.1, 2.7, 3.6, 4.7 — пародонтальные карманы.'),
      );
      // Карманы в заключении без повторного списка зубов.
      expect(
        report.conclusion,
        contains('Пародонтальные карманы (смотрите описание).'),
      );
      expect(
        report.conclusion,
        contains('Признаки пародонтита, рецессия костной ткани.'),
      );
    });

    test('обе рецессии дают одну строку заключения', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'opg_recession_cervical'),
          SelectedPathology(uid: '2', pathologyId: 'opg_recession_third'),
        ],
        extractedFdis: const {},
      );
      expect('Признаки пародонтита'.allMatches(report.conclusion).length, 1);
    });

    test('нижнечелюстной канал и ВНЧС: находка вытесняет норму', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_mandibular_canal',
            side: Side.left,
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'opg_tmj',
            side: Side.bilateral,
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          'Нижнечелюстной канал слева прослеживается неотчётливо, '
          'диаметр изменён.',
        ),
      );
      expect(
        report.description,
        isNot(contains('Нижнечелюстные каналы с обеих сторон')),
      );
      expect(report.description, isNot(contains('головки в суставных ямках')));
      expect(
        report.conclusion,
        contains('Дегенеративные изменения ВНЧС с двух сторон.'),
      );
    });
  });

  group('OpgReportGenerator: тесное положение и ретенция', () {
    test('сегменты из квадрантов выбранных зубов', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_crowding',
            toothFdis: [12, 11, 31, 41, 42],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains('Тесное положение зубов: 1, 3, 4 сегментов.'),
      );
      // Тесное положение в заключение не выносится (шаблон).
      expect(report.conclusion, '');
    });

    test('один сегмент — «сегмента»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_crowding',
            toothFdis: [31, 32],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains('Тесное положение зубов: 3 сегмента.'),
      );
    });

    test('ретенция и дистопия: список зубов', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_retention',
            toothFdis: [38, 48],
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, contains('Ретенция и дистопия: 3.8, 4.8.'));
      expect(report.conclusion, 'Ретенция и дистопия зубов 3.8, 4.8.');
    });
  });

  group('OpgReportGenerator: имплантаты и образования', () {
    test('имплантат: раздел появляется только с находкой', () {
      final normal = generator.generate(
        findings: const [],
        extractedFdis: const {},
      );
      expect(normal.description, isNot(contains('имплантат')));

      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_implant_ok',
            toothFdis: [36, 46],
          ),
        ],
        extractedFdis: const {36, 46},
      );
      expect(
        report.description,
        contains(
          'В области 3.6, 4.6 — дентальные имплантаты, '
          'признаков периимплантита не визуализируется.',
        ),
      );
      expect(
        report.conclusion,
        contains('Дентальный имплантат в области 3.6, 4.6.'),
      );
      // Адентия из формулы идёт первой строкой заключения.
      expect(
        report.conclusion.split('\n').first,
        'Частичная вторичная адентия.',
      );
    });

    test('образование с размером: размер в описании, но не в заключении', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_lesion_lucent',
            toothFdis: [44],
            measurements: Measurements(count: 2, x: '8', y: '6'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        contains(
          'В области 4.4 — дополнительное образование (участок просветления) '
          'размером 8 х 6 мм, не исключается одонтогенное / '
          'неодонтогенное образование.',
        ),
      );
      expect(
        report.conclusion,
        contains('Дополнительное образование в области 4.4.'),
      );
      expect(report.conclusion, isNot(contains('мм')));
    });

    test('находка с незаполненным размером не попадает в текст', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_lesion_lucent',
            toothFdis: [44],
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, isNot(contains('образование')));
      expect(report.conclusion, 'Без видимой патологии.');
      expect(report.conclusion, isNot(contains('образование')));
    });
  });

  group('OpgReportGenerator: порядок заключения', () {
    test('адентия → имплантат → эндо → периодонтит → пародонт', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'opg_pockets',
            toothFdis: [17],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'opg_apical_lucency',
            toothFdis: [27],
          ),
          SelectedPathology(
            uid: '3',
            pathologyId: 'opg_endo_treated',
            toothFdis: [27],
          ),
          SelectedPathology(
            uid: '4',
            pathologyId: 'opg_implant_ok',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {36},
      );
      expect(
        report.conclusion,
        'Частичная вторичная адентия.\n'
        'Дентальный имплантат в области 3.6.\n'
        'Состояние после эндодонтического лечения зуба 2.7.\n'
        'Признаки периодонтита зуба 2.7.\n'
        'Пародонтальные карманы (смотрите описание).',
      );
    });
  });
}
