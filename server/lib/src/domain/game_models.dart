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
  final WebSocket socket;
  int? slot;
  PlayerRole role = PlayerRole.spectator;
  bool ready = false;
  int score = 0;
  double x;
  double y;
  MoveDirection? direction;
  MoveDirection? nextDirection;
  MoveDirection lastDirection = MoveDirection.right;
  bool stopRequested = false;
  LehaAspect aspect = LehaAspect.superLeha;
  int hp = 100;
  int trapCooldownUntil = 0;
  int trapCharges = 0;
  int webCharges = 0;
  int portalCooldownUntil = 0;
  int stunnedUntil = 0;
  int invulnerableUntil = 0;
  int webSlowedUntil = 0;
  int webPhaseUntil = 0;
  double speed = 0;
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
  List<PortalState> portals = [];
  List<int> pendingTrapRechargeAt = [];
  Map<int, List<TrailPoint>> trails = {0: [], 1: []};
}
