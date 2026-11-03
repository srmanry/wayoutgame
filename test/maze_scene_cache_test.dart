import 'dart:ui' as ui;

import 'package:arrow_game/escape/maze_scene_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the scene is drawn once until its level or resolution changes', () {
    final cache = MazeSceneCache();
    addTearDown(cache.dispose);
    final canvas = ui.Canvas(ui.PictureRecorder());
    const size = ui.Size(40, 60);
    var paints = 0;
    void draw(Object key) => cache.draw(canvas, key, size, (scene) => paints++);

    draw('level 1');
    draw('level 1');
    expect(paints, 1);
    draw('level 2');
    expect(paints, 2);
    cache.pixelRatio = 3;
    draw('level 2');
    expect(paints, 3);
  });
}
