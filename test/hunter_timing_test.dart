import 'package:arrow_game/escape/maze_escape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the hunter sets off just after the first swipe', () {
    final game = EscapeGame();
    addTearDown(game.dispose);
    game.selectLevel(41);
    game.advance(.5);
    expect(game.hunterDistance, 0);
    game.swipe(game.maze.waysFrom(game.runnerCell).first);
    for (var t = 0.0; t < 1; t += .016) {
      game.advance(.016);
    }
    expect(game.hunterDistance, greaterThan(0));
  });

  test('an idle runner still gets the time to look at the maze', () {
    final game = EscapeGame();
    addTearDown(game.dispose);
    game.selectLevel(41);
    game.advance(game.maze.hunterDelay - .1);
    expect(game.hunterDistance, 0);
  });
}
