import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:arrow_game/main.dart';
import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  escapeWidgetTests();
  testWidgets(
    'rescue animals, advance to mice, and keep Basic progress separate',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ArrowGameApp());
      await tester.ensureVisible(find.text('Arrow Escape'));
      await tester.tap(find.text('Arrow Escape'));
      await tester.pumpAndSettle();
      final boardFinder = find.byType(PuzzleBoard);
      final basic = tester.widget<PuzzleBoard>(boardFinder).game;
      basic.hint();
      await tester.pump();
      await openMode(tester, 'Animal Rescue');
      final rescue = tester.widget<PuzzleBoard>(boardFinder).game;
      expect(rescue.mode, GameMode.rescue);
      expect(find.text('Field rescue'), findsOneWidget);
      Future<void> tapCell(Cell position) async {
        await tester.ensureVisible(boardFinder);
        final cell =
            tester.getSize(boardFinder).width / (rescue.level.size + 1);
        await tester.tapAt(
          tester.getTopLeft(boardFinder) +
              Offset(cell * (position.x + 1), cell * (position.y + 1)),
        );
        await tester.pumpAndSettle();
      }

      // Clearing the route is enough: the mouse then runs home by itself.
      while (!rescue.isComplete) {
        expect(find.text('Next level →'), findsNothing);
        await tapCell(rescue.remaining.firstWhere(rescue.canExit).head);
      }
      expect(find.text('Congratulations!'), findsWidgets);
      await tester.ensureVisible(find.text('Next level →'));
      await tester.tap(find.text('Next level →'));
      await tester.pumpAndSettle();
      expect(rescue.level.rescue!.prey, AnimalKind.frog);
      expect(find.text('Pond rescue'), findsOneWidget);
      await openMode(tester, 'Arrow Escape');
      expect(
        identical(tester.widget<PuzzleBoard>(boardFinder).game, basic),
        isTrue,
      );
      expect(basic.hints, 2);
      expect(basic.unlockedLevel, 1);
      expect(rescue.unlockedLevel, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('arrows can be tapped to finish a level and unlock the next', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ArrowGameApp());
    await tester.ensureVisible(find.text('Arrow Escape'));
    await tester.tap(find.text('Arrow Escape'));
    await tester.pumpAndSettle();
    final boardFinder = find.byType(PuzzleBoard);
    final game = tester.widget<PuzzleBoard>(boardFinder).game;
    while (!game.isComplete) {
      final arrow = game.remaining.firstWhere(game.canExit);
      await tester.ensureVisible(boardFinder);
      final cell = tester.getSize(boardFinder).width / (game.level.size + 1);
      await tester.tapAt(
        tester.getTopLeft(boardFinder) +
            Offset(cell * (arrow.head.x + 1), cell * (arrow.head.y + 1)),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Congratulations!'), findsOneWidget);
    expect(game.unlockedLevel, 2);
    await tester.ensureVisible(find.text('Next level →'));
    await tester.tap(find.text('Next level →'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 02'), findsOneWidget);
    expect(game.lives, 3);
    expect(game.removed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hint, pause, resume, and level selection work', (tester) async {
    await tester.pumpWidget(const ArrowGameApp());
    await tester.ensureVisible(find.text('Arrow Escape'));
    await tester.tap(find.text('Arrow Escape'));
    await tester.pumpAndSettle();
    expect(find.text('arrow escape'), findsOneWidget);
    expect(find.text('LEVEL 01'), findsOneWidget);
    await tester.ensureVisible(find.text('Hint · 3 left'));
    await tester.tap(find.text('Hint · 3 left'));
    await tester.pump();
    expect(find.text('Hint · 2 left'), findsOneWidget);
    expect(
      find.text('Follow the green arrow. Its path is clear.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byTooltip('Pause game'));
    await tester.tap(find.byTooltip('Pause game'));
    await tester.pump();
    expect(find.text('A moment for you.'), findsOneWidget);
    await tester.ensureVisible(find.text('Keep playing'));
    await tester.tap(find.text('Keep playing'));
    await tester.pump();
    expect(find.text('A moment for you.'), findsNothing);
    await tester.ensureVisible(find.text('LEVEL 01'));
    await tester.tap(find.text('LEVEL 01'));
    await tester.pumpAndSettle();
    expect(find.text('Your little escape'), findsOneWidget);
    // Every level is open for now: no shut locks, open ones instead.
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_open_rounded), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('30'),
      200,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the level list opens at the level being played', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ArrowGameApp());
    await tester.tap(find.text('Arrow Escape'));
    await tester.pumpAndSettle();
    final game = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).game;
    game.selectLevel(150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('LEVEL 150'));
    await tester.pumpAndSettle();
    // Visible straight away, with no scrolling.
    expect(find.text('150').hitTestable(), findsOneWidget);
    expect(find.text('${PuzzleLevel.count}'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(360, 740),
    const Size(390, 844),
    const Size(1200, 800),
    const Size(700, 360),
  ]) {
    testWidgets('layout fits ${size.width} × ${size.height}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ArrowGameApp());
      await tester.ensureVisible(find.text('Arrow Escape'));
      await tester.tap(find.text('Arrow Escape'));
      await tester.pumpAndSettle();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('arrow escape'), findsOneWidget);
      void expectControlsFit() {
        for (final control in [
          find.byTooltip('Restart'),
          find.byTooltip('Undo'),
          find.textContaining('Hint ·'),
        ]) {
          expect(control.hitTestable(), findsOneWidget);
          expect(tester.getBottomRight(control).dy, lessThan(size.height));
        }
        expect(
          find.descendant(
            of: find.byType(GameScreen),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        final boardSize = tester.getSize(find.byType(PuzzleBoard));
        final level = tester
            .widget<PuzzleBoard>(find.byType(PuzzleBoard))
            .game
            .level;
        expect(
          boardSize.width / boardSize.height,
          closeTo((level.size + 1) / (level.rows + 1), .01),
        );
      }

      expectControlsFit();
      await tester.ensureVisible(find.text('Hint · 3 left'));
      expect(tester.takeException(), isNull);
      await openMode(tester, 'Animal Rescue');
      expect(find.text('Field rescue'), findsOneWidget);
      expectControlsFit();
      expect(tester.takeException(), isNull);
      // Animal Rescue keeps a clean header with no help button.
      expect(find.byTooltip('How to play'), findsNothing);
      await tester.ensureVisible(find.text('Hint · 3 left'));
      await tester.tap(find.text('Hint · 3 left'));
      await tester.pumpAndSettle();
      expectControlsFit();
      expect(tester.takeException(), isNull);
    });
  }
}

void escapeWidgetTests() {
  for (final size in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets('swipe the rabbit out of the maze at ${size.width}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ArrowGameApp());
      await openMode(tester, 'Maze Escape');
      final board = find.byType(EscapeBoard);
      final game = tester.widget<EscapeBoard>(board).game;
      expect(game.maze.number, 1);
      // Swipe along the right road, letting the clock run between swipes.
      for (var swipes = 0; swipes < 40 && !game.isOver; swipes++) {
        final way = game.maze.route(game.runnerCell, game.maze.exit);
        final d = way.length < 2
            ? Direction.right
            : Direction.values.firstWhere(
                (d) => game.runnerCell.step(d) == way[1],
              );
        await tester.ensureVisible(board);
        if (size.width < 390) {
          await tester.drag(board, Offset(d.dx * 60.0, d.dy * 60.0));
        } else {
          await tester.tap(find.byTooltip('Run ${d.label}'));
        }
        while (game.running) {
          game.advance(1 / 30);
        }
        await tester.pump();
      }
      expect(game.state, EscapeState.escaped);
      await tester.pumpAndSettle();
      expect(find.text('Congratulations!'), findsWidgets);
      await tester.ensureVisible(find.text('Next level →'));
      await tester.tap(find.text('Next level →'));
      await tester.pumpAndSettle();
      expect(game.maze.number, 2);
      expect(game.isOver, isFalse);
      // Dense later mazes use the screen width instead of shrinking into
      // a narrow column to preserve square rooms.
      for (final level in [1, 100, 200]) {
        game.selectLevel(level);
        await tester.pumpAndSettle();
        // Without a card border the board can use a little more width.
        expect(
          tester.getSize(board).width,
          inInclusiveRange(size.width - 12, size.width - 10),
        );
        expect(tester.getSize(board).height, greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    });
  }
}

// Picks a way to play from the home screen, going back there first if a
// game is open.
Future<void> openMode(WidgetTester tester, String title) async {
  final back = find.byTooltip('All games');
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(title));
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}
