import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/features/protocol/data/catalog/static_pathology_repository.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/selected_pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/services/report_generator.dart';

void main() {
  const generator = ReportGenerator(catalog: StaticPathologyRepository());

  group('ReportGenerator', () {
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
      expect(report.description, '16 зуб - вторичный процесс под пломбой.');
      expect(report.conclusion,
          'КТ-картина соответствует вторичному процессу под пломбой в 16 зубе.');
    });

    test('мультивыбор зубов в анатомическом порядке', () {
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
      expect(report.description,
          '12, 24, 36 зубы - корневые каналы обтурированы частично.');
      expect(report.conclusion,
          'КТ-картина соответствует частичной обтурации корневых каналов в 12, 24, 36 зубах.');
    });

    test('размер: 1 поле -> «до X мм»', () {
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
      expect(report.description,
          '21 зуб - деструкция в апикальной области до 4 мм.');
    });

    test('размер: 2 поля -> «X х Y мм»', () {
      final report = generator.generate(
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
      expect(report.description,
          '21 зуб - деструкция в апикальной области 4 х 5 мм.');
    });

    test('размер: 3 поля -> «X х Y х Z мм»', () {
      final report = generator.generate(
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
      expect(report.description,
          '21 зуб - деструкция в апикальной области 4 х 5 х 6 мм.');
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

    test('удалённый зуб: пометка и «в области N зуба» в заключении', () {
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
      expect(report.description,
          '14 зуб (удален) - деструкция в апикальной области до 5 мм.');
      expect(report.conclusion,
          'КТ-картина соответствует деструкции в апикальной области в области 14 зуба.');
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
        '15 зуб - вторичный процесс под пломбой.\n'
        '14 зуб (удален) - вторичный процесс под пломбой.',
      );
      expect(
        report.conclusion,
        'КТ-картина соответствует вторичному процессу под пломбой в 15 зубе.\n'
        'КТ-картина соответствует вторичному процессу под пломбой в области 14 зуба.',
      );
    });

    test('Radix на удалённом зубе использует специфичный шаблон', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g6_radix',
            toothFdis: [48],
          ),
        ],
        extractedFdis: const {48},
      );
      expect(report.description, '48 зуб (удален) - Radix (остаток корня).');
      expect(report.conclusion,
          'КТ-картина соответствует Radix (остатку корня) в области 48 зуба.');
    });

    test('общая ЛОР-патология: размер и сторона', () {
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
      expect(report.description,
          'Мягкотканый компонент по нижней стенке ВЧС до 8 мм слева.');
      expect(report.conclusion,
          'КТ-картина соответствует мягкотканому компоненту по нижней стенке ВЧС слева.');
    });

    test('двусторонняя патология', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
            uid: '1',
            pathologyId: 'g7_odontogenic',
            side: Side.bilateral,
          ),
        ],
        extractedFdis: const {},
      );
      expect(report.description, 'Одонтогенные изменения ВЧС с двух сторон.');
      expect(report.conclusion,
          'КТ-картина соответствует одонтогенным изменениям ВЧС с двух сторон.');
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
      expect(report.description, 'Шип перегородки полости носа вправо.');
      expect(report.conclusion,
          'КТ-картина соответствует шипу перегородки полости носа вправо.');
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
      expect(report.description, '22 зуб - полость на контакте с 21 зубом.');
      expect(report.conclusion,
          'КТ-картина соответствует полости на контакте с 21 зубом в 22 зубе.');
    });

    test('порядок находок в тексте = порядку добавления', () {
      final report = generator.generate(
        findings: const [
          SelectedPathology(
              uid: '1', pathologyId: 'g8_septum_deviation'),
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
        'Искривление носовой перегородки.\n'
        '11 зуб - вторичный процесс под пломбой.',
      );
    });

    test('plain-text для буфера обмена содержит оба блока', () {
      final text = generator
          .generate(
            findings: const [
              SelectedPathology(
                uid: '1',
                pathologyId: 'g1_secondary_filling',
                toothFdis: [11],
              ),
            ],
            extractedFdis: const {},
          )
          .asPlainText();
      expect(text, contains('ОПИСАТЕЛЬНАЯ ЧАСТЬ:'));
      expect(text, contains('ЗАКЛЮЧЕНИЕ:'));
    });
  });
}
