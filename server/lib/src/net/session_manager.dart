import 'dart:io';
import 'dart:math';

import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_models.dart';
import '../domain/match_series.dart';
import '../game/game_engine.dart';
import '../game/game_logger.dart';
import '../game/maze_service.dart';
import '../game/stats_store.dart';

class ClientPeer {
  ClientPeer({required this.id, required this.socket});

  final String id;
  final WebSocket socket;
  String name = '';
  MatchSession? session;
  PlayerConnection? player;
}

class SessionManager {
  final Map<String, ClientPeer> peers = {};
  final Map<String, MatchSession> sessions = {};
  final StatsStore stats = StatsStore();
  final GameLogger logger = GameLogger();
  int _nextPeerId = 1;
  int _nextSessionId = 1;

  ClientPeer createPeer(WebSocket socket) {
    final peer = ClientPeer(id: 'u${_nextPeerId++}', socket: socket);
    peers[peer.id] = peer;
    return peer;
  }

  void removePeer(ClientPeer peer) {
    peer.session?.remove(peer, disconnected: true);
    peers.remove(peer.id);
    _removeEmptySessions();
  }

  void applyMessage(ClientPeer peer, ClientMessage message) {
    switch (message.type) {
      case ClientMessageType.setName:
        var name = (message.name ?? '').trim();
        if (name.length > 20) name = name.substring(0, 20);
        peer.name = name;
        final player = peer.player;
        if (player != null) player.name = name;
      case ClientMessageType.createSession:
        if (peer.session != null) return;
        var name = (message.sessionName ?? '').trim();
        if (name.isEmpty) name = 'Сессия $_nextSessionId';
        if (name.length > 28) name = name.substring(0, 28);
        final id = 's${_nextSessionId++}';
        final session = MatchSession(
          id: id,
          name: name,
          stats: stats,
          logger: logger,
        );
        sessions[id] = session;
        session.add(peer);
      case ClientMessageType.joinSession:
        if (peer.session != null) return;
        final session = sessions[message.sessionId];
        if (session != null) session.add(peer);
      case ClientMessageType.leaveSession:
        peer.session?.remove(peer, disconnected: false);
        _removeEmptySessions();
      default:
        peer.session?.applyMessage(peer, message);
    }
  }

  void tick() {
    for (final session in sessions.values.toList()) {
      session.tick();
    }
    _removeEmptySessions();
  }

  DirectorySnapshotDto directory() => DirectorySnapshotDto(
        type: 'directory',
        sessions: sessions.values.map((session) => session.summary()).toList(),
      );

  void _removeEmptySessions() {
    sessions.removeWhere((_, session) => session.peers.isEmpty);
  }
}

class MatchSession {
  MatchSession({
    required this.id,
    required this.name,
    required StatsStore stats,
    required GameLogger logger,
  }) : engine = GameEngine(
          maze: MazeService.generate(),
          stats: stats,
          logger: logger,
        );

  static const roundResultDurationMs = 4000;

  final String id;
  final String name;
  final GameEngine engine;
  final List<ClientPeer> peers = [];
  SessionPhase phase = SessionPhase.waiting;
  int roundNumber = 1;
  int? resultUntil;
  final MatchSeries series = MatchSeries();
  String? matchWinnerId;
  bool technical = false;
  final List<RoundResultDto> history = [];
  final Set<String> rematchVotes = {};
  final Map<String, String> participantNames = {};
  final Map<String, PlayerRole> participantRoles = {};

  void add(ClientPeer peer) {
    if (peer.session != null) return;
    final player = engine.createClient(peer.socket)..name = peer.name;
    peer
      ..session = this
      ..player = player;
    peers.add(peer);
  }

  void remove(ClientPeer peer, {required bool disconnected}) {
    final player = peer.player;
    if (player != null && player.slot != null && _competitivePhase) {
      _technicalForfeit(player);
    }
    if (player != null) engine.removeClient(player);
    peers.remove(peer);
    peer
      ..session = null
      ..player = null;
    if (_seatedPlayers.isEmpty && phase != SessionPhase.waiting) {
      _returnToWaiting();
    }
    if (phase == SessionPhase.matchResult && !technical) {
      _returnToWaiting();
    }
    if (!_matchHasStarted) _syncWaitingPhase();
  }

  bool get _matchHasStarted => phase != SessionPhase.waiting;
  bool get _competitivePhase =>
      phase == SessionPhase.picking ||
      phase == SessionPhase.playing ||
      phase == SessionPhase.roundResult;

  void applyMessage(ClientPeer peer, ClientMessage message) {
    final player = peer.player;
    if (player == null) return;
    switch (message.type) {
      case ClientMessageType.selectRole:
        if (phase != SessionPhase.waiting || message.role == null) return;
        engine.selectRole(player, message.role!);
        _syncWaitingPhase();
      case ClientMessageType.spectate:
        if (player.slot != null && _matchHasStarted) {
          _technicalForfeit(player);
          engine.releaseSlot(player);
        } else {
          engine.becomeSpectator(player);
          _syncWaitingPhase();
        }
      case ClientMessageType.selectAspect:
      case ClientMessageType.selectHunter:
        if (phase != SessionPhase.picking || player.ready) return;
        engine.applyMessage(player, message);
      case ClientMessageType.ready:
        if (phase != SessionPhase.picking || player.slot == null) return;
        player.ready = message.ready ?? false;
        if (_seatedPlayers.every((value) => value.ready || value.isBot)) {
          engine.ensureRoundState();
          phase = SessionPhase.playing;
        }
      case ClientMessageType.rematch:
        if (phase != SessionPhase.matchResult || player.slot == null) return;
        rematchVotes.add(player.id);
        if (_seatedPlayers.length == 2 &&
            _seatedPlayers.every((value) => rematchVotes.contains(value.id))) {
          _startRematch();
        }
      case ClientMessageType.addBot:
      case ClientMessageType.removeBot:
      case ClientMessageType.setBiomes:
      case ClientMessageType.setSandbox:
        if (phase != SessionPhase.waiting) return;
        engine.applyMessage(player, message);
        _syncWaitingPhase();
      case ClientMessageType.input:
      case ClientMessageType.stop:
      case ClientMessageType.placeTrap:
      case ClientMessageType.useAbility:
      case ClientMessageType.placeMagicCrystal:
      case ClientMessageType.layClutch:
      case ClientMessageType.activateMagicChain:
      case ClientMessageType.aim:
        if (phase == SessionPhase.playing) engine.applyMessage(player, message);
      default:
        return;
    }
  }

  List<PlayerConnection> get _seatedPlayers => engine.clients.values
      .where((player) => player.slot == 0 || player.slot == 1)
      .toList();

  void _syncWaitingPhase() {
    if (phase != SessionPhase.waiting) return;
    final requiredPlayers = engine.sandboxMode ? 1 : 2;
    if (_seatedPlayers.length != requiredPlayers) return;
    _beginMatch();
  }

  void _beginMatch() {
    phase = SessionPhase.picking;
    roundNumber = 1;
    matchWinnerId = null;
    technical = false;
    history.clear();
    rematchVotes.clear();
    participantNames.clear();
    participantRoles.clear();
    for (final player in _seatedPlayers) {
      participantNames[player.id] = _displayName(player);
      participantRoles[player.id] = player.role;
      player.ready = player.isBot;
    }
    series.reset(_seatedPlayers.map((player) => player.id));
  }

  void tick() {
    if (phase == SessionPhase.playing) {
      engine.tick();
      if (engine.round.phase == GamePhase.ended) _finishRound();
      return;
    }
    if (phase == SessionPhase.roundResult &&
        resultUntil != null &&
        DateTime.now().millisecondsSinceEpoch >= resultUntil!) {
      _nextRound();
    }
    if (phase == SessionPhase.matchResult &&
        technical &&
        resultUntil != null &&
        DateTime.now().millisecondsSinceEpoch >= resultUntil!) {
      _returnToWaiting();
    }
  }

  void _finishRound() {
    final slot = engine.round.winnerSlot;
    if (slot == null) return;
    final winner = engine.findPlayer(slot);
    if (winner == null) return;
    final role = slot == 0 ? PlayerRole.leha : PlayerRole.hunter;
    history.add(RoundResultDto(
      round: roundNumber,
      winnerId: winner.id,
      winnerName: _displayName(winner),
      role: role,
      reason: engine.round.reason,
    ));
    final completesStreak = series.recordWin(winner.id, role);
    if (completesStreak) {
      matchWinnerId = winner.id;
      phase = SessionPhase.matchResult;
      _recordMatchResult(winner.id);
    } else {
      phase = SessionPhase.roundResult;
      resultUntil =
          DateTime.now().millisecondsSinceEpoch + roundResultDurationMs;
    }
  }

  void _nextRound() {
    for (final player in _seatedPlayers) {
      final nextSlot = player.slot == 0 ? 1 : 0;
      player
        ..slot = nextSlot
        ..role = nextSlot == 0 ? PlayerRole.leha : PlayerRole.hunter
        ..ready = player.isBot;
      participantRoles[player.id] = player.role;
    }
    roundNumber += 1;
    resultUntil = null;
    engine.reset(keepBotsReady: true);
    phase = SessionPhase.picking;
  }

  void _technicalForfeit(PlayerConnection loser) {
    final winner = _seatedPlayers.where((value) => value != loser).firstOrNull;
    if (winner == null) return;
    participantNames[loser.id] = _displayName(loser);
    participantRoles[loser.id] = loser.role;
    participantNames[winner.id] = _displayName(winner);
    participantRoles[winner.id] = winner.role;
    matchWinnerId = winner.id;
    technical = true;
    phase = SessionPhase.matchResult;
    resultUntil = DateTime.now().millisecondsSinceEpoch + 5000;
    _recordMatchResult(winner.id);
  }

  void _returnToWaiting() {
    phase = SessionPhase.waiting;
    roundNumber = 1;
    resultUntil = null;
    matchWinnerId = null;
    technical = false;
    series.reset(const []);
    history.clear();
    rematchVotes.clear();
    participantNames.clear();
    participantRoles.clear();
    for (final player in _seatedPlayers) {
      player.ready = player.isBot;
    }
    engine.reset(keepBotsReady: true);
  }

  void _recordMatchResult(String winnerId) {
    final loserId =
        participantNames.keys.where((id) => id != winnerId).firstOrNull;
    engine.stats.recordResult(
      winner: participantNames[winnerId],
      loser: loserId == null ? null : participantNames[loserId],
    );
  }

  void _startRematch() {
    final players = _seatedPlayers;
    if (players.length != 2) return;
    if (Random().nextBool()) {
      final firstSlot = players.first.slot;
      players.first.slot = players.last.slot;
      players.last.slot = firstSlot;
    }
    for (final player in players) {
      player
        ..role = player.slot == 0 ? PlayerRole.leha : PlayerRole.hunter
        ..ready = player.isBot;
    }
    engine.reset(keepBotsReady: true);
    _beginMatch();
  }

  String _displayName(PlayerConnection player) => player.name.trim().isEmpty
      ? (player.isBot ? 'Бот' : 'Игрок ${player.id}')
      : player.name.trim();

  SessionStateDto state() => SessionStateDto(
        id: id,
        name: name,
        phase: phase,
        round: roundNumber,
        players: _matchPlayers(),
        streakOwnerId: series.streakOwnerId,
        streakRole: series.streakRole,
        history: List.unmodifiable(history),
        matchWinnerId: matchWinnerId,
        technical: technical,
      );

  List<MatchPlayerDto> _matchPlayers() {
    final ids = <String>{...participantNames.keys};
    ids.addAll(_seatedPlayers.map((player) => player.id));
    return ids.map((playerId) {
      final player = engine.clients[playerId];
      return MatchPlayerDto(
        id: playerId,
        name: player == null
            ? (participantNames[playerId] ?? 'Игрок')
            : _displayName(player),
        role:
            player?.role ?? participantRoles[playerId] ?? PlayerRole.spectator,
        roundWins: series.roundWins[playerId] ?? 0,
        pickLocked: player?.ready ?? false,
        rematch: rematchVotes.contains(playerId),
      );
    }).toList();
  }

  SessionSummaryDto summary() => SessionSummaryDto(
        id: id,
        name: name,
        phase: phase,
        round: roundNumber,
        players: _matchPlayers(),
        spectators:
            engine.clients.values.where((player) => player.slot == null).length,
      );

  GameSnapshotDto snapshotFor(ClientPeer peer) {
    final player = peer.player!;
    return engine.snapshotFor(player).copyWith(session: state());
  }
}
