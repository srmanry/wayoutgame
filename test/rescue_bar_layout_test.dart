import 'package:arrow_game/screens/arrow_game_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(393, 852),
    const Size(375, 667),
    const Size(430, 932),
    const Size(360, 640),
    const Size(320, 568),
  ]) {
    testWidgets(
      'the rescue card fits its bigger bar tokens and a message on $size',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        addTearDown(t.view.resetPhysicalSize);
        await t.pumpWidget(
          const MaterialApp(home: GameScreen(mode: PlayMode.rescue)),
        );
        final game = t.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
        game.selectLevel(7);
        await t.pump();
        for (final a in game.level.arrows) {
          t.widget<PuzzleBoard>(find.byType(PuzzleBoard)).onArrow(a.id);
          await t.pump();
          if (find.textContaining('blocked').evaluate().isNotEmpty) break;
        }
        expect(find.textContaining('blocked'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
