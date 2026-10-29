import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/features/protocol/data/catalog/static_pathology_repository.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/selected_pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/services/report_generator.dart';

void main() {
  const generator = ReportGenerator(catalog: StaticPathologyRepository());

  group('ReportGenerator: описание', () {
    test('один зуб, патология без уточнений', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, '1.6 зуб — вторичный процесс под пломбой.');
    });

    test('мультивыбор зубов: номера по возрастанию', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g4_partial_obturation',
            toothFdis: [36, 12, 24],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        '1.2, 2.4, 3.6 зубы — корневые каналы обтурированы частично.',
      );
    });

    test('размер: 1 поле -> «размером до X мм»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [21],
            measurements: Measurements(count: 1, x: '4'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        '2.1 зуб — деструкция в апикальной области размером до 4 мм.',
      );
    });

    test('размер: 2 и 3 поля', () {
      final two = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [21],
            measurements: Measurements(count: 2, x: '4', y: '5'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        two.description,
        '2.1 зуб — деструкция в апикальной области размером 4 х 5 мм.',
      );

      final three = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [21],
            measurements: Measurements(count: 3, x: '4', y: '5', z: '6'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        three.description,
        '2.1 зуб — деструкция в апикальной области размером 4 х 5 х 6 мм.',
      );
    });

    test('незаполненный обязательный размер: находка не попадает в текст', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [21],
            measurements: Measurements(count: 2, x: '4'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.isEmpty, isTrue);
    });

    test('находки одного зуба сливаются в одну строку через «;»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g3_furcation_apices',
            toothFdis: [36],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'g4_no_filling',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        '3.6 зуб — деструкция в области фуркации с распространением на апексы; '
        'корневые каналы без следов пломбировки.',
      );
    });

    test(
      'строки описания отсортированы по номеру зуба, а не по порядку добавления',
      () {
        final report = generator.generate(
          findings: const [
            SelectedPathology(
              uid: '1',
              pathologyId: 'g3_furcation_apices',
              toothFdis: [36],
            ),
            SelectedPathology(
              uid: '2',
              pathologyId: 'g2_pdl_widening',
              toothFdis: [13],
            ),
          ],
          extractedFdis: const {},
        );
        expect(
          report.description,
          '1.3 зуб — расширение периодонтального пространства в апикальной области.\n'
          '3.6 зуб — деструкция в области фуркации с распространением на апексы.',
        );
      },
    );

    test('имплантаты: «В области N — …» вместо «N зубы»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g9_implants_ok',
            toothFdis: [21, 11],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        'В области 1.1, 2.1 — дентальные имплантаты, положение их внутрикостное, '
        'признаков периимплантита не определяется.',
      );
    });

    test('смешанный выбор: присутствующие и удалённые зубы разделяются', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [14, 15],
          ),
        ],
        extractedFdis: const {14},
      );
      expect(
        report.description,
        '1.4 зуб (удален) — вторичный процесс под пломбой.\n'
        '1.5 зуб — вторичный процесс под пломбой.',
      );
    });

    test('Radix: area-стиль и специфичный шаблон удалённого зуба', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'g6_radix', toothFdis: [48]),
        ],
        extractedFdis: const {48},
      );
      expect(report.description, 'В области 4.8 — Radix (остаток корня).');
    });

    test('общие находки идут отдельным блоком после зубных', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'g8_septum_deviation'),
          SelectedPathology(
            uid: '2',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [11],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        '1.1 зуб — вторичный процесс под пломбой.\n'
        'Искривление носовой перегородки.',
      );
    });

    test('тотальное и субтотальное заполнение — разные формулировки', () {
      final total = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_total_filling',
            side: Side.right,
          ),
        ],
        extractedFdis: const {},
      );
      final subtotal = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_subtotal_filling',
            side: Side.left,
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        total.description,
        'Тотальное заполнение гайморовой пазухи мягкотканым компонентом '
        'справа.',
      );
      expect(
        subtotal.description,
        'Субтотальное заполнение гайморовой пазухи мягкотканым компонентом '
        'слева.',
      );
    });

    test('общая ЛОР-патология: размер и сторона в описании', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_soft_tissue_wall',
            measurements: Measurements(count: 1, x: '8'),
            side: Side.left,
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        'Мягкотканый компонент по нижней стенке гайморовой пазухи '
        'до 8 мм слева.',
      );
    });

    test('соседний зуб подставляется в шаблон', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_cavity_contact',
            toothFdis: [22],
            adjacentFdi: 21,
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, '2.2 зуб — полость на контакте с 2.1 зубом.');
    });

    test('деструкция коронковой части: описание и заключение', () {
      final one = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_crown_destruction',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(one.description, '1.6 зуб — деструкция коронковой части.');
      expect(
        one.conclusion,
        'КТ-картина:\nДеструкция коронковой части зуба 1.6.',
      );

      final many = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_crown_destruction',
            toothFdis: [26, 16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(many.description, '1.6, 2.6 зубы — деструкция коронковой части.');
      expect(
        many.conclusion,
        'КТ-картина:\nДеструкция коронковой части зубов 1.6, 2.6.',
      );
    });
  });

  group('ReportGenerator: заключение', () {
    test(
      'шапка «КТ-картина:» ровно один раз, номер зуба внутри формулировки',
      () {
        final report = generator.generate(
          findings: const [
            SelectedPathology(
              uid: '1',
              pathologyId: 'g1_secondary_filling',
              toothFdis: [16],
            ),
          ],
          extractedFdis: const {},
        );
        expect(
          report.conclusion,
          'КТ-картина:\n'
          'Вторичный процесс под пломбой зуба 1.6.',
        );
        expect('КТ-картина'.allMatches(report.conclusion).length, 1);
      },
    );

    test('размер в заключение не попадает', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [27],
            measurements: Measurements(count: 1, x: '4'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\nОчаговая деструкция в апикальной области зуба 2.7.',
      );
      expect(report.conclusion, isNot(contains('мм')));
    });

    test('периапикальная деструкция с распространением в фуркацию: '
        'не «деструкция зуба»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_to_furcation',
            toothFdis: [43],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.description,
        '4.3 зуб — периапикальная деструкция с распространением в область фуркации.',
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Периапикальная деструкция 4.3 с распространением в область фуркации.',
      );
    });

    test('одинаковая патология на разных зубах сворачивается в одну строку '
        'с диапазонами', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [15, 14],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [24, 25, 26],
          ),
          SelectedPathology(
            uid: '3',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [45],
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Состояние после эндодонтического лечения зубов 1.4, 1.5, 2.4–2.6, 4.5 '
        '(каналы обтурированы гомогенно).',
      );
    });

    test(
      'находки одного зуба — одно предложение, номер только в первой клаузе',
      () {
        final report = generator.generate(
          findings: const [
            SelectedPathology(
              uid: '1',
              pathologyId: 'g4_no_filling',
              toothFdis: [36],
            ),
            SelectedPathology(
              uid: '2',
              pathologyId: 'g3_furcation_apices',
              toothFdis: [36],
            ),
          ],
          extractedFdis: const {},
        );
        expect(
          report.conclusion,
          'КТ-картина:\n'
          'Признаки деструкции костной ткани в области фуркации с распространением '
          'на апексы зуба 3.6; корневые каналы не обтурированы.',
        );
      },
    );

    test('порядок строк — по убыванию клинической значимости', () {
      final report = generator.generate(
        findings: const [
          // Имплантаты (значимость 1) добавлены первыми,
          // деструкция (5) — последней.
          SelectedPathology(
            uid: '1',
            pathologyId: 'g9_implants_ok',
            toothFdis: [11, 21],
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [45],
          ),
          SelectedPathology(
            uid: '3',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [27],
            measurements: Measurements(count: 1, x: '4'),
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Очаговая деструкция в апикальной области зуба 2.7.\n'
        'Состояние после эндодонтического лечения зуба 4.5 '
        '(каналы обтурированы гомогенно).\n'
        'Дентальные имплантаты в области 1.1, 2.1 без признаков периимплантита.',
      );
    });

    test('удалённый зуб: «в области N» без задвоения «в области»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g2_apical_destruction',
            toothFdis: [14],
            measurements: Measurements(count: 1, x: '5'),
          ),
        ],
        extractedFdis: const {14},
      );
      expect(
        report.conclusion,
        'КТ-картина:\nОчаговая деструкция в апикальной области 1.4.',
      );
    });

    test('Radix на удалённом зубе: «в области 4.8»', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'g6_radix', toothFdis: [48]),
        ],
        extractedFdis: const {48},
      );
      expect(
        report.conclusion,
        'КТ-картина:\nRadix (остаток корня) в области 4.8.',
      );
    });

    test('общая ЛОР-патология: сторона есть, размера нет', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_soft_tissue_wall',
            measurements: Measurements(count: 1, x: '8'),
            side: Side.left,
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\nМягкотканый компонент по нижней стенке '
        'гайморовой пазухи слева.',
      );
    });

    test('направление для шипа перегородки', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g8_septum_spike',
            direction: Direction.toRight,
          ),
        ],
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\nШип перегородки полости носа вправо.',
      );
    });
  });

  group('ReportGenerator: сценарий из образца', () {
    final findings = const [
      SelectedPathology(
        uid: '1',
        pathologyId: 'g3_furcation_apices',
        toothFdis: [36],
      ),
      SelectedPathology(
        uid: '2',
        pathologyId: 'g4_no_filling',
        toothFdis: [36],
      ),
      SelectedPathology(
        uid: '3',
        pathologyId: 'g9_implants_ok',
        toothFdis: [11, 21],
      ),
      SelectedPathology(
        uid: '4',
        pathologyId: 'g2_pdl_widening',
        toothFdis: [13],
      ),
      SelectedPathology(
        uid: '5',
        pathologyId: 'g4_endo_homogeneous',
        toothFdis: [15, 14],
      ),
      SelectedPathology(
        uid: '6',
        pathologyId: 'g4_endo_homogeneous',
        toothFdis: [24, 25, 26],
      ),
      SelectedPathology(
        uid: '7',
        pathologyId: 'g2_apical_destruction',
        toothFdis: [27],
        measurements: Measurements(count: 1, x: '4'),
      ),
      SelectedPathology(
        uid: '8',
        pathologyId: 'g2_cortical_defect',
        toothFdis: [44],
      ),
      SelectedPathology(
        uid: '9',
        pathologyId: 'g4_endo_homogeneous',
        toothFdis: [45],
      ),
    ];

    test('описание: по номеру зуба, размеры на месте', () {
      final report = generator.generate(
        findings: findings,
        extractedFdis: const {},
      );
      expect(
        report.description,
        'В области 1.1, 2.1 — дентальные имплантаты, положение их внутрикостное, '
        'признаков периимплантита не определяется.\n'
        '1.3 зуб — расширение периодонтального пространства в апикальной области.\n'
        '1.4, 1.5 зубы — признаки эндодонтического лечения, каналы заполнены гомогенно.\n'
        '2.4, 2.5, 2.6 зубы — признаки эндодонтического лечения, каналы заполнены гомогенно.\n'
        '2.7 зуб — деструкция в апикальной области размером до 4 мм.\n'
        '3.6 зуб — деструкция в области фуркации с распространением на апексы; '
        'корневые каналы без следов пломбировки.\n'
        '4.4 зуб — деструкция с дефектом кортикальной пластины вестибулярно.\n'
        '4.5 зуб — признаки эндодонтического лечения, каналы заполнены гомогенно.',
      );
    });

    test('заключение: по значимости, свёртки, без размеров', () {
      final report = generator.generate(
        findings: findings,
        extractedFdis: const {},
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Признаки деструкции костной ткани в области фуркации с распространением '
        'на апексы зуба 3.6; корневые каналы не обтурированы.\n'
        'Очаговая деструкция в апикальной области зуба 2.7.\n'
        'Деструкция с дефектом вестибулярной кортикальной пластины в области зуба 4.4.\n'
        'Расширение периодонтальной щели в апикальной области зуба 1.3.\n'
        'Состояние после эндодонтического лечения зубов 1.4, 1.5, 2.4–2.6, 4.5 '
        '(каналы обтурированы гомогенно).\n'
        'Дентальные имплантаты в области 1.1, 2.1 без признаков периимплантита.',
      );
    });
  });

  group('ReportGenerator: каркас протокола', () {
    test('формула, замыкающая фраза и нормы без фразы ВНЧС', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {18},
        includeSkeleton: true,
      );
      expect(
        report.description,
        'Зубная формула: отсутствуют 1.8.\n'
        '1.6 зуб — вторичный процесс под пломбой.\n'
        'Остальные визуализируемые зубы без очаговых изменений '
        'периапикальных тканей.\n'
        'Высота альвеолярных гребней сохранена.\n'
        'Гайморовы пазухи пневматизированы, слизистая не утолщена.',
      );
      expect(
        report.description,
        isNot(contains('ВНЧС без структурных изменений')),
      );
    });

    test('переключатель каркаса добавляет фразу ВНЧС', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
        includeSkeleton: true,
        includeTmjNorm: true,
      );
      expect(report.description, contains('ВНЧС без структурных изменений.'));
    });

    test('фраза ВНЧС не добавляется без каркаса и подавляется находкой', () {
      final withoutSkeleton = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
        includeTmjNorm: true,
      );
      expect(
        withoutSkeleton.description,
        isNot(contains('ВНЧС без структурных изменений')),
      );

      final withTmjFinding = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g10_tmj',
            side: Side.bilateral,
          ),
        ],
        extractedFdis: const {},
        includeSkeleton: true,
        includeTmjNorm: true,
      );
      expect(
        withTmjFinding.description,
        isNot(contains('ВНЧС без структурных изменений')),
      );
    });

    test('снижение альвеолярных гребней вытесняет норму пародонта', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(uid: '1', pathologyId: 'g5_ridge_reduction'),
        ],
        extractedFdis: const {},
        includeSkeleton: true,
      );
      expect(report.description, contains('Снижение альвеолярных гребней.'));
      expect(
        report.description,
        isNot(contains('Высота альвеолярных гребней сохранена')),
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Снижение альвеолярных гребней.',
      );
    });

    test('нормы подавляются находками соответствующих групп', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_odontogenic',
            side: Side.left,
          ),
          SelectedPathology(
            uid: '2',
            pathologyId: 'g5_bone_height',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {},
        includeSkeleton: true,
        includeTmjNorm: true,
      );
      expect(
        report.description,
        isNot(contains('Гайморовы пазухи пневматизированы')),
      );
      expect(
        report.description,
        isNot(contains('Высота альвеолярных гребней сохранена')),
      );
      expect(report.description, contains('ВНЧС без структурных изменений.'));
    });

    test('при норме заключение — без видимой патологии', () {
      final report = generator.generate(
        findings: const [],
        extractedFdis: const {},
        includeSkeleton: true,
      );
      expect(
        report.conclusion,
        'КТ-картина:\n'
        'Без видимой патологии.',
      );
    });

    test('удалённые зубы без находок не получают фразу нормы', () {
      final report = generator.generate(
        findings: const [],
        extractedFdis: const {18},
        includeSkeleton: true,
      );
      expect(report.description, contains('отсутствуют 1.8'));
      expect(report.conclusion, '');
    });

    test('без флага каркас не добавляется', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {18},
      );
      expect(report.description, '1.6 зуб — вторичный процесс под пломбой.');
    });
  });

  test('plain-text для буфера обмена содержит оба блока без заголовков', () {
    final report = generator.generate(
      findings: const [
        SelectedPathology(
          uid: '1',
          pathologyId: 'g1_secondary_filling',
          toothFdis: [11],
        ),
      ],
      extractedFdis: const {},
    );
    final text = report.asPlainText();
    expect(text, isNot(contains('ОПИСАТЕЛЬНАЯ ЧАСТЬ')));
    expect(text, isNot(contains('ЗАКЛЮЧЕНИЕ')));
    expect(text, '${report.description}\n\n${report.conclusion}');
  });
}
