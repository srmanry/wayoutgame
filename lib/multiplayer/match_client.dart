import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../game/puzzle.dart';
import 'race_rules.dart';

class MatchClient extends ChangeNotifier {
  MatchClient({this.connectionTimeout = const Duration(seconds: 8)});
  final Duration connectionTimeout;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  bool _disposed = false;
  bool _intentionalClose = false;
  int _generation = 0;
  int _retryCount = 0;
  String? _token;
  Uri? _endpoint;
  String? playerId;
  String? roomCode;
  String? error;
  String? feedback;
  bool connected = false;
  bool connecting = false;
  bool pendingMove = false;
  int? _pendingSeq;
  Map<String, dynamic>? state;
  PuzzleGame? game;
  int _serverOffsetMs = 0;
  String get phase => state?['phase'] as String? ?? 'setup';
  List<Map<String, dynamic>> get players =>
      (state?['players'] as List? ?? const []).cast<Map<String, dynamic>>();
  Map<String, dynamic>? get me =>
      players.where((p) => p['id'] == playerId).firstOrNull;
  bool get isHost => state?['hostId'] == playerId;
  bool get canPlay =>
      connected &&
      !pendingMove &&
      phase == 'racing' &&
      game != null &&
      !game!.isGameOver;
  int get serverNow => DateTime.now().millisecondsSinceEpoch + _serverOffsetMs;
  int get startAt => state?['startAt'] as int? ?? 0;
  int get elapsedMs => (serverNow - startAt).clamp(0, 1 << 31);

  static Uri parseEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['ws', 'wss'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery) {
      throw const FormatException(
        'Enter a WebSocket address such as wss://your-server/ws.',
      );
    }
    return uri.replace(
      path: uri.path.isEmpty || uri.path == '/' ? '/ws' : uri.path,
    );
  }

  Future<void> enter({
    required String endpoint,
    required String name,
    required String action,
    GameMode mode = GameMode.basic,
    String code = '',
  }) async {
    if (connecting || roomCode != null) return;
    if (name.trim().isEmpty || name.trim().length > 20) {
      error = 'Enter a player name (1–20 characters).';
      notifyListeners();
      return;
    }
    if (action == 'join' &&
        !RegExp(r'^[A-Z2-9]{6}$').hasMatch(code.trim().toUpperCase())) {
      error = 'Enter the six-character room code.';
      notifyListeners();
      return;
    }
    try {
      _endpoint = parseEndpoint(endpoint);
    } on FormatException catch (e) {
      error = e.message;
      notifyListeners();
      return;
    }
    _intentionalClose = false;
    _retryCount = 0;
    await _connect({
      'type': action,
      'name': name.trim(),
      'mode': mode.name,
      if (action == 'join') 'code': code.trim().toUpperCase(),
    });
  }

  Future<void> _connect(Map<String, Object?> request) async {
    if (_disposed || _endpoint == null) return;
    final generation = ++_generation;
    connecting = true;
    connected = false;
    error = null;
    notifyListeners();
    await _subscription?.cancel();
    unawaited(_channel?.sink.close());
    final channel = WebSocketChannel.connect(_endpoint!);
    _channel = channel;
    _subscription = channel.stream.listen(
      (raw) {
        if (!_disposed && generation == _generation) _receive(raw);
      },
      onError: (_) {
        if (generation == _generation) _lost();
      },
      onDone: () {
        if (generation == _generation) _lost();
      },
    );
    try {
      await channel.ready.timeout(connectionTimeout);
      if (_disposed || generation != _generation) return;
      connected = true;
      connecting = false;
      _retryCount = 0;
      channel.sink.add(jsonEncode(request));
      notifyListeners();
    } catch (_) {
      if (!_disposed && generation == _generation) {
        connecting = false;
        error = 'Cannot reach the match server. Check the address and internet connection.';
        _lost();
      }
    }
  }

  void _receive(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'joined':
          playerId = data['id'] as String;
          _token = data['token'] as String;
          roomCode = data['code'] as String;
        case 'state':
          final previousPhase = phase;
          state = data;
          _serverOffsetMs =
              (data['serverNow'] as int) -
              DateTime.now().millisecondsSinceEpoch;
          final level = levelFromJson(data['level'] as Map<String, dynamic>);
          game ??= PuzzleGame(
            mode: data['mode'] == 'rescue' ? GameMode.rescue : GameMode.basic,
            initialLevel: level.number,
          );
          game!.applyMatchState(level, data['you'] as Map<String, dynamic>);
          final confirmed = (data['you'] as Map)['seq'] as int;
          if (_pendingSeq == null || confirmed >= _pendingSeq!) {
            pendingMove = false;
            _pendingSeq = null;
          }
          if (previousPhase != phase) feedback = null;
          error = null;
        case 'moveResult':
          feedback = data['result'] == 'blocked'
              ? 'Blocked route! You lost a heart.'
              : null;
        case 'error':
          error =
              data['message'] as String? ?? 'The server rejected this request.';
          pendingMove = false;
        case 'left':
          _clearRoom();
        case 'hello':
        case 'resumed':
          break;
      }
      notifyListeners();
    } catch (_) {
      error = 'This server sent an incompatible response.';
      notifyListeners();
    }
  }

  void _send(Map<String, Object?> data) {
    if (!connected) return;
    try {
      _channel?.sink.add(jsonEncode(data));
    } on StateError {
      _lost();
    }
  }

  void ready(bool value) => _send({'type': 'ready', 'ready': value});
  void start() => _send({'type': 'start'});
  void move(String action, int id) {
    if (!canPlay) return;
    pendingMove = true;
    _pendingSeq = ((state?['you'] as Map?)?['seq'] as int? ?? 0) + 1;
    _send({'type': 'move', 'action': action, 'id': id, 'seq': _pendingSeq});
    notifyListeners();
  }

  void _lost() {
    if (_disposed ||
        _intentionalClose ||
        (!connected && !connecting && _retry?.isActive == true)) {
      return;
    }
    connected = false;
    connecting = false;
    pendingMove = false;
    _pendingSeq = null;
    if (roomCode != null && _token != null) {
      error = 'Connection lost. Reconnecting to your match…';
      if (_retry?.isActive != true && _retryCount < 5) {
        _retryCount++;
        _retry = Timer(Duration(seconds: _retryCount * 2), reconnect);
      }
    } else {
      error ??= 'Cannot connect to the match server.';
    }
    notifyListeners();
  }

  Future<void> reconnect() async {
    if (_disposed || connecting || connected || roomCode == null) return;
    _retry?.cancel();
    _intentionalClose = false;
    await _connect({
      'type': 'resume',
      'code': roomCode,
      'id': playerId,
      'token': _token,
    });
  }

  Future<void> leave() async {
    _intentionalClose = true;
    _retry?.cancel();
    ++_generation;
    _send({'type': 'leave'});
    await _subscription?.cancel();
    unawaited(_channel?.sink.close());
    _channel = null;
    connected = false;
    connecting = false;
    _clearRoom();
    if (!_disposed) notifyListeners();
  }

  void _clearRoom() {
    roomCode = null;
    playerId = null;
    _token = null;
    state = null;
    game?.dispose();
    game = null;
    pendingMove = false;
    _pendingSeq = null;
    feedback = null;
    error = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _intentionalClose = true;
    _retry?.cancel();
    ++_generation;
    _send({'type': 'leave'});
    unawaited(_subscription?.cancel());
    unawaited(_channel?.sink.close());
    game?.dispose();
    super.dispose();
  }
}
