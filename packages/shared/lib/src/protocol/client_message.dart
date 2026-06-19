import 'package:dart_mappable/dart_mappable.dart';

import 'direction.dart';
import 'game_types.dart';

part 'client_message.mapper.dart';

@MappableEnum()
enum ClientMessageType {
  input,
  stop,
  selectRole,
  ready,
  spectate,
  placeTrap,
  useAbility,
  layClutch,
  selectAspect,
  selectHunter,
  setName,
  addBot,
  removeBot,
  restart,
  setBiomes,
}

@MappableClass()
class ClientMessage with ClientMessageMappable {
  const ClientMessage({
    required this.type,
    this.direction,
    this.role,
    this.aspect,
    this.hunter,
    this.name,
    this.ready,
    this.biomes,
  });

  final ClientMessageType type;
  final MoveDirection? direction;
  final PlayerRole? role;
  final LehaAspect? aspect;
  final HunterKind? hunter;
  final String? name;
  final bool? ready;
  /// Biomes enabled for the next map (for [ClientMessageType.setBiomes]).
  final List<CaveBiome>? biomes;
}
