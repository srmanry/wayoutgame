import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Shared portrait atlas for the board, legends, previews and character picker.
/// Decoded once at startup so moving characters never load images per frame.
class CharacterArt {
  CharacterArt._();

  static const motionAsset = 'assets/characters/maze_walk_v3.png';
  static const humanMotionAsset =
      'assets/characters/human_run_directions_v5.png';
  static const humanIdleAsset =
      'assets/characters/human_idle_directions_v5.png';
  static const _slots = {
    'lion': 0,
    'fox': 1,
    'wolf': 2,
    'cat': 3,
    'snake': 4,
    'owl': 5,
    'male': 6,
    'female': 7,
  };
  static ui.Image? _walk;
  static ui.Image? _humanRun;
  static ui.Image? _humanIdle;
  static const _runCrops = {
    'male': ui.Rect.fromLTWH(.15949, 0, .82297, 1),
    'female': ui.Rect.fromLTWH(.16587, 0, .81659, 1),
  };
  static const _idleCrops = {
    'male': ui.Rect.fromLTWH(.27959, .03608, .44194, .93574),
    'female': ui.Rect.fromLTWH(.27734, .02255, .44419, .94927),
  };

  // One shared crop per row preserves pose alignment while removing the
  // atlas gutters from the displayed character. Coordinates are cell-relative.
  static const _motionCrops = <String, ui.Rect>{
    'lion': ui.Rect.fromLTWH(.10823, .06313, .7982, .89741),
    'fox': ui.Rect.fromLTWH(.10372, .06764, .76663, .8929),
    'wolf': ui.Rect.fromLTWH(.08568, .05411, .78016, .90643),
    'cat': ui.Rect.fromLTWH(.12627, .06313, .71702, .88388),
    'snake': ui.Rect.fromLTWH(.11725, .14431, .77114, .70349),
    'owl': ui.Rect.fromLTWH(.07666, .01804, .87486, .78016),
    'male': ui.Rect.fromLTWH(.21646, .01353, .58625, .9425),
    'female': ui.Rect.fromLTWH(.24352, .02706, .52311, .95152),
  };

  static const _portraitCrops = <String, ui.Rect>{
    'lion': ui.Rect.fromLTWH(.35, .2, .6, .6),
    'fox': ui.Rect.fromLTWH(.4, .35, .55, .55),
    'wolf': ui.Rect.fromLTWH(.37, .33, .58, .58),
    'cat': ui.Rect.fromLTWH(.3, .29, .61, .61),
    'snake': ui.Rect.fromLTWH(.4, .26, .55, .55),
    'owl': ui.Rect.fromLTWH(.33, .37, .53, .53),
    'male': ui.Rect.fromLTWH(.2, .05, .6, .6),
    'female': ui.Rect.fromLTWH(.23, .05, .6, .6),
  };

  // Tight squares round each head in the first walking frame, which faces
  // right. Coordinates are cell-relative.
  static const _faceCrops = <String, ui.Rect>{
    'lion': ui.Rect.fromLTWH(.383, .207, .533, .533),
    'fox': ui.Rect.fromLTWH(.483, .293, .417, .417),
    'wolf': ui.Rect.fromLTWH(.46, .25, .433, .433),
    'cat': ui.Rect.fromLTWH(.483, .293, .393, .393),
    'snake': ui.Rect.fromLTWH(.533, .273, .35, .35),
    'owl': ui.Rect.fromLTWH(.567, .383, .24, .24),
    'male': ui.Rect.fromLTWH(.387, .017, .307, .307),
    'female': ui.Rect.fromLTWH(.413, .093, .283, .283),
  };

  /// A round token: the head alone on a soft tint, ringed in the role colour.
  /// Returns false when the art is unavailable.
  static bool drawFace(
    ui.Canvas canvas,
    ui.Offset center,
    double radius,
    String character,
    ui.Color ring, {
    bool flip = false,
    ui.Color rim = const ui.Color(0xFFFFFFFF),
    double faceShare = .76,
    ui.Color? edge,
  }) {
    final atlas = _walk;
    final slot = _slots[character];
    if (atlas == null || slot == null) return false;
    canvas.drawCircle(
      center + ui.Offset(0, radius * .1),
      radius,
      ui.Paint()..color = const ui.Color(0x40000000),
    );
    if (edge != null) {
      canvas.drawCircle(center, radius + 1, ui.Paint()..color = edge);
    }
    canvas.drawCircle(center, radius, ui.Paint()..color = rim);
    canvas.drawCircle(center, radius * .9, ui.Paint()..color = ring);
    final inner = radius * faceShare;
    canvas.drawCircle(
      center,
      inner,
      ui.Paint()..color = ui.Color.lerp(ring, const ui.Color(0xFFFFFFFF), .85)!,
    );
    final width = atlas.width / 4;
    final height = atlas.height / 8;
    final crop = _faceCrops[character]!;
    canvas.save();
    canvas.clipPath(
      ui.Path()..addOval(ui.Rect.fromCircle(center: center, radius: inner)),
    );
    canvas.translate(center.dx, center.dy);
    if (flip) canvas.scale(-1, 1);
    canvas.drawImageRect(
      atlas,
      ui.Rect.fromLTWH(
        crop.left * width,
        (slot + crop.top) * height,
        crop.width * width,
        crop.height * height,
      ),
      ui.Rect.fromCircle(center: ui.Offset.zero, radius: inner),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    canvas.restore();
    return true;
  }

  static ui.Size actorSize(double radius, String character) {
    final crop = _motionCrops[character] ?? const ui.Rect.fromLTWH(0, 0, 1, 1);
    final aspect = crop.width / crop.height;
    final height = math.min(radius * 2.2, radius * 2.6 / aspect);
    return ui.Size(height * aspect, height);
  }

  static bool get ready => _walk != null;

  /// The atlas every portrait and face comes from, read at startup.
  static Future<void> load() async {
    _walk ??= await _decode(motionAsset);
  }

  /// The full-body human poses. The maze shows faces, so nothing in the game
  /// needs these at startup.
  static Future<void> loadHumanPoses() async {
    await Future.wait([
      if (_humanRun == null)
        _decode(humanMotionAsset).then((image) => _humanRun = image),
      if (_humanIdle == null)
        _decode(humanIdleAsset).then((image) => _humanIdle = image),
    ]);
  }

  // Decoded at the file's own size: enlarging adds memory but no detail.
  static Future<ui.Image> _decode(String asset) async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  /// Returns false when unavailable, allowing the original vector fallback.
  static bool draw(
    ui.Canvas canvas,
    ui.Offset center,
    double radius,
    String character,
  ) {
    final atlas = _walk;
    final slot = _slots[character];
    if (atlas == null || slot == null) return false;
    final width = atlas.width / 4;
    final height = atlas.height / 8;
    final crop = _portraitCrops[character]!;
    canvas.drawImageRect(
      atlas,
      ui.Rect.fromLTWH(
        crop.left * width,
        (slot + crop.top) * height,
        crop.width * width,
        crop.height * height,
      ),
      ui.Rect.fromCenter(
        center: center,
        width: radius * 2.4,
        height: radius * 2.4,
      ),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    return true;
  }

  /// Elevated game sprites share the maze's lighting and room scale.
  static bool drawActor(
    ui.Canvas canvas,
    ui.Offset center,
    double radius,
    String character, {
    required ui.Offset heading,
    required double clock,
    required bool moving,
    double lunge = 0,
    bool? facingLeft,
    double? motionPhase,
  }) {
    final atlas = _walk;
    final row = _slots[character];
    if (atlas == null || row == null) return false;
    final phase = motionPhase ?? clock * 2.5;
    final human = character == 'male' || character == 'female';
    final useRun = human && moving && _humanRun != null;
    final useIdle = human && !moving && _humanIdle != null;
    final direction = heading.dx.abs() > heading.dy.abs()
        ? (heading.dx >= 0 ? 1 : 3)
        : (heading.dy >= 0 ? 0 : 2);
    final frame = moving
        ? (phase * (useRun ? 8 : 4)).floor() % (useRun ? 8 : 4)
        : 0;
    final width = atlas.width / 4;
    final height = atlas.height / 8;
    final crop = _motionCrops[character] ?? const ui.Rect.fromLTWH(0, 0, 1, 1);
    final body = actorSize(radius, character);
    final rect = ui.Rect.fromCenter(
      // The bottom of the body is the world position, shared by movement,
      // collisions, the camera and the ground shadow.
      center: ui.Offset(0, -body.height * .46),
      width: body.width,
      height: body.height,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!human && (facingLeft ?? heading.dx < 0)) canvas.scale(-1, 1);
    final stride = moving && !human ? math.sin(phase * math.pi * 4) : 0.0;
    canvas.translate(lunge * radius * .35, stride * radius * .018);
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset.zero,
        width: body.width * .65,
        height: radius * .25,
      ),
      ui.Paint()..color = const ui.Color(0x30000000),
    );
    final source = ui.Rect.fromLTWH(
      (frame + crop.left) * width,
      (row + crop.top) * height,
      crop.width * width,
      crop.height * height,
    );
    if (useRun || useIdle) {
      final image = useRun ? _humanRun! : _humanIdle!;
      final cellWidth = image.width / (useRun ? 8 : 4);
      final cellHeight = image.height / (useRun ? 8 : 2);
      final sourceRow = useRun
          ? (character == 'female' ? 4 : 0) + direction
          : (character == 'female' ? 1 : 0);
      final sourceColumn = useRun ? frame : direction;
      final runCrop = useRun
          ? _runCrops[character]!
          : (_idleCrops[character] ?? const ui.Rect.fromLTWH(0, 0, 1, 1));
      final runWidth = body.height * runCrop.width / runCrop.height;
      final runRect = ui.Rect.fromCenter(
        center: ui.Offset(0, -body.height * .46),
        width: runWidth,
        height: body.height,
      );
      if (useIdle) canvas.scale(1, 1 + math.sin(clock * 3) * .025);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
          (sourceColumn + runCrop.left) * cellWidth,
          (sourceRow + runCrop.top) * cellHeight,
          runCrop.width * cellWidth,
          runCrop.height * cellHeight,
        ),
        runRect,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else {
      // Idle breathing is anchored at the feet rather than scaling the floor.
      canvas.scale(
        1 + lunge * .12,
        1 + (moving ? lunge * .12 : math.sin(clock * 3) * .025),
      );
      canvas.drawImageRect(
        atlas,
        source,
        rect,
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
    canvas.restore();
    return true;
  }
}
