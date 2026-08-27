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

/// Клик по чипу патологии: добавить находку или снять существующую.
class PathologyToggled extends ProtocolEvent {
  const PathologyToggled(this.pathologyId);
  final String pathologyId;

  @override
  List<Object?> get props => [pathologyId];
}

/// Удаление находки из списка.
class FindingRemoved extends ProtocolEvent {
  const FindingRemoved(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Активация находки для редактирования динамических полей.
class FindingActivated extends ProtocolEvent {
  const FindingActivated(this.uid);
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Смена количества измерений (1/2/3) у активной находки.
class SizeCountChanged extends ProtocolEvent {
  const SizeCountChanged(this.count);
  final int count;

  @override
  List<Object?> get props => [count];
}

/// Изменение значений размеров у активной находки.
class MeasurementsChanged extends ProtocolEvent {
  const MeasurementsChanged({this.x, this.y, this.z});
  final String? x;
  final String? y;
  final String? z;

  @override
  List<Object?> get props => [x, y, z];
}

/// Выбор стороны у активной находки.
class SideChanged extends ProtocolEvent {
  const SideChanged(this.side);
  final Side side;

  @override
  List<Object?> get props => [side];
}

/// Выбор направления у активной находки.
class DirectionChanged extends ProtocolEvent {
  const DirectionChanged(this.direction);
  final Direction direction;

  @override
  List<Object?> get props => [direction];
}

/// Выбор соседнего зуба у активной находки.
class AdjacentChanged extends ProtocolEvent {
  const AdjacentChanged(this.fdi);
  final int fdi;

  @override
  List<Object?> get props => [fdi];
}

/// Полная очистка протокола.
class Cleared extends ProtocolEvent {
  const Cleared();
}
