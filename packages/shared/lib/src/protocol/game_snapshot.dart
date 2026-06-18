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
    this.hunterKind,
    this.blinded = false,
    this.femboy = false,
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
  /// Hunter variant — only sent for the hunter slot (Hunter / Sasha-yakuza).
  final HunterKind? hunterKind;
  /// True while Leha's vision radius is collapsed after a barrel hit.
  final bool blinded;
  /// True while Sima is in femboy form (charm ability active).
  final bool femboy;
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
class BarrelDto with BarrelDtoMappable {
  const BarrelDto({
    required this.x,
    required this.y,
    required this.dirX,
    required this.dirY,
  });

  final double x;
  final double y;
  final double dirX;
  final double dirY;
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
    this.hunterKind,
    this.bot = false,
  });

  final PlayerRole role;
  final int slot;
  final bool taken;
  final bool ready;
  final String? playerId;
  final LehaAspect? aspect;
  final HunterKind? hunterKind;
  /// True when this slot is occupied by an AI bot rather than a human.
  final bool bot;
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
    this.barrelAvailable = false,
    this.barrelCooldownMs = 0,
    this.femboyAvailable = false,
    this.femboyCooldownMs = 0,
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
  /// Sasha-yakuza barrel ability readiness (hunter slot only).
  final bool barrelAvailable;
  final int barrelCooldownMs;
  /// Sima femboy (charm) ability readiness (hunter slot only).
  final bool femboyAvailable;
  final int femboyCooldownMs;
}

@MappableClass()
class YouDto with YouDtoMappable {
  const YouDto({
    required this.id,
    required this.slot,
    required this.role,
    this.name = '',
  });

  final String id;
  final int? slot;
  final PlayerRole role;
  final String name;
}

@MappableClass()
class UserStatsDto with UserStatsDtoMappable {
  const UserStatsDto({
    required this.name,
    required this.wins,
    required this.losses,
  });

  final String name;
  final int wins;
  final int losses;
}

@MappableClass()
class GameSnapshotDto with GameSnapshotDtoMappable {
  const GameSnapshotDto({
    required this.type,
    required this.you,
    required this.rows,
    required this.cols,
    required this.maze,
    this.bushes = const [],
    required this.logos,
    required this.traps,
    required this.webs,
    required this.barrels,
    required this.portals,
    required this.trail,
    required this.players,
    required this.scores,
    required this.connectedPlayers,
    required this.lobby,
    required this.game,
    required this.status,
    this.leaderboard = const [],
    this.yourStats,
  });

  final String type;
  final YouDto you;
  final int rows;
  final int cols;
  final List<String> maze;
  /// Static bush cells (cover): hide players from scent/xray.
  final List<Vec2i> bushes;
  final List<LogoDto> logos;
  final List<TrapDto> traps;
  final List<WebDto> webs;
  final List<BarrelDto> barrels;
  final List<PortalDto> portals;
  final List<TrailPointDto> trail;
  final List<PlayerDto> players;
  final List<ScoreDto> scores;
  final int connectedPlayers;
  final LobbyDto lobby;
  final GameInfoDto game;
  final String status;
  /// Win/loss leaderboard across all registered nicknames (top entries).
  final List<UserStatsDto> leaderboard;
  /// The viewing user's own stats, if they registered a nickname.
  final UserStatsDto? yourStats;
}
