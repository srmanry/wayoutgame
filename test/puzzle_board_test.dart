import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arrows can be tapped while others are still flying', (
    tester,
  ) async {
    final game = PuzzleGame(initialLevel: 27, unlockAllLevels: true);
    addTearDown(game.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 340,
            child: PuzzleBoard(game: game, onArrow: game.tap),
          ),
        ),
      ),
    );
    final board = find.byType(PuzzleBoard);
    Future<void> tapArrow(ArrowPiece arrow) async {
      final cell = tester.getSize(board).width / (game.level.size + 1);
      await tester.tapAt(
        tester.getTopLeft(board) +
            Offset(cell * (arrow.head.x + 1), cell * (arrow.head.y + 1)),
      );
    }

    final free = game.remaining.where(game.canExit).take(3).toList();
    expect(free, hasLength(3));
    for (final arrow in free) {
      await tapArrow(arrow);
      // Well inside the shortest flight.
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(game.removed, containsAll(free.map((a) => a.id)));
    expect(game.lives, 3);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
