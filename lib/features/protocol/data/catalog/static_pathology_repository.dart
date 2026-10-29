import '../../domain/entities/pathology.dart';
import '../../domain/entities/study_type.dart';
import '../../domain/repositories/pathology_repository.dart';
import 'opg_pathology_catalog.dart';
import 'pathology_catalog.dart';

/// Репозиторий поверх статических каталогов: КЛКТ (по умолчанию) или ОПГ.
class StaticPathologyRepository implements PathologyRepository {
  const StaticPathologyRepository() : studyType = StudyType.cbct;

  const StaticPathologyRepository.opg() : studyType = StudyType.opg;

  final StudyType studyType;

  @override
  List<PathologyGroup> get groups => switch (studyType) {
        StudyType.cbct => PathologyCatalog.groups,
        StudyType.opg => OpgPathologyCatalog.groups,
      };

  @override
  Pathology? byId(String id) => switch (studyType) {
        StudyType.cbct => PathologyCatalog.byId[id],
        StudyType.opg => OpgPathologyCatalog.byId[id],
      };
}
