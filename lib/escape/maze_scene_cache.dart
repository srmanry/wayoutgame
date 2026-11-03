import 'dart:ui' as ui;

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

  void dispose() {
    _image?.dispose();
    _image = null;
    _key = null;
  }
}
