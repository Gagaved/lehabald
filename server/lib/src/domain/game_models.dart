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
  int stunnedUntil = 0;
  int invulnerableUntil = 0;
  int webSlowedUntil = 0;
  int webPhaseUntil = 0;
  double speed = 0;

  /// Cell key ('x,y') the player occupied last tick — used so a portal only
  /// fires when the player freshly steps onto it, never when the second portal
  /// opens beneath a player already standing on the first.
  String? lastCellKey;
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
  });

  double x;
  double y;
  double dirX;
  double dirY;
  final int spawnedAt;
  final String ownerId;

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
  List<int> pendingTrapRechargeAt = [];
  List<int> pendingWebRechargeAt = [];
  Map<int, List<TrailPoint>> trails = {0: [], 1: []};
}
