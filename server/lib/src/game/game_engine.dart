import 'dart:io';
import 'dart:math';

import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_constants.dart';
import '../domain/game_models.dart';
import 'maze_service.dart';

class GameEngine {
  GameEngine({required MazeService maze}) : _maze = maze {
    logos = maze.createLogos();
  }

  MazeService _maze;
  MazeService get maze => _maze;
  final Map<String, PlayerConnection> clients = {};
  var round = GameRound();
  var logos = <String>{};
  int _nextId = 1;

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
        if (client.slot == null || round.phase != GamePhase.playing || direction == null) return;
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
        ensureRoundState();
      case ClientMessageType.spectate:
        becomeSpectator(client);
      case ClientMessageType.placeTrap:
        placeTrap(client);
      case ClientMessageType.useAbility:
        useAbility(client);
      case ClientMessageType.selectAspect:
        final aspect = message.aspect;
        if (aspect != null) selectAspect(client, aspect);
      case ClientMessageType.restart:
        reset();
    }
  }

  void reset() {
    _maze = MazeService.generate();
    logos = _maze.createLogos();
    round = GameRound();
    for (final client in clients.values) {
      final start = GameConstants.starts[client.slot ?? 0];
      client
        ..score = 0
        ..ready = false
        ..x = start.x + 0.5
        ..y = start.y + 0.5
        ..direction = null
        ..nextDirection = null
        ..lastDirection = MoveDirection.right
        ..stopRequested = false
        ..hp = client.slot == 1 ? 100 : client.hp
        ..trapCharges = client.slot == 1 ? GameConstants.maxTrapCharges : 0
        ..trapCooldownUntil = 0
        ..webCharges = client.slot == 0 ? GameConstants.maxWebCharges : 0
        ..portalCooldownUntil = 0
        ..stunnedUntil = 0
        ..invulnerableUntil = 0
        ..webSlowedUntil = 0
        ..webPhaseUntil = 0
        ..speed = speedFor(client, nowMs());
    }
    ensureRoundState();
  }

  void selectRole(PlayerConnection client, PlayerRole role) {
    if (round.phase != GamePhase.waiting || role == PlayerRole.spectator) return;
    final slot = GameConstants.roles.indexOf(role);
    if (slot == -1) return;
    final occupied = clients.values.any((other) => other != client && other.slot == slot);
    if (occupied) return;

    final start = GameConstants.starts[slot];
    client
      ..slot = slot
      ..role = role
      ..ready = false
      ..score = 0
      ..x = start.x + 0.5
      ..y = start.y + 0.5
      ..direction = null
      ..nextDirection = null
      ..lastDirection = MoveDirection.right
      ..stopRequested = false
      ..hp = slot == 1 ? 100 : client.hp
      ..trapCharges = slot == 1 ? GameConstants.maxTrapCharges : 0
      ..trapCooldownUntil = 0
      ..webCharges = slot == 0 ? GameConstants.maxWebCharges : 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..invulnerableUntil = 0
      ..webSlowedUntil = 0
      ..webPhaseUntil = 0
      ..speed = speedFor(client, nowMs());
    ensureRoundState();
  }

  void selectAspect(PlayerConnection client, LehaAspect aspect) {
    if (round.phase != GamePhase.waiting || client.slot != 0) return;
    client
      ..aspect = aspect
      ..webCharges = aspect == LehaAspect.spider ? GameConstants.maxWebCharges : 0
      ..portalCooldownUntil = 0;
    ensureRoundState();
  }

  void becomeSpectator(PlayerConnection client) {
    if (round.phase != GamePhase.waiting) return;
    client
      ..slot = null
      ..role = PlayerRole.spectator
      ..ready = false
      ..score = 0
      ..direction = null
      ..nextDirection = null
      ..lastDirection = MoveDirection.right
      ..stopRequested = false
      ..hp = 100
      ..trapCharges = 0
      ..trapCooldownUntil = 0
      ..webCharges = 0
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
    if (maze.isWall(cell.x, cell.y)) return;
    client.trapCharges -= 1;
    round.traps.add(TrapState(
      x: cell.x,
      y: cell.y,
      placedAt: now,
      expiresAt: now + GameConstants.trapDurationMs,
    ));
  }

  void useAbility(PlayerConnection client) {
    if (round.phase != GamePhase.playing || client.slot != 0) return;
    switch (client.aspect) {
      case LehaAspect.superLeha:
        return;
      case LehaAspect.spider:
        placeWeb(client);
      case LehaAspect.wizard:
        placePortal(client);
    }
  }

  void placeWeb(PlayerConnection client) {
    if (client.webCharges <= 0) return;
    final now = nowMs();
    final cell = centerCell(client);
    final dir = client.lastDirection;
    // Place ONE web directly in front of Leha (same as facing direction).
    final bx = (cell.x + dir.dx).round();
    final by = (cell.y + dir.dy).round();
    if (bx < 0 || bx >= maze.cols || by < 0 || by >= maze.rows) return;
    if (round.webs.any((web) => web.x == bx && web.y == by)) return;
    client.webCharges -= 1;
    round.webs.add(WebState(x: bx, y: by, createdAt: now));
  }

  void placePortal(PlayerConnection client) {
    final now = nowMs();
    if (now < client.portalCooldownUntil) return;
    final current = centerCell(client);
    final direction = client.lastDirection;
    final cell = Point((current.x + direction.dx).round(), (current.y + direction.dy).round());
    if (cell.x < 0 || cell.x >= maze.cols || cell.y < 0 || cell.y >= maze.rows) return;
    if (maze.isWall(cell.x, cell.y)) return;
    round.portals.add(PortalState(x: cell.x, y: cell.y, createdAt: now));
    if (round.portals.length > 2) {
      round.portals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      round.portals.removeAt(0);
    }
    if (round.portals.length == 2) {
      client.portalCooldownUntil = now + GameConstants.portalCooldownMs;
    }
  }

  void ensureRoundState() {
    final activePlayers = clients.values.where((client) => client.slot != null).toList();
    final hasLeha = activePlayers.any((client) => client.slot == 0);
    final hasBakhirkin = activePlayers.any((client) => client.slot == 1);
    final bothReady = hasLeha &&
        hasBakhirkin &&
        activePlayers.where((client) => client.slot == 0 || client.slot == 1).every((client) => client.ready);

    if (!hasLeha || !hasBakhirkin || !bothReady) {
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
        ..portals = []
        ..pendingTrapRechargeAt = []
        ..trails = {0: [], 1: []};
      final bakhirkin = findPlayer(1);
      if (bakhirkin != null) {
        bakhirkin
          ..hp = 100
          ..trapCharges = GameConstants.maxTrapCharges
          ..trapCooldownUntil = 0
          ..invulnerableUntil = 0
          ..stunnedUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0;
      }
      final leha = findPlayer(0);
      if (leha != null) {
        leha
          ..webCharges = leha.aspect == LehaAspect.spider ? GameConstants.maxWebCharges : 0
          ..portalCooldownUntil = 0
          ..stunnedUntil = 0
          ..invulnerableUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0;
      }
    }
  }

  void tick() {
    ensureRoundState();
    if (round.phase != GamePhase.playing) return;

    final now = nowMs();
    expireTraps(now);
    expireWebs(now);
    rechargeTraps(now);
    for (final client in clients.values) {
      if (client.slot == null) continue;
      updatePlayerState(client, now);
      movePlayer(client, GameConstants.tickMs / 1000);
      if (client.slot == 0) {
        collectLogo(client);
        resolvePortal(client);
      }
    }

    final leha = findPlayer(0);
    final bakhirkin = findPlayer(1);
    if (leha != null) updateTrail(leha, now);
    if (bakhirkin != null) updateTrail(bakhirkin, now);
    resolveCollision(leha, bakhirkin, now);
    resolveTrap(leha, now);

    final startedAt = round.startedAt;
    if (round.phase == GamePhase.playing &&
        startedAt != null &&
        now - startedAt >= GameConstants.roundDurationMs) {
      endGame(0, 'Леха продержался 2 минуты.');
    }
    if (round.phase == GamePhase.playing && logos.isEmpty) {
      endGame(0, 'Леха съел все TikTok-логотипы.');
    }
  }

  GameSnapshotDto snapshotFor(PlayerConnection viewer) {
    final now = nowMs();
    final visiblePlayers = clients.values
        .where((player) => player.slot != null)
        .where((player) => viewer.slot == null || player == viewer || canSeePlayer(viewer, player, now))
        .map((player) => serializePlayer(player, now))
        .toList();
    final startedAt = round.startedAt;
    final timeLeftMs = startedAt != null && round.phase == GamePhase.playing
        ? max(0, GameConstants.roundDurationMs - (now - startedAt))
        : GameConstants.roundDurationMs;

    return GameSnapshotDto(
      type: 'state',
      you: YouDto(id: viewer.id, slot: viewer.slot, role: viewer.role),
      rows: maze.rows,
      cols: maze.cols,
      maze: maze.maze,
      logos: visibleLogosFor(viewer).map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return LogoDto(
          x: parts[0],
          y: parts[1],
          power: findPlayer(0)?.aspect == LehaAspect.superLeha && maze.superLogoKeys.contains(key),
        );
      }).toList(),
      traps: visibleTrapsFor(viewer, now),
      webs: visibleWebsFor(viewer),
      portals: visiblePortalsFor(viewer),
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
        trapCooldownMs: viewer.slot == 1 ? max(0, viewer.trapCooldownUntil - now) : 0,
        trapActive: round.traps.isNotEmpty,
        trapCharges: viewer.slot == 1 ? viewer.trapCharges : 0,
        abilityAvailable: abilityAvailableFor(viewer, now),
        abilityCooldownMs: abilityCooldownFor(viewer, now),
        abilityCharges: abilityChargesFor(viewer),
      ),
      status: statusFor(viewer),
    );
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

    final distance = player.speed * dt;
    final requested = player.nextDirection;
    if (requested == null) {
      player.direction = null;
      return;
    }

    player
      ..direction = requested
      ..lastDirection = requested;
    if (!tryMove(player, requested.dx * distance, requested.dy * distance, now)) {
      player.direction = null;
    }

    _wrapTunnel(player);
    resolveWebContact(player, now);
  }

  void updatePlayerState(PlayerConnection player, int now) {
    player.speed = speedFor(player, now);
  }

  double speedFor(PlayerConnection player, int now) {
    var base = speedForSlot(player.slot, now);
    if (player.slot == 1 && now < player.stunnedUntil) return 0;
    final leha = findPlayer(0);
    if (player.slot == 1 && leha != null && now < leha.stunnedUntil) base *= 1.1;
    if (player.slot == 1 && now < player.webSlowedUntil) return base * 0.5;
    return base;
  }

  double speedForSlot(int? slot, int now) {
    if (slot == 0) return now < round.lehaPowerUntil ? GameConstants.baseSpeed * 1.2 : GameConstants.baseSpeed;
    if (slot == 1) return GameConstants.baseSpeed * 1.1;
    return GameConstants.baseSpeed;
  }

  void collectLogo(PlayerConnection player) {
    final cell = centerCell(player);
    final key = '${cell.x},${cell.y}';
    if (!logos.remove(key)) return;
    player.score += 10;
    if (player.aspect == LehaAspect.superLeha && maze.superLogoKeys.contains(key)) {
      round.lehaPowerUntil = nowMs() + GameConstants.powerDurationMs;
    }
  }

  void updateTrail(PlayerConnection player, int now) {
    final slot = player.slot;
    if (slot == null) return;
    final trail = round.trails[slot] ?? <TrailPoint>[];
    final last = trail.isEmpty ? null : trail.last;
    // Add a new point only when player moved far enough — keeps point count manageable.
    if (last != null && sqrt(pow(last.x - player.x, 2) + pow(last.y - player.y, 2)) < 0.35) {
      return;
    }
    trail.add(TrailPoint(x: _round3(player.x), y: _round3(player.y), at: now));
    round.trails[slot] = trail
        .where((point) => now - point.at <= GameConstants.trailLifetimeMs)
        .toList();
  }

  void resolveCollision(PlayerConnection? leha, PlayerConnection? bakhirkin, int now) {
    if (leha == null || bakhirkin == null) return;
    final distance = sqrt(pow(leha.x - bakhirkin.x, 2) + pow(leha.y - bakhirkin.y, 2));
    if (distance > 0.62) return;
    if (now < round.lehaPowerUntil && now >= bakhirkin.invulnerableUntil) {
      hitBakhirkin(bakhirkin, now);
    } else if (now < bakhirkin.invulnerableUntil) {
      // Bakhirkin is stunned/invulnerable — ignore the collision entirely.
    } else {
      endGame(1, 'Бахиркин поймал Леху.');
    }
  }

  void expireWebs(int now) {
    final spider = findPlayer(0);
    // Only wall-webs expire after 10 s; floor-webs persist until game end.
    final expiring = round.webs
        .where((web) => maze.isWall(web.x, web.y) && now - web.createdAt >= GameConstants.webDurationMs)
        .toList();
    round.webs.removeWhere((web) => maze.isWall(web.x, web.y) && now - web.createdAt >= GameConstants.webDurationMs);
    // If Spider Leha is inside an expiring wall-web cell, push her to safety.
    if (spider != null && spider.aspect == LehaAspect.spider) {
      for (final web in expiring) {
        if (!maze.isWall(web.x, web.y)) continue;
        final cx = spider.x, cy = spider.y;
        if (cx > web.x && cx < web.x + 1 && cy > web.y && cy < web.y + 1) {
          final safe = nearestOpenCell(Point(web.x, web.y));
          spider
            ..x = safe.x + 0.5
            ..y = safe.y + 0.5;
          break;
        }
      }
    }
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
      (trap) => trap.triggeredAt == null && now < trap.expiresAt && cell.x == trap.x && cell.y == trap.y,
    );
    if (trapIndex != -1) {
      leha
        ..stunnedUntil = now + GameConstants.trapStunMs
        ..webPhaseUntil = 0
        ..direction = null
        ..nextDirection = null
        ..stopRequested = false;
      // Mark as triggered and keep briefly so Bakhirkin sees the notification.
      round.traps[trapIndex]
        ..triggeredAt = now
        ..expiresAt = now + GameConstants.trapTriggeredDisplayMs;
      scheduleTrapRecharge(now);
    }
  }

  void scheduleTrapRecharge(int now) {
    round.pendingTrapRechargeAt.add(now + GameConstants.trapCooldownMs);
    final bakhirkin = findPlayer(1);
    if (bakhirkin != null) {
      bakhirkin.trapCooldownUntil = round.pendingTrapRechargeAt.reduce(min);
    }
  }

  void rechargeTraps(int now) {
    final ready = round.pendingTrapRechargeAt.where((time) => now >= time).length;
    if (ready == 0) return;
    round.pendingTrapRechargeAt.removeWhere((time) => now >= time);
    final bakhirkin = findPlayer(1);
    if (bakhirkin != null) {
      bakhirkin.trapCharges = min(GameConstants.maxTrapCharges, bakhirkin.trapCharges + ready);
      bakhirkin.trapCooldownUntil = round.pendingTrapRechargeAt.isEmpty ? 0 : round.pendingTrapRechargeAt.reduce(min);
    }
  }

  void hitBakhirkin(PlayerConnection bakhirkin, int now) {
    bakhirkin
      ..hp = max(0, bakhirkin.hp - 50)
      ..stunnedUntil = now + GameConstants.hunterStunMs
      ..invulnerableUntil = now + GameConstants.hunterStunMs
      ..webPhaseUntil = 0
      ..direction = null
      ..nextDirection = null
      ..stopRequested = false;
    round.lehaPowerUntil = 0;
    if (bakhirkin.hp <= 0) {
      endGame(0, 'Супер-Леха съел Бахиркина второй раз.');
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
  }

  Point<int> centerCell(PlayerConnection player) => Point(player.x.floor(), player.y.floor());

  bool canMoveFrom(PlayerConnection player, MoveDirection direction) {
    final cell = centerCell(player);
    final nextX = (cell.x + direction.dx).round();
    final nextY = (cell.y + direction.dy).round();
    if (player.slot == 0 && player.aspect == LehaAspect.spider && maze.isWall(nextX, nextY)) {
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
    if (GameConstants.tunnelRows.contains(y.floor()) && (x < 0 || x >= maze.cols)) {
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
            round.webs.any((w) => w.x == cx && w.y == cy)) { continue; }
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
        for (var slot = 0; slot < GameConstants.roles.length; slot += 1) _roleState(slot),
      ],
      spectators: clients.values.where((client) => client.slot == null).length,
    );
  }

  RoleStateDto _roleState(int slot) {
    final player = clients.values.where((client) => client.slot == slot).firstOrNull;
    return RoleStateDto(
      role: GameConstants.roles[slot],
      slot: slot,
      taken: player != null,
      ready: player?.ready ?? false,
      playerId: player?.id,
      aspect: slot == 0 ? player?.aspect ?? LehaAspect.superLeha : null,
    );
  }

  Iterable<String> visibleLogosFor(PlayerConnection viewer) {
    if (viewer.slot == null || viewer.slot == 0) return logos;
    // Bakhirkin sees super-logo positions only when Leha is actually Super Leha.
    final leha = findPlayer(0);
    if (leha?.aspect == LehaAspect.superLeha) return logos.where(maze.superLogoKeys.contains);
    return const [];
  }

  List<TrapDto> visibleTrapsFor(PlayerConnection viewer, int now) {
    final activeTraps = round.traps.where((trap) => now < trap.expiresAt);
    if (viewer.slot == null) return activeTraps.map(_trapDto).toList();
    final vp = playerPos(viewer);
    return activeTraps
        .where((trap) {
          // Bakhirkin always sees triggered traps (catch notification).
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

  List<PortalDto> visiblePortalsFor(PlayerConnection viewer) {
    // Spectators (slot == null) see nothing; Leha and Bakhirkin both see portals.
    if (viewer.slot == null) return const [];
    final vp = playerPos(viewer);
    return [
      for (var i = 0; i < round.portals.length; i += 1)
        if (viewer.slot == 0 ||
            maze.hasXrayVisibility(vp, Point(round.portals[i].x + 0.5, round.portals[i].y + 0.5)) ||
            maze.hasLineOfSight(vp, Point(round.portals[i].x + 0.5, round.portals[i].y + 0.5)))
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
      LehaAspect.wizard => now >= viewer.portalCooldownUntil,
    };
  }

  int abilityCooldownFor(PlayerConnection viewer, int now) {
    if (viewer.slot != 0 || viewer.aspect != LehaAspect.wizard) return 0;
    return max(0, viewer.portalCooldownUntil - now);
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
    final showFacing = aspect == LehaAspect.spider || aspect == LehaAspect.wizard;
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
      facing: showFacing ? player.lastDirection : null,
    );
  }

  String statusFor(PlayerConnection viewer) {
    if (round.phase == GamePhase.waiting) return 'Выберите персонажей и нажмите готовность.';
    if (round.phase == GamePhase.ended) {
      final side = round.winnerSlot == 0 ? 'Леха выиграл' : 'Бахиркин выиграл';
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
    return trailPointsForSlot(sourceSlot, now).where((point) => canViewerSeeTrailPoint(viewer, point)).toList();
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
    // Bakhirkin smells Leha's trail within scentRadius — no line-of-sight needed.
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
    return maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp);
  }

  Point<double> playerPos(PlayerConnection p) => Point(p.x, p.y);

  void resolvePortal(PlayerConnection player) {
    if (player.aspect != LehaAspect.wizard || round.portals.length != 2) return;
    final cell = centerCell(player);
    final portalIndex = round.portals.indexWhere((portal) => portal.x == cell.x && portal.y == cell.y);
    if (portalIndex == -1) return;
    final target = round.portals[portalIndex == 0 ? 1 : 0];
    player
      ..x = target.x + 0.5
      ..y = target.y + 0.5
      ..direction = null
      ..nextDirection = null;
    round.portals = [];
  }

  void resolveWebContact(PlayerConnection player, int now) {
    if (player.slot != 1) return;
    final cell = centerCell(player);
    // Only floor webs (non-wall cells) slow Bakhirkin; wall webs are for Spider traversal.
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
    final next = Point((cell.x + direction.dx).round(), (cell.y + direction.dy).round());
    if (!maze.isWall(next.x, next.y)) return;
    consumeWebBridge(cell, next, preview: false);
  }

  bool consumeWebBridge(Point<int> from, Point<int> to, {required bool preview}) {
    // Wall webs persist until they expire; Spider can traverse them repeatedly.
    return round.webs.any(
      (web) => (web.x == from.x && web.y == from.y) || (web.x == to.x && web.y == to.y),
    );
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
        if (cell.x < 0 || cell.x >= maze.cols || cell.y < 0 || cell.y >= maze.rows) continue;
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
