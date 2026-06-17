import 'package:dart_mappable/dart_mappable.dart';

part 'direction.mapper.dart';

@MappableEnum()
enum MoveDirection {
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight;

  static const _d = 0.7071067811865476; // 1/sqrt(2)

  double get dx => switch (this) {
        MoveDirection.left || MoveDirection.upLeft || MoveDirection.downLeft => -1,
        MoveDirection.right || MoveDirection.upRight || MoveDirection.downRight => 1,
        _ => 0,
      } * (isDiagonal ? _d : 1.0);

  double get dy => switch (this) {
        MoveDirection.up || MoveDirection.upLeft || MoveDirection.upRight => -1,
        MoveDirection.down || MoveDirection.downLeft || MoveDirection.downRight => 1,
        _ => 0,
      } * (isDiagonal ? _d : 1.0);

  bool get isDiagonal => switch (this) {
        MoveDirection.upLeft ||
        MoveDirection.upRight ||
        MoveDirection.downLeft ||
        MoveDirection.downRight =>
          true,
        _ => false,
      };
}
