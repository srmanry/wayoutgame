import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config/game_settings.dart';
import '../game/puzzle_rules.dart';
import '../widgets/character_art.dart';
import '../widgets/critters.dart';
import '../widgets/player_avatar.dart';
import '../widgets/puzzle_board.dart' show ink, mint;
import 'maze_escape.dart';
import 'maze_camera.dart';
import 'maze_decor.dart';
import 'maze_gate.dart';
import 'maze_image_scenery.dart';
import 'maze_palette.dart';
import 'maze_scene_cache.dart';
import 'maze_theme.dart';
import 'maze_wall_art.dart';

/// The Escape maze: swipe to run your chosen character down a corridor
/// while a hunter follows. The way out is the gap on the right.
class EscapeBoard extends StatefulWidget {
  const EscapeBoard({
    super.key,
    required this.game,
    this.character = PlayerCharacter.male,
    this.paused = false,
    this.tapToMove = false,
    this.overview = true,
    this.onEscaped,
    this.onCaught,
  });

  final EscapeGame game;
  final PlayerCharacter character;
  final bool paused;
  // Touch controls: tap a room and the runner walks there.
  final bool tapToMove;
  final bool overview;
  final VoidCallback? onEscaped;
  final VoidCallback? onCaught;

  // Margins round the maze, in rooms: room on the left for the snake's
  // burrow and on the right for the way out.
  static const sideMargin = .62, endMargin = .35;

  /// Width over height of the board for [maze].
  static double aspectOf(EscapeMaze maze) =>
      (maze.width + 2 * sideMargin) / (maze.rows + 2 * endMargin);

  @override
  State<EscapeBoard> createState() => _EscapeBoardState();
}

class _EscapeBoardState extends State<EscapeBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier(0);
  final _sceneCache = MazeSceneCache();
  Duration _last = Duration.zero;
  // Seconds since the run ended, for the run out of the maze or the bite.
  double _after = 0;
  EscapeState _state = EscapeState.playing;
  Offset _drag = Offset.zero;
  bool _swiped = false;
  ImageStream? _sceneryStream;
  ImageStreamListener? _sceneryListener;
  ImageInfo? _sceneryImage;
  String? _sceneryAsset;

  EscapeGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    game.addListener(_changed);
    _state = game.state;
    _sync();
  }

  @override
  void didUpdateWidget(covariant EscapeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.game, game)) {
      oldWidget.game.removeListener(_changed);
      game.addListener(_changed);
    }
    _loadScenery();
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadScenery();
  }

  void _loadScenery() {
    final asset = MazeImageScenery.forLevel(game.maze.number)?.asset;
    if (asset == _sceneryAsset) return;
    _clearScenery();
    _sceneryAsset = asset;
    if (asset == null) return;
    final stream = AssetImage(asset)
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      if (!mounted || _sceneryAsset != asset) {
        info.dispose();
        return;
      }
      setState(() {
        _sceneryImage?.dispose();
        _sceneryImage = info;
      });
    });
    _sceneryStream = stream;
    _sceneryListener = listener;
    stream.addListener(listener);
  }

  void _clearScenery() {
    if (_sceneryStream != null && _sceneryListener != null) {
      _sceneryStream!.removeListener(_sceneryListener!);
    }
    _sceneryStream = null;
    _sceneryListener = null;
    _sceneryImage?.dispose();
    _sceneryImage = null;
  }

  @override
  void dispose() {
    game.removeListener(_changed);
    _clearScenery();
    _sceneCache.dispose();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _changed() {
    if (MazeImageScenery.forLevel(game.maze.number)?.asset != _sceneryAsset) {
      _loadScenery();
      setState(() {});
    }
    if (game.state == _state) {
      _sync();
      return;
    }
    final before = _state;
    _state = game.state;
    _after = 0;
    if (before == EscapeState.playing) {
      if (_state == EscapeState.escaped) widget.onEscaped?.call();
      if (_state == EscapeState.caught) widget.onCaught?.call();
    }
    _sync();
  }

  // The clock runs while the chase is on and briefly after it ends.
  void _sync() {
    final run =
        GameSettings.escapeClock &&
        !widget.paused &&
        (!game.isOver || _after < 1.6);
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 0.0
        : math.min(.05, (now - _last).inMicroseconds / 1e6);
    _last = now;
    if (game.isOver) {
      _after += dt;
      if (_after >= 1.6) _sync();
    } else {
      game.advance(dt);
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    _sceneCache.pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return _board(context);
  }

  Widget _board(BuildContext context) => Semantics(
    label:
        'Maze. Swipe to run your ${widget.character.label.toLowerCase()} character to the gap on the right before the ${game.maze.hunter.name} catches you.',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.tapToMove && !widget.paused
          ? (details) {
              final size = context.size;
              if (size == null) return;
              // Same as the arrow pad: the way from the runner to the tap.
              final runner = _runnerPoint(size);
              if ((details.localPosition - runner).distance < 4) return;
              game.swipe(directionOf(details.localPosition - runner));
            }
          : null,
      onPanStart: (_) {
        _drag = Offset.zero;
        _swiped = false;
      },
      onPanUpdate: (details) {
        if (_swiped || widget.paused || game.isOver) return;
        _drag += details.delta;
        if (_drag.distance < 14) return;
        _swiped = true;
        game.swipe(directionOf(_drag));
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _EscapePainter(
            game,
            widget.character,
            widget.overview,
            _sceneryImage,
            _sceneCache,
            () => _after,
            Listenable.merge([game, _frame]),
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

extension on _EscapeBoardState {
  // Where the runner is drawn, using the same layout as the painter.
  Offset _runnerPoint(Size size) {
    final maze = game.maze;
    final cellWidth = size.width / (maze.width + 2 * EscapeBoard.sideMargin);
    final cellHeight = math.min(
      cellWidth,
      size.height / (maze.rows + 2 * EscapeBoard.endMargin),
    );
    final origin = Offset(
      (size.width - maze.width * cellWidth) / 2,
      (size.height - maze.rows * cellHeight) / 2,
    );
    Offset at(Offset room) =>
        origin +
        Offset((room.dx + .5) * cellWidth, (room.dy + .5) * cellHeight);
    return MazeCamera.follow(
      size: size,
      runner: at(game.runnerAt),
      hunter: at(game.snakeAt),
      cell: Size(cellWidth, cellHeight),
      overview: widget.overview,
    ).toScreen(at(game.runnerAt));
  }
}

/// The main way a drag points.
Direction directionOf(Offset drag) => drag.dx.abs() > drag.dy.abs()
    ? (drag.dx > 0 ? Direction.right : Direction.left)
    : (drag.dy > 0 ? Direction.down : Direction.up);

class _EscapePainter extends CustomPainter {
  _EscapePainter(
    this.game,
    this.character,
    this.overview,
    this.sceneryImage,
    this.sceneCache,
    this.after,
    Listenable repaint,
  ) : super(repaint: repaint);

  final EscapeGame game;
  final PlayerCharacter character;
  final bool overview;
  final ImageInfo? sceneryImage;
  final MazeSceneCache sceneCache;
  final double Function() after;

  static const _danger = Color(0xFFD9485F);
  static const _exitGreen = Color(0xFF26A06E);

  @override
  void paint(Canvas canvas, Size size) {
    final maze = game.maze;
    final cellWidth = size.width / (maze.width + 2 * EscapeBoard.sideMargin);
    final cellHeight = math.min(
      cellWidth,
      size.height / (maze.rows + 2 * EscapeBoard.endMargin),
    );
    final cell = math.min(cellWidth, cellHeight);
    final origin = Offset(
      (size.width - maze.width * cellWidth) / 2,
      (size.height - maze.rows * cellHeight) / 2,
    );
    Offset at(Offset room) =>
        origin +
        Offset((room.dx + .5) * cellWidth, (room.dy + .5) * cellHeight);
    final camera = MazeCamera.follow(
      size: size,
      runner: at(game.runnerAt),
      hunter: at(game.snakeAt),
      cell: Size(cellWidth, cellHeight),
      overview: overview,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(camera.scale);
    canvas.translate(-camera.origin.dx, -camera.origin.dy);
    sceneCache.draw(
      canvas,
      (maze, size, sceneryImage),
      size,
      (background) => _paintScenery(background, size),
    );
    MazeDecor.forLevel(maze.number)?.paintLife(
      canvas,
      size,
      MazeLayout(maze, origin, cellWidth, cellHeight),
      game.clock + after(),
    );
    _drawHint(canvas, at(game.runnerAt), Size(cellWidth, cellHeight));

    final t = after();
    // The exit gate breathes a green ring so the way out is easy to find.
    if (!game.isOver) {
      final (_, exitGate, room) = _gates(size);
      final pulse = .5 + .5 * math.sin(game.clock * 3);
      canvas.drawCircle(
        exitGate + Offset(0, -room.height * .18),
        room.width * (.62 + .16 * pulse),
        Paint()
          ..color = _exitGreen.withValues(alpha: .75 - .45 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, room.width * .07),
      );
    }

    // Characters share the maze's room scale. The camera enlarges both
    // together, preserving their relationship to paths and walls.
    final portraitRadius = cell * .46;
    final hunter = at(game.snakeAt);
    final hunterCenter = hunter;
    final caught = game.state == EscapeState.caught;
    final lunge = caught ? math.sin(math.min(t / .35, 1) * math.pi) : 0.0;
    // Tokens sit inside a corridor, trimmed like the level's buttons. In the
    // densest mazes they keep a size that shows the face, over the walls.
    final faceRadius = math.max(cell * .43, 14.0);
    final faceEdge = Colors.black.withValues(alpha: .45);
    final faceRim =
        MazeDecor.forLevel(maze.number)?.frame.look.face ?? Colors.white;
    const faceShare = .8;
    void drawHunter() {
      // The snake always comes whole, its long body winding along the path.
      if (maze.hunter == AnimalKind.snake) {
        _drawSnake(
          canvas,
          cell,
          at,
          game.clock + t,
          burrow: maze.number == 115 ? _gates(size).$1 : null,
        );
        return;
      }
      if (CharacterArt.drawFace(
        canvas,
        // A waiting hunter stays whole beside the left-edge gate.
        Offset(math.max(faceRadius + 1, hunterCenter.dx), hunterCenter.dy),
        faceRadius,
        maze.hunter.name,
        _danger,
        flip: game.hunterLookingLeft,
        rim: faceRim,
        faceShare: faceShare,
        edge: faceEdge,
      )) {
        return;
      }
      final hunterDrawn = CharacterArt.drawActor(
        canvas,
        hunterCenter,
        portraitRadius,
        maze.hunter.name,
        heading: game.hunterHeading,
        clock: game.clock + t,
        moving: !game.isOver && game.clock > game.hunterHeadStart,
        lunge: lunge,
        facingLeft: game.hunterLookingLeft,
        motionPhase: game.hunterDistance / 1.1,
      );
      if (!hunterDrawn) {
        _roleDisc(canvas, hunterCenter, portraitRadius, _danger);
        drawMazeAnimal(
          canvas,
          hunterCenter,
          portraitRadius,
          maze.hunter,
          hunter: true,
        );
      }
    }

    // After escaping, the runner dashes off through the gap.
    var runner = at(game.runnerAt);
    if (game.state == EscapeState.escaped) {
      runner += Offset(math.min(t * 9, 1.2) * cellWidth, 0);
    }
    if (game.state == EscapeState.caught) {
      // A bright warning ring that reads on any ground: a white halo, a
      // red fill and a pulsing red edge.
      final pulse = .5 + .5 * math.sin(t * 10);
      final radius = cell * (.6 + .2 * math.sin(math.min(t, 1) * math.pi));
      canvas.drawCircle(
        runner,
        radius + cell * .12,
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
      canvas.drawCircle(
        runner,
        radius,
        Paint()..color = _danger.withValues(alpha: .55 + .25 * pulse),
      );
      canvas.drawCircle(
        runner,
        radius + cell * .12,
        Paint()
          ..color = _danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, cell * .08),
      );
    }
    final playerCenter = runner;
    final settling = (game.clock - game.runnerLastMovedAt).clamp(0.0, .22);
    final runningPose =
        game.running ||
        (!game.isOver && game.clock - game.runnerLastMovedAt < .22) ||
        game.state == EscapeState.escaped;
    if (hunterCenter.dy <= playerCenter.dy) drawHunter();
    final playerDrawn =
        CharacterArt.drawFace(
          canvas,
          playerCenter,
          faceRadius,
          character.name,
          _exitGreen,
          flip: game.runnerLookingLeft,
          rim: faceRim,
          faceShare: faceShare,
          edge: faceEdge,
        ) ||
        CharacterArt.drawActor(
          canvas,
          playerCenter,
          portraitRadius * .9,
          character.name,
          heading: Offset(game.facing.dx.toDouble(), game.facing.dy.toDouble()),
          clock: game.clock + t,
          moving: runningPose,
          facingLeft: game.runnerLookingLeft,
          motionPhase:
              game.runnerDistance / 2.2 +
              (game.running ? 0 : settling * 2.8) +
              (game.state == EscapeState.escaped ? t * 2.8 : 0),
        );
    if (!playerDrawn) {
      _roleDisc(canvas, playerCenter, portraitRadius, _exitGreen);
      drawPlayerPortrait(canvas, playerCenter, portraitRadius, character);
    }
    if (hunterCenter.dy > playerCenter.dy) drawHunter();
    canvas.restore();
    if (!overview && camera.scale > 1.05) {
      _drawMiniMap(canvas, size, camera, at);
    }
  }

  void _drawMiniMap(
    Canvas canvas,
    Size size,
    MazeCamera camera,
    Offset Function(Offset) at,
  ) {
    final scale = math.min(72 / size.width, 104 / size.height);
    final mapSize = Size(size.width * scale, size.height * scale);
    final rect = Rect.fromLTWH(
      size.width - mapSize.width - 8,
      8,
      mapSize.width,
      mapSize.height,
    );
    final frame = RRect.fromRectAndRadius(
      rect.inflate(3),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      frame,
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)));
    canvas.translate(rect.left, rect.top);
    canvas.scale(scale);
    sceneCache.draw(
      canvas,
      (game.maze, size, sceneryImage),
      size,
      (background) => _paintScenery(background, size),
    );
    canvas.drawRect(
      camera.visibleWorld,
      Paint()..color = Colors.white.withValues(alpha: .18),
    );
    canvas.drawRect(
      camera.visibleWorld,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale,
    );
    for (final (point, color) in [
      (at(game.snakeAt), _danger),
      (at(game.runnerAt), _exitGreen),
    ]) {
      canvas.drawCircle(point, 3.5 / scale, Paint()..color = Colors.white);
      canvas.drawCircle(point, 2.5 / scale, Paint()..color = color);
    }
    canvas.restore();
  }

  // A coloured disc with a soft drop that lifts a portrait off the maze.
  static void _roleDisc(Canvas canvas, Offset c, double r, Color colour) {
    canvas.drawCircle(
      c + Offset(0, r * .15),
      r * 1.2,
      Paint()..color = Colors.black.withValues(alpha: .25),
    );
    canvas.drawCircle(c, r * 1.2, Paint()..color = colour);
  }

  // Where the two gates stand, and how big they are drawn. In a dense maze
  // they grow past a room and are kept inside the board.
  (Offset, Offset, Size) _gates(Size size) {
    final maze = game.maze;
    final cellWidth = size.width / (maze.width + 2 * EscapeBoard.sideMargin);
    final cellHeight = math.min(
      cellWidth,
      size.height / (maze.rows + 2 * EscapeBoard.endMargin),
    );
    final origin = Offset(
      (size.width - maze.width * cellWidth) / 2,
      (size.height - maze.rows * cellHeight) / 2,
    );
    Offset at(double x, double y) =>
        origin + Offset((x + .5) * cellWidth, (y + .5) * cellHeight);
    final room = Size(math.max(cellWidth, 18), math.max(cellHeight, 18));
    final edge = room.width * .48;
    final hunter = at(maze.snake.x - .62, maze.snake.y.toDouble());
    final exit =
        at(maze.exit.x.toDouble(), maze.exit.y.toDouble()) +
        Offset(cellWidth * .7, 0);
    return (
      Offset(math.max(edge, hunter.dx), hunter.dy),
      Offset(math.min(size.width - edge, exit.dx), exit.dy),
      room,
    );
  }

  void _paintScenery(Canvas canvas, Size size) {
    final maze = game.maze;
    final palette = MazePalette.forMaze(maze);
    final drawnWalls = MazeDecor.forLevel(maze.number)?.walls;
    final wallArt = drawnWalls ?? MazeWallArt.forLevel(maze.number);
    final imageScenery = drawnWalls != null
        ? null
        : MazeImageScenery.forLevel(maze.number);
    final cellWidth = size.width / (maze.width + 2 * EscapeBoard.sideMargin);
    final cellHeight = math.min(
      cellWidth,
      size.height / (maze.rows + 2 * EscapeBoard.endMargin),
    );
    final cell = math.min(cellWidth, cellHeight);
    final origin = Offset(
      (size.width - maze.width * cellWidth) / 2,
      (size.height - maze.rows * cellHeight) / 2,
    );
    Offset corner(int x, int y) =>
        origin + Offset(x * cellWidth, y * cellHeight);

    final floorPath = Path();
    for (final room in maze.cells) {
      floorPath.addRect(
        Rect.fromLTWH(
          corner(room.x, room.y).dx,
          corner(room.x, room.y).dy,
          cellWidth,
          cellHeight,
        ),
      );
    }
    // Walls between rooms, with the burrow and the exit left open.
    final walls = Path();
    for (final here in maze.cells) {
      final x = here.x, y = here.y;
      final rightOpen =
          here == maze.exit || maze.canStep(here, Direction.right);
      if (!rightOpen) {
        walls
          ..moveTo(corner(x + 1, y).dx, corner(x + 1, y).dy)
          ..lineTo(corner(x + 1, y + 1).dx, corner(x + 1, y + 1).dy);
      }
      if (!maze.canStep(here, Direction.down)) {
        walls
          ..moveTo(corner(x, y + 1).dx, corner(x, y + 1).dy)
          ..lineTo(corner(x + 1, y + 1).dx, corner(x + 1, y + 1).dy);
      }
      if (!maze.inside(here.step(Direction.up))) {
        walls
          ..moveTo(corner(x, y).dx, corner(x, y).dy)
          ..lineTo(corner(x + 1, y).dx, corner(x + 1, y).dy);
      }
      if (!maze.inside(here.step(Direction.left)) && here != maze.snake) {
        walls
          ..moveTo(corner(x, y).dx, corner(x, y).dy)
          ..lineTo(corner(x, y + 1).dx, corner(x, y + 1).dy);
      }
    }
    final decor = MazeDecor.forLevel(maze.number);
    final layout = MazeLayout(maze, origin, cellWidth, cellHeight);
    if (decor != null) {
      if (maze.number == 170) {
        // Level 170 sits on plain white, like its screen.
        canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      } else {
        decor.paintGround(canvas, size, layout, floorPath);
      }
      decor
        ..paintPath(canvas, size, layout, floorPath, walls)
        ..paintProps(canvas, layout)
        ..paintWallShadow(canvas, layout, walls);
    } else {
      canvas.drawPath(
        floorPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.floorTop, palette.floorBottom],
          ).createShader(Offset.zero & size),
      );
    }

    final sceneryFilter = MazePalette.sceneryFilterForLevel(maze.number);
    if (sceneryFilter != null) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..colorFilter = sceneryFilter,
      );
    }
    if (imageScenery != null) {
      drawImageScenery(canvas, walls, cell, imageScenery, sceneryImage?.image);
    } else if (wallArt != null) {
      drawMazeWallArt(
        canvas,
        walls,
        cell,
        wallArt,
        variationSeed: MazeTheme.variationForLevel(maze.number) == 0
            ? 0
            : maze.number * 7919,
      );
    } else {
      final wallWidth = (cell * .095).clamp(1.7, 2.6);
      canvas.save();
      canvas.translate(0, .7);
      canvas.drawPath(
        walls,
        Paint()
          ..color = palette.wall.withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = wallWidth + .7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
      canvas.drawPath(
        walls,
        Paint()
          ..color = palette.wall
          ..style = PaintingStyle.stroke
          ..strokeWidth = wallWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (sceneryFilter != null) canvas.restore();

    // Gateways sit above scenery so grass and buildings cannot cover them.
    final (hunterGate, exitGate, gateRoom) = _gates(size);
    // Level 115 tries the snake coming out of a burrow in the ground.
    if (maze.number == 115) {
      drawSnakeBurrow(canvas, hunterGate, gateRoom);
    } else {
      drawMazeGate(
        canvas,
        hunterGate,
        gateRoom,
        exit: false,
        level: maze.number,
        palette: palette,
      );
    }
    drawMazeGate(
      canvas,
      exitGate,
      gateRoom,
      exit: true,
      level: maze.number,
      palette: palette,
    );
  }

  // A chevron from the runner toward the right way.
  void _drawHint(Canvas canvas, Offset from, Size roomSize) {
    final d = game.hintDirection;
    if (d == null || game.isOver) return;
    final cell = roomSize.shortestSide;
    final step = Offset(d.dx.toDouble(), d.dy.toDouble());
    final spacing = Offset(d.dx * roomSize.width, d.dy * roomSize.height);
    final side = Offset(-step.dy, step.dx);
    final glow = Paint()..color = mint.withValues(alpha: .18);
    canvas.drawCircle(from + spacing, cell * .45, glow);
    final tip = from + spacing * 1.15;
    final chevron = Path()
      ..moveTo(
        (tip - step * cell * .3 + side * cell * .25).dx,
        (tip - step * cell * .3 + side * cell * .25).dy,
      )
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(
        (tip - step * cell * .3 - side * cell * .25).dx,
        (tip - step * cell * .3 - side * cell * .25).dy,
      );
    canvas.drawPath(
      chevron,
      Paint()
        ..color = mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * .13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // The snake: a striped body along its recent trail, about three rooms
  // long, and a head with eyes facing where it goes.
  // A long patterned snake: it waits coiled, then its body unwinds along the
  // corridors behind its head, thin at the tail and swaying a little.
  void _drawSnake(
    Canvas canvas,
    double cell,
    Offset Function(Offset) at,
    double wave, {
    Offset? burrow,
  }) {
    const bodyRooms = 4.0, coilArm = .2 * 2 * math.pi;
    // In a dense maze the body keeps a size that still reads as a snake.
    final girth = math.max(cell, 26.0);
    final points = [...game.trail, game.snakeAt];
    // A gate on the board's edge must not cut the coil or the tail off.
    Offset onBoard(Offset p) {
      final spot = at(p);
      return Offset(math.max(spot.dx, cell * .42), spot.dy);
    }

    final spine = <Offset>[onBoard(points.last)];
    var length = 0.0;
    for (var i = points.length - 2; i >= 0 && length < bodyRooms; i--) {
      length += (points[i] - points[i + 1]).distance;
      spine.insert(0, onBoard(points[i]));
    }
    // Whatever has not left yet stays coiled round the end of the trail.
    final path = Path();
    final turns = math.min(2.0, math.max(0.0, bodyRooms - length) / coilArm);
    if (burrow != null && length < bodyRooms) {
      // Out of a burrow: until the whole body is out the tail stays down the
      // hole, and a snake still waiting only peeks its head out. Once out,
      // it lets go of the hole and follows its trail like any other.
      path.moveTo(burrow.dx, burrow.dy);
      if (length == 0) {
        final peek = burrow + Offset(girth * .42, 0);
        path.lineTo(peek.dx, peek.dy);
        spine.last = peek;
      } else {
        for (final p in spine) {
          path.lineTo(p.dx, p.dy);
        }
      }
    } else if (turns > .05) {
      final centre = spine.first;
      final steps = (turns * 16).ceil();
      for (var i = 0; i <= steps; i++) {
        final f = i / steps;
        final spot =
            centre +
            Offset.fromDirection(
              f * turns * 2 * math.pi + 2.4,
              girth * .34 * (1 - f) * math.min(1.0, turns),
            );
        i == 0 ? path.moveTo(spot.dx, spot.dy) : path.lineTo(spot.dx, spot.dy);
      }
      for (final p in spine.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    } else {
      path.moveTo(spine.first.dx, spine.first.dy);
      for (final p in spine.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    final metric = path.computeMetrics().firstOrNull;
    final samples = <(Offset, double)>[];
    if (metric != null && metric.length > 0) {
      final step = math.max(1.5, cell * .07);
      for (var d = 0.0; d < metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d)!;
        final f = d / metric.length;
        final side = Offset(-tangent.vector.dy, tangent.vector.dx);
        final sway = math.sin(d / cell * 3 - wave * 4) * girth * .05 * (1 - f);
        samples.add((
          tangent.position + side * sway,
          girth * (.045 + .1 * math.min(1.0, f / .55)),
        ));
      }
    }
    // Coloured to stand out on this level's scene, with a pale halo and a
    // dark edge besides.
    final colours = sceneCache.snake;
    final paint = Paint()..color = Colors.white.withValues(alpha: .85);
    for (final (spot, radius) in samples) {
      canvas.drawCircle(spot, radius + girth * .05, paint);
    }
    paint.color = colours.edge;
    for (final (spot, radius) in samples) {
      canvas.drawCircle(spot, radius + girth * .025, paint);
    }
    paint.color = colours.body;
    for (final (spot, radius) in samples) {
      canvas.drawCircle(spot, radius, paint);
    }
    // Pale diamonds along the back.
    final every = math.max(1, (cell * .34 / math.max(1.5, cell * .07)).round());
    paint.color = colours.spots;
    for (var i = every ~/ 2; i < samples.length - 2; i += every) {
      final (spot, radius) = samples[i];
      final size = radius * .55;
      canvas.drawPath(
        Path()
          ..moveTo(spot.dx, spot.dy - size)
          ..lineTo(spot.dx + size, spot.dy)
          ..lineTo(spot.dx, spot.dy + size)
          ..lineTo(spot.dx - size, spot.dy)
          ..close(),
        paint,
      );
    }
    // The head points the way it is going, its tongue flicking now and then.
    var facing = game.hunterHeading;
    if (facing.distance == 0) facing = const Offset(1, 0);
    final h = girth * .22;
    canvas.save();
    canvas.translate(spine.last.dx, spine.last.dy);
    canvas.rotate(facing.direction);
    if (math.sin(wave * 5) > -.2) {
      canvas.drawPath(
        Path()
          ..moveTo(h * 1.2, 0)
          ..lineTo(h * 1.85, 0)
          ..lineTo(h * 2.2, -h * .28)
          ..moveTo(h * 1.85, 0)
          ..lineTo(h * 2.2, h * .28),
        Paint()
          ..color = _danger
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, girth * .035)
          ..strokeCap = StrokeCap.round,
      );
    }
    final head = Path()
      ..moveTo(-h * .9, -h * .55)
      ..quadraticBezierTo(h * .1, -h * 1.15, h * .85, -h * .5)
      ..quadraticBezierTo(h * 1.35, 0, h * .85, h * .5)
      ..quadraticBezierTo(h * .1, h * 1.15, -h * .9, h * .55)
      ..close();
    canvas.drawPath(
      head,
      Paint()
        ..color = Colors.white.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = girth * .1
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = colours.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = girth * .05
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(head, Paint()..color = colours.head);
    for (final s in [-1.0, 1.0]) {
      final eye = Offset(h * .3, s * h * .52);
      canvas.drawCircle(eye, h * .27, Paint()..color = const Color(0xFFFFF3C4));
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: h * .32, height: h * .12),
        Paint()..color = ink,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EscapePainter oldDelegate) =>
      !identical(oldDelegate.game, game) ||
      oldDelegate.character != character ||
      oldDelegate.overview != overview ||
      oldDelegate.sceneryImage != sceneryImage;
}
