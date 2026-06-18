import 'package:dart_mappable/dart_mappable.dart';

part 'game_types.mapper.dart';

@MappableEnum()
enum PlayerRole { leha, hunter, spectator }

@MappableEnum()
enum LehaAspect { superLeha, spider, wizard }

@MappableEnum()
enum HunterKind { bakhirkin, sashaYakuza, sima }

@MappableEnum()
enum GamePhase { waiting, playing, ended }

@MappableClass()
class Vec2i with Vec2iMappable {
  const Vec2i(this.x, this.y);

  final int x;
  final int y;
}

@MappableClass()
class Vec2d with Vec2dMappable {
  const Vec2d(this.x, this.y);

  final double x;
  final double y;
}
