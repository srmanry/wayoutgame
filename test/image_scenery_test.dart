import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'switch image scenery in a live board and return to vector levels',
    (tester) async {
      final game = EscapeGame()..selectLevel(8);
      addTearDown(game.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EscapeBoard(game: game)),
        ),
      );
      for (final level in [8, 9, 10, 9, 8, 1]) {
        game.selectLevel(level);
        await tester.pump();
        if (level == 8 || level == 9) {
          await tester.runAsync(() async {
            await precacheImage(
              AssetImage(
                level == 8
                    ? 'assets/maze/natural_grass.png'
                    : 'assets/maze/city_rooftop.png',
              ),
              tester.element(find.byType(EscapeBoard)),
            );
          });
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
