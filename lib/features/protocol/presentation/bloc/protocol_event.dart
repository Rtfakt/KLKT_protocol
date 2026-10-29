import 'package:equatable/equatable.dart';

import '../../domain/entities/pathology.dart';

sealed class ProtocolEvent extends Equatable {
  const ProtocolEvent();

  @override
  List<Object?> get props => [];
}

/// Клик по зубу в формуле — toggle мультивыбора.
class ToothSelectionToggled extends ProtocolEvent {
  const ToothSelectionToggled(this.fdi);
  final int fdi;

  @override
  List<Object?> get props => [fdi];
}

/// Пометка «удален» для зуба (долгое нажатие / ПКМ).
class ExtractedToggled extends ProtocolEvent {
  const ExtractedToggled(this.fdi);
  final int fdi;

  @override
  List<Object?> get props => [fdi];
}

/// Клик по чипу патологии: добавить/убрать из черновиков
/// (в режиме правки — заменить патологию редактируемой находки).
class PathologySelected extends ProtocolEvent {
  const PathologySelected(this.pathologyId);
  final String pathologyId;

  @override
  List<Object?> get props => [pathologyId];
}

/// Кнопка «Добавить в протокол» / «Сохранить изменения»:
/// зафиксировать черновики в findings и сбросить выбор.
class DraftCommitted extends ProtocolEvent {
  const DraftCommitted();
}

/// Кнопка «Отмена»: сбросить черновики и выбор зубов без добавления.
class DraftDiscarded extends ProtocolEvent {
  const DraftDiscarded();
}

/// Удаление находки из списка.
class FindingRemoved extends ProtocolEvent {
  const FindingRemoved(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Клик по чипу находки: вернуть её в редактор (черновик + зубы).
class FindingEditRequested extends ProtocolEvent {
  const FindingEditRequested(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Вернуть в выбор набор зубов последней добавленной находки.
class TeethRestored extends ProtocolEvent {
  const TeethRestored();
}

/// Отменить последнее добавление: снять находки и вернуть их в черновики.
class LastCommitUndone extends ProtocolEvent {
  const LastCommitUndone();
}

/// Смена количества измерений (1/2/3) у черновика.
class SizeCountChanged extends ProtocolEvent {
  const SizeCountChanged(this.count, {this.pathologyId});
  final int count;
  final String? pathologyId;

  @override
  List<Object?> get props => [count, pathologyId];
}

/// Изменение значений размеров у черновика.
class MeasurementsChanged extends ProtocolEvent {
  const MeasurementsChanged({this.pathologyId, this.x, this.y, this.z});
  final String? pathologyId;
  final String? x;
  final String? y;
  final String? z;

  @override
  List<Object?> get props => [pathologyId, x, y, z];
}

/// Выбор стороны у черновика.
class SideChanged extends ProtocolEvent {
  const SideChanged(this.side, {this.pathologyId});
  final Side side;
  final String? pathologyId;

  @override
  List<Object?> get props => [side, pathologyId];
}

/// Выбор направления у черновика.
class DirectionChanged extends ProtocolEvent {
  const DirectionChanged(this.direction, {this.pathologyId});
  final Direction direction;
  final String? pathologyId;

  @override
  List<Object?> get props => [direction, pathologyId];
}

/// Выбор соседнего зуба у черновика.
class AdjacentChanged extends ProtocolEvent {
  const AdjacentChanged(this.fdi, {this.pathologyId});
  final int fdi;
  final String? pathologyId;

  @override
  List<Object?> get props => [fdi, pathologyId];
}

/// Переключение фразы «ВНЧС без структурных изменений» в каркасе КЛКТ.
class SkeletonToggled extends ProtocolEvent {
  const SkeletonToggled();
}

/// Полная очистка протокола.
class Cleared extends ProtocolEvent {
  const Cleared();
}
