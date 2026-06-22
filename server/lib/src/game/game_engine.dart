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
    logos.removeWhere(maze.lava.contains);
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

  /// Biomes the next generated map may use (toggled from the lobby).
  Set<CaveBiome> enabledBiomes = CaveBiome.values.toSet();
  bool sandboxMode = false;
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
        ensureRoundState();
      case ClientMessageType.spectate:
        becomeSpectator(client);
      case ClientMessageType.placeTrap:
        placeTrap(client, message.targetX, message.targetY);
      case ClientMessageType.useAbility:
        useAbility(client, message.targetX, message.targetY);
      case ClientMessageType.comingOut:
        throwHeart(client, message.targetX, message.targetY);
      case ClientMessageType.placeMagicCrystal:
        placeOrPickMagicCrystal(client, message.targetX, message.targetY);
      case ClientMessageType.layClutch:
        layClutch(client, message.targetX, message.targetY);
      case ClientMessageType.activateMagicChain:
        break; // chains auto-activate on crystal placement
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
      case ClientMessageType.setBiomes:
        final biomes = message.biomes;
        if (biomes != null && biomes.isNotEmpty) {
          setEnabledBiomes(biomes);
        }
      case ClientMessageType.setSandbox:
        if (round.phase == GamePhase.waiting) {
          sandboxMode = message.sandbox ?? false;
          ensureRoundState();
        }
      case ClientMessageType.aim:
        updateAim(client, message.targetX, message.targetY);
      case ClientMessageType.createSession:
      case ClientMessageType.joinSession:
      case ClientMessageType.leaveSession:
      case ClientMessageType.rematch:
        return;
    }
  }

  /// Applies map filters immediately to the lobby preview. An active round is
  /// never replaced underneath the players; in that case the selection remains
  /// the configuration for the next reset.
  void setEnabledBiomes(Iterable<CaveBiome> biomes) {
    final next = biomes.toSet();
    if (next.isEmpty) return;
    enabledBiomes = next;
    if (round.phase != GamePhase.waiting) return;
    _regenerateLobbyMap();
  }

  void _regenerateLobbyMap() {
    _maze = MazeService.generate(biomes: enabledBiomes);
    logos = switch (findPlayer(0)?.aspect) {
      LehaAspect.spider => _spawnRafaelki(),
      LehaAspect.wizard => <String>{},
      _ => _maze.createLogos(),
    };
    logos.removeWhere(maze.lava.contains);
    final now = nowMs();
    round
      ..shardsIntact = Set<String>.from(_maze.amethystShards)
      ..chimes = []
      ..mushrooms = _spawnMushrooms()
      ..spores = []
      ..nextAmethystGrowAt = now + GameConstants.amethystShardGrowIntervalMs
      ..sarcophagi = _spawnSarcophagi()
      ..mummies = [];
  }

  void reset({bool keepBotsReady = true}) {
    _maze = MazeService.generate(biomes: enabledBiomes);
    logos = switch (findPlayer(0)?.aspect) {
      LehaAspect.spider => _spawnRafaelki(),
      LehaAspect.wizard => <String>{},
      _ => _maze.createLogos(),
    };
    logos.removeWhere(maze.lava.contains);
    round = GameRound();
    for (final client in clients.values) {
      final start = GameConstants.starts[client.slot ?? 0];
      client
        ..score = 0
        ..ready = keepBotsReady && client.isBot
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
        ..magicChainCooldownUntil = 0
        ..crystalCharges = client.slot == 0 &&
                client.aspect == LehaAspect.wizard
            ? GameConstants.wizardMaxCrystals
            : 0
        ..chainStunImmuneUntil = 0
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
      ..simaCooldownUntil = 0
      ..heartCharges =
          kind == HunterKind.sima ? GameConstants.simaHeartMaxCharges : 0
      ..heartShotCooldownUntil = 0
      ..heartRechargeAt = 0;
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
      ..portalCooldownUntil = 0
      ..magicChainCooldownUntil = 0
      ..crystalCharges =
          aspect == LehaAspect.wizard ? GameConstants.wizardMaxCrystals : 0;
    // Keep the lobby board's collectibles in sync with the chosen aspect:
    // Spider shows 5 Raffaellos, everyone else the TikTok logos.
    logos = switch (aspect) {
      LehaAspect.spider => _spawnRafaelki(),
      LehaAspect.wizard => <String>{},
      LehaAspect.superLeha => _maze.createLogos(),
    };
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
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..webSlowedUntil = 0;
    client.webPhaseUntil = 0;
    ensureRoundState();
  }

  /// Bakhirkin's trap button: places a trap, or — if he's standing on one of
  /// his own un-sprung traps — picks it back up (refunding the charge). There's
  /// no cooldown; he just can't have more than [maxTrapCharges] traps out.
  void placeTrap(PlayerConnection client, [double? targetX, double? targetY]) {
    final now = nowMs();
    if (round.phase != GamePhase.playing ||
        client.slot != 1 ||
        client.hunterKind != HunterKind.bakhirkin ||
        now < client.stunnedUntil) {
      return;
    }
    final targeted =
        _targetCell(client, targetX, targetY, SkillTargetRange.trap);
    if (targetX != null && targeted == null) return;
    final cell = targeted ?? centerCell(client);
    // Same button collects an un-sprung trap underfoot.
    final existing = round.traps.indexWhere((trap) =>
        trap.triggeredAt == null && trap.x == cell.x && trap.y == cell.y);
    if (existing != -1) {
      round.traps.removeAt(existing);
      client.trapCharges =
          min(GameConstants.maxTrapCharges, client.trapCharges + 1);
      return;
    }
    if (client.trapCharges <= 0) return;
    if (maze.isWall(cell.x, cell.y) ||
        maze.isBush(cell.x, cell.y) ||
        maze.isLava(cell.x, cell.y) ||
        round.emberRocks.any((r) => r.x == cell.x && r.y == cell.y)) {
      return;
    }
    client.trapCharges -= 1;
    round.traps.add(TrapState(
      x: cell.x,
      y: cell.y,
      placedAt: now,
      // Placed traps don't expire on a timer; only a sprung trap counts down
      // (its brief "caught!" display). Sentinel keeps it active until triggered.
      expiresAt: _trapNeverExpires,
    ));
  }

  static const _trapNeverExpires = 1 << 62;

  void useAbility(PlayerConnection client, [double? targetX, double? targetY]) {
    if (round.phase != GamePhase.playing) return;
    if (client.slot == 1) {
      if (client.hunterKind == HunterKind.sashaYakuza) {
        throwBarrel(client, targetX, targetY);
      }
      if (client.hunterKind == HunterKind.sima) activateFemboy(client);
      return;
    }
    if (client.slot != 0) return;
    switch (client.aspect) {
      case LehaAspect.superLeha:
        return;
      case LehaAspect.spider:
        placeWeb(client, targetX, targetY);
      case LehaAspect.wizard:
        placePortal(client, targetX, targetY);
    }
  }

  /// Sima's "Фембой" form: a self-buff aura. While it's up, a visible
  /// non-powered Leha is slowed when fleeing (see [movePlayer]).
  void activateFemboy(PlayerConnection client) {
    final now = nowMs();
    if (now < client.simaCooldownUntil || now < client.stunnedUntil) return;
    client.simaFemboyUntil = now + GameConstants.simaFemboyMs;
    client.simaCooldownUntil = now + GameConstants.simaFemboyCooldownMs;
  }

  /// Sima's "Камингаут": fires one heart projectile per call, gated by charges
  /// and a short shot cooldown. The client holds the button and re-sends, so a
  /// held key sprays a heart every [simaHeartShotCooldownMs] until charges run
  /// out. Hearts are aimed at [targetX]/[targetY] if given, else Sima's facing.
  void throwHeart(PlayerConnection client,
      [double? targetX, double? targetY]) {
    final now = nowMs();
    if (round.phase != GamePhase.playing ||
        client.slot != 1 ||
        client.hunterKind != HunterKind.sima ||
        now < client.stunnedUntil ||
        now < client.heartShotCooldownUntil ||
        client.heartCharges <= 0) {
      return;
    }
    var aimX = targetX == null ? client.lastDirection.dx : targetX - client.x;
    var aimY = targetY == null ? client.lastDirection.dy : targetY - client.y;
    final aimLen = sqrt(aimX * aimX + aimY * aimY);
    if (aimLen < 1e-4) {
      aimX = client.lastDirection.dx;
      aimY = client.lastDirection.dy;
    } else {
      aimX /= aimLen;
      aimY /= aimLen;
    }
    client.heartCharges -= 1;
    client.heartShotCooldownUntil = now + GameConstants.simaHeartShotCooldownMs;
    // Start the recharge clock when the first charge of a (re)fill is spent.
    if (client.heartCharges == GameConstants.simaHeartMaxCharges - 1) {
      client.heartRechargeAt = now + GameConstants.simaHeartRechargeMs;
    }
    // Randomise the sway so a held spray fans out unpredictably. Phase stays 0
    // (and amplitude is ramped in flight) so the heart leaves Sima's hand at her
    // position instead of teleporting sideways into a wall on the first tick.
    final amplitude = GameConstants.simaHeartSineAmplitude *
        (0.5 + _rng.nextDouble()) *
        (_rng.nextBool() ? 1 : -1);
    const phase = 0.0;
    round.hearts.add(HeartState(
      id: round.nextHeartId++,
      cx: client.x,
      cy: client.y,
      dirX: aimX,
      dirY: aimY,
      perpX: -aimY,
      perpY: aimX,
      amplitude: amplitude,
      phase: phase,
      spawnedAt: now,
      ownerId: client.id,
    ));
  }

  void throwBarrel(PlayerConnection client,
      [double? targetX, double? targetY]) {
    final now = nowMs();
    if (now < client.barrelCooldownUntil || now < client.stunnedUntil) return;
    final aimX = targetX == null ? client.lastDirection.dx : targetX - client.x;
    final aimY = targetY == null ? client.lastDirection.dy : targetY - client.y;
    final aimLength = sqrt(aimX * aimX + aimY * aimY);
    if (aimLength < 1e-4) return;
    client.barrelCooldownUntil = now + GameConstants.barrelCooldownMs;
    round.barrels.add(BarrelState(
      x: client.x,
      y: client.y,
      dirX: aimX / aimLength,
      dirY: aimY / aimLength,
      spawnedAt: now,
      ownerId: client.id,
      // Cursor targeting and the preview promise a deterministic ricochet path.
      homing: false,
    ));
  }

  void placeWeb(PlayerConnection client, [double? targetX, double? targetY]) {
    if (client.webCharges <= 0) return;
    final now = nowMs();
    final cell = centerCell(client);
    // Can't spin a new web while standing inside a wall — otherwise she could
    // chain webs cell-by-cell and camp inside walls indefinitely.
    if (maze.isWall(cell.x, cell.y)) return;
    final target = _targetCell(client, targetX, targetY, SkillTargetRange.web);
    if (targetX != null && target == null) return;
    final dir = client.lastDirection;
    final bx = target?.x ?? (cell.x + dir.dx).round();
    final by = target?.y ?? (cell.y + dir.dy).round();
    if (bx < 0 || bx >= maze.cols || by < 0 || by >= maze.rows) return;
    if (!canPlaceWebAt(bx, by)) return;
    if (round.webs.any((web) => web.x == bx && web.y == by)) return;
    client.webCharges -= 1;
    round.webs.add(WebState(x: bx, y: by, createdAt: now));
    scheduleWebRecharge(client, now);
  }

  /// Spider webs may bridge a cracked wall or cover ordinary floor. Biome
  /// hazards keep their cell readable and mechanically unobstructed.
  bool canPlaceWebAt(int x, int y) {
    if (maze.isCrackedWall(x, y)) return true;
    if (maze.isWall(x, y)) return false;
    final key = '$x,$y';
    if (maze.quicksand.contains(key) ||
        maze.isLava(x, y) ||
        round.emberRocks.any((r) => r.x == x && r.y == y) ||
        maze.amethystWalls.contains(key) ||
        round.shardsIntact.contains(key)) {
      return false;
    }
    return !round.mushrooms
        .any((mushroom) => mushroom.x == x && mushroom.y == y);
  }

  void placePortal(PlayerConnection client,
      [double? targetX, double? targetY]) {
    final now = nowMs();
    // The cooldown is on *laying a pair* of portals, not on teleporting. It
    // starts only once the second portal lands, and blocks laying any new
    // portal until it elapses.
    if (now < client.portalCooldownUntil) return;
    final current = centerCell(client);
    final direction = client.lastDirection;
    final targeted =
        _targetCell(client, targetX, targetY, SkillTargetRange.portal);
    if (targetX != null && targeted == null) return;
    final cell = targeted ??
        Point((current.x + direction.dx).round(),
            (current.y + direction.dy).round());
    if (cell.x < 0 ||
        cell.x >= maze.cols ||
        cell.y < 0 ||
        cell.y >= maze.rows) {
      return;
    }
    if (maze.isWall(cell.x, cell.y) ||
        maze.isBush(cell.x, cell.y) ||
        maze.isLava(cell.x, cell.y) ||
        round.emberRocks.any((r) => r.x == cell.x && r.y == cell.y)) {
      return;
    }
    round.portals.add(PortalState(x: cell.x, y: cell.y, createdAt: now));
    if (round.portals.length > 2) {
      round.portals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      round.portals.removeAt(0);
    }
    // Second portal of the pair just landed — start the placement cooldown.
    if (round.portals.length == 2) {
      client.portalCooldownUntil = now + GameConstants.portalCooldownMs;
    }
  }

  void placeOrPickMagicCrystal(PlayerConnection client,
      [double? targetX, double? targetY]) {
    final now = nowMs();
    if (round.phase != GamePhase.playing ||
        client.slot != 0 ||
        client.aspect != LehaAspect.wizard ||
        now < client.stunnedUntil) {
      return;
    }
    final current = centerCell(client);
    final pickX = targetX ?? client.x;
    final pickY = targetY ?? client.y;
    final nearby = round.magicCrystals.where((crystal) {
      final dx = crystal.x + 0.5 - pickX;
      final dy = crystal.y + 0.5 - pickY;
      final px = crystal.x + 0.5 - client.x;
      final py = crystal.y + 0.5 - client.y;
      return dx * dx + dy * dy <= 0.85 * 0.85 &&
          px * px + py * py <=
              SkillTargetRange.crystal * SkillTargetRange.crystal;
    }).toList();
    if (nearby.isNotEmpty) {
      _removeMagicCrystal(nearby.first.id, now);
      client.crystalCharges =
          min(GameConstants.wizardMaxCrystals, client.crystalCharges + 1);
      return;
    }
    if (client.crystalCharges <= 0) return;
    final direction = client.lastDirection;
    final targeted =
        _targetCell(client, targetX, targetY, SkillTargetRange.crystal);
    if (targetX != null && targeted == null) return;
    final target = targeted ??
        Point((current.x + direction.dx).round(),
            (current.y + direction.dy).round());
    if (target.x < 0 ||
        target.x >= maze.cols ||
        target.y < 0 ||
        target.y >= maze.rows ||
        maze.isWall(target.x, target.y) ||
        maze.isLava(target.x, target.y) ||
        round.emberRocks.any((r) => r.x == target.x && r.y == target.y) ||
        round.magicCrystals
            .any((crystal) => crystal.x == target.x && crystal.y == target.y)) {
      return;
    }
    client.crystalCharges -= 1;
    _scheduleCrystalRecharge(client, now);
    round.magicCrystals.add(MagicCrystalState(
      id: round.nextMagicCrystalId++,
      x: target.x,
      y: target.y,
    ));
    autoActivateMagicChains(now);
  }

  List<MagicChainDto> _magicChainsForSnapshot() {
    final active = round.magicCrystals.where((c) => !c.fallen).toList();
    if (active.length < 2) return [];
    final edges = <List<int>>[];
    final emitted = <String>{};
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        final a = active[i], b = active[j];
        final key = _magicEdgeKey(a.id, b.id);
        if (!emitted.add(key)) continue;
        if (maze.hasLineOfSight(
          Point(a.x + 0.5, a.y + 0.5),
          Point(b.x + 0.5, b.y + 0.5),
          ignoreCover: true,
        )) {
          edges.add([a.id, b.id]);
        }
      }
    }
    if (edges.isEmpty) return [];
    return [MagicChainDto(id: 1, contours: edges)];
  }

  void autoActivateMagicChains(int now) {
    final crystals =
        round.magicCrystals.where((c) => !c.fallen).toList();
    if (crystals.length < 3) return;
    for (final crystal in crystals) {
      final cycle = _bestMagicCycle(crystal.id);
      if (cycle == null || _magicContourExists(cycle)) continue;
      final touching = round.magicChains
          .where((chain) => chain.contours.any((contour) =>
              contour.toSet().intersection(cycle.toSet()).length >= 2))
          .toList();
      if (touching.isEmpty) {
        round.magicChains.add(MagicChainState(
          id: round.nextMagicChainId++,
          contours: [cycle],
        ));
      } else {
        final contours = <List<int>>[cycle];
        for (final chain in touching) {
          contours.addAll(chain.contours);
        }
        final id = touching.map((chain) => chain.id).reduce(min);
        round.magicChains.removeWhere(touching.contains);
        round.magicChains.add(MagicChainState(id: id, contours: contours));
      }
    }
    _destroyObjectsOnMagicChains();
  }

  List<int>? _bestMagicCycle(int seedId) {
    final crystals =
        round.magicCrystals.where((crystal) => !crystal.fallen).toList();
    if (crystals.length < 3) return null;
    final byId = {for (final crystal in crystals) crystal.id: crystal};
    final others = crystals.where((crystal) => crystal.id != seedId).toList();
    List<int>? best;
    var bestAddedLength = -1.0;
    var bestPerimeter = -1.0;
    var bestArea = -1.0;
    final energizedEdges = _magicChainEdgeKeys();

    void search(List<int> path, Set<int> used) {
      if (path.length >= 3 &&
          _validMagicContour(path, byId) &&
          _magicContourCompatibleWithExisting(path, byId)) {
        var addedLength = 0.0;
        var perimeter = 0.0;
        for (var i = 0; i < path.length; i++) {
          final a = byId[path[i]]!, b = byId[path[(i + 1) % path.length]]!;
          final length = sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
          perimeter += length;
          if (!energizedEdges.contains(_magicEdgeKey(a.id, b.id))) {
            addedLength += length;
          }
        }
        final area = _magicContourArea(path, byId);
        if (addedLength > bestAddedLength + 1e-9 ||
            ((addedLength - bestAddedLength).abs() <= 1e-9 &&
                (perimeter > bestPerimeter + 1e-9 ||
                    ((perimeter - bestPerimeter).abs() <= 1e-9 &&
                        (area > bestArea + 1e-9 ||
                            ((area - bestArea).abs() <= 1e-9 &&
                                path.length > (best?.length ?? 0))))))) {
          bestAddedLength = addedLength;
          bestPerimeter = perimeter;
          bestArea = area;
          best = List<int>.from(path);
        }
      }
      if (path.length >= crystals.length) return;
      for (final crystal in others) {
        if (!used.add(crystal.id)) continue;
        path.add(crystal.id);
        search(path, used);
        path.removeLast();
        used.remove(crystal.id);
      }
    }

    search([seedId], {seedId});
    return best;
  }

  String _magicEdgeKey(int a, int b) => a < b ? '$a:$b' : '$b:$a';

  Set<String> _magicChainEdgeKeys() {
    final result = <String>{};
    for (final chain in round.magicChains) {
      for (final contour in chain.contours) {
        for (var i = 0; i < contour.length; i++) {
          result.add(
              _magicEdgeKey(contour[i], contour[(i + 1) % contour.length]));
        }
      }
    }
    return result;
  }

  bool _magicContourCompatibleWithExisting(
      List<int> candidate, Map<int, MagicCrystalState> crystals) {
    for (var i = 0; i < candidate.length; i++) {
      final aId = candidate[i], bId = candidate[(i + 1) % candidate.length];
      final a = crystals[aId]!, b = crystals[bId]!;
      for (final chain in round.magicChains) {
        for (final contour in chain.contours) {
          for (var j = 0; j < contour.length; j++) {
            final cId = contour[j], dId = contour[(j + 1) % contour.length];
            if ({aId, bId}.intersection({cId, dId}).isNotEmpty) continue;
            final c = crystals[cId], d = crystals[dId];
            if (c == null || d == null) continue;
            if (_segmentsIntersect(
              Point(a.x + 0.5, a.y + 0.5),
              Point(b.x + 0.5, b.y + 0.5),
              Point(c.x + 0.5, c.y + 0.5),
              Point(d.x + 0.5, d.y + 0.5),
            )) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  bool _validMagicContour(List<int> ids, Map<int, MagicCrystalState> crystals) {
    if (ids.length < 3 || ids.toSet().length != ids.length) return false;
    for (var i = 0; i < ids.length; i++) {
      final a = crystals[ids[i]], b = crystals[ids[(i + 1) % ids.length]];
      if (a == null || b == null || a.fallen || b.fallen) return false;
      if (!maze.hasLineOfSight(
        Point(a.x + 0.5, a.y + 0.5),
        Point(b.x + 0.5, b.y + 0.5),
        ignoreCover: true,
      )) {
        return false;
      }
    }
    if (_magicContourArea(ids, crystals) <= 1e-4) {
      return false;
    }
    for (var i = 0; i < ids.length; i++) {
      final a1 = crystals[ids[i]]!, a2 = crystals[ids[(i + 1) % ids.length]]!;
      for (var j = i + 1; j < ids.length; j++) {
        if (j == i || j == (i + 1) % ids.length || (j + 1) % ids.length == i) {
          continue;
        }
        final b1 = crystals[ids[j]]!, b2 = crystals[ids[(j + 1) % ids.length]]!;
        if (_segmentsIntersect(
          Point(a1.x + 0.5, a1.y + 0.5),
          Point(a2.x + 0.5, a2.y + 0.5),
          Point(b1.x + 0.5, b1.y + 0.5),
          Point(b2.x + 0.5, b2.y + 0.5),
        )) {
          return false;
        }
      }
    }
    return true;
  }

  double _magicContourArea(
      List<int> ids, Map<int, MagicCrystalState> crystals) {
    var sum = 0.0;
    for (var i = 0; i < ids.length; i++) {
      final a = crystals[ids[i]]!, b = crystals[ids[(i + 1) % ids.length]]!;
      sum += (a.x + 0.5) * (b.y + 0.5) - (b.x + 0.5) * (a.y + 0.5);
    }
    return sum.abs() / 2;
  }

  bool _segmentsIntersect(
      Point<double> a, Point<double> b, Point<double> c, Point<double> d) {
    double cross(Point<double> p, Point<double> q, Point<double> r) =>
        (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
    final abC = cross(a, b, c), abD = cross(a, b, d);
    final cdA = cross(c, d, a), cdB = cross(c, d, b);
    return abC * abD <= 0 && cdA * cdB <= 0;
  }

  bool _magicContourExists(List<int> candidate) {
    bool sameCycle(List<int> a, List<int> b) {
      if (a.length != b.length || a.toSet().difference(b.toSet()).isNotEmpty) {
        return false;
      }
      for (var offset = 0; offset < b.length; offset++) {
        if (b[offset] != a.first) continue;
        final forward =
            List.generate(a.length, (i) => b[(offset + i) % b.length]);
        final reverse = List.generate(
            a.length, (i) => b[(offset - i + b.length * 2) % b.length]);
        if (_sameInts(a, forward) || _sameInts(a, reverse)) return true;
      }
      return false;
    }

    return round.magicChains.any((chain) =>
        chain.contours.any((contour) => sameCycle(candidate, contour)));
  }

  bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _removeMagicCrystal(int id, int now) {
    round.magicCrystals.removeWhere((crystal) => crystal.id == id);
    _rebuildMagicChainsWithout(id, now);
  }

  void _rebuildMagicChainsWithout(int id, int now) {
    final byId = {
      for (final crystal in round.magicCrystals) crystal.id: crystal
    };
    final rebuilt = <MagicChainState>[];
    for (final chain in round.magicChains) {
      final contours = <List<int>>[];
      for (final contour in chain.contours) {
        if (!contour.contains(id)) {
          contours.add(contour);
          continue;
        }
        final remaining =
            contour.where((crystalId) => crystalId != id).toList();
        if (_validMagicContour(remaining, byId)) contours.add(remaining);
      }
      if (contours.isNotEmpty) {
        rebuilt.add(MagicChainState(id: chain.id, contours: contours));
      }
    }
    round.magicChains = rebuilt;
  }

  void updateMagicChains(int now, int dtMs) {
    final wizard = findPlayer(0);
    if (wizard?.aspect != LehaAspect.wizard) return;
    final hunter = findPlayer(1);
    if (hunter != null) {
      for (final crystal in round.magicCrystals) {
        if (crystal.fallen) continue;
        final dx = crystal.x + 0.5 - hunter.x;
        final dy = crystal.y + 0.5 - hunter.y;
        if (dx * dx + dy * dy <= 0.62 * 0.62) {
          _removeMagicCrystal(crystal.id, now);
          break;
        }
      }
      if (_pointOnMagicChain(hunter.x, hunter.y) &&
          now >= hunter.chainStunImmuneUntil) {
        hunter
          ..stunnedUntil = max(hunter.stunnedUntil,
              now + GameConstants.wizardChainStunMs)
          ..chainStunImmuneUntil = now +
              GameConstants.wizardChainStunMs +
              GameConstants.wizardChainStunImmuneMs
          ..direction = null
          ..nextDirection = null;
      }
    }
    if (round.magicChains.isEmpty) return;
    _destroyObjectsOnMagicChains();

    final byId = {
      for (final crystal in round.magicCrystals) crystal.id: crystal
    };
    var multiplier = 0.0;
    for (final chain in round.magicChains) {
      for (final contour in chain.contours) {
        final area = _magicContourArea(contour, byId);
        multiplier +=
            pow(area / GameConstants.wizardSaturationReferenceArea, 1.5).clamp(
                GameConstants.wizardSaturationMinMultiplier,
                GameConstants.wizardSaturationMaxMultiplier);
      }
    }
    round.wizardSaturation += dtMs /
        GameConstants.wizardSaturationBaseMs *
        multiplier *
        GameConstants.wizardSaturationSpeedMultiplier;
    if (round.wizardSaturation >= 1) {
      round.wizardSaturation = 1;
      endGame(0, 'Леха-Маг насытил магические цепи.');
    }
  }

  Iterable<(Point<double>, Point<double>)> _magicChainEdges() sync* {
    final active =
        round.magicCrystals.where((c) => !c.fallen).toList();
    final emitted = <String>{};
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        final a = active[i], b = active[j];
        if (!emitted.add(_magicEdgeKey(a.id, b.id))) continue;
        if (!maze.hasLineOfSight(
          Point(a.x + 0.5, a.y + 0.5),
          Point(b.x + 0.5, b.y + 0.5),
          ignoreCover: true,
        )) {
          continue;
        }
        yield (
          Point(a.x + 0.5, a.y + 0.5),
          Point(b.x + 0.5, b.y + 0.5),
        );
      }
    }
  }

  bool _pointOnMagicChain(double x, double y, [double extraRadius = 0]) {
    final point = Point<double>(x, y);
    final radius = GameConstants.wizardChainCollisionRadius + extraRadius;
    for (final edge in _magicChainEdges()) {
      if (_distanceToSegment(point, edge.$1, edge.$2) <= radius) {
        return true;
      }
    }
    return false;
  }

  double _distanceToSegment(Point<double> p, Point<double> a, Point<double> b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared <= 1e-9) {
      return sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
    }
    final t =
        (((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared).clamp(0.0, 1.0);
    final qx = a.x + dx * t, qy = a.y + dy * t;
    return sqrt(pow(p.x - qx, 2) + pow(p.y - qy, 2));
  }

  void _destroyObjectsOnMagicChains() {
    if (round.magicChains.isEmpty) return;
    bool hitsCell(int x, int y) => _pointOnMagicChain(x + 0.5, y + 0.5, 0.25);
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.cols; x++) {
        if (maze.isWall(x, y) || !hitsCell(x, y)) continue;
        maze.destroyNonWallContent(x, y);
        round.shardsIntact.remove('$x,$y');
        logos.remove('$x,$y');
      }
    }
    round.traps.removeWhere((trap) => hitsCell(trap.x, trap.y));
    round.webs.removeWhere((web) => hitsCell(web.x, web.y));
    round.barrels
        .removeWhere((barrel) => _pointOnMagicChain(barrel.x, barrel.y));
    round.mushrooms.removeWhere((mushroom) => hitsCell(mushroom.x, mushroom.y));
    round.spores.removeWhere((spore) => hitsCell(spore.x, spore.y));
    round.mummies.removeWhere((mummy) => _pointOnMagicChain(mummy.x, mummy.y));
    if (round.clutch != null && hitsCell(round.clutch!.x, round.clutch!.y)) {
      round.clutch = null;
    }
    maze.dynamicCover
      ..clear()
      ..addAll(round.spores.map((spore) => '${spore.x},${spore.y}'));
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
        bot.trapCharges > 0) {
      placeTrap(bot);
    }
    bot.nextDirection = _bfsFirstStep(cell, (x, y) => x == lc.x && y == lc.y) ??
        bot.nextDirection;
  }

  /// One open cell step from (x,y) along [step], honoring tunnel wrap; null if blocked.
  Point<int>? _stepCell(int x, int y, (MoveDirection, int, int) step) {
    var nx = x + step.$2;
    var ny = y + step.$3;
    if (GameConstants.tunnelRows.contains(ny)) {
      if (nx < 0) nx = maze.cols - 1;
      if (nx >= maze.cols) nx = 0;
    }
    if (maze.biome != CaveBiome.ember &&
        GameConstants.tunnelCols.contains(nx)) {
      if (ny < 0) ny = maze.rows - 1;
      if (ny >= maze.rows) ny = 0;
    }
    if (ny < 0 || ny >= maze.rows || nx < 0 || nx >= maze.cols) return null;
    if (maze.isWall(nx, ny)) return null;
    if (!_emberCellPassable(nx, ny)) return null;
    return Point(nx, ny);
  }

  /// BFS over maze cells; returns the first move toward the nearest cell
  /// satisfying [isGoal], or null if none reachable.
  MoveDirection? _bfsFirstStep(
      Point<int> rawStart, bool Function(int, int) isGoal) {
    // A player mid-tunnel-wrap sits just outside the grid (e.g. x=-0.35 → cell
    // -1, or rows+0.35 → cell `rows`). Normalize back into bounds so the visited
    // array isn't indexed out of range.
    final start = _wrapCell(rawStart);
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

  /// Wraps an out-of-bounds cell (a player caught mid-tunnel-wrap) back into the
  /// grid so it can be used as a grid index.
  Point<int> _wrapCell(Point<int> c) => Point(
      (c.x % maze.cols + maze.cols) % maze.cols,
      (c.y % maze.rows + maze.rows) % maze.rows);

  /// Open neighbor that maximizes distance from [threat].
  MoveDirection? _fleeStep(Point<int> rawFrom, Point<int> threat) {
    final from = _wrapCell(rawFrom);
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
      if (barrel.homing && leha != null) _steerBarrelToward(barrel, leha);
      _advanceBarrel(barrel,
          slowed ? baseDist * GameConstants.barrelWebSlowFactor : baseDist);
      if (maze.isLava(barrel.x.floor(), barrel.y.floor())) continue;
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

  /// Bends a homing barrel's heading toward [leha] by a capped amount per tick.
  void _steerBarrelToward(BarrelState barrel, PlayerConnection leha) {
    final desired = atan2(leha.y - barrel.y, leha.x - barrel.x);
    final current = atan2(barrel.dirY, barrel.dirX);
    var delta = desired - current;
    // Normalize to (-pi, pi] so we always turn the short way around.
    while (delta > pi) {
      delta -= 2 * pi;
    }
    while (delta < -pi) {
      delta += 2 * pi;
    }
    final maxTurn = GameConstants.barrelHomingTurnPerTick;
    final turn = delta.clamp(-maxTurn, maxTurn);
    final angle = current + turn;
    barrel
      ..dirX = cos(angle)
      ..dirY = sin(angle);
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
    if (maze.biome != CaveBiome.ember &&
        GameConstants.tunnelCols.contains(x.floor()) &&
        (y < 0 || y >= maze.rows)) {
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
    if (GameConstants.tunnelRows.contains(barrel.y.floor())) {
      if (barrel.x < -0.35) barrel.x = maze.cols + 0.35;
      if (barrel.x > maze.cols + 0.35) barrel.x = -0.35;
    }
    if (maze.biome != CaveBiome.ember &&
        GameConstants.tunnelCols.contains(barrel.x.floor())) {
      if (barrel.y < -0.35) barrel.y = maze.rows + 0.35;
      if (barrel.y > maze.rows + 0.35) barrel.y = -0.35;
    }
  }

  void updateHearts(PlayerConnection? leha, int now, double dt) {
    if (round.hearts.isEmpty) return;
    final step = GameConstants.baseSpeed *
        GameConstants.simaHeartSpeedMultiplier *
        dt;
    final survivors = <HeartState>[];
    for (final heart in round.hearts) {
      if (heart.impactUntil != 0) {
        if (now < heart.impactUntil) survivors.add(heart);
        continue;
      }
      heart
        ..traveled += step
        ..cx += heart.dirX * step
        ..cy += heart.dirY * step;
      // Lateral sine sway starts at zero and grows across the entire flight.
      // The full configured amplitude is reached only at maximum range, making
      // close and medium-range shots substantially easier to land.
      final ramp =
          (heart.traveled / GameConstants.simaHeartRangeBlocks).clamp(0.0, 1.0);
      final sway = sin(heart.traveled /
                  GameConstants.simaHeartSineWavelength *
                  2 *
                  pi +
              heart.phase) *
          heart.amplitude *
          ramp;
      heart
        ..x = heart.cx + heart.perpX * sway
        ..y = heart.cy + heart.perpY * sway;
      // No ricochet — a wall or the max range simply ends it.
      if (heart.traveled >= GameConstants.simaHeartRangeBlocks) continue;
      if (barrelBlocked(heart.x, heart.y)) {
        heart.impactUntil = now + GameConstants.simaHeartWallImpactMs;
        survivors.add(heart);
        continue;
      }
      // A non-powered Leha it touches is charmed: pulled toward Sima briefly.
      if (leha != null && now >= round.lehaPowerUntil) {
        final ddx = leha.x - heart.x;
        final ddy = leha.y - heart.y;
        if (ddx * ddx + ddy * ddy <=
            GameConstants.simaHeartHitRadius *
                GameConstants.simaHeartHitRadius) {
          leha.charmPullUntil = now + GameConstants.simaHeartPullMs;
          continue;
        }
      }
      survivors.add(heart);
    }
    round.hearts = survivors;
  }

  /// Refills Sima's spent heart charges one at a time.
  void rechargeHearts(int now) {
    final hunter = findPlayer(1);
    if (hunter == null || hunter.hunterKind != HunterKind.sima) return;
    if (hunter.heartCharges >= GameConstants.simaHeartMaxCharges) return;
    if (hunter.heartRechargeAt == 0 || now < hunter.heartRechargeAt) return;
    hunter.heartCharges += 1;
    hunter.heartRechargeAt =
        hunter.heartCharges >= GameConstants.simaHeartMaxCharges
            ? 0
            : now + GameConstants.simaHeartRechargeMs;
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
    final selectedPlayers = activePlayers
        .where((client) => client.slot == 0 || client.slot == 1)
        .toList();
    final canStart = sandboxMode
        ? selectedPlayers.isNotEmpty &&
            selectedPlayers.every((client) => client.ready)
        : hasLeha &&
            hasHunter &&
            selectedPlayers.every((client) => client.ready);

    if (!canStart) {
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
        ..hearts = []
        ..nextHeartId = 1
        ..portals = []
        ..magicCrystals = []
        ..magicChains = []
        ..nextMagicCrystalId = 1
        ..nextMagicChainId = 1
        ..wizardSaturation = 0
        ..pendingTrapRechargeAt = []
        ..pendingWebRechargeAt = []
        ..pendingCrystalRechargeAt = []
        ..clutch = null
        ..sarcophagi = _spawnSarcophagi()
        ..mummies = []
        ..shardsIntact = Set<String>.from(maze.amethystShards)
        ..chimes = []
        ..mushrooms = _spawnMushrooms()
        ..spores = []
        ..emberRocks = _initialEmberRocks()
        ..geysers = []
        ..sulfur = []
        ..nextEmberEntityId = 100
        ..nextGeyserAt = nowMs() + _geyserDelay()
        ..nextAmethystGrowAt =
            nowMs() + GameConstants.amethystShardGrowIntervalMs
        ..rafaelkiEaten = 0
        ..trails = {0: [], 1: []};
      maze.dynamicCover.clear();
      logos = switch (findPlayer(0)?.aspect) {
        LehaAspect.spider => _spawnRafaelki(),
        LehaAspect.wizard => <String>{},
        _ => _maze.createLogos(),
      };
      logos.removeWhere(maze.lava.contains);
      final hunter = findPlayer(1);
      if (hunter != null) {
        hunter
          ..hp = 100
          ..trapCharges = _trapChargesFor(hunter)
          ..trapCooldownUntil = 0
          ..barrelCooldownUntil = 0
          ..simaFemboyUntil = 0
          ..simaCooldownUntil = 0
          ..heartCharges = hunter.hunterKind == HunterKind.sima
              ? GameConstants.simaHeartMaxCharges
              : 0
          ..heartShotCooldownUntil = 0
          ..heartRechargeAt = 0
          ..invulnerableUntil = 0
          ..stunnedUntil = 0
          ..chainStunImmuneUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0
          ..scentMaskedUntil = 0;
      }
      final leha = findPlayer(0);
      if (leha != null) {
        leha
          ..webCharges =
              leha.aspect == LehaAspect.spider ? GameConstants.maxWebCharges : 0
          ..webCooldownUntil = 0
          ..portalCooldownUntil = 0
          ..magicChainCooldownUntil = 0
          ..crystalCharges = leha.aspect == LehaAspect.wizard
              ? GameConstants.wizardMaxCrystals
              : 0
          ..stunnedUntil = 0
          ..invulnerableUntil = 0
          ..blindUntil = 0
          ..charmPullUntil = 0
          ..webSlowedUntil = 0
          ..webPhaseUntil = 0
          ..scentMaskedUntil = 0;
      }
      logger.log({
        'event': 'start',
        'leha': _playerLog(leha, leha?.aspect.name ?? '—'),
        'hunter': _playerLog(hunter, hunter?.hunterKind.name ?? '—'),
        'logos': logos.length,
      });
    }
  }

  List<SarcophagusState> _spawnSarcophagi() {
    return maze.sarcophagi.map((key) {
      final parts = key.split(',').map(int.parse).toList();
      return SarcophagusState(x: parts[0], y: parts[1]);
    }).toList();
  }

  /// Seeds a few connected mushroom colonies instead of scattering individuals.
  List<MushroomState> _spawnMushrooms() {
    if (maze.biome != CaveBiome.amethyst) return [];
    final now = nowMs();
    final cells = _openFloorCells()..shuffle(_rng);
    final allowed = cells.map((p) => '${p.x},${p.y}').toSet();
    final selected = <String>{};
    final frontier = <Point<int>>[];
    for (final seed in cells) {
      if (frontier.length >= 3) break;
      if (frontier
          .every((p) => (p.x - seed.x).abs() + (p.y - seed.y).abs() >= 6)) {
        frontier.add(seed);
      }
    }
    const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    while (frontier.isNotEmpty &&
        selected.length < GameConstants.mushroomStartCount) {
      final cell = frontier.removeAt(_rng.nextInt(frontier.length));
      final key = '${cell.x},${cell.y}';
      if (!allowed.contains(key) || !selected.add(key)) continue;
      final neighbours = dirs
          .map((d) => Point(cell.x + d.x, cell.y + d.y))
          .where((p) =>
              allowed.contains('${p.x},${p.y}') &&
              !selected.contains('${p.x},${p.y}'))
          .toList()
        ..shuffle(_rng);
      frontier.addAll(neighbours.take(2));
    }
    return selected.map((key) {
      final p = key.split(',').map(int.parse).toList();
      final stage = _rng.nextInt(GameConstants.mushroomMaxStage + 1);
      return MushroomState(
        x: p[0],
        y: p[1],
        stage: stage,
        nextGrowAt: now +
            _rng.nextInt(stage == GameConstants.mushroomMaxStage
                ? GameConstants.mushroomMatureIntervalMs
                : GameConstants.mushroomGrowIntervalMs),
      );
    }).toList();
  }

  /// Interior open-floor cells away from spawns and tunnels.
  List<Point<int>> _openFloorCells() {
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    final cells = <Point<int>>[];
    for (var y = 1; y < maze.rows - 1; y++) {
      if (GameConstants.tunnelRows.contains(y)) continue;
      for (var x = 1; x < maze.cols - 1; x++) {
        if (GameConstants.tunnelCols.contains(x)) continue;
        if (maze.isWall(x, y) || starts.contains('$x,$y')) continue;
        cells.add(Point(x, y));
      }
    }
    return cells;
  }

  /// Fires a chime when a player steps onto an intact amethyst shard, shattering
  /// it and ringing out a pulse that reveals where they were.
  void resolveAmethystShard(PlayerConnection player, int now) {
    if (round.shardsIntact.isEmpty) return;
    final cx = player.x.floor(), cy = player.y.floor();
    final key = '$cx,$cy';
    if (!round.shardsIntact.remove(key)) return;
    round.chimes.add(ChimeState(x: cx + 0.5, y: cy + 0.5, firedAt: now));
  }

  void updateChimes(int now) {
    if (round.chimes.isEmpty) return;
    round.chimes
        .removeWhere((c) => now - c.firedAt >= GameConstants.chimeDurationMs);
  }

  /// Trampling a mushroom drops a single spore and resets it to a sprout — it is
  /// always passable and simply regrows.
  void resolveMushroomTrample(PlayerConnection player, int now) {
    if (round.mushrooms.isEmpty) return;
    final cx = player.x.floor(), cy = player.y.floor();
    for (final m in round.mushrooms) {
      if (m.x != cx || m.y != cy) continue;
      if (m.stage == GameConstants.mushroomMaxStage) {
        _burstSpores(cx, cy, now);
      } else {
        _addSpore(cx, cy, now);
      }
      m
        ..stage = 0
        ..nextGrowAt = now + GameConstants.mushroomGrowIntervalMs;
      break;
    }
  }

  void _addSpore(int x, int y, int now) {
    if (maze.isWall(x, y)) return;
    final expiresAt = now + GameConstants.mushroomSporeDurationMs;
    for (final s in round.spores) {
      if (s.x == x && s.y == y) {
        s.expiresAt = max(s.expiresAt, expiresAt);
        return;
      }
    }
    round.spores.add(SporeState(x: x, y: y, expiresAt: expiresAt));
  }

  void _burstSpores(int x, int y, int now) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        _addSpore(x + dx, y + dy, now);
      }
    }
  }

  /// Advances the mushroom colony: grows mushrooms, kills mature ones into spore
  /// bursts that spawn fresh sprouts nearby, and expires old spores.
  void updateMushrooms(int now) {
    if (maze.biome != CaveBiome.amethyst) return;

    final survivors = <MushroomState>[];
    for (final m in round.mushrooms) {
      if (now < m.nextGrowAt) {
        survivors.add(m);
        continue;
      }
      if (m.stage < GameConstants.mushroomMaxStage) {
        final nextStage = m.stage + 1;
        m
          ..stage = nextStage
          ..nextGrowAt = now +
              (nextStage == GameConstants.mushroomMaxStage
                  ? GameConstants.mushroomMatureIntervalMs
                  : GameConstants.mushroomGrowIntervalMs);
        survivors.add(m);
        continue;
      }
      // Mature mushroom dies into fog. Any new growth is resolved only when
      // those spores expire.
      _burstSpores(m.x, m.y, now);
    }
    round.mushrooms = survivors;

    final expired = round.spores.where((s) => now >= s.expiresAt).toList()
      ..shuffle(_rng);
    var births = 0;
    for (final spore in expired) {
      if (births >= GameConstants.mushroomSporeMaxBirthsPerTick ||
          round.mushrooms.length >= GameConstants.mushroomMaxCount) {
        break;
      }
      if (_growMushroomFromSpore(spore, now)) births++;
    }
    round.spores.removeWhere((s) => now >= s.expiresAt);
    maze.dynamicCover
      ..clear()
      ..addAll(round.spores.map((s) => '${s.x},${s.y}'));
  }

  /// Regrows one destructible shard along a colony frontier. Permanent wall
  /// sources restart growth even when players clear every floor shard.
  void updateAmethystShards(int now) {
    if (maze.biome != CaveBiome.amethyst || now < round.nextAmethystGrowAt) {
      return;
    }
    round.nextAmethystGrowAt = now + GameConstants.amethystShardGrowIntervalMs;
    if (round.shardsIntact.length >= GameConstants.amethystShardMaxCount) {
      return;
    }

    const dirs = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
    final groups = maze.amethystWallGroups
        .map((group) => group.map((key) {
              final xy = key.split(',').map(int.parse).toList();
              return Point(xy[0], xy[1]);
            }).toList())
        .toList();
    final shards = round.shardsIntact.map((key) {
      final xy = key.split(',').map(int.parse).toList();
      return Point(xy[0], xy[1]);
    }).toList();
    final counts = List<int>.filled(groups.length, 0);
    for (final shard in shards) {
      final group = _nearestAmethystGroup(shard, groups);
      if (group != null) counts[group]++;
    }
    final growthOrder = List<int>.generate(groups.length, (index) => index)
      ..sort((a, b) => counts[a].compareTo(counts[b]));

    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    // Try the emptiest colony first. If its local geometry is exhausted, fall
    // through to the next one rather than stalling all growth.
    for (final groupIndex in growthOrder) {
      final sources = groups[groupIndex];
      final localShards = shards
          .where((shard) => _nearestAmethystGroup(shard, groups) == groupIndex);
      final roots = <Point<int>>[...sources, ...localShards];
      final candidates = <Point<int>>[];
      final seen = <String>{};
      for (final root in roots) {
        for (final d in dirs) {
          final p = Point(root.x + d.x, root.y + d.y);
          final key = '${p.x},${p.y}';
          if (!seen.add(key) ||
              p.x <= 0 ||
              p.x >= maze.cols - 1 ||
              p.y <= 0 ||
              p.y >= maze.rows - 1 ||
              maze.isWall(p.x, p.y) ||
              starts.contains(key) ||
              round.shardsIntact.contains(key) ||
              GameConstants.tunnelRows.contains(p.y) ||
              GameConstants.tunnelCols.contains(p.x) ||
              !sources.any((source) =>
                  (source.x - p.x).abs() + (source.y - p.y).abs() <=
                  GameConstants.amethystShardSourceRadius)) {
            continue;
          }
          candidates.add(p);
        }
      }
      if (candidates.isEmpty) continue;
      final cell = candidates[_rng.nextInt(candidates.length)];
      round.shardsIntact.add('${cell.x},${cell.y}');
      return;
    }
  }

  int? _nearestAmethystGroup(Point<int> cell, List<List<Point<int>>> groups) {
    int? nearest;
    var bestDistance = 1 << 30;
    for (var index = 0; index < groups.length; index++) {
      final distance = groups[index]
          .map(
              (source) => (source.x - cell.x).abs() + (source.y - cell.y).abs())
          .reduce(min);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = index;
      }
    }
    return nearest;
  }

  /// An isolated spore has a 50% chance to leave a sprout. Every mushroom in
  /// the local colony divides that chance again, naturally thinning dense areas.
  bool _growMushroomFromSpore(SporeState spore, int now) {
    final key = '${spore.x},${spore.y}';
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    if (spore.x <= 0 ||
        spore.x >= maze.cols - 1 ||
        spore.y <= 0 ||
        spore.y >= maze.rows - 1 ||
        maze.isWall(spore.x, spore.y) ||
        starts.contains(key) ||
        GameConstants.tunnelRows.contains(spore.y) ||
        GameConstants.tunnelCols.contains(spore.x) ||
        round.mushrooms.any((m) => m.x == spore.x && m.y == spore.y)) {
      return false;
    }
    final nearby = round.mushrooms
        .where((m) =>
            (m.x - spore.x).abs() <= GameConstants.mushroomSpreadRadius &&
            (m.y - spore.y).abs() <= GameConstants.mushroomSpreadRadius)
        .length;
    final chance = GameConstants.mushroomSporeGrowChance / (nearby + 1);
    if (_rng.nextDouble() >= chance) return false;
    round.mushrooms.add(MushroomState(
      x: spore.x,
      y: spore.y,
      stage: 0,
      nextGrowAt: now + GameConstants.mushroomGrowIntervalMs,
    ));
    return true;
  }

  void releaseSlot(PlayerConnection client) {
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
      ..webCooldownUntil = 0
      ..portalCooldownUntil = 0
      ..stunnedUntil = 0
      ..webSlowedUntil = 0
      ..webPhaseUntil = 0;
  }

  void tick() {
    ensureRoundState();
    final now = nowMs();
    if (round.phase != GamePhase.playing) return;

    expireTraps(now);
    expireWebs(now);
    updateEmber(now);
    rechargeWebs(now);
    rechargeCrystals(now);
    rechargeHearts(now);
    updateBots(now);
    for (final client in clients.values) {
      if (client.slot == null) continue;
      updatePlayerState(client, now);
      movePlayer(client, GameConstants.tickMs / 1000);
      if (client.slot == 0) collectLogo(client);
      // Both Leha and the hunter can step through Wizard-Leha's portals.
      if (client.slot == 0 || client.slot == 1) resolvePortal(client, now);
      // Amethyst-biome floor reactions to whoever just moved.
      resolveAmethystShard(client, now);
      resolveMushroomTrample(client, now);
    }

    final leha = findPlayer(0);
    final hunter = findPlayer(1);
    if (leha != null) updateTrail(leha, now);
    if (hunter != null) updateTrail(hunter, now);
    updateBarrels(leha, now, GameConstants.tickMs / 1000);
    updateHearts(leha, now, GameConstants.tickMs / 1000);
    updateSarcophagi(now);
    updateMummies(now, GameConstants.tickMs / 1000);
    updateMushrooms(now);
    updateAmethystShards(now);
    updateChimes(now);
    updateMagicChains(now, GameConstants.tickMs);
    resolveCollision(leha, hunter, now);
    resolveTrap(leha, now);
    resolveClutch(hunter, now);
    if (round.phase != GamePhase.playing) return;

    final startedAt = round.startedAt;
    // Spider's Raffaello mode has no survival timer — only a hatched clutch
    // (Spider wins) or being caught (hunter wins) ends the round.
    if (findPlayer(0)?.aspect == LehaAspect.superLeha &&
        startedAt != null &&
        now - startedAt >= GameConstants.roundDurationMs) {
      endGame(0, 'Леха продержался 3 минуты.');
    }
  }

  int _geyserDelay() =>
      GameConstants.geyserMinIntervalMs +
      _rng.nextInt(GameConstants.geyserMaxIntervalMs -
          GameConstants.geyserMinIntervalMs +
          1);

  List<EmberRockState> _initialEmberRocks() {
    if (maze.biome != CaveBiome.ember) return [];
    final rocks = <EmberRockState>[];
    for (var stream = 0; stream < maze.lavaStreams.length; stream++) {
      final cell = _crossingLavaCellForStream(stream, occupied: rocks);
      if (cell != null) {
        rocks.add(EmberRockState(
          id: stream + 1,
          x: cell.x,
          y: cell.y,
          stream: stream,
        ));
      }
    }
    return rocks;
  }

  /// Picks a lava cell in [stream] that makes a usable stepping stone: it must
  /// have open ground on both sides across the stream so a player can step on
  /// from one bank and off onto the other.
  Point<int>? _crossingLavaCellForStream(int stream,
      {Iterable<EmberRockState> occupied = const []}) {
    if (stream < 0 || stream >= maze.lavaStreams.length) return null;
    final candidates = <Point<int>>[];
    for (final key in maze.lavaStreams[stream]) {
      final xy = key.split(',').map(int.parse).toList();
      final p = Point<int>(xy[0], xy[1]);
      // A stream is a single row, so the two banks are directly above/below.
      if (maze.isWall(p.x, p.y - 1) || maze.isWall(p.x, p.y + 1)) continue;
      if (maze.isLava(p.x, p.y - 1) || maze.isLava(p.x, p.y + 1)) continue;
      if (occupied.any((r) => r.x == p.x && r.y == p.y)) continue;
      candidates.add(p);
    }
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }

  void updateEmber(int now) {
    if (maze.biome != CaveBiome.ember) return;
    round.sulfur.removeWhere((cloud) => now >= cloud.expiresAt);
    maze.dynamicCover
      ..clear()
      ..addAll(round.sulfur.map((cloud) => '${cloud.x},${cloud.y}'));

    for (final rock in round.emberRocks) {
      // The sink timer only starts once a player has stepped onto the rock.
      if (rock.steppedSince == null &&
          clients.values
              .where((p) => p.slot != null)
              .any((p) => _circleOverlapsCell(p.x, p.y, rock.x, rock.y))) {
        rock.steppedSince = now;
      }
      final since = rock.steppedSince;
      if (since != null && now - since >= GameConstants.emberBridgeSinkMs) {
        rock.sinking = true;
      }
    }
    round.emberRocks.removeWhere((rock) {
      if (!rock.sinking) return false;
      // Keep the rock until the player's collision circle fully clears the
      // cell — not just their centre. Removing it the instant floor() flips
      // onto the bank leaves the circle still overlapping the (now solid) lava
      // cell, which wedges the player against the edge.
      return !clients.values
          .where((p) => p.slot != null)
          .any((p) => _circleOverlapsCell(p.x, p.y, rock.x, rock.y));
    });
    _ensureEmberCrossings();

    final erupting =
        round.geysers.where((geyser) => now >= geyser.eruptAt).toList();
    round.geysers.removeWhere((geyser) => now >= geyser.eruptAt);
    for (final geyser in erupting) {
      _eruptGeyser(geyser, now);
    }

    if (now >= round.nextGeyserAt) {
      _scheduleGeyser(now);
      round.nextGeyserAt = now + _geyserDelay();
    }
  }

  void _ensureEmberCrossings() {
    for (var stream = 0; stream < maze.lavaStreams.length; stream++) {
      final available = round.emberRocks.any((rock) => rock.stream == stream);
      if (available) continue;
      final cell = _crossingLavaCellForStream(stream, occupied: round.emberRocks);
      if (cell == null) continue;
      round.emberRocks.add(EmberRockState(
        id: round.nextEmberEntityId++,
        x: cell.x,
        y: cell.y,
        stream: stream,
      ));
    }
  }

  void _scheduleGeyser(int now) {
    final target = _randomEmberFloorCell();
    if (target == null) return;
    round.geysers.add(EmberGeyserState(
      id: round.nextEmberEntityId++,
      x: target.x,
      y: target.y,
      eruptAt: now + GameConstants.geyserWarningMs,
    ));
  }

  Point<int>? _randomEmberFloorCell() {
    final cells = <Point<int>>[];
    for (var y = 1; y < maze.rows - 1; y++) {
      for (var x = 1; x < maze.cols - 1; x++) {
        if (maze.isWall(x, y) || maze.isLava(x, y)) continue;
        if (round.emberRocks.any((r) => r.x == x && r.y == y)) continue;
        if (_emberObjectAt(x, y)) continue;
        cells.add(Point(x, y));
      }
    }
    if (cells.isEmpty) return null;
    return cells[_rng.nextInt(cells.length)];
  }

  void _eruptGeyser(EmberGeyserState geyser, int now) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final x = geyser.x + dx, y = geyser.y + dy;
        if (maze.isWall(x, y) || maze.isLava(x, y)) continue;
        round.sulfur.removeWhere((cloud) => cloud.x == x && cloud.y == y);
        round.sulfur.add(SulfurCloudState(
          x: x,
          y: y,
          expiresAt: now + GameConstants.sulfurDurationMs,
        ));
      }
    }
  }

  bool _emberObjectAt(int x, int y) =>
      clients.values
          .where((p) => p.slot != null)
          .any((p) => p.x.floor() == x && p.y.floor() == y) ||
      round.traps.any((e) => e.x == x && e.y == y) ||
      round.webs.any((e) => e.x == x && e.y == y) ||
      round.portals.any((e) => e.x == x && e.y == y) ||
      round.magicCrystals.any((e) => e.x == x && e.y == y) ||
      round.mushrooms.any((e) => e.x == x && e.y == y) ||
      round.geysers.any((e) => e.x == x && e.y == y) ||
      (round.clutch?.x == x && round.clutch?.y == y);

  /// Hatches the Spider's clutch (she wins) or, if the hunter reaches it first,
  /// destroys it and respawns a fresh batch of Raffaellos to try again.
  void updateSarcophagi(int now) {
    if (round.sarcophagi.isEmpty) return;
    final players =
        clients.values.where((client) => client.slot != null).toList();
    for (final sarcophagus in round.sarcophagi) {
      if (!sarcophagus.hasMummy) {
        sarcophagus.playersInRadius.clear();
        continue;
      }
      final current = <String>{};
      final sx = sarcophagus.x + 0.5;
      final sy = sarcophagus.y + 0.5;
      for (final player in players) {
        final dx = player.x - sx;
        final dy = player.y - sy;
        if (dx * dx + dy * dy <=
            GameConstants.sarcophagusTriggerRadius *
                GameConstants.sarcophagusTriggerRadius) {
          current.add(player.id);
        }
      }
      final entered =
          current.difference(sarcophagus.playersInRadius).isNotEmpty;
      if (entered) {
        if (!sarcophagus.cracked) {
          sarcophagus.cracked = true;
        } else {
          _releaseMummy(sarcophagus);
          current.clear();
        }
      }
      sarcophagus.playersInRadius
        ..clear()
        ..addAll(current);
    }
    // A flushed-out lair is now an open, destroyed block — drop it.
    round.sarcophagi.removeWhere((s) => !s.hasMummy);
  }

  void _releaseMummy(SarcophagusState sarcophagus) {
    sarcophagus
      ..hasMummy = false
      ..cracked = false;
    round.mummies.add(MummyState(
      x: sarcophagus.x + 0.5,
      y: sarcophagus.y + 0.5,
    ));
    // The sandstone block the mummy climbs out of is destroyed for good.
    maze.destroyWall(sarcophagus.x, sarcophagus.y);
  }

  void updateMummies(int now, double dt) {
    if (round.mummies.isEmpty) return;
    final survivors = <MummyState>[];
    for (final mummy in round.mummies) {
      _resolveMummyHits(mummy, now);
      if (mummy.fleeing) {
        _ensureMummyFleeTarget(mummy);
        _moveMummyToTarget(
            mummy,
            GameConstants.baseSpeed *
                GameConstants.mummyFleeSpeedMultiplier *
                dt,
            now);
        if (_mummyReachedTarget(mummy)) {
          final tx = mummy.targetX, ty = mummy.targetY;
          // Dive into the sandstone block: it becomes a fresh sealed lair.
          if (tx != null &&
              ty != null &&
              maze.isWall(tx, ty) &&
              _sarcophagusAt(tx, ty) == null) {
            round.sarcophagi.add(SarcophagusState(x: tx, y: ty));
          }
          continue;
        }
      } else {
        final target = _nearestPlayer(mummy);
        if (target != null) {
          _moveMummyToward(
              mummy,
              Point(target.x, target.y),
              GameConstants.baseSpeed *
                  GameConstants.mummyChaseSpeedMultiplier *
                  dt,
              now);
        }
      }
      survivors.add(mummy);
    }
    round.mummies = survivors;
  }

  void _resolveMummyHits(MummyState mummy, int now) {
    for (final player
        in clients.values.where((client) => client.slot != null)) {
      final dx = player.x - mummy.x;
      final dy = player.y - mummy.y;
      if (dx * dx + dy * dy >
          GameConstants.mummyHitRadius * GameConstants.mummyHitRadius) {
        continue;
      }
      if ((mummy.hitCooldownUntil[player.id] ?? 0) > now) continue;
      player
        ..stunnedUntil =
            max(player.stunnedUntil, now + GameConstants.mummyStunMs)
        ..direction = null
        ..nextDirection = null
        ..stopRequested = false;
      mummy.hitCooldownUntil[player.id] = now + GameConstants.mummyStunMs;
      if (!mummy.fleeing) {
        mummy.fleeing = true;
        mummy.targetX = null;
        mummy.targetY = null;
      }
    }
  }

  PlayerConnection? _nearestPlayer(MummyState mummy) {
    PlayerConnection? best;
    var bestD2 = double.infinity;
    for (final player
        in clients.values.where((client) => client.slot != null)) {
      final dx = player.x - mummy.x;
      final dy = player.y - mummy.y;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD2) {
        bestD2 = d2;
        best = player;
      }
    }
    return best;
  }

  void _ensureMummyFleeTarget(MummyState mummy) {
    if (mummy.targetX != null && mummy.targetY != null) return;
    // Avoid blocks another mummy is already heading for or sealed inside.
    final reserved = <String>{
      for (final s in round.sarcophagi) '${s.x},${s.y}',
      for (final m in round.mummies)
        if (m != mummy && m.targetX != null && m.targetY != null)
          '${m.targetX},${m.targetY}',
    };
    final candidates = maze.sandstoneWalls().where((p) {
      if (reserved.contains('${p.x},${p.y}')) return false;
      final dx = mummy.x - (p.x + 0.5);
      final dy = mummy.y - (p.y + 0.5);
      return dx * dx + dy * dy > 1;
    }).toList();
    if (candidates.isNotEmpty) {
      // Dive into a randomly chosen sandstone wall.
      final target = candidates[_rng.nextInt(candidates.length)];
      mummy
        ..targetX = target.x
        ..targetY = target.y;
      return;
    }
    final tunnels = <Point<int>>[];
    for (final y in GameConstants.tunnelRows) {
      for (var x = 0; x < maze.cols; x++) {
        if (!maze.isWall(x, y)) tunnels.add(Point(x, y));
      }
    }
    for (final x in GameConstants.tunnelCols) {
      for (var y = 0; y < maze.rows; y++) {
        if (!maze.isWall(x, y)) tunnels.add(Point(x, y));
      }
    }
    final target = tunnels.isEmpty
        ? Point(mummy.x.floor(), mummy.y.floor())
        : tunnels[_rng.nextInt(tunnels.length)];
    mummy
      ..targetX = target.x
      ..targetY = target.y;
  }

  SarcophagusState? _sarcophagusAt(int? x, int? y) {
    if (x == null || y == null) return null;
    for (final sarcophagus in round.sarcophagi) {
      if (sarcophagus.x == x && sarcophagus.y == y) return sarcophagus;
    }
    return null;
  }

  bool _mummyReachedTarget(MummyState mummy) {
    final tx = mummy.targetX, ty = mummy.targetY;
    if (tx == null || ty == null) return false;
    // A wall lair can't be stood on, so reaching the floor cell orthogonally
    // adjacent to the block counts as diving in.
    if (maze.isWall(tx, ty)) {
      final mcx = mummy.x.floor(), mcy = mummy.y.floor();
      return (mcx - tx).abs() + (mcy - ty).abs() == 1;
    }
    final dx = mummy.x - (tx + 0.5);
    final dy = mummy.y - (ty + 0.5);
    return dx * dx + dy * dy <=
        GameConstants.mummyHideRadius * GameConstants.mummyHideRadius;
  }

  void _moveMummyToTarget(MummyState mummy, double dist, int now) {
    final tx = mummy.targetX, ty = mummy.targetY;
    if (tx == null || ty == null) return;
    _moveMummyToward(mummy, Point(tx + 0.5, ty + 0.5), dist, now);
  }

  void _moveMummyToward(
      MummyState mummy, Point<double> target, double dist, int now) {
    var dx = target.x - mummy.x;
    var dy = target.y - mummy.y;
    var len = sqrt(dx * dx + dy * dy);
    if (len < 1e-5) return;
    final start = Point(mummy.x.floor(), mummy.y.floor());
    final goal = Point(target.x.floor(), target.y.floor());
    // A wall lair can't be walked onto, so route to the floor cell beside it.
    final goalIsWall = maze.isWall(goal.x, goal.y);
    final step = _bfsFirstStep(
        start,
        goalIsWall
            ? (x, y) => (x - goal.x).abs() + (y - goal.y).abs() == 1
            : (x, y) => x == goal.x && y == goal.y);
    if (step != null) {
      final stepTarget = Point(
        start.x + step.dx + 0.5,
        start.y + step.dy + 0.5,
      );
      dx = stepTarget.x - mummy.x;
      dy = stepTarget.y - mummy.y;
      len = sqrt(dx * dx + dy * dy);
      if (len < 1e-5) return;
    }
    _tryMoveMummy(mummy, dx / len * dist, dy / len * dist, now);
    _wrapMummyTunnel(mummy);
  }

  bool _tryMoveMummy(MummyState mummy, double dx, double dy, int now) {
    if (_mummyPositionOpen(mummy.x + dx, mummy.y + dy)) {
      mummy
        ..x += dx
        ..y += dy;
      return true;
    }
    if (_mummyPositionOpen(mummy.x + dx, mummy.y)) {
      mummy.x += dx;
      return true;
    }
    if (_mummyPositionOpen(mummy.x, mummy.y + dy)) {
      mummy.y += dy;
      return true;
    }
    return false;
  }

  bool _mummyPositionOpen(double x, double y) {
    if (GameConstants.tunnelRows.contains(y.floor()) &&
        (x < 0 || x >= maze.cols)) {
      return true;
    }
    if (GameConstants.tunnelCols.contains(x.floor()) &&
        (y < 0 || y >= maze.rows)) {
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
        final closestX = x.clamp(cx.toDouble(), cx + 1.0);
        final closestY = y.clamp(cy.toDouble(), cy + 1.0);
        final ddx = x - closestX;
        final ddy = y - closestY;
        if (ddx * ddx + ddy * ddy < r * r) return false;
      }
    }
    return true;
  }

  void _wrapMummyTunnel(MummyState mummy) {
    if (GameConstants.tunnelRows.contains(mummy.y.floor())) {
      if (mummy.x < -0.35) mummy.x = maze.cols + 0.35;
      if (mummy.x > maze.cols + 0.35) mummy.x = -0.35;
    }
    if (GameConstants.tunnelCols.contains(mummy.x.floor())) {
      if (mummy.y < -0.35) mummy.y = maze.rows + 0.35;
      if (mummy.y > maze.rows + 0.35) mummy.y = -0.35;
    }
  }

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
      leaves: maze.leafLitter.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      crackedWalls: maze.crackedWalls.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      biome: maze.biome,
      stoneSeed: maze.stoneSeed,
      crystals: maze.crystals.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      quicksand: maze.quicksand.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      amethystWalls: maze.amethystWalls.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      amethystShards: round.shardsIntact.map((key) {
        final parts = key.split(',').map(int.parse).toList();
        return Vec2i(parts[0], parts[1]);
      }).toList(),
      chimes: round.chimes
          .map((c) => ChimeDto(
                x: _round3(c.x),
                y: _round3(c.y),
                progress: _round3(
                    ((now - c.firedAt) / GameConstants.chimeDurationMs)
                        .clamp(0.0, 1.0)),
              ))
          .toList(),
      mushrooms: round.mushrooms
          .map((m) => MushroomDto(x: m.x, y: m.y, stage: m.stage))
          .toList(),
      spores: round.spores.map((s) => Vec2i(s.x, s.y)).toList(),
      lava: [
        for (var stream = 0; stream < maze.lavaStreams.length; stream++)
          for (final key in maze.lavaStreams[stream])
            LavaCellDto(
              x: int.parse(key.split(',')[0]),
              y: int.parse(key.split(',')[1]),
              stream: stream,
            ),
      ],
      emberRocks: round.emberRocks
          .map((rock) => EmberRockDto(
                id: rock.id,
                x: rock.x,
                y: rock.y,
                stream: rock.stream,
                // Every surfaced rock is a steppable platform.
                bridge: true,
                sinking: rock.sinking,
              ))
          .toList(),
      geysers: round.geysers
          .map((geyser) => EmberGeyserDto(
                id: geyser.id,
                x: geyser.x,
                y: geyser.y,
                progress: _round3((1 -
                        (geyser.eruptAt - now) / GameConstants.geyserWarningMs)
                    .clamp(0.0, 1.0)),
              ))
          .toList(),
      sulfur: round.sulfur
          .map((cloud) => SulfurDto(
                x: cloud.x,
                y: cloud.y,
                life: _round3(
                    ((cloud.expiresAt - now) / GameConstants.sulfurDurationMs)
                        .clamp(0.0, 1.0)),
              ))
          .toList(),
      illusions: visibleIllusionsFor(viewer, now),
      sarcophagi: round.sarcophagi
          .map((s) => SarcophagusDto(
                x: s.x,
                y: s.y,
                cracked: s.cracked,
                hasMummy: s.hasMummy,
              ))
          .toList(),
      mummies: round.mummies
          .map((m) => MummyDto(
                x: _round3(m.x),
                y: _round3(m.y),
                fleeing: m.fleeing,
              ))
          .toList(),
      enabledBiomes: enabledBiomes.toList(),
      sandboxMode: sandboxMode,
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
      hearts: round.hearts
          .map((h) => HeartDto(
                x: _round3(h.x),
                y: _round3(h.y),
                impact: h.impactUntil != 0,
              ))
          .toList(),
      portals: visiblePortalsFor(viewer),
      magicCrystals: round.magicCrystals
          .map((crystal) => MagicCrystalDto(
                id: crystal.id,
                x: crystal.x,
                y: crystal.y,
                fallen: crystal.fallen,
                burstProgress: crystal.burstAt == 0
                    ? 1
                    : _round3(((now - crystal.burstAt) / 700).clamp(0.0, 1.0)),
              ))
          .toList(),
      magicChains: _magicChainsForSnapshot(),
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
            now >= viewer.stunnedUntil,
        trapCooldownMs: 0,
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
        comingOutAvailable: viewer.slot == 1 &&
            viewer.hunterKind == HunterKind.sima &&
            round.phase == GamePhase.playing &&
            now >= viewer.stunnedUntil &&
            now >= viewer.heartShotCooldownUntil &&
            viewer.heartCharges > 0,
        comingOutCharges:
            viewer.slot == 1 && viewer.hunterKind == HunterKind.sima
                ? viewer.heartCharges
                : 0,
        comingOutCooldownMs:
            viewer.slot == 1 && viewer.hunterKind == HunterKind.sima
                ? max(0, viewer.heartShotCooldownUntil - now)
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
        wizardSaturation: _round3(round.wizardSaturation),
        magicChainCooldownMs: viewer.aspect == LehaAspect.wizard
            ? max(0, viewer.magicChainCooldownUntil - now)
            : 0,
        magicCrystalCharges:
            viewer.slot == 0 && viewer.aspect == LehaAspect.wizard
                ? viewer.crystalCharges
                : 0,
        magicCrystalAvailable: magicCrystalAvailableFor(viewer, now),
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

    // Heart charm (Камингаут hit): a non-powered Leha is dragged straight
    // toward Sima at half speed, overriding his input, for a brief moment.
    if (player.slot == 0 && now >= round.lehaPowerUntil && now < player.charmPullUntil) {
      final sima = findPlayer(1);
      if (sima != null && sima.hunterKind == HunterKind.sima) {
        _charmMove(player, sima, dt, now);
        _wrapTunnel(player);
        resolveWebContact(player, now);
        consumePassedWallWeb(player);
        return;
      }
    }

    var distance = player.speed * dt;
    final requested = player.nextDirection;
    if (requested == null) {
      player.direction = null;
      return;
    }

    // Sima's "Фембой" form: while it's up and she can see a non-powered Leha,
    // any movement that carries him away from her is slowed by half.
    if (player.slot == 0 && now >= round.lehaPowerUntil) {
      final sima = _activeSima(now);
      if (sima != null &&
          maze.hasLineOfSight(playerPos(player), playerPos(sima))) {
        final awayX = player.x - sima.x;
        final awayY = player.y - sima.y;
        if (requested.dx * awayX + requested.dy * awayY > 0) {
          distance *= GameConstants.simaSlowFactor;
        }
      }
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
    if (player.slot == 1 && now < player.webSlowedUntil) base *= 0.5;
    // Quicksand bogs down anyone walking through it.
    if (maze.isQuicksand(player.x.floor(), player.y.floor())) {
      base *= GameConstants.quicksandSlowFactor;
    }
    // Amethyst spores slow anyone wading through the fog.
    if (round.spores.any((spore) =>
        spore.x == player.x.floor() && spore.y == player.y.floor())) {
      base *= GameConstants.mushroomSporeSlowFactor;
    }
    if (player.slot == 1 && _pointOnMagicChain(player.x, player.y, 0.18)) {
      base *= GameConstants.wizardChainSlowFactor;
    }
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
    if (player.aspect == LehaAspect.wizard) return;
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
        if (maze.isWall(x, y) || maze.isLava(x, y) || spawns.contains(key)) {
          continue;
        }
        open.add(key);
      }
    }
    open.shuffle(_rng);
    return open.take(GameConstants.rafaelkiCount).toSet();
  }

  /// Spider lays an egg clutch once she's eaten enough Raffaellos. Allowed on
  /// floor and in bushes, but not on walls or webs. One clutch at a time.
  void layClutch(PlayerConnection client, [double? targetX, double? targetY]) {
    if (round.phase != GamePhase.playing) return;
    if (client.slot != 0 || client.aspect != LehaAspect.spider) return;
    if (round.clutch != null) return;
    if (round.rafaelkiEaten < GameConstants.rafaelkiNeeded) return;
    final targeted =
        _targetCell(client, targetX, targetY, SkillTargetRange.clutch);
    if (targetX != null && targeted == null) return;
    final cell = targeted ?? centerCell(client);
    if (maze.isWall(cell.x, cell.y) ||
        maze.isLava(cell.x, cell.y) ||
        round.emberRocks.any((r) => r.x == cell.x && r.y == cell.y)) {
      return;
    }
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
    // No scent is left while hiding in any cover (bush, amethyst spores, sulfur
    // cloud), and the mask lingers for a grace period after breaking cover so
    // the victim leaves no footprints at all for a short while — the gap stays
    // invisible even after the window passes, since no points are ever laid.
    if (maze.conceals(player.x.floor(), player.y.floor())) {
      player.scentMaskedUntil = now + GameConstants.scentMaskGraceMs;
      return;
    }
    if (now < player.scentMaskedUntil) return;
    final trail = round.trails[slot] ?? <TrailPoint>[];
    final last = trail.isEmpty ? null : trail.last;
    // Add a new point only when player moved far enough — keeps point count manageable.
    if (last != null &&
        sqrt(pow(last.x - player.x, 2) + pow(last.y - player.y, 2)) < 0.35) {
      return;
    }
    // Crossing dry leaf litter leaves a "loud" footprint: it lasts longer and
    // the opponent reads it from anywhere on the map.
    final loud = maze.isLeafLitter(player.x.floor(), player.y.floor());
    trail.add(TrailPoint(
        x: _round3(player.x), y: _round3(player.y), at: now, loud: loud));
    round.trails[slot] =
        trail.where((point) => now - point.at <= _trailLifetime(point)).toList();
  }

  int _trailLifetime(TrailPoint point) => point.loud
      ? GameConstants.loudTrailLifetimeMs
      : GameConstants.trailLifetimeMs;

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
    // Only sprung traps clear (after their brief "caught!" display); un-sprung
    // traps persist until Leha triggers them or Bakhirkin collects them.
    round.traps.removeWhere((trap) => now >= trap.expiresAt);
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
      // A sprung trap is spent — its charge is not refunded.
      round.traps[trapIndex]
        ..triggeredAt = now
        ..expiresAt = now + GameConstants.trapTriggeredDisplayMs;
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

  void _scheduleCrystalRecharge(PlayerConnection wizard, int now) {
    round.pendingCrystalRechargeAt
        .add(now + GameConstants.wizardCrystalCooldownMs);
    wizard.magicChainCooldownUntil =
        round.pendingCrystalRechargeAt.reduce(min);
  }

  void rechargeCrystals(int now) {
    final ready =
        round.pendingCrystalRechargeAt.where((time) => now >= time).length;
    if (ready == 0) return;
    round.pendingCrystalRechargeAt.removeWhere((time) => now >= time);
    final wizard = findPlayer(0);
    if (wizard != null && wizard.aspect == LehaAspect.wizard) {
      wizard.crystalCharges =
          min(GameConstants.wizardMaxCrystals, wizard.crystalCharges + ready);
      wizard.magicChainCooldownUntil = round.pendingCrystalRechargeAt.isEmpty
          ? 0
          : round.pendingCrystalRechargeAt.reduce(min);
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
    if (sandboxMode) return;
    round
      ..phase = GamePhase.ended
      ..endedAt = nowMs()
      ..winnerSlot = winnerSlot
      ..reason = reason;
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

  Point<int>? _targetCell(
      PlayerConnection player, double? x, double? y, double radius) {
    if (x == null || y == null) return null;
    final dx = x - player.x;
    final dy = y - player.y;
    if (dx * dx + dy * dy > radius * radius) return null;
    final cell = Point<int>(x.floor(), y.floor());
    if (cell.x < 0 ||
        cell.x >= maze.cols ||
        cell.y < 0 ||
        cell.y >= maze.rows) {
      return null;
    }
    return cell;
  }

  void updateAim(PlayerConnection player, double? x, double? y) {
    if (x == null || y == null || player.slot == null) return;
    final dx = x - player.x;
    final dy = y - player.y;
    if (dx.abs() < 0.05 && dy.abs() < 0.05) return;
    final horizontal = dx.abs() > dy.abs() * 2 ? dx.sign : 0;
    final vertical = dy.abs() > dx.abs() * 2 ? dy.sign : 0;
    player.lastDirection = switch ((horizontal, vertical, dx.sign, dy.sign)) {
      (1, 0, _, _) => MoveDirection.right,
      (-1, 0, _, _) => MoveDirection.left,
      (0, 1, _, _) => MoveDirection.down,
      (0, -1, _, _) => MoveDirection.up,
      (_, _, 1, 1) => MoveDirection.downRight,
      (_, _, 1, -1) => MoveDirection.upRight,
      (_, _, -1, 1) => MoveDirection.downLeft,
      _ => MoveDirection.upLeft,
    };
  }

  bool canMoveFrom(PlayerConnection player, MoveDirection direction) {
    final cell = centerCell(player);
    final nextX = (cell.x + direction.dx).round();
    final nextY = (cell.y + direction.dy).round();
    if (player.slot == 0 &&
        player.aspect == LehaAspect.spider &&
        maze.isWall(nextX, nextY)) {
      return consumeWebBridge(cell, Point(nextX, nextY), preview: true);
    }
    return !maze.isWall(nextX, nextY) && _emberCellPassable(nextX, nextY);
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
    if (maze.biome != CaveBiome.ember &&
        GameConstants.tunnelCols.contains(x.floor()) &&
        (y < 0 || y >= maze.rows)) {
      return true;
    }

    final r = GameConstants.collisionRadius;
    final minCx = (x - r).floor();
    final maxCx = (x + r).ceil();
    final minCy = (y - r).floor();
    final maxCy = (y + r).ceil();

    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        final terrainBlocked =
            maze.isWall(cx, cy) || !_emberCellPassable(cx, cy);
        if (!terrainBlocked) continue;
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

  bool _emberCellPassable(int x, int y) {
    if (!maze.isLava(x, y)) return true;
    // A lava cell is only passable while a surfaced rock occupies it.
    return round.emberRocks.any((rock) => rock.x == x && rock.y == y);
  }

  LobbyDto lobbyState() {
    return LobbyDto(
      roles: [
        for (var slot = 0; slot < GameConstants.roles.length; slot += 1)
          _roleState(slot),
      ],
      spectators: clients.values.where((client) => client.slot == null).length,
      users: clients.values
          .map((client) => ConnectedUserDto(
                id: client.id,
                name: client.name.trim().isEmpty
                    ? (client.isBot ? 'Бот' : 'Игрок ${client.id}')
                    : client.name.trim(),
                role: client.role,
                bot: client.isBot,
              ))
          .toList(),
    );
  }

  RoleStateDto _roleState(int slot) {
    final player =
        clients.values.where((client) => client.slot == slot).firstOrNull;
    return RoleStateDto(
      role: GameConstants.roles[slot],
      slot: slot,
      taken: player != null,
      ready: player?.ready ?? false,
      playerId: player?.id,
      aspect: slot == 0 ? player?.aspect ?? LehaAspect.superLeha : null,
      hunterKind: slot == 1 ? player?.hunterKind ?? HunterKind.bakhirkin : null,
      bot: player?.isBot ?? false,
    );
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
    if (maze.conceals(c.x, c.y) &&
        !maze.conceals(viewer.x.floor(), viewer.y.floor())) {
      return null;
    }
    final tp = Point(c.x + 0.5, c.y + 0.5);
    if (maze.hasXrayVisibility(vp, tp) || maze.hasLineOfSight(vp, tp)) {
      return dto;
    }
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

  /// Crystal mirror projections visible to [viewer]. Each crystal projects every
  /// active player onto the line through the crystal that is perpendicular to
  /// the player→crystal ray, at the crystal-to-player distance. A projection is
  /// dropped if a wall sits between it and the crystal, and (like a real player)
  /// only shows when the viewer has a clear line on it.
  /// Opacity fades from full at [crystalIllusionFadeStart] to nothing at
  /// [crystalIllusionMaxRange].
  List<IllusionDto> visibleIllusionsFor(PlayerConnection viewer, int now) {
    if (maze.crystals.isEmpty) return const [];
    final vp = playerPos(viewer);
    final viewerSees = viewer.slot != null;
    final players =
        clients.values.where((p) => p.slot != null).toList(growable: false);
    final result = <IllusionDto>[];
    for (final key in maze.crystals) {
      final parts = key.split(',');
      final cc = Point(int.parse(parts[0]) + 0.5, int.parse(parts[1]) + 0.5);
      for (final p in players) {
        final pp = playerPos(p);
        final toCrystal = Point(cc.x - pp.x, cc.y - pp.y);
        final d = sqrt(toCrystal.x * toCrystal.x + toCrystal.y * toCrystal.y);
        if (d < 0.5 || d >= GameConstants.crystalIllusionCullRange) continue;
        final perp = Point(-toCrystal.y / d, toCrystal.x / d);
        final opacity = d <= GameConstants.crystalIllusionFadeStart
            ? 1.0
            : (1.0 -
                    (d - GameConstants.crystalIllusionFadeStart) /
                        (GameConstants.crystalIllusionMaxRange -
                            GameConstants.crystalIllusionFadeStart))
                .clamp(0.0, 1.0);
        for (final side in const [-1.0, 1.0]) {
          final ix = cc.x + perp.x * d * side;
          final iy = cc.y + perp.y * d * side;
          if (ix < 0 || ix >= maze.cols || iy < 0 || iy >= maze.rows) continue;
          final tp = Point(ix, iy);
          // A wall between the crystal and the projection hides it.
          if (!maze.hasLineOfSight(cc, tp)) continue;
          // The viewer always sees their own illusions (so they can recognise
          // their mirror image); for everyone else it's seen like any character
          // — the viewer needs a clear line on it.
          final own = viewerSees && p.slot == viewer.slot;
          if (viewerSees &&
              !own &&
              !(maze.hasLineOfSight(vp, tp) ||
                  maze.hasXrayVisibility(vp, tp))) {
            continue;
          }
          result.add(IllusionDto(
            x: _round3(ix),
            y: _round3(iy),
            slot: p.slot,
            opacity: _round3(opacity),
            aspect: p.slot == 0 ? p.aspect : null,
            hunterKind: p.slot == 1 ? p.hunterKind : null,
            powered: p.slot == 0 && now < round.lehaPowerUntil,
            femboy: p.slot == 1 &&
                p.hunterKind == HunterKind.sima &&
                now < p.simaFemboyUntil,
            own: own,
          ));
        }
      }
    }
    return result;
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
    if (viewer.slot != 0) return 0;
    return switch (viewer.aspect) {
      LehaAspect.superLeha => 0,
      LehaAspect.spider => viewer.webCharges >= GameConstants.maxWebCharges
          ? 0
          : max(0, viewer.webCooldownUntil - now),
      LehaAspect.wizard => max(0, viewer.portalCooldownUntil - now),
    };
  }

  int abilityChargesFor(PlayerConnection viewer) {
    if (viewer.slot != 0) return 0;
    return switch (viewer.aspect) {
      LehaAspect.superLeha => 0,
      LehaAspect.spider => viewer.webCharges,
      LehaAspect.wizard => max(0, 2 - round.portals.length),
    };
  }

  bool magicCrystalAvailableFor(PlayerConnection viewer, int now) {
    if (viewer.slot != 0 ||
        viewer.aspect != LehaAspect.wizard ||
        round.phase != GamePhase.playing ||
        now < viewer.stunnedUntil) {
      return false;
    }
    if (viewer.crystalCharges > 0) return true;
    return round.magicCrystals.any((crystal) {
      final dx = crystal.x + 0.5 - viewer.x;
      final dy = crystal.y + 0.5 - viewer.y;
      return dx * dx + dy * dy <= 0.85 * 0.85;
    });
  }

  PlayerDto serializePlayer(PlayerConnection player, int now) {
    final aspect = player.slot == 0 ? player.aspect : null;
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
      charmed: player.slot == 0 &&
          now >= round.lehaPowerUntil &&
          now < player.charmPullUntil,
      facing: player.lastDirection,
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
    final slot = viewer.slot;
    if (slot == null) return const [];
    final sourceSlot = slot == 1 ? 0 : 1;
    final result = <TrailPointDto>[];
    // Leha only reads the hunter's ordinary scent while powered; the hunter
    // always smells Leha's. Loud leaf-litter footprints are the exception —
    // they ring out across the map to the opponent regardless of power state.
    final scentGated = slot == 0 && now >= round.lehaPowerUntil;
    for (final point in trailPointsForSlot(sourceSlot, now)) {
      if (point.loud) {
        result.add(point);
      } else if (!scentGated && canViewerSeeTrailPoint(viewer, point)) {
        result.add(point);
      }
    }
    // Your own loud leaf-litter footprints — shown back to you so you can see
    // the track you're leaving for the opponent to follow.
    result.addAll(trailPointsForSlot(slot, now).where((point) => point.loud));
    return result;
  }

  List<TrailPointDto> trailPointsForSlot(int slot, int now) {
    return (round.trails[slot] ?? const <TrailPoint>[])
        .map((point) {
          final age = now - point.at;
          final lifetime = _trailLifetime(point);
          if (age > lifetime) return null;
          // Linear fade: 1.0 when fresh, 0.0 when expired.
          final alpha = 1.0 - age / lifetime;
          return TrailPointDto(
              x: point.x, y: point.y, alpha: alpha, loud: point.loud);
        })
        .whereType<TrailPointDto>()
        .toList();
  }

  bool canViewerSeeTrailPoint(PlayerConnection viewer, TrailPointDto point) {
    final vp = playerPos(viewer);
    final tp = Point(point.x, point.y);
    final distance = sqrt(pow(vp.x - tp.x, 2) + pow(vp.y - tp.y, 2));
    // A loud leaf-litter footprint rings out across the whole map — the
    // opponent always picks it up, no scent range or line-of-sight needed.
    if (point.loud) return true;
    // Hunter smells Leha's trail within scentRadius — no line-of-sight needed.
    // Ice crystals dampen the scent: signals near a crystal are not shown.
    if (viewer.slot == 1) {
      if (distance > GameConstants.trailScentRadius) return false;
      return !_nearCrystal(tp);
    }
    // Leha (powered) sees trail within visibility radius or with direct LOS.
    if (distance <= GameConstants.trailVisibilityRadius) return true;
    return maze.hasLineOfSight(vp, tp);
  }

  /// Whether a point lies within the scent-dampening field of any ice crystal.
  bool _nearCrystal(Point<double> p) {
    if (maze.crystals.isEmpty) return false;
    const r = GameConstants.crystalScentDampenRadius;
    for (final key in maze.crystals) {
      final parts = key.split(',');
      final cx = int.parse(parts[0]) + 0.5;
      final cy = int.parse(parts[1]) + 0.5;
      final dx = cx - p.x;
      final dy = cy - p.y;
      if (dx * dx + dy * dy <= r * r) return true;
    }
    return false;
  }

  bool canSeePlayer(PlayerConnection viewer, PlayerConnection target, int now) {
    if (viewer == target) return true;
    if (isGhost(viewer, now) || isGhost(target, now)) return true;
    final vp = playerPos(viewer);
    final tp = playerPos(target);
    // A target hiding in a bush can't be x-rayed; direct line of sight only
    // works when the viewer is in a bush too (otherwise the bush conceals).
    if (maze.conceals(target.x.floor(), target.y.floor())) {
      if (!maze.conceals(viewer.x.floor(), viewer.y.floor())) return false;
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

    // Teleport whenever both portals are open and the player freshly steps onto
    // one — passing through is free; the cooldown is on laying portals instead.
    if (round.portals.length != 2 || !freshlyEntered) return;
    final portalIndex = round.portals
        .indexWhere((portal) => portal.x == cell.x && portal.y == cell.y);
    if (portalIndex == -1) return;
    final target = round.portals[portalIndex == 0 ? 1 : 0];
    player
      ..x = target.x + 0.5
      ..y = target.y + 0.5
      ..direction = null
      ..nextDirection = null
      ..lastCellKey = '${target.x},${target.y}';
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
    if (GameConstants.tunnelRows.contains(player.y.floor())) {
      if (player.x < -0.35) player.x = maze.cols + 0.35;
      if (player.x > maze.cols + 0.35) player.x = -0.35;
    }
    if (maze.biome != CaveBiome.ember &&
        GameConstants.tunnelCols.contains(player.x.floor())) {
      if (player.y < -0.35) player.y = maze.rows + 0.35;
      if (player.y > maze.rows + 0.35) player.y = -0.35;
    }
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
