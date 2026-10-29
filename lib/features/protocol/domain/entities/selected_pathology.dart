import 'package:equatable/equatable.dart';

import 'pathology.dart';

/// Размеры находки: 1, 2 или 3 измерения в мм.
class Measurements extends Equatable {
  const Measurements({this.count = 1, this.x = '', this.y = '', this.z = ''});

  final int count; // 1 | 2 | 3
  final String x;
  final String y;
  final String z;

  bool get isComplete => switch (count) {
    1 => x.trim().isNotEmpty,
    2 => x.trim().isNotEmpty && y.trim().isNotEmpty,
    _ => x.trim().isNotEmpty && y.trim().isNotEmpty && z.trim().isNotEmpty,
  };

  /// «до X мм» / «X х Y мм» / «X х Y х Z мм».
  String render() => switch (count) {
    1 => 'до ${x.trim()} мм',
    2 => '${x.trim()} х ${y.trim()} мм',
    _ => '${x.trim()} х ${y.trim()} х ${z.trim()} мм',
  };

  Measurements copyWith({int? count, String? x, String? y, String? z}) =>
      Measurements(
        count: count ?? this.count,
        x: x ?? this.x,
        y: y ?? this.y,
        z: z ?? this.z,
      );

  @override
  List<Object?> get props => [count, x, y, z];
}

/// Находка: выбранная патология с уточнениями и списком зубов.
class SelectedPathology extends Equatable {
  const SelectedPathology({
    required this.uid,
    required this.pathologyId,
    this.toothFdis = const [],
    this.measurements,
    this.side,
    this.direction,
    this.adjacentFdi,
  });

  final String uid;
  final String pathologyId;

  /// Пусто для общих (general) патологий.
  final List<int> toothFdis;

  final Measurements? measurements;
  final Side? side;
  final Direction? direction;
  final int? adjacentFdi;

  /// Все ли обязательные уточнения заполнены.
  bool isCompleteFor(Pathology pathology) {
    if (pathology.requiresSize && !(measurements?.isComplete ?? false)) {
      return false;
    }
    if (pathology.requiresSide && side == null) return false;
    if (pathology.requiresDirection && direction == null) return false;
    if (pathology.requiresAdjacentTooth && adjacentFdi == null) return false;
    return true;
  }

  SelectedPathology copyWith({
    List<int>? toothFdis,
    Measurements? measurements,
    Side? side,
    Direction? direction,
    int? adjacentFdi,
    bool clearAdjacentFdi = false,
  }) => SelectedPathology(
    uid: uid,
    pathologyId: pathologyId,
    toothFdis: toothFdis ?? this.toothFdis,
    measurements: measurements ?? this.measurements,
    side: side ?? this.side,
    direction: direction ?? this.direction,
    adjacentFdi: clearAdjacentFdi ? null : (adjacentFdi ?? this.adjacentFdi),
  );

  @override
  List<Object?> get props => [
    uid,
    pathologyId,
    toothFdis,
    measurements,
    side,
    direction,
    adjacentFdi,
  ];
}
