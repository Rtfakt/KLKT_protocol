import '../entities/pathology.dart';

/// Доступ к справочнику патологий. Синхронный: данные живут в памяти.
abstract class PathologyRepository {
  /// Группы в порядке отображения, патологии внутри — по убыванию частоты.
  List<PathologyGroup> get groups;

  Pathology? byId(String id);
}
