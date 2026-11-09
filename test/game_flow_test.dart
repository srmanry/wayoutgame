import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/screens/arrow_game_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => GameSettings.levelTimer = true);
  tearDown(() {
    GameSettings.levelTimer = false;
    GameSettings.escapeClock = false;
  });

  testWidgets('help pauses the countdown until dismissed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump(const Duration(seconds: 1));
    final game = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
    await tester.tap(find.byTooltip('How to play'));
    await tester.pump(const Duration(milliseconds: 300));
    final elapsed = game.elapsed;
    await tester.pump(const Duration(seconds: 10));
    expect(game.elapsed, elapsed);
    await tester.tap(find.text('Let’s play'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(game.elapsed - elapsed, lessThan(const Duration(seconds: 2)));
    expect(game.elapsed, greaterThan(elapsed));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('restart confirmation pauses the current attempt', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    final game = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
    game.tap(game.remaining.firstWhere(game.canExit).id);
    await tester.pump();
    await tester.tap(find.byTooltip('Restart'));
    await tester.pump(const Duration(milliseconds: 300));
    final elapsed = game.elapsed;
    await tester.pump(const Duration(seconds: 10));
    expect(game.elapsed, elapsed);
    await tester.tap(find.text('Keep playing'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(game.moves, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('maze level picker pauses the hunter clock', (tester) async {
    GameSettings.escapeClock = true;
    await tester.pumpWidget(
      const MaterialApp(home: GameScreen(mode: PlayMode.escape)),
    );
    final game = tester.widget<EscapeBoard>(find.byType(EscapeBoard)).game;
    await tester.tap(find.byTooltip('Choose a level'));
    await tester.pump(const Duration(milliseconds: 300));
    final clock = game.clock;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.clock, clock);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('backgrounding with help open keeps the attempt paused', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    final game = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
    await tester.tap(find.byTooltip('How to play'));
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.tap(find.text('Let’s play'));
    await tester.pump(const Duration(milliseconds: 300));
    final elapsed = game.elapsed;
    await tester.pump(const Duration(seconds: 10));
    expect(game.elapsed, elapsed);
    expect(find.text('A moment for you.'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
  });

  for (final mode in PlayMode.values) {
    testWidgets('${mode.name} guide fits a short landscape screen', (
      tester,
    ) async {
      GameSettings.showGuides = true;
      addTearDown(() => GameSettings.showGuides = false);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(667, 375);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: GameScreen(mode: mode)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Let’s play'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
