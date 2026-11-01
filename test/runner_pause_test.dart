import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a paused runner ignores swipes and moves after resuming', (
    tester,
  ) async {
    final game = EscapeGame();
    addTearDown(game.dispose);
    Future<void> showBoard(bool paused) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EscapeBoard(game: game, paused: paused),
        ),
      ),
    );
    await showBoard(true);
    final start = game.runnerAt;
    final direction = game.maze.waysFrom(game.runnerCell).first;
    final swipe = Offset(direction.dx * 60.0, direction.dy * 60.0);
    await tester.drag(find.byType(EscapeBoard), swipe);
    await tester.pump();
    expect(game.moves, 0);
    expect(game.runnerAt, start);
    await showBoard(false);
    await tester.drag(find.byType(EscapeBoard), swipe);
    await tester.pump();
    expect(game.moves, 1);
    game.advance(.02);
    expect(game.runnerAt, isNot(start));
    expect(tester.takeException(), isNull);
  });
}
