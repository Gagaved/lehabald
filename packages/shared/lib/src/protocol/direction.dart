import 'package:dart_mappable/dart_mappable.dart';

part 'direction.mapper.dart';

@MappableEnum()
enum MoveDirection {
  up,
  down,
  left,
  right;

  int get dx => switch (this) {
        MoveDirection.left => -1,
        MoveDirection.right => 1,
        _ => 0,
      };

  int get dy => switch (this) {
        MoveDirection.up => -1,
        MoveDirection.down => 1,
        _ => 0,
      };
}
