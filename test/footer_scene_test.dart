import 'package:arrow_game/escape/maze_decor.dart';
import 'package:arrow_game/escape/maze_escape.dart';
import 'package:arrow_game/escape/maze_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no two levels in a row share a footer', () {
    final scenes = [
      for (var n = 1; n <= EscapeMaze.count; n++) MazeDecor.footerScene(n),
    ];
    expect(scenes.toSet().length, FrameStyle.footerScenes + 1);
    for (var i = 1; i < scenes.length; i++) {
      final same = scenes[i] == scenes[i - 1];
      final ownFooters = scenes[i] == null;
      final sameWorld =
          MazeDecor.forLevel(i)?.frame.shape ==
          MazeDecor.forLevel(i + 1)?.frame.shape;
      expect(
        same && (!ownFooters || sameWorld),
        isFalse,
        reason: 'Level ${i + 1}',
      );
    }
  });

  test('later log worlds take a different footer', () {
    for (var n = 41; n <= EscapeMaze.count; n++) {
      if (MazeDecor.forLevel(n)?.frame.shape == FrameShape.wood) {
        expect(MazeDecor.footerScene(n), isNotNull, reason: 'Level $n');
      }
    }
    expect(MazeDecor.footerScene(186), isNotNull);
  });

  test('only one level has the bamboo fence', () {
    final bamboo = [
      for (var n = 1; n <= EscapeMaze.count; n++)
        if (MazeDecor.footerScene(n) == MazeDecor.bambooScene) n,
    ];
    expect(bamboo, [EscapeMaze.count]);
  });

  test('only one level has the woven fence', () {
    final woven = [
      for (var n = 1; n <= EscapeMaze.count; n++)
        if (MazeDecor.footerScene(n) == MazeDecor.wovenScene) n,
    ];
    expect(woven, [198]);
  });

  test('only one level has the striped awning header', () {
    final striped = [
      for (var n = 1; n <= EscapeMaze.count; n++)
        if (MazeDecor.headerFrame(n)?.layout == HeaderLayout.awning) n,
    ];
    expect(striped, [2]);
  });

  test('the frozen level keeps its ice wall', () {
    expect(MazeDecor.footerScene(70), isNull);
  });
}
