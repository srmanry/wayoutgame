import 'dart:ui' as ui;

import 'snake_colours.dart';

/// Keeps static landscaping out of the per-frame path. The scene is drawn once
/// into an image at screen resolution, so a frame costs one image copy however
/// many walls and plants the level has. The board owns this image and releases
/// it when its level view goes away.
class MazeSceneCache {
  /// Physical pixels per logical pixel; the board sets this as it builds.
  double pixelRatio = 1;

  Object? _key;
  double _keyRatio = 0;
  ui.Image? _image;

  /// The snake colouring that stands out most on the scene, measured once
  /// the scene is drawn.
  SnakeColours snake = snakeColourings.first;

  void draw(
    ui.Canvas canvas,
    Object key,
    ui.Size size,
    void Function(ui.Canvas) paint,
  ) {
    if (size.isEmpty) return;
    if (_image == null || key != _key || pixelRatio != _keyRatio) {
      final recorder = ui.PictureRecorder();
      paint(ui.Canvas(recorder)..scale(pixelRatio));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(
        (size.width * pixelRatio).ceil(),
        (size.height * pixelRatio).ceil(),
      );
      picture.dispose();
      _image?.dispose();
      _image = image;
      _key = key;
      _keyRatio = pixelRatio;
      _measure(image, key);
    }
    final image = _image!;
    canvas.drawImageRect(
      image,
      ui.Offset.zero & ui.Size(image.width.toDouble(), image.height.toDouble()),
      ui.Offset.zero &
          ui.Size(image.width / pixelRatio, image.height / pixelRatio),
      ui.Paint()..filterQuality = ui.FilterQuality.low,
    );
  }

  // Shrinks the scene to a few pixels and picks the snake colouring from them.
  void _measure(ui.Image image, Object key) {
    const side = 32;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      ui.Offset.zero & ui.Size(image.width.toDouble(), image.height.toDouble()),
      const ui.Rect.fromLTWH(0, 0, side + .0, side + .0),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final thumb = picture.toImageSync(side, side);
    picture.dispose();
    thumb.toByteData(format: ui.ImageByteFormat.rawRgba).then((data) {
      thumb.dispose();
      if (data != null && key == _key) {
        snake = standoutSnake(data.buffer.asUint8List());
      }
    }, onError: (Object _) => thumb.dispose());
  }

  void dispose() {
    _image?.dispose();
    _image = null;
    _key = null;
  }
}
