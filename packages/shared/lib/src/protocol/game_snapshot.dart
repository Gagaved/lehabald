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
    this.charmed = false,
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

  /// True while Leha is being pulled toward Sima by a "Камингаут" heart hit.
  final bool charmed;

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

/// One of Sima's "Камингаут" heart projectiles in flight.
@MappableClass()
class HeartDto with HeartDtoMappable {
  const HeartDto({
    required this.x,
    required this.y,
    this.impact = false,
  });

  final double x;
  final double y;
  final bool impact;
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
class MagicCrystalDto with MagicCrystalDtoMappable {
  const MagicCrystalDto({
    required this.id,
    required this.x,
    required this.y,
    required this.fallen,
    this.burstProgress = 1,
  });

  final int id;
  final int x;
  final int y;
  final bool fallen;

  /// 0..1 for the brief failed-activation explosion; 1 when inactive.
  final double burstProgress;
}

@MappableClass()
class MagicChainDto with MagicChainDtoMappable {
  const MagicChainDto({required this.id, required this.contours});

  final int id;
  final List<List<int>> contours;
}

/// A crystal's mirror projection of a player. Drawn like the mimicked player
/// but with [opacity] (fades with the crystal-to-player distance).
@MappableClass()
class IllusionDto with IllusionDtoMappable {
  const IllusionDto({
    required this.x,
    required this.y,
    required this.slot,
    required this.opacity,
    this.aspect,
    this.hunterKind,
    this.powered = false,
    this.femboy = false,
    this.own = false,
  });

  final double x;
  final double y;
  final int? slot;
  final double opacity;
  final LehaAspect? aspect;
  final HunterKind? hunterKind;
  final bool powered;
  final bool femboy;

  /// Whether this is the viewer's own illusion — always shown (no line-of-sight
  /// required) and rendered with a translucent blue tint so the player can tell
  /// their own mirror image apart from a real opponent.
  final bool own;
}

@MappableClass()
class SarcophagusDto with SarcophagusDtoMappable {
  const SarcophagusDto({
    required this.x,
    required this.y,
    required this.cracked,
    required this.hasMummy,
  });

  final int x;
  final int y;
  final bool cracked;
  final bool hasMummy;
}

@MappableClass()
class MummyDto with MummyDtoMappable {
  const MummyDto({
    required this.x,
    required this.y,
    required this.fleeing,
  });

  final double x;
  final double y;
  final bool fleeing;
}

@MappableClass()
class ChimeDto with ChimeDtoMappable {
  const ChimeDto({
    required this.x,
    required this.y,
    required this.progress,
  });

  final double x;
  final double y;

  /// 0..1 expansion progress of the pulse (drives ring radius and fade).
  final double progress;
}

@MappableClass()
class MushroomDto with MushroomDtoMappable {
  const MushroomDto({
    required this.x,
    required this.y,
    required this.stage,
  });

  final int x;
  final int y;

  /// Growth stage 0 (sprout) .. max (mature).
  final int stage;
}

@MappableClass()
class LavaCellDto with LavaCellDtoMappable {
  const LavaCellDto({required this.x, required this.y, required this.stream});
  final int x;
  final int y;
  final int stream;
}

@MappableClass()
class EmberRockDto with EmberRockDtoMappable {
  const EmberRockDto({
    required this.id,
    required this.x,
    required this.y,
    required this.stream,
    required this.bridge,
    required this.sinking,
  });
  final int id;
  final int x;
  final int y;
  final int stream;
  final bool bridge;
  final bool sinking;
}

@MappableClass()
class EmberGeyserDto with EmberGeyserDtoMappable {
  const EmberGeyserDto({
    required this.id,
    required this.x,
    required this.y,
    required this.progress,
  });
  final int id;
  final int x;
  final int y;
  // 0 → just started building, 1 → about to erupt.
  final double progress;
}

@MappableClass()
class SulfurDto with SulfurDtoMappable {
  const SulfurDto({required this.x, required this.y, required this.life});
  final int x;
  final int y;
  final double life;
}

@MappableClass()
class ClutchDto with ClutchDtoMappable {
  const ClutchDto({
    required this.x,
    required this.y,
    required this.hatchMs,
  });

  final int x;
  final int y;

  /// Milliseconds remaining until it hatches (for the growing visual).
  final int hatchMs;
}

@MappableClass()
class TrailPointDto with TrailPointDtoMappable {
  const TrailPointDto({
    required this.x,
    required this.y,
    required this.alpha,
    this.loud = false,
  });

  final double x;
  final double y;
  final double alpha;

  /// A "loud" footprint left while crossing forest leaf litter: it lasts longer
  /// and the opponent always sees it, regardless of scent range or sight.
  final bool loud;
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
    this.users = const [],
  });

  final List<RoleStateDto> roles;
  final int spectators;
  final List<ConnectedUserDto> users;
}

@MappableClass()
class ConnectedUserDto with ConnectedUserDtoMappable {
  const ConnectedUserDto({
    required this.id,
    required this.name,
    required this.role,
    required this.bot,
  });

  final String id;
  final String name;
  final PlayerRole role;
  final bool bot;
}

@MappableClass()
class MatchPlayerDto with MatchPlayerDtoMappable {
  const MatchPlayerDto({
    required this.id,
    required this.name,
    required this.role,
    required this.roundWins,
    required this.pickLocked,
    required this.rematch,
  });

  final String id;
  final String name;
  final PlayerRole role;
  final int roundWins;
  final bool pickLocked;
  final bool rematch;
}

@MappableClass()
class RoundResultDto with RoundResultDtoMappable {
  const RoundResultDto({
    required this.round,
    required this.winnerId,
    required this.winnerName,
    required this.role,
    required this.reason,
  });

  final int round;
  final String winnerId;
  final String winnerName;
  final PlayerRole role;
  final String reason;
}

@MappableClass()
class SessionStateDto with SessionStateDtoMappable {
  const SessionStateDto({
    required this.id,
    required this.name,
    required this.phase,
    required this.round,
    required this.players,
    required this.streakOwnerId,
    required this.streakRole,
    required this.history,
    required this.matchWinnerId,
    required this.technical,
  });

  final String id;
  final String name;
  final SessionPhase phase;
  final int round;
  final List<MatchPlayerDto> players;
  final String? streakOwnerId;
  final PlayerRole? streakRole;
  final List<RoundResultDto> history;
  final String? matchWinnerId;
  final bool technical;
}

@MappableClass()
class SessionSummaryDto with SessionSummaryDtoMappable {
  const SessionSummaryDto({
    required this.id,
    required this.name,
    required this.phase,
    required this.round,
    required this.players,
    required this.spectators,
  });

  final String id;
  final String name;
  final SessionPhase phase;
  final int round;
  final List<MatchPlayerDto> players;
  final int spectators;
}

@MappableClass()
class DirectorySnapshotDto with DirectorySnapshotDtoMappable {
  const DirectorySnapshotDto({
    required this.type,
    required this.sessions,
    this.onlineUsers = 0,
    this.leaderboard = const [],
    this.yourStats,
  });

  final String type;
  final List<SessionSummaryDto> sessions;
  final int onlineUsers;
  final List<UserStatsDto> leaderboard;
  final UserStatsDto? yourStats;
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
    this.comingOutAvailable = false,
    this.comingOutCharges = 0,
    this.comingOutCooldownMs = 0,
    this.spiderMode = false,
    this.rafaelkiEaten = 0,
    this.rafaelkiNeeded = 0,
    this.clutchAvailable = false,
    this.clutchActive = false,
    this.clutchHatchMs = 0,
    this.wizardSaturation = 0,
    this.magicChainCooldownMs = 0,
    this.magicCrystalCharges = 0,
    this.magicCrystalAvailable = false,
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

  /// Sima femboy (form) ability readiness (hunter slot only).
  final bool femboyAvailable;
  final int femboyCooldownMs;

  /// Sima "Камингаут" heart ability readiness/charges (hunter slot only).
  final bool comingOutAvailable;
  final int comingOutCharges;
  final int comingOutCooldownMs;

  /// Spider-Leha "Raffaello" mode: collect Raffaellos to lay an egg clutch.
  final bool spiderMode;
  final int rafaelkiEaten;
  final int rafaelkiNeeded;

  /// True when the Spider has eaten enough Raffaellos to lay a clutch (key F).
  final bool clutchAvailable;

  /// True while an egg clutch is on the map (drives the hunter's alert banner).
  final bool clutchActive;

  /// Milliseconds left until the clutch hatches (Spider wins).
  final int clutchHatchMs;

  /// Wizard victory progress, from 0 to 1.
  final double wizardSaturation;

  /// Remaining delay before another chain activation attempt.
  final int magicChainCooldownMs;
  final int magicCrystalCharges;
  final bool magicCrystalAvailable;
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
    this.leaves = const [],
    this.crackedWalls = const [],
    this.biome = CaveBiome.forest,
    this.stoneSeed = 0,
    this.crystals = const [],
    this.quicksand = const [],
    this.amethystWalls = const [],
    this.amethystShards = const [],
    this.chimes = const [],
    this.mushrooms = const [],
    this.spores = const [],
    this.lava = const [],
    this.emberRocks = const [],
    this.geysers = const [],
    this.sulfur = const [],
    this.illusions = const [],
    this.sarcophagi = const [],
    this.mummies = const [],
    this.enabledBiomes = const [],
    this.sandboxMode = false,
    required this.logos,
    required this.traps,
    required this.webs,
    this.hearts = const [],
    required this.barrels,
    required this.portals,
    this.magicCrystals = const [],
    this.magicChains = const [],
    this.clutch,
    required this.trail,
    required this.players,
    required this.scores,
    required this.connectedPlayers,
    required this.lobby,
    required this.game,
    required this.status,
    this.leaderboard = const [],
    this.yourStats,
    this.session,
  });

  final String type;
  final YouDto you;
  final int rows;
  final int cols;
  final List<String> maze;

  /// Static bush cells (cover): hide players from scent/xray.
  final List<Vec2i> bushes;

  /// Forest-biome dry leaf-litter cells: crossing them leaves a loud footprint
  /// the opponent can read from anywhere.
  final List<Vec2i> leaves;

  /// Cracked wall cells — the only places Spider-Leha may spin a web.
  final List<Vec2i> crackedWalls;

  /// The cave's visual theme (drives wall/bush palette on the client).
  final CaveBiome biome;

  /// Per-map seed so the stone colour varies between maps of the same biome.
  final int stoneSeed;

  /// Ice-biome crystal entities — each projects mirror illusions of players.
  final List<Vec2i> crystals;

  /// Sandstone-biome quicksand cells — anyone standing on them moves slower.
  final List<Vec2i> quicksand;

  /// Permanent wall-nodes that seed destructible amethyst floor colonies.
  final List<Vec2i> amethystWalls;

  /// Amethyst-biome intact shard cells (shatter & ring out when stepped on).
  final List<Vec2i> amethystShards;

  /// Active amethyst chimes — expanding pulses revealing a stepper's position.
  final List<ChimeDto> chimes;

  /// Amethyst-biome mushroom colony entities (grow, then die into spores).
  final List<MushroomDto> mushrooms;

  /// Amethyst-biome spore cells — conceal like bushes and slow movement.
  final List<Vec2i> spores;

  /// Ember-only terrain and transient entities.
  final List<LavaCellDto> lava;

  /// Solid rocks that surface inside the lava as temporary stepping stones.
  final List<EmberRockDto> emberRocks;

  /// Sulfur geysers building up to erupt (progress 0→1).
  final List<EmberGeyserDto> geysers;

  /// Drifting sulfur clouds — conceal like bushes, then fade.
  final List<SulfurDto> sulfur;

  /// Crystal-projected player illusions visible to this viewer.
  final List<IllusionDto> illusions;

  /// Sandstone-biome sarcophagi that can crack and release mummies.
  final List<SarcophagusDto> sarcophagi;

  /// Active mummy-zombies released from sarcophagi.
  final List<MummyDto> mummies;

  /// Which biomes are enabled for the lobby preview and next round.
  final List<CaveBiome> enabledBiomes;
  final bool sandboxMode;
  final List<LogoDto> logos;
  final List<TrapDto> traps;
  final List<WebDto> webs;

  /// Sima's "Камингаут" heart projectiles currently in flight.
  final List<HeartDto> hearts;
  final List<BarrelDto> barrels;
  final List<PortalDto> portals;
  final List<MagicCrystalDto> magicCrystals;
  final List<MagicChainDto> magicChains;

  /// The Spider's egg clutch, when one is laid and visible to the viewer.
  final ClutchDto? clutch;
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
  final SessionStateDto? session;
}
