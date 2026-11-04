import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/game/puzzle_rules.dart';
import 'package:arrow_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show openMode;

void main() {
  testWidgets('the tap cue fades on the first step', (tester) async {
    await tester.pumpWidget(const ArrowGameApp());
    await openMode(tester, 'Maze Escape');
    final game = tester.widget<EscapeBoard>(find.byType(EscapeBoard)).game;
    game.selectLevel(35);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Arrow controls (tap to use touch)'));
    await tester.pumpAndSettle();

    double opacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text('Tap to move'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;

    expect(opacity(), 1);
    expect(Direction.values.any(game.swipe), isTrue);
    await tester.pump();
    expect(opacity(), 0);

    game.restart();
    await tester.pumpAndSettle();
    expect(opacity(), 1);

    // Every other level shows the same short cue, on its own footer.
    for (final level in [1, 34, 100, 170, 200]) {
      game.selectLevel(level);
      await tester.pumpAndSettle();
      expect(opacity(), 1);
    }
    expect(tester.takeException(), isNull);
  });
}
