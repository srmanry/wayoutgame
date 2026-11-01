import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/multiplayer/match_client.dart';
import 'package:arrow_game/multiplayer/race_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../server/match_server.dart';

import 'level_sample.dart';

class Peer {
  Peer(this.socket) {
    sub = socket.listen((raw) {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      messages.add(message);
      if (message['type'] == 'state') state = message;
    });
  }
  final WebSocket socket;
  late StreamSubscription<dynamic> sub;
  final List<Map<String, dynamic>> messages = [];
  Map<String, dynamic>? state;
  void send(Map<String, Object?> data) => socket.add(jsonEncode(data));
  Future<Map<String, dynamic>> wait(
    bool Function(Map<String, dynamic>) predicate,
  ) async {
    final end = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(end)) {
      final index = messages.indexWhere(predicate);
      if (index >= 0) return messages.removeAt(index);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    throw TimeoutException(
      'Server did not send expected event; last state: $state',
    );
  }

  Future<void> close() async {
    await socket.close();
    await sub.cancel();
  }
}

Future<void> until(bool Function() predicate) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Condition not reached');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late MatchServer server;
  final peers = <Peer>[];
  setUp(() async {
    server = MatchServer(countdown: const Duration(milliseconds: 100));
    await server.bind(port: 0, address: InternetAddress.loopbackIPv4);
  });
  tearDown(() async {
    for (final peer in peers) {
      await peer.close();
    }
    peers.clear();
    await server.close();
  });
  Future<Peer> peer() async {
    final result = Peer(
      await WebSocket.connect('ws://127.0.0.1:${server.port}/ws'),
    );
    peers.add(result);
    return result;
  }

  Future<(Peer, Peer, String)> lobby({
    String mode = 'basic',
    bool quick = false,
  }) async {
    final first = await peer();
    first.send({
      'type': quick ? 'quick' : 'create',
      'name': 'Asha',
      'mode': mode,
      'level': 1,
    });
    final joined = await first.wait((m) => m['type'] == 'joined');
    final second = await peer();
    second.send({
      'type': quick ? 'quick' : 'join',
      'name': 'Rafi',
      'mode': mode,
      'code': joined['code'],
      'level': 1,
    });
    await second.wait((m) => m['type'] == 'joined');
    await first.wait(
      (m) => m['type'] == 'state' && (m['players'] as List).length == 2,
    );
    return (first, second, joined['code'] as String);
  }

  Future<void> start(Peer first, Peer second, {bool quick = false}) async {
    first.send({'type': 'ready', 'ready': true});
    second.send({'type': 'ready', 'ready': true});
    if (!quick) {
      await first.wait(
        (m) =>
            m['type'] == 'state' &&
            (m['players'] as List).every((p) => p['ready'] == true),
      );
      first.send({'type': 'start'});
    }
    await first.wait((m) => m['type'] == 'state' && m['phase'] == 'racing');
    await second.wait((m) => m['type'] == 'state' && m['phase'] == 'racing');
  }

  for (final mode in ['basic', 'rescue']) {
    test(
      'two independent sockets race in $mode; server verifies the first finish',
      () async {
        final (first, second, _) = await lobby(mode: mode);
        await start(first, second);
        expect(first.state!['level'], second.state!['level']);
        second.send({'type': 'finish'});
        await second.wait((m) => m['type'] == 'error');
        expect(second.state!['phase'], 'racing');
        final level = levelFromJson(
          first.state!['level'] as Map<String, dynamic>,
        );
        var seq = 0;
        Future<void> move(String action, int id) async {
          await pace();
          first.send({
            'type': 'move',
            'action': action,
            'id': id,
            'seq': ++seq,
          });
          await first.wait(
            (m) => m['type'] == 'state' && m['you']['seq'] == seq,
          );
        }

        for (final arrow in level.arrows.reversed) {
          await move('arrow', arrow.id);
        }
        if (level.rescue != null) {
          expect(first.state!['phase'], 'racing');
          for (final animal in level.rescue!.targets) {
            await move('rescue', animal.id);
          }
        }
        expect(first.state!['phase'], 'finished');
        final finish = await second.wait(
          (m) => m['type'] == 'state' && m['phase'] == 'finished',
        );
        expect(finish['winnerId'], first.state!['you']['id']);
        expect(finish['reason'], 'completed');
        expect((finish['players'] as List).first['finishMs'], isNonNegative);
        second.send({
          'type': 'move',
          'action': 'arrow',
          'id': level.arrows.last.id,
          'seq': 1,
        });
        await second.wait((m) => m['type'] == 'error');
        expect(second.state!['winnerId'], first.state!['winnerId']);
      },
    );
  }

  test(
    'Quick Match pairs waiting players and starts after both ready',
    () async {
      final (first, second, _) = await lobby(quick: true);
      expect(first.state!['code'], second.state!['code']);
      await start(first, second, quick: true);
      expect(first.state!['phase'], 'racing');
    },
  );

  test('ready checks, invalid room, full room, and duplicate sequences are enforced', () async {
    final missing = await peer();
    missing.send({'type': 'join', 'name': 'Visitor', 'code': 'ZZZZZZ'});
    expect(
      (await missing.wait((m) => m['type'] == 'error'))['message'],
      contains('not found'),
    );
    final (first, second, code) = await lobby();
    first.send({'type': 'start'});
    await first.wait((m) => m['type'] == 'error');
    for (var i = 0; i < 2; i++) {
      final extra = await peer();
      extra.send({'type': 'join', 'name': 'Player $i', 'code': code});
      await extra.wait((m) => m['type'] == 'joined');
      extra.send({'type': 'ready', 'ready': true});
    }
    missing.send({'type': 'join', 'name': 'Visitor', 'code': code});
    expect(
      (await missing.wait((m) => m['type'] == 'error'))['message'],
      contains('full'),
    );
    await start(first, second);
    final level = levelFromJson(first.state!['level'] as Map<String, dynamic>);
    final move = {
      'type': 'move',
      'action': 'arrow',
      'id': level.arrows.last.id,
      'seq': 1,
    };
    first.send(move);
    await first.wait((m) => m['type'] == 'state' && m['you']['seq'] == 1);
    first.send(move);
    final duplicate = await first.wait(
      (m) => m['type'] == 'state' && m['you']['seq'] == 1,
    );
    expect(duplicate['you']['moves'], 1);
  });

  test(
    'reconnect requires secret token and restores exact server board',
    () async {
      final first = await peer();
      first.send({'type': 'create', 'name': 'Asha', 'level': 1});
      final credentials = await first.wait((m) => m['type'] == 'joined');
      final second = await peer();
      second.send({
        'type': 'join',
        'name': 'Rafi',
        'code': credentials['code'],
      });
      await second.wait((m) => m['type'] == 'joined');
      await start(first, second);
      final level = levelFromJson(
        first.state!['level'] as Map<String, dynamic>,
      );
      first.send({
        'type': 'move',
        'action': 'arrow',
        'id': level.arrows.last.id,
        'seq': 1,
      });
      await first.wait((m) => m['type'] == 'state' && m['you']['seq'] == 1);
      await first.socket.close();
      final resumed = await peer();
      resumed.send({
        'type': 'resume',
        'code': credentials['code'],
        'id': credentials['id'],
        'token': 'wrong',
      });
      await resumed.wait((m) => m['type'] == 'error');
      resumed.send({
        'type': 'resume',
        'code': credentials['code'],
        'id': credentials['id'],
        'token': credentials['token'],
      });
      final restored = await resumed.wait((m) => m['type'] == 'state');
      expect(restored['you']['removed'], [level.arrows.last.id]);
      expect(restored['you']['seq'], 1);
      expect(restored['phase'], 'racing');
    },
  );

  test('real Flutter client connects, readies, sends moves, and receives live progress', () async {
    final a = MatchClient();
    final b = MatchClient();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final endpoint = 'ws://127.0.0.1:${server.port}/ws';
    await a.enter(endpoint: endpoint, name: 'Asha', action: 'create');
    await until(() => a.roomCode != null && a.state != null);
    await b.enter(
      endpoint: endpoint,
      name: 'Rafi',
      action: 'join',
      code: a.roomCode!,
    );
    await until(() => a.players.length == 2 && b.state != null);
    a.ready(true);
    b.ready(true);
    await until(() => a.players.every((p) => p['ready'] == true));
    a.start();
    await until(() => a.phase == 'racing' && b.phase == 'racing');
    a.move('arrow', a.game!.level.arrows.last.id);
    expect(a.pendingMove, isTrue);
    await until(() => !a.pendingMove && a.game!.moves == 1);
    await until(() => (b.players.first['progress'] as num) > 0);
    expect(b.game!.removed, isEmpty);
    await a.leave();
    await b.leave();
  });

  test(
    'near-simultaneous final moves produce exactly one shared winner',
    () async {
      final (first, second, _) = await lobby();
      await start(first, second);
      final level = levelFromJson(
        first.state!['level'] as Map<String, dynamic>,
      );
      var seq = 0;
      final order = level.arrows.reversed.toList();
      for (final arrow in order.take(order.length - 1)) {
        await pace();
        seq++;
        for (final p in [first, second]) {
          p.send({
            'type': 'move',
            'action': 'arrow',
            'id': arrow.id,
            'seq': seq,
          });
          await p.wait((m) => m['type'] == 'state' && m['you']['seq'] == seq);
        }
      }
      for (final p in [first, second]) {
        p.send({
          'type': 'move',
          'action': 'arrow',
          'id': order.last.id,
          'seq': seq + 1,
        });
      }
      final a = await first.wait(
        (m) => m['type'] == 'state' && m['phase'] == 'finished',
      );
      final b = await second.wait(
        (m) => m['type'] == 'state' && m['phase'] == 'finished',
      );
      expect(a['winnerId'], b['winnerId']);
      expect(
        (a['players'] as List).where((p) => p['finishMs'] != null).length,
        1,
      );
    },
  );

  test('timeout ends a race without inventing a winner', () async {
    await server.close();
    server = MatchServer(
      countdown: const Duration(milliseconds: 100),
      matchLimit: const Duration(milliseconds: 300),
    );
    await server.bind(port: 0, address: InternetAddress.loopbackIPv4);
    final (first, second, _) = await lobby();
    await start(first, second);
    final result = await first.wait(
      (m) => m['type'] == 'state' && m['phase'] == 'finished',
    );
    expect(result['winnerId'], isNull);
    expect(result['reason'], 'timeout');
  });

  test('server and solo rules agree for every level in both modes', () {
    for (final mode in GameMode.values) {
      for (final number in sampleLevels) {
        final solo = PuzzleGame(mode: mode, initialLevel: number);
        final race = RaceBoard(
          levelFromJson(
            jsonDecode(jsonEncode(levelToJson(solo.level)))
                as Map<String, dynamic>,
          ),
        );
        for (final arrow in solo.level.arrows.reversed) {
          expect(race.canExit(arrow), solo.canExit(arrow));
          expect(race.apply('arrow', arrow.id), solo.tap(arrow.id).name);
        }
        for (final target
            in solo.level.rescue?.targets ?? const <RescueTarget>[]) {
          expect(race.canRescue(target), solo.canRescue(target));
          expect(
            race.apply('rescue', target.id),
            solo.rescueAnimal(target.id).name,
          );
        }
        expect(race.complete, solo.isComplete);
        solo.dispose();
      }
    }
  });
}

// The server drops sockets that send more than 40 messages a second; big
// boards have more arrows than that, so scripted players keep a human pace.
Future<void> pace() => Future<void>.delayed(const Duration(milliseconds: 30));
