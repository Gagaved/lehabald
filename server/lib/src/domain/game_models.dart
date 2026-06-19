import 'dart:io';

import 'package:leha_bald_shared/leha_bald_shared.dart';

class PlayerConnection {
  PlayerConnection({
    required this.id,
    required this.socket,
    required this.x,
    required this.y,
  });

  final String id;
  final WebSocket? socket;
  bool isBot = false;
  int botNextThinkAt = 0;
  String name = '';
  int? slot;
  PlayerRole role = PlayerRole.spectator;
  bool ready = false;
  int? readyTimeoutStartedAt;
  int score = 0;
  double x;
  double y;
  MoveDirection? direction;
  MoveDirection? nextDirection;
  MoveDirection lastDirection = MoveDirection.right;
  bool stopRequested = false;
  LehaAspect aspect = LehaAspect.superLeha;
  HunterKind hunterKind = HunterKind.bakhirkin;
  int hp = 100;
  int trapCooldownUntil = 0;
  int barrelCooldownUntil = 0;
  int blindUntil = 0;
  int simaFemboyUntil = 0;
  int simaCooldownUntil = 0;
  int trapCharges = 0;
  int webCharges = 0;
  int webCooldownUntil = 0;
  int portalCooldownUntil = 0;
  int magicChainCooldownUntil = 0;
  int stunnedUntil = 0;
  int invulnerableUntil = 0;
  int webSlowedUntil = 0;
  int webPhaseUntil = 0;
  double speed = 0;

  /// Cell key ('x,y') the player occupied last tick — used so a portal only
  /// fires when the player freshly steps onto it, never when the second portal
  /// opens beneath a player already standing on the first.
  String? lastCellKey;

  /// Wall cell the Spider is currently traversing via a web. Its web is
  /// consumed only once she has fully cleared the cell (her collision circle no
  /// longer overlaps it), so she's never stranded overlapping a tile that
  /// turned solid mid-move.
  String? wallWebCellKey;
}

class TrapState {
  TrapState({
    required this.x,
    required this.y,
    required this.placedAt,
    required this.expiresAt,
  });

  final int x;
  final int y;
  final int placedAt;
  int expiresAt;
  int? triggeredAt;
}

class WebState {
  WebState({required this.x, required this.y, required this.createdAt});

  final int x;
  final int y;
  final int createdAt;
}

class BarrelState {
  BarrelState({
    required this.x,
    required this.y,
    required this.dirX,
    required this.dirY,
    required this.spawnedAt,
    required this.ownerId,
    this.homing = false,
  });

  double x;
  double y;
  double dirX;
  double dirY;
  final int spawnedAt;
  final String ownerId;

  /// If Leha was in direct line of sight when this barrel was thrown, it gently
  /// corrects course toward him (not a guided missile, just a nudge per tick).
  final bool homing;

  /// While now < slowUntil the barrel crawls (set when it touches Spider's web).
  int slowUntil = 0;
}

class PortalState {
  PortalState({
    required this.x,
    required this.y,
    required this.createdAt,
  });

  final int x;
  final int y;
  final int createdAt;
}

class MagicCrystalState {
  MagicCrystalState({
    required this.id,
    required this.x,
    required this.y,
    this.fallen = false,
    this.burstAt = 0,
  });

  final int id;
  final int x;
  final int y;
  bool fallen;
  int burstAt;
}

class MagicChainState {
  MagicChainState({required this.id, required this.contours});

  final int id;
  final List<List<int>> contours;
}

class TrailPoint {
  TrailPoint({
    required this.x,
    required this.y,
    required this.at,
  });

  double x;
  double y;
  int at;
}

/// Spider-Leha's egg clutch. Hatches at [hatchAt] (Spider wins) unless the
/// hunter reaches its cell first and destroys it.
class ClutchState {
  ClutchState({required this.x, required this.y, required this.hatchAt});

  final int x;
  final int y;
  final int hatchAt;
}

class SarcophagusState {
  SarcophagusState({
    required this.x,
    required this.y,
    this.cracked = false,
    this.hasMummy = true,
  });

  final int x;
  final int y;
  bool cracked;
  bool hasMummy;
  final Set<String> playersInRadius = {};
}

class MummyState {
  MummyState({
    required this.x,
    required this.y,
    this.fleeing = false,
    this.targetX,
    this.targetY,
  });

  double x;
  double y;
  bool fleeing;
  int? targetX;
  int? targetY;
  final Map<String, int> hitCooldownUntil = {};
}

/// An amethyst shard's "chime": an expanding purple pulse fired when a player
/// steps on a shard, revealing where they were.
class ChimeState {
  ChimeState({required this.x, required this.y, required this.firedAt});

  final double x;
  final double y;
  final int firedAt;
}

/// A growing mushroom in the amethyst colony. Advances through [stage] until it
/// reaches the max stage, then dies and releases spores.
class MushroomState {
  MushroomState(
      {required this.x, required this.y, this.stage = 0, this.nextGrowAt = 0});

  final int x;
  final int y;
  int stage;
  int nextGrowAt;
}

/// A patch of purple spores: conceals like a bush and slows anyone passing
/// through, until [expiresAt].
class SporeState {
  SporeState({required this.x, required this.y, required this.expiresAt});

  final int x;
  final int y;
  int expiresAt;
}

class GameRound {
  GamePhase phase = GamePhase.waiting;
  int? startedAt;
  int? endedAt;
  int? winnerSlot;
  String reason = '';
  int lehaPowerUntil = 0;
  List<TrapState> traps = [];
  List<WebState> webs = [];
  List<BarrelState> barrels = [];
  List<PortalState> portals = [];
  List<MagicCrystalState> magicCrystals = [];
  List<MagicChainState> magicChains = [];
  int nextMagicCrystalId = 1;
  int nextMagicChainId = 1;
  double wizardSaturation = 0;
  List<int> pendingTrapRechargeAt = [];
  List<int> pendingWebRechargeAt = [];
  // Spider "Raffaello" mode: collect Raffaellos to lay an egg clutch.
  ClutchState? clutch;
  List<SarcophagusState> sarcophagi = [];
  List<MummyState> mummies = [];
  // Amethyst biome: shards still intact, active chimes, mushroom colony + spores.
  Set<String> shardsIntact = {};
  List<ChimeState> chimes = [];
  List<MushroomState> mushrooms = [];
  List<SporeState> spores = [];
  int nextAmethystGrowAt = 0;
  int rafaelkiEaten = 0;
  Map<int, List<TrailPoint>> trails = {0: [], 1: []};
}
