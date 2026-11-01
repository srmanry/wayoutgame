import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/main.dart';
import 'package:arrow_game/multiplayer/competition_screen.dart';
import 'package:arrow_game/multiplayer/match_client.dart';
import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/multiplayer/race_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PreviewClient extends MatchClient {
  PreviewClient(String phase) {
    connected = true;
    playerId = 'asha';
    roomCode = 'ABC234';
    final board = PuzzleLevel.generate(1);
    game = PuzzleGame();
    state = {
      'phase': phase,
      'hostId': 'asha',
      'mode': 'basic',
      'quick': false,
      'startAt': DateTime.now().millisecondsSinceEpoch - 1000,
      'limitMs': 300000,
      'winnerId': phase == 'finished' ? 'asha' : null,
      'players': [
        {
          'id': 'asha',
          'name': 'Asha',
          'ready': true,
          'connected': true,
          'left': false,
          'progress': phase == 'finished' ? 1 : .4,
          'lives': 3,
          'moves': 4,
          'finishMs': 12340,
        },
        {
          'id': 'rafi',
          'name': 'Rafi',
          'ready': true,
          'connected': true,
          'left': false,
          'progress': .2,
          'lives': 2,
          'moves': 2,
          'finishMs': null,
        },
      ],
      'you': {'id': 'asha', 'seq': 0},
      'level': levelToJson(board),
    };
  }
}

void main() {
  test('WebSocket endpoint validation rejects missing/invalid addresses', () {
    expect(() => MatchClient.parseEndpoint(''), throwsFormatException);
    expect(
      () => MatchClient.parseEndpoint('https://example.com'),
      throwsFormatException,
    );
    expect(
      MatchClient.parseEndpoint('wss://example.com').toString(),
      'wss://example.com/ws',
    );
  });
  testWidgets('competition is hidden from the hub for now', (tester) async {
    await tester.pumpWidget(const ArrowGameApp());
    expect(find.text('Arrow Escape'), findsOneWidget);
    expect(
      find.text('Competition'),
      GameSettings.showCompetition ? findsOneWidget : findsNothing,
    );
  });
  testWidgets('competition shows setup validation and goes back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CompetitionScreen(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('One puzzle. One winner.'), findsOneWidget);
    await tester.ensureVisible(find.text('Quick Match · 2 players'));
    await tester.tap(find.text('Quick Match · 2 players'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a player name (1–20 characters).'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to solo'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
  for (final size in [const Size(320, 640), const Size(1200, 800)]) {
    for (final phase in ['setup', 'lobby', 'racing', 'finished']) {
      testWidgets('competition $phase layout fits ${size.width}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final client = phase == 'setup' ? MatchClient() : PreviewClient(phase);
        addTearDown(client.dispose);
        await tester.pumpWidget(
          MaterialApp(home: CompetitionScreen(client: client)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Competition'), findsOneWidget);
        if (phase == 'finished') expect(find.text('You won!'), findsOneWidget);
      });
    }
  }
}
