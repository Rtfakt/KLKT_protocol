import '../../domain/entities/pathology.dart';
import '../../domain/repositories/pathology_repository.dart';
import 'pathology_catalog.dart';

/// Репозиторий поверх статического [PathologyCatalog].
class StaticPathologyRepository implements PathologyRepository {
  const StaticPathologyRepository();

  @override
  List<PathologyGroup> get groups => PathologyCatalog.groups;

  @override
  Pathology? byId(String id) => PathologyCatalog.byId[id];
}
