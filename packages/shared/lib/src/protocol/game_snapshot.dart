import 'package:dart_mappable/dart_mappable.dart';

import 'direction.dart';
import 'game_types.dart';

part 'game_snapshot.mapper.dart';

@MappableClass()
class PlayerDto with PlayerDtoMappable {
  const PlayerDto({
    required this.id,
    required this.slot,
    required this.role,
    required this.x,
    required this.y,
    required this.score,
    required this.powered,
    required this.ghost,
    required this.stunned,
    required this.invulnerable,
    required this.hp,
    required this.aspect,
    this.facing,
  });

  final String id;
  final int? slot;
  final PlayerRole role;
  final double x;
  final double y;
  final int score;
  final bool powered;
  final bool ghost;
  final bool stunned;
  final bool invulnerable;
  final int hp;
  final LehaAspect? aspect;
  /// Facing direction — only sent for Spider and Wizard Leha (direction indicator).
  final MoveDirection? facing;
}

@MappableClass()
class LogoDto with LogoDtoMappable {
  const LogoDto({
    required this.x,
    required this.y,
    required this.power,
  });

  final int x;
  final int y;
  final bool power;
}

@MappableClass()
class TrapDto with TrapDtoMappable {
  const TrapDto({
    required this.x,
    required this.y,
    required this.placedAt,
    required this.expiresAt,
    this.triggered = false,
  });

  final int x;
  final int y;
  final int placedAt;
  final int expiresAt;
  final bool triggered;
}

@MappableClass()
class WebDto with WebDtoMappable {
  const WebDto({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

@MappableClass()
class PortalDto with PortalDtoMappable {
  const PortalDto({
    required this.x,
    required this.y,
    required this.index,
    required this.active,
  });

  final int x;
  final int y;
  final int index;
  final bool active;
}

@MappableClass()
class TrailPointDto with TrailPointDtoMappable {
  const TrailPointDto({
    required this.x,
    required this.y,
    required this.alpha,
  });

  final double x;
  final double y;
  final double alpha;
}

@MappableClass()
class ScoreDto with ScoreDtoMappable {
  const ScoreDto({
    required this.id,
    required this.slot,
    required this.role,
    required this.score,
  });

  final String id;
  final int? slot;
  final PlayerRole? role;
  final int score;
}

@MappableClass()
class RoleStateDto with RoleStateDtoMappable {
  const RoleStateDto({
    required this.role,
    required this.slot,
    required this.taken,
    required this.ready,
    required this.playerId,
    required this.aspect,
  });

  final PlayerRole role;
  final int slot;
  final bool taken;
  final bool ready;
  final String? playerId;
  final LehaAspect? aspect;
}

@MappableClass()
class LobbyDto with LobbyDtoMappable {
  const LobbyDto({
    required this.roles,
    required this.spectators,
  });

  final List<RoleStateDto> roles;
  final int spectators;
}

@MappableClass()
class GameInfoDto with GameInfoDtoMappable {
  const GameInfoDto({
    required this.phase,
    required this.winnerSlot,
    required this.reason,
    required this.timeLeftMs,
    required this.lehaPowered,
    required this.powerLeftMs,
    required this.trapAvailable,
    required this.trapCooldownMs,
    required this.trapActive,
    required this.trapCharges,
    required this.abilityAvailable,
    required this.abilityCooldownMs,
    required this.abilityCharges,
  });

  final GamePhase phase;
  final int? winnerSlot;
  final String reason;
  final int timeLeftMs;
  final bool lehaPowered;
  final int powerLeftMs;
  final bool trapAvailable;
  final int trapCooldownMs;
  final bool trapActive;
  final int trapCharges;
  final bool abilityAvailable;
  final int abilityCooldownMs;
  final int abilityCharges;
}

@MappableClass()
class YouDto with YouDtoMappable {
  const YouDto({
    required this.id,
    required this.slot,
    required this.role,
  });

  final String id;
  final int? slot;
  final PlayerRole role;
}

@MappableClass()
class GameSnapshotDto with GameSnapshotDtoMappable {
  const GameSnapshotDto({
    required this.type,
    required this.you,
    required this.rows,
    required this.cols,
    required this.maze,
    required this.logos,
    required this.traps,
    required this.webs,
    required this.portals,
    required this.trail,
    required this.players,
    required this.scores,
    required this.connectedPlayers,
    required this.lobby,
    required this.game,
    required this.status,
  });

  final String type;
  final YouDto you;
  final int rows;
  final int cols;
  final List<String> maze;
  final List<LogoDto> logos;
  final List<TrapDto> traps;
  final List<WebDto> webs;
  final List<PortalDto> portals;
  final List<TrailPointDto> trail;
  final List<PlayerDto> players;
  final List<ScoreDto> scores;
  final int connectedPlayers;
  final LobbyDto lobby;
  final GameInfoDto game;
  final String status;
}
