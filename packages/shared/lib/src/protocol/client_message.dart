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
  placeMagicCrystal,
  layClutch,
  activateMagicChain,
  selectAspect,
  selectHunter,
  setName,
  addBot,
  removeBot,
  setBiomes,
  setSandbox,
  aim,
  createSession,
  joinSession,
  leaveSession,
  rematch,
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
    this.sandbox,
    this.targetX,
    this.targetY,
    this.sessionId,
    this.sessionName,
  });

  final ClientMessageType type;
  final MoveDirection? direction;
  final PlayerRole? role;
  final LehaAspect? aspect;
  final HunterKind? hunter;
  final String? name;
  final bool? ready;

  /// Biomes enabled for the lobby preview and the next round.
  final List<CaveBiome>? biomes;
  final bool? sandbox;
  final double? targetX;
  final double? targetY;
  final String? sessionId;
  final String? sessionName;
}
