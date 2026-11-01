import 'dart:ui' as ui;

/// Keeps static landscaping out of the per-frame path and object generation.
/// The board owns this recording and releases it when its level view goes away.
class MazeSceneCache {
  Object? _key;
  ui.Picture? _picture;

  void draw(ui.Canvas canvas, Object key, void Function(ui.Canvas) paint) {
    if (_picture == null || key != _key) {
      final recorder = ui.PictureRecorder();
      paint(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      _picture?.dispose();
      _picture = picture;
      _key = key;
    }
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _key = null;
  }
}
