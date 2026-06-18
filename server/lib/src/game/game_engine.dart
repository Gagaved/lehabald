import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_constants.dart';
import '../domain/game_models.dart';
import 'game_logger.dart';
import 'maze_service.dart';
import 'stats_store.dart';

class GameEngine {
  GameEngine({required MazeService maze, StatsStore? stats, GameLogger? logger})
      : _maze = maze,
        stats = stats ?? StatsStore(),
        logger = logger ?? GameLogger() {
    logos = maze.createLogos();
  }

  MazeService _maze;
  MazeService get maze => _maze;
  final StatsStore stats;
  final GameLogger logger;

  String _playerLog(PlayerConnection? p, String character) => p == null
      ? 'none'
      : '${p.isBot ? 'BOT' : (p.name.isEmpty ? 'anon' : p.name)} ($character)';
  final Map<String, PlayerConnection> clients = {};
  var round = GameRound();
  var logos = <String>{};
  int _nextId = 1;
  final _rng = Random();

  PlayerConnection createClient(WebSocket socket) {
    final start = GameConstants.starts.first;
    final client = PlayerConnection(
      id: '${_nextId++}',
      socket: socket,
      x: start.x + 0.5,
      y: start.y + 0.5,
    )..speed = speedForSlot(null, nowMs());
    clients[client.id] = client;
    ensureRoundState();
    return client;
  }

  void removeClient(PlayerConnection client) {
    clients.remove(client.id);
    ensureRoundState();
  }

  void applyMessage(PlayerConnection client, ClientMessage message) {
    switch (message.type) {
      case ClientMessageType.input:
        final direction = message.direction;
        if (client.slot == null ||
            round.phase != GamePhase.playing ||
            direction == null) {
          return;
        }
        client.nextDirection = direction;
        client.lastDirection = direction;
        client.stopRequested = false;
      case ClientMessageType.stop:
        if (client.slot == null) return;
        client.direction = null;
        client.nextDirection = null;
        client.stopRequested = false;
      case ClientMessageType.selectRole:
        final role = message.role;
        if (role != null) selectRole(client, role);
      case ClientMessageType.ready:
        if (client.slot == null) return;
        client.ready = message.ready ?? false;
        client.readyTimeoutStartedAt = null;
        ensureRoundState();
      case ClientMessageType.spectate:
        becomeSpectator(client);
      case ClientMessageType.placeTrap:
        placeTrap(client);
      case ClientMessageType.useAbility:
        useAbility(client);
      case ClientMessageType.layClutch:
        layClutch(client);
      case ClientMessageType.selectAspect:
        final aspect = message.aspect;
        if (aspect != null) selectAspect(client, aspect);
      case ClientMessageType.selectHunter:
        final hunter = message.hunter;
        if (hunter != null) selectHunter(client, hunter);
      case ClientMessageType.setName:
        final name = message.name;
        if (name != null) setName(client, name);
      case ClientMessageType.addBot:
        final role = message.role;
        if (role != null) addBot(role);
      case ClientMessageType.removeBot:
        final role = message.role;
        if (role != null) removeBot(role);
      case ClientMessageType.restart:
        // A spectator (e.g. watching two bots) returns everyone to the lobby;
        // an actual player triggers a rematch.
        reset(keepBotsReady: client.slot != null);
    }
  }

  void reset({bool keepBotsReady = true}) {
    _maze = MazeService.generate();
    logos = findPlayer(0)?.aspect == LehaAspect.spider
        ? _spawnRafaelki()
        : _maze.createLogos();
    round = GameRound();
    for (final client in clients.values) {
      final start = GameConstants.starts[client.slot ?? 0];
      client
        ..score = 0
        ..ready = keepBotsReady && client.isBot
        ..readyTimeoutStartedAt = null
        ..x = start.x + 0.5
        ..y = start.y + 0.5
        ..direction = null
        ..nextDirection = null
        ..lastDirection = MoveDirection.right
        ..stopRequested = false
        ..hp = client.slot == 1 ? 100 : client.hp
        ..trapCharges = _trapChargesFor(client)
        ..trapCooldownUntil = 0
        ..barrelCooldownUntil = 0
        ..simaFemboyUntil = 0
        ..simaCooldownUntil = 0
        ..blindUntil = 0
        ..webCharges = client.slot == 0 ? GameConstants.maxWebCharges : 0
        ..webCooldownUntil = 0
        ..portalCooldownUntil = 0
        ..stunnedUntil = 0
        ..invulnerableUntil = 0
        ..webSlowedUntil = 0
        ..webPhaseUntil = 0
        ..speed = speedFor(client, nowMs());
    }
    ensureRoundState();
  }

  /// Only Bakhirkin places traps; Sasha-yakuza throws barrels instead.
  int _trapChargesFor(PlayerConnection client) =>
      client.slot == 1 && client.hunterKind == HunterKind.bakhirkin
          ? GameConstants.maxTrapCharges
          : 0;

  void selectRole(PlayerConnection client, PlayerRole role) {
    if (round.phase != GamePhase.waiting || role == PlayerRole.spectator) {
      return;
    }
    final slot = GameConstants.roles.indexOf(role);
    if (slot == -1) return;
    final occupied =
        clients.values.any((other) => other != client && other.slot == slot);
    if (occupied) return;

    final start = GameConstants.starts[slot];
    client
      ..slot = slot
      ..role = role
      ..ready = false
      ..readyTimeoutStartedAt = null
      ..score = 0
      ..x = start.x + 0.5
      ..y = start.y + 0.5
      ..direction = null
      ..nextDirection = null
      ..lastDirection = MoveDirection.right
      ..stopRequested = false
      ..hp = slot == 1 ? 100 : client.hp
      ..trapCharges = slot == 1 && client.hunterKind == HunterKind.bakhirkin
          ? GameConstants.maxTrapCharges
          : 0
      ..trapCooldownUntil = 0
      ..barrelCooldownUntil = 0
      ..simaFemboyUntil = 0
      ..simaCooldownUntil = 0
      ..blindUntil = 0
      ..webCharges = slot == 0 ? GameConstants.maxWebCharges : 0
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..invulnerableUntil = 0
      ..webSlowedUntil = 0
      ..webPhaseUntil = 0
      ..speed = speedFor(client, nowMs());
    ensureRoundState();
  }

  void selectHunter(PlayerConnection client, HunterKind kind) {
    if (round.phase != GamePhase.waiting || client.slot != 1) return;
    client
      ..hunterKind = kind
      ..trapCharges =
          kind == HunterKind.bakhirkin ? GameConstants.maxTrapCharges : 0
      ..trapCooldownUntil = 0
      ..barrelCooldownUntil = 0
      ..simaFemboyUntil = 0
      ..simaCooldownUntil = 0;
    ensureRoundState();
  }

  void setName(PlayerConnection client, String name) {
    var trimmed = name.trim();
    if (trimmed.length > 20) trimmed = trimmed.substring(0, 20);
    client.name = trimmed;
  }

  /// Adds an always-ready AI bot to the [role] slot (Super-Leha for Leha,
  /// Bakhirkin for the hunter). No-op if the slot is already taken.
  void addBot(PlayerRole role) {
    if (round.phase != GamePhase.waiting) return;
    if (role != PlayerRole.leha && role != PlayerRole.hunter) return;
    final slot = GameConstants.roles.indexOf(role);
    if (clients.values.any((c) => c.slot == slot)) return;
    final start = GameConstants.starts[slot];
    final bot = PlayerConnection(
      id: 'bot-$slot-${_nextId++}',
      socket: null,
      x: start.x + 0.5,
      y: start.y + 0.5,
    )
      ..isBot = true
      ..slot = slot
      ..role = role
      ..ready = true
      ..readyTimeoutStartedAt = null
      ..name = ''
      ..aspect = LehaAspect.superLeha
      ..hunterKind = HunterKind.bakhirkin
      ..hp = 100
      ..trapCharges = slot == 1 ? GameConstants.maxTrapCharges : 0
      ..lastDirection = MoveDirection.right
      ..speed = speedForSlot(slot, nowMs());
    clients[bot.id] = bot;
    ensureRoundState();
  }

  void removeBot(PlayerRole role) {
    if (round.phase != GamePhase.waiting) return;
    final slot = GameConstants.roles.indexOf(role);
    clients.removeWhere((_, c) => c.isBot && c.slot == slot);
    ensureRoundState();
  }

  void selectAspect(PlayerConnection client, LehaAspect aspect) {
    if (round.phase != GamePhase.waiting || client.slot != 0) return;
    client
      ..aspect = aspect
      ..webCharges =
          aspect == LehaAspect.spider ? GameConstants.maxWebCharges : 0
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0;
    // Keep the lobby board's collectibles in sync with the chosen aspect:
    // Spider shows 5 Raffaellos, everyone else the TikTok logos.
    logos = aspect == LehaAspect.spider ? _spawnRafaelki() : _maze.createLogos();
    ensureRoundState();
  }

  void becomeSpectator(PlayerConnection client) {
    if (round.phase != GamePhase.waiting) return;
    client
      ..slot = null
      ..role = PlayerRole.spectator
      ..ready = false
      ..readyTimeoutStartedAt = null
      ..score = 0
      ..direction = null
      ..nextDirection = null
      ..lastDirection = MoveDirection.right
      ..stopRequested = false
      ..hp = 100
      ..trapCharges = 0
      ..trapCooldownUntil = 0
      ..webCharges = 0
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..webSlowedUntil = 0;
    client.webPhaseUntil = 0;
    ensureRoundState();
  }

  void placeTrap(PlayerConnection client) {
    final now = nowMs();
    if (round.phase != GamePhase.playing ||
        client.slot != 1 ||
        client.trapCharges <= 0 ||
        now < client.stunnedUntil ||
        now < client.trapCooldownUntil) {
      return;
    }
    final cell = centerCell(client);
    if (maze.isWall(cell.x, cell.y) || maze.isBush(cell.x, cell.y)) return;
    client.trapCharges -= 1;
    round.traps.add(TrapState(
      x: cell.x,
      y: cell.y,
      placedAt: now,
      expiresAt: now + GameConstants.trapDurationMs,
    ));
  }

  void useAbility(PlayerConnection client) {
    if (round.phase != GamePhase.playing) return;
    if (client.slot == 1) {
      if (client.hunterKind == HunterKind.sashaYakuza) throwBarrel(client);
      if (client.hunterKind == HunterKind.sima) activateFemboy(client);
      return;
    }
    if (client.slot != 0) return;
    switch (client.aspect) {
      case LehaAspect.superLeha:
        return;
      case LehaAspect.spider:
        placeWeb(client);
      case LehaAspect.wizard:
        placePortal(client);
    }
  }

  void activateFemboy(PlayerConnection client) {
    final now = nowMs();
    if (now < client.simaCooldownUntil || now < client.stunnedUntil) return;
    client.simaFemboyUntil = now + GameConstants.simaFemboyMs;
    client.simaCooldownUntil = now + GameConstants.simaFemboyCooldownMs;
  }

  void throwBarrel(PlayerConnection client) {
    final now = nowMs();
    if (now < client.barrelCooldownUntil || now < client.stunnedUntil) return;
    final dir = client.lastDirection;
    client.barrelCooldownUntil = now + GameConstants.barrelCooldownMs;
    round.barrels.add(BarrelState(
      x: client.x,
      y: client.y,
      dirX: dir.dx,
      dirY: dir.dy,
      spawnedAt: now,
      ownerId: client.id,
    ));
  }

  void placeWeb(PlayerConnection client) {
    if (client.webCharges <= 0) return;
    final now = nowMs();
    final cell = centerCell(client);
    // Can't spin a new web while standing inside a wall — otherwise she could
    // chain webs cell-by-cell and camp inside walls indefinitely.
    if (maze.isWall(cell.x, cell.y)) return;
    final dir = client.lastDirection;
    // Place ONE web directly in front of Leha (same as facing direction).
    final bx = (cell.x + dir.dx).round();
    final by = (cell.y + dir.dy).round();
    if (bx < 0 || bx >= maze.cols || by < 0 || by >= maze.rows) return;
    if (maze.isBush(bx, by)) return;
    if (round.webs.any((web) => web.x == bx && web.y == by)) return;
    client.webCharges -= 1;
    round.webs.add(WebState(x: bx, y: by, createdAt: now));
    scheduleWebRecharge(client, now);
  }

  void placePortal(PlayerConnection client) {
    final now = nowMs();
    // Placing portals is free (no cooldown); the only cooldown is the 12s after
    // someone teleports through a pair.
    final current = centerCell(client);
    final direction = client.lastDirection;
    final cell = Point(
        (current.x + direction.dx).round(), (current.y + direction.dy).round());
    if (cell.x < 0 ||
        cell.x >= maze.cols ||
        cell.y < 0 ||
        cell.y >= maze.rows) {
      return;
    }
    if (maze.isWall(cell.x, cell.y) || maze.isBush(cell.x, cell.y)) return;
    round.portals.add(PortalState(x: cell.x, y: cell.y, createdAt: now));
    if (round.portals.length > 2) {
      round.portals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      round.portals.removeAt(0);
    }
  }

  // ---- Bots -------------------------------------------------------------

  static const _steps = <(MoveDirection, int, int)>[
    (MoveDirection.right, 1, 0),
    (MoveDirection.left, -1, 0),
    (MoveDirection.down, 0, 1),
    (MoveDirection.up, 0, -1),
  ];

  void updateBots(int now) {
    for (final bot in clients.values) {
      if (!bot.isBot || bot.slot == null) continue;
      if (now < bot.stunnedUntil) {
        bot.nextDirection = null;
        continue;
      }
      // Re-plan a few times per second; keep moving between decisions.
      if (now < bot.botNextThinkAt) continue;
      bot.botNextThinkAt = now + 180;
      if (bot.slot == 0) {
        _thinkLehaBot(bot, now);
      } else {
        _thinkHunterBot(bot, now);
      }
    }
  }

  void _thinkLehaBot(PlayerConnection bot, int now) {
    final cell = centerCell(bot);
    final hunter = findPlayer(1);
    final powered = now < round.lehaPowerUntil;
    if (hunter != null) {
      final hc = centerCell(hunter);
      final dist = _cellDist(cell, hc);
      if (!powered && dist <= 4) {
        // Threatened: run away from the hunter.
        bot.nextDirection = _fleeStep(cell, hc) ?? bot.nextDirection;
        return;
      }
      if (powered && dist <= 7) {
        // Powered: hunt the hunter down to eat him.
        bot.nextDirection =
            _bfsFirstStep(cell, (x, y) => x == hc.x && y == hc.y) ??
                bot.nextDirection;
        return;
      }
    }
    // Otherwise head for the nearest TikTok logo.
    bot.nextDirection =
        _bfsFirstStep(cell, (x, y) => logos.contains('$x,$y')) ??
            bot.nextDirection;
  }

  void _thinkHunterBot(PlayerConnection bot, int now) {
    final cell = centerCell(bot);
    final leha = findPlayer(0);
    if (leha == null) {
      bot.nextDirection = null;
      return;
    }
    final lc = centerCell(leha);
    if (now < round.lehaPowerUntil) {
      // Powered Leha can eat the hunter — keep distance.
      bot.nextDirection = _fleeStep(cell, lc) ?? bot.nextDirection;
      return;
    }
    // Drop a trap when close, then keep chasing.
    if (bot.hunterKind == HunterKind.bakhirkin &&
        _cellDist(cell, lc) <= 4 &&
        bot.trapCharges > 0 &&
        now >= bot.trapCooldownUntil) {
      placeTrap(bot);
    }
    bot.nextDirection = _bfsFirstStep(cell, (x, y) => x == lc.x && y == lc.y) ??
        bot.nextDirection;
  }

  /// One open cell step from (x,y) along [step], honoring tunnel wrap; null if blocked.
  Point<int>? _stepCell(int x, int y, (MoveDirection, int, int) step) {
    var nx = x + step.$2;
    final ny = y + step.$3;
    if (GameConstants.tunnelRows.contains(ny)) {
      if (nx < 0) nx = maze.cols - 1;
      if (nx >= maze.cols) nx = 0;
    }
    if (ny < 0 || ny >= maze.rows || nx < 0 || nx >= maze.cols) return null;
    if (maze.isWall(nx, ny)) return null;
    return Point(nx, ny);
  }

  /// BFS over maze cells; returns the first move toward the nearest cell
  /// satisfying [isGoal], or null if none reachable.
  MoveDirection? _bfsFirstStep(
      Point<int> start, bool Function(int, int) isGoal) {
    if (isGoal(start.x, start.y)) return null;
    final cols = maze.cols;
    final visited = List<bool>.filled(maze.rows * cols, false);
    visited[start.y * cols + start.x] = true;
    final queue = Queue<({int x, int y, MoveDirection first})>();
    for (final step in _steps) {
      final n = _stepCell(start.x, start.y, step);
      if (n == null || visited[n.y * cols + n.x]) continue;
      if (isGoal(n.x, n.y)) return step.$1;
      visited[n.y * cols + n.x] = true;
      queue.add((x: n.x, y: n.y, first: step.$1));
    }
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      for (final step in _steps) {
        final n = _stepCell(node.x, node.y, step);
        if (n == null || visited[n.y * cols + n.x]) continue;
        if (isGoal(n.x, n.y)) return node.first;
        visited[n.y * cols + n.x] = true;
        queue.add((x: n.x, y: n.y, first: node.first));
      }
    }
    return null;
  }

  /// Open neighbor that maximizes distance from [threat].
  MoveDirection? _fleeStep(Point<int> from, Point<int> threat) {
    MoveDirection? best;
    var bestDist = -1;
    for (final step in _steps) {
      final n = _stepCell(from.x, from.y, step);
      if (n == null) continue;
      final d = _cellDist(n, threat);
      if (d > bestDist) {
        bestDist = d;
        best = step.$1;
      }
    }
    return best;
  }

  int _cellDist(Point<int> a, Point<int> b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();

  void updateBarrels(PlayerConnection? leha, int now, double dt) {
    if (round.barrels.isEmpty) return;
    final baseDist =
        GameConstants.baseSpeed * GameConstants.barrelSpeedMultiplier * dt;
    final survivors = <BarrelState>[];
    for (final barrel in round.barrels) {
      // Destroyed after living for its full lifetime.
      if (now - barrel.spawnedAt >= GameConstants.barrelLifetimeMs) continue;
      // Touching Spider's web slows the barrel to a crawl, and the slow lingers
      // for a moment after it rolls off the web.
      final onWeb = round.webs
          .any((w) => w.x == barrel.x.floor() && w.y == barrel.y.floor());
      if (onWeb) barrel.slowUntil = now + GameConstants.barrelWebSlowMs;
      final slowed = now < barrel.slowUntil;
      _advanceBarrel(barrel,
          slowed ? baseDist * GameConstants.barrelWebSlowFactor : baseDist);
      // Ricochets off walls indefinitely — only lifetime or a hit destroys it.
      // A barrel that reaches Leha is consumed; it only stuns a non-powered Leha
      // (Super/powered Leha shatters the barrel with no effect).
      if (leha != null) {
        final ddx = leha.x - barrel.x;
        final ddy = leha.y - barrel.y;
        if (ddx * ddx + ddy * ddy <=
            GameConstants.barrelHitRadius * GameConstants.barrelHitRadius) {
          if (now >= round.lehaPowerUntil) hitLehaWithBarrel(leha, now);
          continue;
        }
      }
      survivors.add(barrel);
    }
    round.barrels = survivors;
  }

  void _advanceBarrel(BarrelState barrel, double dist) {
    final stepX = barrel.dirX * dist;
    final stepY = barrel.dirY * dist;
    if (!barrelBlocked(barrel.x + stepX, barrel.y + stepY)) {
      barrel
        ..x += stepX
        ..y += stepY;
    } else {
      final blockedX = barrelBlocked(barrel.x + stepX, barrel.y);
      final blockedY = barrelBlocked(barrel.x, barrel.y + stepY);
      if (blockedX) barrel.dirX = -barrel.dirX;
      if (blockedY) barrel.dirY = -barrel.dirY;
      // Head-on into a corner with both axes individually clear: reverse fully.
      if (!blockedX && !blockedY) {
        barrel
          ..dirX = -barrel.dirX
          ..dirY = -barrel.dirY;
      }
      final rx = barrel.x + barrel.dirX * dist;
      final ry = barrel.y + barrel.dirY * dist;
      if (!barrelBlocked(rx, ry)) {
        barrel
          ..x = rx
          ..y = ry;
      } else {
        if (!barrelBlocked(barrel.x + barrel.dirX * dist, barrel.y)) {
          barrel.x += barrel.dirX * dist;
        }
        if (!barrelBlocked(barrel.x, barrel.y + barrel.dirY * dist)) {
          barrel.y += barrel.dirY * dist;
        }
      }
    }
    _wrapBarrelTunnel(barrel);
  }

  /// Circle-vs-AABB wall test for barrels (no spider/web exceptions).
  bool barrelBlocked(double x, double y) {
    if (GameConstants.tunnelRows.contains(y.floor()) &&
        (x < 0 || x >= maze.cols)) {
      return false;
    }
    final r = GameConstants.barrelRadius;
    final minCx = (x - r).floor();
    final maxCx = (x + r).ceil();
    final minCy = (y - r).floor();
    final maxCy = (y + r).ceil();
    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        if (!maze.isWall(cx, cy)) continue;
        final closestX = x.clamp(cx.toDouble(), cx + 1.0);
        final closestY = y.clamp(cy.toDouble(), cy + 1.0);
        final ddx = x - closestX;
        final ddy = y - closestY;
        if (ddx * ddx + ddy * ddy < r * r) return true;
      }
    }
    return false;
  }

  void _wrapBarrelTunnel(BarrelState barrel) {
    if (!GameConstants.tunnelRows.contains(barrel.y.floor())) return;
    if (barrel.x < -0.35) barrel.x = maze.cols + 0.35;
    if (barrel.x > maze.cols + 0.35) barrel.x = -0.35;
  }

  void hitLehaWithBarrel(PlayerConnection leha, int now) {
    leha
      ..stunnedUntil = now + GameConstants.barrelStunMs
      ..blindUntil = now + GameConstants.barrelBlindMs
      ..webPhaseUntil = 0
      ..direction = null
      ..nextDirection = null
      ..stopRequested = false;
  }

  void ensureRoundState() {
    final activePlayers =
        clients.values.where((client) => client.slot != null).toList();
    final hasLeha = activePlayers.any((client) => client.slot == 0);
    final hasHunter = activePlayers.any((client) => client.slot == 1);
    final bothReady = hasLeha &&
        hasHunter &&
        activePlayers
            .where((client) => client.slot == 0 || client.slot == 1)
            .every((client) => client.ready);

    if (!hasLeha || !hasHunter || !bothReady) {
      if (round.phase != GamePhase.ended) {
        round.phase = GamePhase.waiting;
        round.startedAt = null;
      }
      return;
    }

    if (round.phase == GamePhase.waiting) {
      round
        ..phase = GamePhase.playing
        ..startedAt = nowMs()
        ..endedAt = null
        ..winnerSlot = null
        ..reason = ''
        ..lehaPowerUntil = 0
        ..traps = []
        ..webs = []
        ..barrels = []
        ..portals = []
        ..pendingTrapRechargeAt = []
        ..pendingWebRechargeAt = []
        ..clutch = null
        ..rafaelkiEaten = 0
        ..trails = {0: [], 1: []};
      // Spider plays the Raffaello mode (5 candies, no TikToks); other Lehas
      // keep the classic TikTok logos.
      if (findPlayer(0)?.aspect == LehaAspect.spider) {
        logos = _spawnRafaelki();
      } else {
        logos = _maze.createLogos();
      }
      final hunter = findPlayer(1);
      if (hunter != null) {
        hunter
          ..hp = 100
          ..trapCharges = _trapChargesFor(hunter)
          ..trapCooldownUntil = 0
          ..barrelCooldownUntil = 0
          ..simaFemboyUntil = 0
          ..simaCooldownUntil = 0
          ..invulnerableUntil = 0
          ..stunnedUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0;
      }
      final leha = findPlayer(0);
      if (leha != null) {
        leha
          ..webCharges =
              leha.aspect == LehaAspect.spider ? GameConstants.maxWebCharges : 0
          ..webCooldownUntil = 0
          ..portalCooldownUntil = 0
          ..stunnedUntil = 0
          ..invulnerableUntil = 0
          ..blindUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0;
      }
      logger.log({
        'event': 'start',
        'leha': _playerLog(leha, leha?.aspect.name ?? '—'),
        'hunter': _playerLog(hunter, hunter?.hunterKind.name ?? '—'),
        'logos': logos.length,
      });
    }
  }

  void enforceReadyTimeout(int now) {
    if (round.phase != GamePhase.waiting) return;

    final leha = findPlayer(0);
    final hunter = findPlayer(1);
    if (leha == null || hunter == null) {
      leha?.readyTimeoutStartedAt = null;
      hunter?.readyTimeoutStartedAt = null;
      return;
    }

    for (final player in [leha, hunter]) {
      if (player.ready || player.isBot) {
        player.readyTimeoutStartedAt = null;
        continue;
      }
      final startedAt = player.readyTimeoutStartedAt ?? now;
      player.readyTimeoutStartedAt = startedAt;
      if (now - startedAt >= GameConstants.readyTimeoutMs) {
        releaseSlot(player);
      }
    }
  }

  void releaseSlot(PlayerConnection client) {
    client
      ..slot = null
      ..role = PlayerRole.spectator
      ..ready = false
      ..readyTimeoutStartedAt = null
      ..score = 0
      ..direction = null
      ..nextDirection = null
      ..lastDirection = MoveDirection.right
      ..stopRequested = false
      ..hp = 100
      ..trapCharges = 0
      ..trapCooldownUntil = 0
      ..webCharges = 0
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..webSlowedUntil = 0
      ..webPhaseUntil = 0;
  }

  void tick() {
    ensureRoundState();
    final now = nowMs();
    enforceReadyTimeout(now);
    if (round.phase != GamePhase.playing) return;

    expireTraps(now);
    expireWebs(now);
    rechargeTraps(now);
    rechargeWebs(now);
    updateBots(now);
    for (final client in clients.values) {
      if (client.slot == null) continue;
      updatePlayerState(client, now);
      movePlayer(client, GameConstants.tickMs / 1000);
      if (client.slot == 0) collectLogo(client);
      // Both Leha and the hunter can step through Wizard-Leha's portals.
      if (client.slot == 0 || client.slot == 1) resolvePortal(client, now);
    }

    final leha = findPlayer(0);
    final hunter = findPlayer(1);
    if (leha != null) updateTrail(leha, now);
    if (hunter != null) updateTrail(hunter, now);
    updateBarrels(leha, now, GameConstants.tickMs / 1000);
    resolveCollision(leha, hunter, now);
    resolveTrap(leha, now);
    resolveClutch(hunter, now);
    if (round.phase != GamePhase.playing) return;

    final startedAt = round.startedAt;
    // Spider's Raffaello mode has no survival timer — only a hatched clutch
    // (Spider wins) or being caught (hunter wins) ends the round.
    if (!_isSpiderRound() &&
        startedAt != null &&
        now - startedAt >= GameConstants.roundDurationMs) {
      endGame(0, 'Леха продержался 3 минуты.');
    }
  }

  /// Hatches the Spider's clutch (she wins) or, if the hunter reaches it first,
  /// destroys it and respawns a fresh batch of Raffaellos to try again.
  void resolveClutch(PlayerConnection? hunter, int now) {
    final clutch = round.clutch;
    if (clutch == null) return;
    if (hunter != null) {
      final hc = centerCell(hunter);
      if (hc.x == clutch.x && hc.y == clutch.y) {
        round
          ..clutch = null
          ..rafaelkiEaten = 0;
        logos = _spawnRafaelki();
        logger.log({'event': 'clutch_destroyed'});
        return;
      }
    }
    if (now >= clutch.hatchAt) {
      endGame(0, 'Кладка вылупилась — Леха-паук победил!');
    }
  }

  GameSnapshotDto snapshotFor(PlayerConnection viewer) {
    final now = nowMs();
    final lehaBlinded = viewer.slot == 0 && now < viewer.blindUntil;
    final visiblePlayers = clients.values
        .where((player) => player.slot != null)
        .where((player) {
          if (viewer.slot == null || player == viewer) return true;
          if (!canSeePlayer(viewer, player, now)) return false;
          return !lehaBlinded || _withinBlindRadius(viewer, player.x, player.y);
        })
        .map((player) => serializePlayer(player, now))
        .toList();
    final startedAt = round.startedAt;
    final timeLeftMs = startedAt != null && round.phase == GamePhase.playing
        ? max(0, GameConstants.roundDurationMs - (now - startedAt))
        : GameConstants.roundDurationMs;

    return GameSnapshotDto(
      type: 'state',
      you: YouDto(
          id: viewer.id,
          slot: viewer.slot,
          role: viewer.role,
          name: viewer.name),
      rows: maze.rows,
      cols: maze.cols,
      maze: maze.maze,
      bushes: maze.bushes.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      logos: visibleLogosFor(viewer).where((key) {
        if (!lehaBlinded) return true;
        final parts = key.split(',').map(int.parse).toList();
        return _withinBlindRadius(viewer, parts[0] + 0.5, parts[1] + 0.5);
      }).map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return LogoDto(
          x: parts[0],
          y: parts[1],
          power: findPlayer(0)?.aspect == LehaAspect.superLeha &&
              maze.superLogoKeys.contains(key),
        );
      }).toList(),
      traps: visibleTrapsFor(viewer, now),
      webs: visibleWebsFor(viewer),
      barrels: visibleBarrelsFor(viewer, now),
      portals: visiblePortalsFor(viewer),
      clutch: visibleClutchFor(viewer, now),
      trail: trailForClient(viewer, now),
      players: visiblePlayers,
      scores: clients.values
          .map((player) => ScoreDto(
                id: player.id,
                slot: player.slot,
                role: player.role,
                score: player.score,
              ))
          .toList(),
      connectedPlayers: clients.length,
      lobby: lobbyState(),
      game: GameInfoDto(
        phase: round.phase,
        winnerSlot: round.winnerSlot,
        reason: round.reason,
        timeLeftMs: timeLeftMs,
        lehaPowered: now < round.lehaPowerUntil,
        powerLeftMs: max(0, round.lehaPowerUntil - now),
        trapAvailable: viewer.slot == 1 &&
            round.phase == GamePhase.playing &&
            viewer.trapCharges > 0 &&
            now >= viewer.stunnedUntil &&
            now >= viewer.trapCooldownUntil,
        trapCooldownMs:
            viewer.slot == 1 ? max(0, viewer.trapCooldownUntil - now) : 0,
        trapActive: round.traps.isNotEmpty,
        trapCharges: viewer.slot == 1 ? viewer.trapCharges : 0,
        abilityAvailable: abilityAvailableFor(viewer, now),
        abilityCooldownMs: abilityCooldownFor(viewer, now),
        abilityCharges: abilityChargesFor(viewer),
        barrelAvailable: viewer.slot == 1 &&
            viewer.hunterKind == HunterKind.sashaYakuza &&
            round.phase == GamePhase.playing &&
            now >= viewer.stunnedUntil &&
            now >= viewer.barrelCooldownUntil,
        barrelCooldownMs:
            viewer.slot == 1 && viewer.hunterKind == HunterKind.sashaYakuza
                ? max(0, viewer.barrelCooldownUntil - now)
                : 0,
        femboyAvailable: viewer.slot == 1 &&
            viewer.hunterKind == HunterKind.sima &&
            round.phase == GamePhase.playing &&
            now >= viewer.stunnedUntil &&
            now >= viewer.simaCooldownUntil,
        femboyCooldownMs:
            viewer.slot == 1 && viewer.hunterKind == HunterKind.sima
                ? max(0, viewer.simaCooldownUntil - now)
                : 0,
        spiderMode: _isSpiderRound(),
        rafaelkiEaten: round.rafaelkiEaten,
        rafaelkiNeeded: GameConstants.rafaelkiNeeded,
        clutchAvailable: viewer.slot == 0 &&
            _isSpiderRound() &&
            round.phase == GamePhase.playing &&
            round.clutch == null &&
            round.rafaelkiEaten >= GameConstants.rafaelkiNeeded,
        clutchActive: round.clutch != null,
        clutchHatchMs:
            round.clutch == null ? 0 : max(0, round.clutch!.hatchAt - now),
      ),
      status: statusFor(viewer),
      leaderboard: stats
          .leaderboard()
          .map(
              (e) => UserStatsDto(name: e.name, wins: e.wins, losses: e.losses))
          .toList(),
      yourStats: _yourStats(viewer),
    );
  }

  UserStatsDto? _yourStats(PlayerConnection viewer) {
    final name = viewer.name.trim();
    if (name.isEmpty) return null;
    final s = stats.statsFor(name);
    return UserStatsDto(name: name, wins: s?.wins ?? 0, losses: s?.losses ?? 0);
  }

  void movePlayer(PlayerConnection player, double dt) {
    final now = nowMs();
    if (now < player.stunnedUntil) {
      player.direction = null;
      player.nextDirection = null;
      player.stopRequested = false;
      return;
    }

    if (player.webPhaseUntil != 0 && now >= player.webPhaseUntil) {
      endWebPhase(player);
    }

    // Sima's femboy charm: a non-powered Leha with line of sight is dragged
    // straight toward Sima at half speed, overriding his input.
    if (player.slot == 0 && now >= round.lehaPowerUntil) {
      final sima = _activeSima(now);
      if (sima != null &&
          maze.hasLineOfSight(playerPos(player), playerPos(sima))) {
        _charmMove(player, sima, dt, now);
        _wrapTunnel(player);
        resolveWebContact(player, now);
        consumePassedWallWeb(player);
        return;
      }
    }

    final distance = player.speed * dt;
    final requested = player.nextDirection;
    if (requested == null) {
      player.direction = null;
      return;
    }

    player
      ..direction = requested
      ..lastDirection = requested;
    if (!_moveWithCornering(player, requested, distance, now)) {
      player.direction = null;
    }

    _wrapTunnel(player);
    resolveWebContact(player, now);
    consumePassedWallWeb(player);
  }

  /// Moves [player] by [dist] in [dir]. If a cardinal move is blocked only
  /// because the player is off the lane centre (the classic "can't turn into
  /// the corridor" problem), it nudges the perpendicular axis toward the centre
  /// of the target cell and retries — giving forgiving Pac-Man-style cornering.
  bool _moveWithCornering(
      PlayerConnection player, MoveDirection dir, double dist, int now) {
    if (tryMove(player, dir.dx * dist, dir.dy * dist, now)) return true;
    if (dir.isDiagonal) return false;
    if (!canMoveFrom(player, dir)) return false; // genuinely walled ahead

    final cell = centerCell(player);
    // Allow a slightly faster snap than travel speed so turns feel responsive.
    final snap = dist * 1.5;
    if (dir.dx != 0) {
      final centerY = cell.y + 0.5;
      final ny = _approach(player.y, centerY, snap);
      if (isPositionOpen(player, player.x, ny, now)) player.y = ny;
    } else {
      final centerX = cell.x + 0.5;
      final nx = _approach(player.x, centerX, snap);
      if (isPositionOpen(player, nx, player.y, now)) player.x = nx;
    }
    return tryMove(player, dir.dx * dist, dir.dy * dist, now);
  }

  /// The hunter if it is Sima and currently in femboy form, else null.
  PlayerConnection? _activeSima(int now) {
    final hunter = findPlayer(1);
    if (hunter != null &&
        hunter.hunterKind == HunterKind.sima &&
        now < hunter.simaFemboyUntil) {
      return hunter;
    }
    return null;
  }

  /// Drags [leha] in a straight line toward [sima] at half base speed.
  void _charmMove(
      PlayerConnection leha, PlayerConnection sima, double dt, int now) {
    leha.direction = null;
    final dx = sima.x - leha.x;
    final dy = sima.y - leha.y;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1e-4) return;
    final dist = GameConstants.baseSpeed * GameConstants.simaSlowFactor * dt;
    tryMove(leha, dx / len * dist, dy / len * dist, now);
  }

  double _approach(double value, double target, double maxStep) {
    final delta = target - value;
    if (delta.abs() <= maxStep) return target;
    return value + (delta > 0 ? maxStep : -maxStep);
  }

  void updatePlayerState(PlayerConnection player, int now) {
    player.speed = speedFor(player, now);
  }

  double speedFor(PlayerConnection player, int now) {
    var base = speedForSlot(player.slot, now);
    if (player.slot == 1 && now < player.stunnedUntil) return 0;
    final leha = findPlayer(0);
    if (player.slot == 1 && leha != null && now < leha.stunnedUntil) {
      base *= 1.1;
    }
    if (player.slot == 1 && now < player.webSlowedUntil) return base * 0.5;
    return base;
  }

  double speedForSlot(int? slot, int now) {
    // Hunters move at Leha's base speed; Super-Leha (powered) is 10% faster than a hunter.
    if (slot == 0) {
      return now < round.lehaPowerUntil
          ? GameConstants.baseSpeed * 1.1
          : GameConstants.baseSpeed;
    }
    if (slot == 1) return GameConstants.baseSpeed;
    return GameConstants.baseSpeed;
  }

  void collectLogo(PlayerConnection player) {
    final cell = centerCell(player);
    final key = '${cell.x},${cell.y}';
    if (!logos.remove(key)) return;
    // Spider eats Raffaellos toward a clutch — no score, power or timer change.
    if (_isSpiderRound()) {
      round.rafaelkiEaten += 1;
      return;
    }
    player.score += 10;
    final startedAt = round.startedAt;
    if (round.phase == GamePhase.playing && startedAt != null) {
      round.startedAt = startedAt - GameConstants.logoTimerReductionMs;
    }
    if (player.aspect == LehaAspect.superLeha &&
        maze.superLogoKeys.contains(key)) {
      round.lehaPowerUntil = nowMs() + GameConstants.powerDurationMs;
    }
  }

  bool _isSpiderRound() => findPlayer(0)?.aspect == LehaAspect.spider;

  /// Picks [GameConstants.rafaelkiCount] random open cells for Raffaellos.
  Set<String> _spawnRafaelki() {
    final spawns = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    final open = <String>[];
    for (var y = 0; y < maze.rows; y += 1) {
      for (var x = 0; x < maze.cols; x += 1) {
        final key = '$x,$y';
        if (maze.isWall(x, y) || spawns.contains(key)) continue;
        open.add(key);
      }
    }
    open.shuffle(_rng);
    return open.take(GameConstants.rafaelkiCount).toSet();
  }

  /// Spider lays an egg clutch once she's eaten enough Raffaellos. Allowed on
  /// floor and in bushes, but not on walls or webs. One clutch at a time.
  void layClutch(PlayerConnection client) {
    if (round.phase != GamePhase.playing) return;
    if (client.slot != 0 || client.aspect != LehaAspect.spider) return;
    if (round.clutch != null) return;
    if (round.rafaelkiEaten < GameConstants.rafaelkiNeeded) return;
    final cell = centerCell(client);
    if (maze.isWall(cell.x, cell.y)) return;
    if (round.webs.any((w) => w.x == cell.x && w.y == cell.y)) return;
    round
      ..clutch = ClutchState(
        x: cell.x,
        y: cell.y,
        hatchAt: nowMs() + GameConstants.clutchHatchMs,
      )
      ..rafaelkiEaten = 0;
    // Remaining Raffaellos no longer matter while the clutch is incubating.
    logos = {};
    logger.log({'event': 'clutch_laid', 'x': cell.x, 'y': cell.y});
  }

  void updateTrail(PlayerConnection player, int now) {
    final slot = player.slot;
    if (slot == null) return;
    // No scent is left while hiding in a bush.
    if (maze.isBush(player.x.floor(), player.y.floor())) return;
    final trail = round.trails[slot] ?? <TrailPoint>[];
    final last = trail.isEmpty ? null : trail.last;
    // Add a new point only when player moved far enough — keeps point count manageable.
    if (last != null &&
        sqrt(pow(last.x - player.x, 2) + pow(last.y - player.y, 2)) < 0.35) {
      return;
    }
    trail.add(TrailPoint(x: _round3(player.x), y: _round3(player.y), at: now));
    round.trails[slot] = trail
        .where((point) => now - point.at <= GameConstants.trailLifetimeMs)
        .toList();
  }

  void resolveCollision(
      PlayerConnection? leha, PlayerConnection? hunter, int now) {
    if (leha == null || hunter == null) return;
    final distance =
        sqrt(pow(leha.x - hunter.x, 2) + pow(leha.y - hunter.y, 2));
    if (distance > 0.62) return;
    if (now < round.lehaPowerUntil && now >= hunter.invulnerableUntil) {
      hitHunter(hunter, now);
    } else if (now < hunter.invulnerableUntil) {
      // Hunter is stunned/invulnerable — ignore the collision entirely.
    } else {
      endGame(1, 'Охотник поймал Леху.');
    }
  }

  void expireWebs(int now) {
    // Floor webs persist until the hunter steps on them; wall webs are a
    // temporary shortcut that expires by timer. If the Spider is still inside
    // an expiring wall web she's ejected to open ground — no camping in walls.
    final spider = findPlayer(0);
    round.webs.removeWhere((web) {
      if (!maze.isWall(web.x, web.y)) return false;
      if (now - web.createdAt < GameConstants.wallWebLifetimeMs) return false;
      if (spider != null &&
          spider.aspect == LehaAspect.spider &&
          _circleOverlapsCell(spider.x, spider.y, web.x, web.y)) {
        _ejectFromWall(spider);
      }
      return true;
    });
  }

  /// Snaps the Spider to the nearest open cell centre (used when she'd otherwise
  /// be left overlapping a wall tile, e.g. an expiring wall web).
  void _ejectFromWall(PlayerConnection spider) {
    final target = nearestOpenCell(centerCell(spider));
    spider
      ..x = target.x + 0.5
      ..y = target.y + 0.5
      ..direction = null
      ..nextDirection = null
      ..wallWebCellKey = null;
  }

  void expireTraps(int now) {
    final expired = round.traps.where((trap) => now >= trap.expiresAt).length;
    if (expired == 0) return;
    round.traps.removeWhere((trap) => now >= trap.expiresAt);
    for (var i = 0; i < expired; i += 1) {
      scheduleTrapRecharge(now);
    }
  }

  void resolveTrap(PlayerConnection? leha, int now) {
    if (leha == null) return;
    final cell = centerCell(leha);
    final trapIndex = round.traps.indexWhere(
      (trap) =>
          trap.triggeredAt == null &&
          now < trap.expiresAt &&
          cell.x == trap.x &&
          cell.y == trap.y,
    );
    if (trapIndex != -1) {
      leha
        ..stunnedUntil = now + GameConstants.trapStunMs
        ..webPhaseUntil = 0
        ..direction = null
        ..nextDirection = null
        ..stopRequested = false;
      // Mark as triggered and keep briefly so Hunter sees the notification.
      round.traps[trapIndex]
        ..triggeredAt = now
        ..expiresAt = now + GameConstants.trapTriggeredDisplayMs;
      scheduleTrapRecharge(now);
    }
  }

  void scheduleTrapRecharge(int now) {
    round.pendingTrapRechargeAt.add(now + GameConstants.trapCooldownMs);
    final hunter = findPlayer(1);
    if (hunter != null) {
      hunter.trapCooldownUntil = round.pendingTrapRechargeAt.reduce(min);
    }
  }

  void rechargeTraps(int now) {
    final ready =
        round.pendingTrapRechargeAt.where((time) => now >= time).length;
    if (ready == 0) return;
    round.pendingTrapRechargeAt.removeWhere((time) => now >= time);
    final hunter = findPlayer(1);
    if (hunter != null) {
      hunter.trapCharges =
          min(GameConstants.maxTrapCharges, hunter.trapCharges + ready);
      hunter.trapCooldownUntil = round.pendingTrapRechargeAt.isEmpty
          ? 0
          : round.pendingTrapRechargeAt.reduce(min);
    }
  }

  void scheduleWebRecharge(PlayerConnection spider, int now) {
    round.pendingWebRechargeAt.add(now + GameConstants.webCooldownMs);
    spider.webCooldownUntil = round.pendingWebRechargeAt.reduce(min);
  }

  void rechargeWebs(int now) {
    final ready =
        round.pendingWebRechargeAt.where((time) => now >= time).length;
    if (ready == 0) return;
    round.pendingWebRechargeAt.removeWhere((time) => now >= time);
    final spider = findPlayer(0);
    if (spider != null && spider.aspect == LehaAspect.spider) {
      spider.webCharges =
          min(GameConstants.maxWebCharges, spider.webCharges + ready);
      spider.webCooldownUntil = round.pendingWebRechargeAt.isEmpty
          ? 0
          : round.pendingWebRechargeAt.reduce(min);
    }
  }

  void hitHunter(PlayerConnection hunter, int now) {
    hunter
      ..hp = max(0, hunter.hp - 50)
      ..stunnedUntil = now + GameConstants.hunterStunMs
      ..invulnerableUntil = now + GameConstants.hunterStunMs
      ..webPhaseUntil = 0
      ..direction = null
      ..nextDirection = null
      ..stopRequested = false;
    round.lehaPowerUntil = 0;
    if (hunter.hp <= 0) {
      endGame(0, 'Супер-Леха съел Охотника второй раз.');
    }
  }

  bool isGhost(PlayerConnection player, [int? at]) => false;

  PlayerConnection? findPlayer(int slot) {
    for (final client in clients.values) {
      if (client.slot == slot) return client;
    }
    return null;
  }

  void endGame(int winnerSlot, String reason) {
    round
      ..phase = GamePhase.ended
      ..endedAt = nowMs()
      ..winnerSlot = winnerSlot
      ..reason = reason;
    final winner = findPlayer(winnerSlot);
    final loser = findPlayer(winnerSlot == 0 ? 1 : 0);
    stats.recordResult(winner: winner?.name.trim(), loser: loser?.name.trim());
    final startedAt = round.startedAt;
    logger.log({
      'event': 'end',
      'winner': winnerSlot == 0 ? 'leha' : 'hunter',
      'reason': reason,
      'durationMs':
          startedAt == null ? null : (round.endedAt ?? nowMs()) - startedAt,
      'leha': _playerLog(findPlayer(0), findPlayer(0)?.aspect.name ?? '—'),
      'hunter':
          _playerLog(findPlayer(1), findPlayer(1)?.hunterKind.name ?? '—'),
      'lehaScore': findPlayer(0)?.score ?? 0,
    });
  }

  Point<int> centerCell(PlayerConnection player) =>
      Point(player.x.floor(), player.y.floor());

  bool canMoveFrom(PlayerConnection player, MoveDirection direction) {
    final cell = centerCell(player);
    final nextX = (cell.x + direction.dx).round();
    final nextY = (cell.y + direction.dy).round();
    if (player.slot == 0 &&
        player.aspect == LehaAspect.spider &&
        maze.isWall(nextX, nextY)) {
      return consumeWebBridge(cell, Point(nextX, nextY), preview: true);
    }
    return !maze.isWall(nextX, nextY);
  }

  bool tryMove(PlayerConnection player, double dx, double dy, int now) {
    if (dx == 0 && dy == 0) return true;
    final targetX = player.x + dx;
    final targetY = player.y + dy;
    if (isPositionOpen(player, targetX, targetY, now)) {
      player
        ..x = targetX
        ..y = targetY;
      return true;
    }

    if (dx != 0 && isPositionOpen(player, targetX, player.y, now)) {
      player.x = targetX;
      return true;
    }
    if (dy != 0 && isPositionOpen(player, player.x, targetY, now)) {
      player.y = targetY;
      return true;
    }

    return false;
  }

  /// Circle-vs-AABB collision: tests every wall tile whose bounding box
  /// [cx, cx+1] × [cy, cy+1] could overlap the player circle. Clamping the
  /// circle centre to the tile gives the closest point; if its distance to
  /// the centre is less than the radius, the position is blocked. This works
  /// correctly in open multi-cell spaces (no rails) and in 1-cell corridors.
  bool isPositionOpen(PlayerConnection player, double x, double y, int now) {
    if (GameConstants.tunnelRows.contains(y.floor()) &&
        (x < 0 || x >= maze.cols)) {
      return true;
    }

    final r = GameConstants.collisionRadius;
    final minCx = (x - r).floor();
    final maxCx = (x + r).ceil();
    final minCy = (y - r).floor();
    final maxCy = (y + r).ceil();

    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        if (!maze.isWall(cx, cy)) continue;
        // Spider Leha: web-covered wall cells are passable.
        if (player.slot == 0 &&
            player.aspect == LehaAspect.spider &&
            round.webs.any((w) => w.x == cx && w.y == cy)) {
          continue;
        }
        final closestX = x.clamp(cx.toDouble(), cx + 1.0);
        final closestY = y.clamp(cy.toDouble(), cy + 1.0);
        final ddx = x - closestX;
        final ddy = y - closestY;
        if (ddx * ddx + ddy * ddy < r * r) return false;
      }
    }
    return true;
  }

  LobbyDto lobbyState() {
    return LobbyDto(
      roles: [
        for (var slot = 0; slot < GameConstants.roles.length; slot += 1)
          _roleState(slot),
      ],
      spectators: clients.values.where((client) => client.slot == null).length,
    );
  }

  RoleStateDto _roleState(int slot) {
    final player =
        clients.values.where((client) => client.slot == slot).firstOrNull;
    final readyTimeoutMs = _readyTimeoutMs(player);
    return RoleStateDto(
      role: GameConstants.roles[slot],
      slot: slot,
      taken: player != null,
      ready: player?.ready ?? false,
      playerId: player?.id,
      aspect: slot == 0 ? player?.aspect ?? LehaAspect.superLeha : null,
      hunterKind: slot == 1 ? player?.hunterKind ?? HunterKind.bakhirkin : null,
      bot: player?.isBot ?? false,
      readyTimeoutMs: readyTimeoutMs,
    );
  }

  int? _readyTimeoutMs(PlayerConnection? player) {
    final startedAt = player?.readyTimeoutStartedAt;
    if (player == null || player.ready || player.isBot || startedAt == null) {
      return null;
    }
    return max(0, GameConstants.readyTimeoutMs - (nowMs() - startedAt));
  }

  Iterable<String> visibleLogosFor(PlayerConnection viewer) {
    // Spider's Raffaellos are seen only with normal sight (no map-wide reveal),
    // by both Leha and the hunter.
    if (_isSpiderRound()) {
      if (viewer.slot == null) return logos;
      final vp = playerPos(viewer);
      return logos.where((key) {
        final p = key.split(',');
        final tp = Point(int.parse(p[0]) + 0.5, int.parse(p[1]) + 0.5);
        return maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp);
      });
    }
    if (viewer.slot == null || viewer.slot == 0) return logos;
    // Hunter sees super-logo positions only when Leha is actually Super Leha.
    final leha = findPlayer(0);
    if (leha?.aspect == LehaAspect.superLeha) {
      return logos.where(maze.superLogoKeys.contains);
    }
    return const [];
  }

  /// The clutch as seen by [viewer]: Leha and spectators always see their own;
  /// the hunter must find it with normal sight (it can hide in a bush).
  ClutchDto? visibleClutchFor(PlayerConnection viewer, int now) {
    final c = round.clutch;
    if (c == null) return null;
    final dto = ClutchDto(x: c.x, y: c.y, hatchMs: max(0, c.hatchAt - now));
    if (viewer.slot == 0 || viewer.slot == null) return dto;
    final vp = playerPos(viewer);
    if (maze.isBush(c.x, c.y) &&
        !maze.isBush(viewer.x.floor(), viewer.y.floor())) {
      return null;
    }
    final tp = Point(c.x + 0.5, c.y + 0.5);
    if (maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp)) return dto;
    return null;
  }

  List<TrapDto> visibleTrapsFor(PlayerConnection viewer, int now) {
    final activeTraps = round.traps.where((trap) => now < trap.expiresAt);
    if (viewer.slot == null) return activeTraps.map(_trapDto).toList();
    if (viewer.slot == 1 && viewer.hunterKind == HunterKind.bakhirkin) {
      return activeTraps.map(_trapDto).toList();
    }
    final vp = playerPos(viewer);
    return activeTraps
        .where((trap) {
          // Hunter always sees triggered traps (catch notification).
          if (viewer.slot == 1 && trap.triggeredAt != null) return true;
          final tp = Point(trap.x + 0.5, trap.y + 0.5);
          return maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp);
        })
        .map(_trapDto)
        .toList();
  }

  List<WebDto> visibleWebsFor(PlayerConnection viewer) {
    if (viewer.slot == null || viewer.slot == 0) {
      return round.webs.map((web) => WebDto(x: web.x, y: web.y)).toList();
    }
    final vp = playerPos(viewer);
    return round.webs
        .where((web) {
          final tp = Point(web.x + 0.5, web.y + 0.5);
          return maze.hasLineOfSight(vp, tp) || maze.hasXrayVisibility(vp, tp);
        })
        .map((web) => WebDto(x: web.x, y: web.y))
        .toList();
  }

  List<BarrelDto> visibleBarrelsFor(PlayerConnection viewer, int now) {
    final lehaBlinded = viewer.slot == 0 && now < viewer.blindUntil;
    BarrelDto toDto(BarrelState b) => BarrelDto(
          x: _round3(b.x),
          y: _round3(b.y),
          dirX: _round3(b.dirX),
          dirY: _round3(b.dirY),
        );
    if (viewer.slot == null) return round.barrels.map(toDto).toList();
    final vp = playerPos(viewer);
    return round.barrels
        .where((b) {
          // The thrower always sees their own barrels.
          if (b.ownerId == viewer.id) return true;
          final tp = Point(b.x, b.y);
          if (!(maze.hasLineOfSight(vp, tp) ||
              maze.hasXrayVisibility(vp, tp))) {
            return false;
          }
          return !lehaBlinded || _withinBlindRadius(viewer, b.x, b.y);
        })
        .map(toDto)
        .toList();
  }

  bool _withinBlindRadius(PlayerConnection viewer, double x, double y) {
    final dx = viewer.x - x;
    final dy = viewer.y - y;
    return dx * dx + dy * dy <=
        GameConstants.lehaBlindRadius * GameConstants.lehaBlindRadius;
  }

  List<PortalDto> visiblePortalsFor(PlayerConnection viewer) {
    // Spectators (slot == null) see nothing; Leha and the hunter both always
    // see Wizard-Leha's portals (the hunter needs to anticipate teleports).
    if (viewer.slot == null) return const [];
    return [
      for (var i = 0; i < round.portals.length; i += 1)
        PortalDto(
          x: round.portals[i].x,
          y: round.portals[i].y,
          index: i,
          active: round.portals.length == 2,
        ),
    ];
  }

  bool abilityAvailableFor(PlayerConnection viewer, int now) {
    if (viewer.slot != 0 || round.phase != GamePhase.playing) return false;
    return switch (viewer.aspect) {
      LehaAspect.superLeha => false,
      LehaAspect.spider => viewer.webCharges > 0,
      // Placing portals is always free; the cooldown is on teleporting, not placing.
      LehaAspect.wizard => true,
    };
  }

  int abilityCooldownFor(PlayerConnection viewer, int now) {
    if (viewer.slot != 0) return 0;
    return switch (viewer.aspect) {
      LehaAspect.superLeha => 0,
      LehaAspect.spider => viewer.webCharges >= GameConstants.maxWebCharges
          ? 0
          : max(0, viewer.webCooldownUntil - now),
      LehaAspect.wizard => 0,
    };
  }

  int abilityChargesFor(PlayerConnection viewer) {
    if (viewer.slot != 0) return 0;
    return switch (viewer.aspect) {
      LehaAspect.superLeha => 0,
      LehaAspect.spider => viewer.webCharges,
      LehaAspect.wizard => 2 - round.portals.length.clamp(0, 2),
    };
  }

  PlayerDto serializePlayer(PlayerConnection player, int now) {
    final aspect = player.slot == 0 ? player.aspect : null;
    final showFacing =
        aspect == LehaAspect.spider || aspect == LehaAspect.wizard;
    return PlayerDto(
      id: player.id,
      slot: player.slot,
      role: player.role,
      x: _round3(player.x),
      y: _round3(player.y),
      score: player.score,
      powered: player.slot == 0 && now < round.lehaPowerUntil,
      ghost: isGhost(player, now),
      stunned: now < player.stunnedUntil,
      invulnerable: now < player.invulnerableUntil,
      hp: player.hp,
      aspect: aspect,
      hunterKind: player.slot == 1 ? player.hunterKind : null,
      blinded: player.slot == 0 && now < player.blindUntil,
      femboy: player.slot == 1 &&
          player.hunterKind == HunterKind.sima &&
          now < player.simaFemboyUntil,
      facing: showFacing ? player.lastDirection : null,
    );
  }

  String statusFor(PlayerConnection viewer) {
    if (round.phase == GamePhase.waiting) {
      return 'Выберите персонажей и нажмите готовность.';
    }
    if (round.phase == GamePhase.ended) {
      final side = round.winnerSlot == 0 ? 'Леха выиграл' : 'Охотник выиграл';
      final personal = viewer.slot == null
          ? 'Вы наблюдатель.'
          : round.winnerSlot == viewer.slot
              ? 'Ты выиграл.'
              : 'Ты проиграл.';
      return '$side. ${round.reason} $personal Нажми Рестарт для новой игры.';
    }
    return '';
  }

  List<TrailPointDto> trailForClient(PlayerConnection viewer, int now) {
    if (viewer.slot == null) return const [];
    final sourceSlot = viewer.slot == 1 ? 0 : 1;
    if (viewer.slot == 0 && now >= round.lehaPowerUntil) return const [];
    return trailPointsForSlot(sourceSlot, now)
        .where((point) => canViewerSeeTrailPoint(viewer, point))
        .toList();
  }

  List<TrailPointDto> trailPointsForSlot(int slot, int now) {
    return (round.trails[slot] ?? const <TrailPoint>[])
        .map((point) {
          final age = now - point.at;
          if (age > GameConstants.trailLifetimeMs) return null;
          // Linear fade: 1.0 when fresh, 0.0 when expired.
          final alpha = 1.0 - age / GameConstants.trailLifetimeMs;
          return TrailPointDto(x: point.x, y: point.y, alpha: alpha);
        })
        .whereType<TrailPointDto>()
        .toList();
  }

  bool canViewerSeeTrailPoint(PlayerConnection viewer, TrailPointDto point) {
    final vp = playerPos(viewer);
    final tp = Point(point.x, point.y);
    final distance = sqrt(pow(vp.x - tp.x, 2) + pow(vp.y - tp.y, 2));
    // Hunter smells Leha's trail within scentRadius — no line-of-sight needed.
    if (viewer.slot == 1) return distance <= GameConstants.trailScentRadius;
    // Leha (powered) sees trail within visibility radius or with direct LOS.
    if (distance <= GameConstants.trailVisibilityRadius) return true;
    return maze.hasLineOfSight(vp, tp);
  }

  bool canSeePlayer(PlayerConnection viewer, PlayerConnection target, int now) {
    if (viewer == target) return true;
    if (isGhost(viewer, now) || isGhost(target, now)) return true;
    final vp = playerPos(viewer);
    final tp = playerPos(target);
    // A target hiding in a bush can't be x-rayed; direct line of sight only
    // works when the viewer is in a bush too (otherwise the bush conceals).
    if (maze.isBush(target.x.floor(), target.y.floor())) {
      if (!maze.isBush(viewer.x.floor(), viewer.y.floor())) return false;
      return maze.hasLineOfSight(vp, tp);
    }
    return maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp);
  }

  Point<double> playerPos(PlayerConnection p) => Point(p.x, p.y);

  void resolvePortal(PlayerConnection player, int now) {
    final cell = centerCell(player);
    final cellKey = '${cell.x},${cell.y}';
    final freshlyEntered = cellKey != player.lastCellKey;
    player.lastCellKey = cellKey;

    // Teleport only with both portals open, on a fresh step onto a portal, and
    // when this player isn't on their post-teleport cooldown.
    if (round.portals.length != 2 || !freshlyEntered) return;
    if (now < player.portalTeleportUntil) return;
    final portalIndex = round.portals
        .indexWhere((portal) => portal.x == cell.x && portal.y == cell.y);
    if (portalIndex == -1) return;
    final target = round.portals[portalIndex == 0 ? 1 : 0];
    player
      ..x = target.x + 0.5
      ..y = target.y + 0.5
      ..direction = null
      ..nextDirection = null
      ..lastCellKey = '${target.x},${target.y}'
      ..portalTeleportUntil = now + GameConstants.portalTeleportCooldownMs;
    // Portals are consumed on use.
    round.portals = [];
  }

  void resolveWebContact(PlayerConnection player, int now) {
    if (player.slot != 1) return;
    final cell = centerCell(player);
    // Only floor webs (non-wall cells) slow Hunter; wall webs are for Spider traversal.
    final index = round.webs.indexWhere(
      (web) => web.x == cell.x && web.y == cell.y && !maze.isWall(web.x, web.y),
    );
    if (index == -1) return;
    round.webs.removeAt(index);
    player.webSlowedUntil = now + GameConstants.webSlowMs;
  }

  void consumeWebForStep(PlayerConnection player) {
    if (player.slot != 0 || player.aspect != LehaAspect.spider) return;
    final direction = player.direction;
    if (direction == null) return;
    final cell = centerCell(player);
    final next =
        Point((cell.x + direction.dx).round(), (cell.y + direction.dy).round());
    if (!maze.isWall(next.x, next.y)) return;
    consumeWebBridge(cell, next, preview: false);
  }

  bool consumeWebBridge(Point<int> from, Point<int> to,
      {required bool preview}) {
    // Spider can traverse only wall cells covered by a wall web.
    return round.webs.any(
      (web) =>
          (maze.isWall(from.x, from.y) && web.x == from.x && web.y == from.y) ||
          (maze.isWall(to.x, to.y) && web.x == to.x && web.y == to.y),
    );
  }

  /// Tracks the wall cell the Spider is passing through and only consumes its
  /// web once she has *fully* cleared the cell. Removing it the instant her
  /// centre crosses out — while her body still overlaps the tile — would turn
  /// the tile solid beneath her and strand her (the classic "stuck in wall").
  void consumePassedWallWeb(PlayerConnection player) {
    if (player.slot != 0 || player.aspect != LehaAspect.spider) return;
    final cell = centerCell(player);
    if (maze.isWall(cell.x, cell.y)) {
      // Still inside a wall cell — remember it so we can consume it on exit.
      player.wallWebCellKey = '${cell.x},${cell.y}';
      return;
    }
    final key = player.wallWebCellKey;
    if (key == null) return;
    final parts = key.split(',');
    final wx = int.parse(parts[0]);
    final wy = int.parse(parts[1]);
    // Wait until her collision circle no longer touches the wall cell.
    if (_circleOverlapsCell(player.x, player.y, wx, wy)) return;
    final index = round.webs.indexWhere((web) => web.x == wx && web.y == wy);
    if (index != -1) round.webs.removeAt(index);
    player.wallWebCellKey = null;
  }

  bool _circleOverlapsCell(double x, double y, int cx, int cy) {
    final r = GameConstants.collisionRadius;
    final closestX = x.clamp(cx.toDouble(), cx + 1.0);
    final closestY = y.clamp(cy.toDouble(), cy + 1.0);
    final ddx = x - closestX;
    final ddy = y - closestY;
    return ddx * ddx + ddy * ddy < r * r;
  }

  void endWebPhase(PlayerConnection player) {
    player.webPhaseUntil = 0;
    if (!maze.isWall(player.x.floor(), player.y.floor())) return;
    final target = nearestOpenCell(centerCell(player));
    player
      ..x = target.x + 0.5
      ..y = target.y + 0.5
      ..direction = null
      ..nextDirection = null;
  }

  Point<int> nearestOpenCell(Point<int> origin) {
    final visited = <String>{};
    var frontier = <Point<int>>[origin];
    while (frontier.isNotEmpty) {
      final next = <Point<int>>[];
      for (final cell in frontier) {
        if (cell.x < 0 ||
            cell.x >= maze.cols ||
            cell.y < 0 ||
            cell.y >= maze.rows) {
          continue;
        }
        final key = '${cell.x},${cell.y}';
        if (!visited.add(key)) continue;
        if (!maze.isWall(cell.x, cell.y)) return cell;
        next
          ..add(Point(cell.x + 1, cell.y))
          ..add(Point(cell.x - 1, cell.y))
          ..add(Point(cell.x, cell.y + 1))
          ..add(Point(cell.x, cell.y - 1));
      }
      frontier = next;
    }
    final fallback = GameConstants.starts.first;
    return Point(fallback.x, fallback.y);
  }

  void _wrapTunnel(PlayerConnection player) {
    if (!GameConstants.tunnelRows.contains(player.y.floor())) return;
    if (player.x < -0.35) player.x = maze.cols + 0.35;
    if (player.x > maze.cols + 0.35) player.x = -0.35;
  }

  TrapDto _trapDto(TrapState trap) => TrapDto(
        x: trap.x,
        y: trap.y,
        placedAt: trap.placedAt,
        expiresAt: trap.expiresAt,
        triggered: trap.triggeredAt != null,
      );

  double _round3(double value) => (value * 1000).roundToDouble() / 1000;

  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
