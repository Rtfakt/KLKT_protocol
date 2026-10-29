import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/core/constants/fdi.dart';
import 'package:klkt_protocol/features/protocol/data/catalog/static_pathology_repository.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/selected_pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/services/finding_validator.dart';

void main() {
  const validator = FindingValidator(catalog: StaticPathologyRepository());

  group('FindingValidator: полная адентия', () {
    test('несовместима с находками на сохранённых зубах', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(uid: 'a', pathologyId: 'g6_full_adentia'),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [16],
          ),
        ],
        extractedFdis: const {},
      );
      expect(issues, hasLength(1));
      expect(issues.first.severity, IssueSeverity.error);
      expect(issues.first.message, contains('1.6'));
      expect(issues.first.relatedUids, containsAll(['a', 'b']));
    });

    test('несовместима с непомеченными зубами в формуле', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(uid: 'a', pathologyId: 'g6_full_adentia'),
        ],
        extractedFdis: const {18},
      );
      expect(issues, hasLength(1));
      expect(issues.first.message, contains('отметьте все зубы'));
    });

    test('корректна, когда все зубы помечены удалёнными', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(uid: 'a', pathologyId: 'g6_full_adentia'),
        ],
        extractedFdis: allFdis.toSet(),
      );
      expect(issues, isEmpty);
    });

    test('полная + частичная адентия взаимоисключающие', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(uid: 'a', pathologyId: 'g6_full_adentia'),
          SelectedPathology(uid: 'b', pathologyId: 'g6_partial_adentia'),
        ],
        extractedFdis: allFdis.toSet(),
      );
      expect(issues, hasLength(1));
      expect(issues.first.message, contains('взаимоисключающие'));
      expect(issues.first.relatedUids, containsAll(['a', 'b']));
    });
  });

  group('FindingValidator: состояния каналов', () {
    test('эндолечение и «без пломбировки» на одном зубе', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [36],
          ),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'g4_no_filling',
            toothFdis: [36],
          ),
        ],
        extractedFdis: const {},
      );
      expect(issues, hasLength(1));
      expect(issues.first.message, contains('3.6'));
      expect(issues.first.relatedUids, containsAll(['a', 'b']));
    });

    test('на разных зубах конфликта нет', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'g4_endo_homogeneous',
            toothFdis: [36],
          ),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'g4_no_filling',
            toothFdis: [46],
          ),
        ],
        extractedFdis: const {},
      );
      expect(issues, isEmpty);
    });
  });

  group('FindingValidator: дубли', () {
    test('одна патология дважды на одном зубе', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16, 17],
          ),
        ],
        extractedFdis: const {},
      );
      expect(issues, hasLength(1));
      expect(issues.first.severity, IssueSeverity.warning);
      expect(issues.first.message, contains('1.6'));
    });

    test('одна патология на разных зубах — не дубль', () {
      final issues = validator.validate(
        findings: const [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [16],
          ),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'g1_secondary_filling',
            toothFdis: [26],
          ),
        ],
        extractedFdis: const {},
      );
      expect(issues, isEmpty);
    });
  });
}
