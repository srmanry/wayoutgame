// Relative imports keep the standalone server runnable without Flutter.
// ignore_for_file: avoid_relative_lib_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../lib/game/puzzle_rules.dart';
import '../lib/multiplayer/race_rules.dart';

class RacePlayer {
  RacePlayer(this.id, this.token, this.name, this.socket);
  final String id;
  final String token;
  final String name;
  WebSocket? socket;
  bool ready = false;
  bool left = false;
  int seq = 0;
  RaceBoard? board;
  int? finishMs;
  DateTime? disconnectedAt;
  bool get connected => socket != null;
}

class RaceRoom {
  RaceRoom(this.code, this.hostId, this.mode, this.level, this.quick);
  final String code;
  String hostId;
  final GameMode mode;
  final PuzzleLevel level;
  final bool quick;
  final List<RacePlayer> players = [];
  String phase = 'lobby';
  String? winnerId;
  String? reason;
  final clock = Stopwatch();
  int startAt = 0;
  DateTime updatedAt = DateTime.now();
}

/// A single-process, in-memory room server. No Flutter or external packages.
class MatchServer {
  MatchServer({
    this.countdown = const Duration(seconds: 3),
    this.matchLimit = const Duration(minutes: 5),
    this.reconnectGrace = const Duration(seconds: 30),
  });
  final Duration countdown;
  final Duration matchLimit;
  final Duration reconnectGrace;
  final Map<String, RaceRoom> rooms = {};
  final Map<WebSocket, ({RaceRoom room, RacePlayer player})> _sessions = {};
  final Set<WebSocket> _sockets = {};
  final Map<WebSocket, ({DateTime start, int count})> _rates = {};
  final Random _random = Random.secure();
  HttpServer? _http;
  Timer? _ticker;
  int get port => _http!.port;

  Future<void> bind({int port = 8080, InternetAddress? address}) async {
    _http = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
    _http!.listen(_request);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  Future<void> _request(HttpRequest request) async {
    if (request.uri.path == '/health') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({'status': 'ok', 'rooms': rooms.length}),
      );
      await request.response.close();
      return;
    }
    if (request.uri.path != '/ws' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (_sockets.length >= 500) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(
        request,
        maxPayloadLength: 8192,
      );
      _sockets.add(socket);
      socket.pingInterval = const Duration(seconds: 15);
      _send(socket, {'type': 'hello', 'version': 1});
      socket.listen(
        (data) => _message(socket, data),
        onDone: () => _disconnect(socket),
        onError: (_) => _disconnect(socket),
      );
    } catch (_) {
      // A client may disconnect while the upgrade is still in flight.
    }
  }

  String _key(int length) => List.generate(
    length,
    (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[_random.nextInt(32)],
  ).join();
  void _send(WebSocket? socket, Map<String, Object?> message) {
    if (socket?.readyState != WebSocket.open) return;
    try {
      socket!.add(jsonEncode(message));
    } on StateError {
      // A close handshake can finish before readyState changes.
    }
  }

  void _error(WebSocket socket, String message) =>
      _send(socket, {'type': 'error', 'message': message});

  void _message(WebSocket socket, dynamic raw) {
    final now = DateTime.now();
    final rate = _rates[socket];
    if (rate != null && now.difference(rate.start).inSeconds < 1) {
      if (rate.count >= 40) {
        _error(socket, 'Too many requests. Slow down.');
        return;
      }
      _rates[socket] = (start: rate.start, count: rate.count + 1);
    } else {
      _rates[socket] = (start: now, count: 1);
    }
    try {
      if (raw is! String || raw.length > 4096) throw const FormatException();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'];
      if (type == 'create' || type == 'join' || type == 'quick') {
        if (_sessions.containsKey(socket)) {
          _error(socket, 'Leave your current room first.');
          return;
        }
        _join(socket, data);
        return;
      }
      if (type == 'resume') {
        _resume(socket, data);
        return;
      }
      final session = _sessions[socket];
      if (session == null) {
        _error(socket, 'Join a room first.');
        return;
      }
      final room = session.room;
      final player = session.player;
      room.updatedAt = now;
      switch (type) {
        case 'ready':
          if (room.phase != 'lobby') return;
          player.ready = data['ready'] == true;
          if (room.quick && _canStart(room)) _start(room);
          _broadcast(room);
        case 'start':
          if (room.hostId != player.id || !_canStart(room)) {
            _error(socket, 'At least two connected, ready players are needed.');
            return;
          }
          _start(room);
          _broadcast(room);
        case 'move':
          _move(socket, room, player, data);
        case 'leave':
          _leave(socket, room, player);
        case 'sync':
          _snapshot(room, player);
        default:
          _error(socket, 'Unknown request.');
      }
    } catch (_) {
      _error(socket, 'Invalid request.');
    }
  }

  void _join(WebSocket socket, Map<String, dynamic> data) {
    final name = (data['name'] as String? ?? '').trim();
    if (name.isEmpty ||
        name.length > 20 ||
        name.contains(RegExp(r'[\x00-\x1F]'))) {
      _error(socket, 'Use a player name between 1 and 20 characters.');
      return;
    }
    final mode = data['mode'] == 'rescue' ? GameMode.rescue : GameMode.basic;
    RaceRoom? room;
    if (data['type'] == 'join') {
      room = rooms[(data['code'] as String? ?? '').trim().toUpperCase()];
      if (room == null) {
        _error(socket, 'Room not found. Check the code.');
        return;
      }
    } else if (data['type'] == 'quick') {
      room = rooms.values
          .where(
            (r) =>
                r.quick &&
                r.phase == 'lobby' &&
                r.mode == mode &&
                r.players.length < 2,
          )
          .firstOrNull;
    }
    final id = _key(12);
    if (room == null) {
      if (rooms.length >= 100) {
        _error(socket, 'Server is busy. Try again shortly.');
        return;
      }
      String code;
      do {
        code = _key(6);
      } while (rooms.containsKey(code));
      final number = data['level'] is int
          ? (data['level'] as int).clamp(1, PuzzleLevel.count)
          : 1 + _random.nextInt(12);
      room = RaceRoom(
        code,
        id,
        mode,
        PuzzleLevel.generate(number, mode: mode),
        data['type'] == 'quick',
      );
      rooms[code] = room;
    }
    if (room.phase != 'lobby') {
      _error(socket, 'This match has already started.');
      return;
    }
    if (room.players.length >= (room.quick ? 2 : 4)) {
      _error(socket, 'This room is full.');
      return;
    }
    if (room.players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      _error(socket, 'That name is already in the room.');
      return;
    }
    final player = RacePlayer(id, _key(40), name, socket);
    room.players.add(player);
    room.updatedAt = DateTime.now();
    _sessions[socket] = (room: room, player: player);
    _send(socket, {
      'type': 'joined',
      'id': id,
      'token': player.token,
      'code': room.code,
    });
    _broadcast(room);
  }

  void _resume(WebSocket socket, Map<String, dynamic> data) {
    if (_sessions.containsKey(socket)) {
      _error(socket, 'Already connected to a room.');
      return;
    }
    final room = rooms[data['code']];
    final player = room?.players
        .where((p) => p.id == data['id'] && p.token == data['token'] && !p.left)
        .firstOrNull;
    if (room == null ||
        player == null ||
        (player.disconnectedAt != null &&
            DateTime.now().difference(player.disconnectedAt!) >=
                reconnectGrace)) {
      _error(socket, 'This session expired. Join a new match.');
      return;
    }
    final old = player.socket;
    if (old != null) {
      _sessions.remove(old);
      unawaited(old.close(1000, 'Reconnected elsewhere'));
    }
    player.socket = socket;
    player.disconnectedAt = null;
    _sessions[socket] = (room: room, player: player);
    _send(socket, {'type': 'resumed'});
    _broadcast(room);
  }

  bool _canStart(RaceRoom room) =>
      room.phase == 'lobby' &&
      room.players.length >= 2 &&
      room.players.every((p) => p.connected && p.ready);
  void _start(RaceRoom room) {
    room.phase = 'countdown';
    room.startAt =
        DateTime.now().millisecondsSinceEpoch + countdown.inMilliseconds;
    room.clock
      ..reset()
      ..start();
    for (final p in room.players) {
      p.board = RaceBoard(room.level);
    }
  }

  void _move(
    WebSocket socket,
    RaceRoom room,
    RacePlayer player,
    Map<String, dynamic> data,
  ) {
    if (room.phase == 'countdown' && room.clock.elapsed >= countdown) {
      room.phase = 'racing';
    }
    if (room.phase != 'racing' || player.left || player.board == null) {
      _error(socket, 'The race is not active.');
      return;
    }
    if (room.clock.elapsed - countdown >= matchLimit) {
      room.phase = 'finished';
      room.reason = 'timeout';
      _broadcast(room);
      return;
    }
    if (data['seq'] is! int ||
        data['seq'] != player.seq + 1 ||
        data['id'] is! int) {
      _snapshot(room, player);
      return;
    }
    player.seq++;
    final result = player.board!.apply(
      data['action'] as String? ?? '',
      data['id'] as int,
    );
    _send(socket, {'type': 'moveResult', 'result': result, 'seq': player.seq});
    if (player.board!.complete) {
      player.finishMs = max(
        0,
        room.clock.elapsedMilliseconds - countdown.inMilliseconds,
      );
      room.winnerId = player.id;
      room.phase = 'finished';
      room.reason = 'completed';
    } else if (room.players.every((p) => p.left || p.board!.lives == 0)) {
      room.phase = 'finished';
      room.reason = 'eliminated';
    }
    _broadcast(room);
  }

  void _leave(WebSocket socket, RaceRoom room, RacePlayer player) {
    _sessions.remove(socket);
    player.socket = null;
    player.left = true;
    if (room.phase == 'lobby' || room.phase == 'countdown') {
      room.players.remove(player);
      if (room.phase == 'countdown') _cancelCountdown(room);
      if (room.players.isNotEmpty && room.hostId == player.id) {
        room.hostId = room.players.first.id;
      }
    }
    _send(socket, {'type': 'left'});
    _broadcast(room);
  }

  void _cancelCountdown(RaceRoom room) {
    room.phase = 'lobby';
    room.clock.stop();
    room.startAt = 0;
    for (final p in room.players) {
      p.ready = false;
      p.board = null;
    }
  }

  void _disconnect(WebSocket socket) {
    _sockets.remove(socket);
    _rates.remove(socket);
    final session = _sessions.remove(socket);
    if (session == null || session.player.socket != socket) return;
    session.player.socket = null;
    session.player.disconnectedAt = DateTime.now();
    session.player.ready = false;
    if (session.room.phase == 'countdown') _cancelCountdown(session.room);
    _broadcast(session.room);
  }

  void _snapshot(RaceRoom room, RacePlayer viewer) => _send(viewer.socket, {
    'type': 'state',
    'code': room.code,
    'phase': room.phase,
    'hostId': room.hostId,
    'mode': room.mode.name,
    'quick': room.quick,
    'level': levelToJson(room.level),
    'serverNow': DateTime.now().millisecondsSinceEpoch,
    'startAt': room.startAt,
    'limitMs': matchLimit.inMilliseconds,
    'winnerId': room.winnerId,
    'reason': room.reason,
    'players': [
      for (final p in room.players)
        {
          'id': p.id,
          'name': p.name,
          'ready': p.ready,
          'connected': p.connected,
          'left': p.left,
          'progress': p.board?.progress ?? 0,
          'lives': p.board?.lives ?? 3,
          'moves': p.board?.moves ?? 0,
          'finishMs': p.finishMs,
        },
    ],
    'you': {'id': viewer.id, 'seq': viewer.seq, ...?viewer.board?.toJson()},
  });

  void _broadcast(RaceRoom room) {
    room.updatedAt = DateTime.now();
    for (final p in room.players) {
      _snapshot(room, p);
    }
  }

  void _tick() {
    final now = DateTime.now();
    for (final room in rooms.values.toList()) {
      var changed = false;
      if (room.phase == 'countdown' && room.clock.elapsed >= countdown) {
        room.phase = 'racing';
        changed = true;
      }
      for (final p in room.players.toList()) {
        if (p.disconnectedAt != null &&
            now.difference(p.disconnectedAt!) >= reconnectGrace) {
          p.left = true;
          p.disconnectedAt = null;
          if (room.phase == 'lobby') {
            room.players.remove(p);
            if (room.hostId == p.id && room.players.isNotEmpty) {
              room.hostId = room.players.first.id;
            }
          }
          changed = true;
        }
      }
      if (room.phase == 'racing') {
        if (room.clock.elapsed - countdown >= matchLimit) {
          room.phase = 'finished';
          room.reason = 'timeout';
          changed = true;
        } else if (room.players.every((p) => p.left || p.board!.lives == 0)) {
          room.phase = 'finished';
          room.reason = 'eliminated';
          changed = true;
        }
      }
      if (changed) _broadcast(room);
      if (room.players.isEmpty ||
          (room.players.every((p) => !p.connected) &&
              now.difference(room.updatedAt) > const Duration(minutes: 2)) ||
          now.difference(room.updatedAt) > const Duration(minutes: 30)) {
        rooms.remove(room.code);
        for (final p in room.players) {
          final socket = p.socket;
          if (socket != null) {
            _sessions.remove(socket);
            unawaited(socket.close(1000, 'Room expired'));
          }
        }
      }
    }
  }

  Future<void> close() async {
    _ticker?.cancel();
    _sessions.clear();
    for (final socket in _sockets.toList()) {
      await socket.close(1001, 'Server stopping');
    }
    await _http?.close(force: true);
    rooms.clear();
    _sessions.clear();
    _sockets.clear();
    _rates.clear();
  }
}

Future<void> main() async {
  final server = MatchServer();
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  await server.bind(port: port);
  stdout.writeln(
    'Arrow Escape match server listening on 0.0.0.0:${server.port} (/ws, /health)',
  );
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
