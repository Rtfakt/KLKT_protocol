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
    conclusionTemplate: 'зубная без уточнений {teeth}',
    frequency: 5,
    scope: PathologyScope.tooth,
  );

  static const toothSize = Pathology(
    id: 'tooth_size',
    groupId: 'g_test',
    name: 'Зубная с размером',
    descriptionTemplate: 'зубная с размером {size}',
    conclusionTemplate: 'зубная с размером {teeth}',
    frequency: 4,
    scope: PathologyScope.tooth,
    requiresSize: true,
  );

  static const toothSizeTwo = Pathology(
    id: 'tooth_size_two',
    groupId: 'g_test',
    name: 'Зубная с двумя размерами',
    descriptionTemplate: 'зубная с двумя размерами {size}',
    conclusionTemplate: 'зубная с двумя размерами {teeth}',
    frequency: 4,
    scope: PathologyScope.tooth,
    requiresSize: true,
    defaultSizeCount: 2,
  );

  static const generalSide = Pathology(
    id: 'general_side',
    groupId: 'g_test',
    name: 'Общая со стороной',
    descriptionTemplate: 'общая со стороной',
    conclusionTemplate: 'общая со стороной',
    frequency: 3,
    scope: PathologyScope.general,
    requiresSide: true,
  );

  static const toothAdjacent = Pathology(
    id: 'tooth_adjacent',
    groupId: 'g_test',
    name: 'Зубная с соседом',
    descriptionTemplate: 'на контакте с {adjacent}',
    conclusionTemplate: 'на контакте с {adjacent} {teeth}',
    frequency: 1,
    scope: PathologyScope.tooth,
    requiresAdjacentTooth: true,
  );

  static const toothExtracted = Pathology(
    id: 'tooth_extracted',
    groupId: 'g_test',
    name: 'Зубная с шаблоном удаления',
    descriptionTemplate: 'зубная',
    extractedTemplate: 'зубная (шаблон удалённого)',
    conclusionTemplate: 'зубная {teeth}',
    frequency: 2,
    scope: PathologyScope.tooth,
  );

  static const _all = [
    toothSimple,
    toothSize,
    toothSizeTwo,
    generalSide,
    toothAdjacent,
    toothExtracted,
  ];

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
