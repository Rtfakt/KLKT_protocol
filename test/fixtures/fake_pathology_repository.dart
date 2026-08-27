import 'package:klkt_protocol/features/protocol/domain/entities/pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/repositories/pathology_repository.dart';

/// Минимальный справочник для тестов Bloc: по одной патологии на каждый
/// интересующий случай.
class FakePathologyRepository implements PathologyRepository {
  static const toothSimple = Pathology(
    id: 'tooth_simple',
    groupId: 'g_test',
    name: 'Зубная без уточнений',
    descriptionTemplate: 'зубная без уточнений',
    conclusionText: 'зубной без уточнений',
    frequency: 5,
    scope: PathologyScope.tooth,
  );

  static const toothSize = Pathology(
    id: 'tooth_size',
    groupId: 'g_test',
    name: 'Зубная с размером',
    descriptionTemplate: 'зубная с размером {size}',
    conclusionText: 'зубной с размером',
    frequency: 4,
    scope: PathologyScope.tooth,
    requiresSize: true,
  );

  static const generalSide = Pathology(
    id: 'general_side',
    groupId: 'g_test',
    name: 'Общая со стороной',
    descriptionTemplate: 'общая со стороной',
    conclusionText: 'общей со стороной',
    frequency: 3,
    scope: PathologyScope.general,
    requiresSide: true,
  );

  static const toothExtracted = Pathology(
    id: 'tooth_extracted',
    groupId: 'g_test',
    name: 'Зубная с шаблоном удаления',
    descriptionTemplate: 'зубная',
    extractedTemplate: 'зубная (шаблон удалённого)',
    conclusionText: 'зубной',
    frequency: 2,
    scope: PathologyScope.tooth,
  );

  static const _all = [toothSimple, toothSize, generalSide, toothExtracted];

  @override
  List<PathologyGroup> get groups => const [
        PathologyGroup(id: 'g_test', title: 'Тест', order: 1, items: _all),
      ];

  @override
  Pathology? byId(String id) {
    for (final p in _all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
