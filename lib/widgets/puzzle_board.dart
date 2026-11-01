import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config/game_settings.dart';
import '../game/puzzle.dart';
import 'animal_avatar.dart';
import 'critters.dart';

const ink = Color(0xFF25374C);
const accent = Color(0xFF4264E9);
const mint = Color(0xFF15A581);

class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.game,
    required this.onArrow,
    this.onRescue,
    this.chase = false,
    this.timed = false,
  });
  final PuzzleGame game;
  final ValueChanged<int> onArrow;
  final ValueChanged<int>? onRescue;
  // Solo rescue: the hunter closes in on a clock, not only after mistakes.
  final bool chase;
  // Solo play: the level's countdown runs while this board is on screen,
  // so it stops whenever the game is paused.
  final bool timed;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  // An animal's run home, or its shake when the route is still blocked.
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  // A blocked arrow bumps forward and springs back.
  late final AnimationController _shake =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _blocked = null);
        }
      });
  // Arrows sliding off the board. Several can be in flight at once, so each
  // keeps its own start time on a shared clock.
  final _flights = <_Flight>[];
  late final Ticker _flightClock = createTicker(_onFlight);
  final _flightTime = ValueNotifier(Duration.zero);
  // Big picture boards can be pinched to zoom; panning only once zoomed so
  // the page still scrolls normally.
  final _zoom = TransformationController();
  double _scale = 1;
  // Rescue scenes: the hunter prowls the border toward its prey, leaps
  // closer after every mistake and pounces when it arrives.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  // Plays a roar after a mistake, or the final pounce.
  late final AnimationController _hunt = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Ticker _clock = createTicker(_onClock);
  late final Ticker _countdown = createTicker(_onCountdown);
  Duration _lastCount = Duration.zero;
  Duration _lastTick = Duration.zero;
  // Hunter position along its route as drawn, easing toward the real one.
  final _shown = ValueNotifier<double>(0);
  late int _lives = widget.game.lives;
  bool _pounced = false;
  bool _roaring = false;
  int? _blocked;
  RescueTarget? _escaping;
  int? _blockedAnimal;

  bool get _chasing => widget.chase && GameSettings.rescueChase;

  // Without a chase clock (multiplayer) the hunter waits nearby and only
  // mistakes bring it closer.
  double get _huntTarget {
    final game = widget.game;
    if (game.isGameOver) return 1;
    return _chasing ? game.huntProgress : .8 + (3 - game.lives) * .05;
  }

  // Idle motion loops while the chase is on; otherwise it runs for a while
  // after each change, then rests so the board can settle.
  void _wake() {
    if (!widget.game.isRescue) return;
    final live = _chasing && !widget.game.allRescued && !widget.game.isGameOver;
    live ? _ambient.repeat() : _ambient.repeat(count: 12);
    if (!_clock.isActive) {
      _lastTick = Duration.zero;
      _clock.start();
    }
  }

  void _onClock(Duration elapsed) {
    final step = elapsed - _lastTick;
    final dt = step.inMicroseconds / 1e6;
    _lastTick = elapsed;
    final game = widget.game;
    final target = _huntTarget;
    final shown = _shown.value + (target - _shown.value) * min(1, dt * 6);
    _shown.value = shown;
    final settled = (target - shown).abs() < .002;
    if (settled && (!_chasing || game.allRescued || game.isGameOver)) {
      _clock.stop();
    }
  }

  void _onCountdown(Duration elapsed) {
    final game = widget.game;
    game.advanceTime(elapsed - _lastCount);
    _lastCount = elapsed;
    if (game.isComplete || game.isGameOver) _countdown.stop();
  }

  void _onGame() {
    final game = widget.game;
    if (game.isRescue && game.isComplete) _sweepAway();
    if (game.lives < _lives && !game.isGameOver) {
      _roaring = true;
      _hunt.forward(from: 0);
    }
    _lives = game.lives;
    if (game.isRescue && game.isGameOver && !_pounced) {
      _pounced = true;
      _roaring = false;
      _hunt.forward(from: 0);
    }
    _wake();
    // Arrows, animals and their tap targets changed.
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_onGame);
      widget.game.addListener(_onGame);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_onGame);
    // The hunter enters at the far corner and starts prowling.
    _shown.value = _chasing ? widget.game.huntProgress : 0;
    _wake();
    final game = widget.game;
    if (widget.timed &&
        GameSettings.levelTimer &&
        !game.isComplete &&
        !game.isGameOver) {
      _countdown.start();
    }
    _zoom.addListener(() {
      final scale = _zoom.value.getMaxScaleOnAxis();
      if ((scale > 1.01) != (_scale > 1.01)) setState(() => _scale = scale);
      _scale = scale;
    });
  }

  @override
  void dispose() {
    widget.game.removeListener(_onGame);
    _clock.dispose();
    _countdown.dispose();
    _flightClock.dispose();
    _flightTime.dispose();
    _shake.dispose();
    _shown.dispose();
    _ambient.dispose();
    _hunt.dispose();
    _zoom.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _tap(ArrowPiece arrow) {
    final game = widget.game;
    if (game.isGameOver || game.isComplete) return;
    final canExit = game.canExit(arrow);
    widget.onArrow(arrow.id);
    _wake();
    if (!canExit) {
      setState(() => _blocked = arrow.id);
      _shake.forward(from: 0);
      return;
    }
    // Once the last arrow on its route is gone, the animal runs home itself
    // as soon as that arrow is out of the way.
    _launch(
      arrow,
      rescueAfter: game.waitingAnimals.where(game.canRescue).firstOrNull,
    );
  }

  final _launched = <int>{};

  void _launch(
    ArrowPiece arrow, {
    RescueTarget? rescueAfter,
    Duration delay = Duration.zero,
  }) {
    _launched.add(arrow.id);
    // Distance in cells until the tail has left the board.
    var ahead = 0;
    for (
      var c = arrow.head.step(arrow.direction);
      widget.game.level.contains(c);
      c = c.step(arrow.direction)
    ) {
      ahead++;
    }
    final cells = ahead + arrow.cells.length + 1;
    if (!_flightClock.isActive) {
      _flightTime.value = Duration.zero;
      _flightClock.start();
    }
    _flights.add(
      _Flight(
        arrow: arrow,
        cells: cells,
        start: _flightTime.value + delay,
        // Roughly the same speed for every arrow, long or short.
        duration: Duration(milliseconds: (240 + cells * 22).clamp(320, 900)),
        rescueAfter: rescueAfter,
      ),
    );
  }

  // When a rescue wins the level, the arrows still standing fly off one
  // after another.
  void _sweepAway() {
    final game = widget.game;
    var i = 0;
    for (final arrow in game.level.arrows) {
      if (!game.removed.contains(arrow.id) || _launched.contains(arrow.id)) {
        continue;
      }
      _launch(arrow, delay: Duration(milliseconds: 250 + 35 * i++));
    }
  }

  void _onFlight(Duration elapsed) {
    _flightTime.value = elapsed;
    final landed = _flights
        .where((f) => elapsed - f.start >= f.duration)
        .toList();
    if (landed.isEmpty) return;
    _flights.removeWhere(landed.contains);
    if (_flights.isEmpty) _flightClock.stop();
    for (final flight in landed) {
      final target = flight.rescueAfter;
      final game = widget.game;
      if (target != null &&
          game.waitingAnimals.contains(target) &&
          game.canRescue(target)) {
        _rescue(target);
      }
    }
  }

  void _rescue(RescueTarget target) {
    if (_animation.isAnimating ||
        widget.game.isGameOver ||
        widget.game.isComplete ||
        widget.onRescue == null) {
      return;
    }
    final clear = widget.game.canRescue(target);
    setState(() {
      _escaping = clear ? target : null;
      _blockedAnimal = clear ? null : target.id;
    });
    widget.onRescue!(target.id);
    // A safe run home takes longer on a long winding road, and leaves time
    // for a little celebration at the gate.
    final steps =
        widget.game.level.escapeRoute(target, {
          for (final a in widget.game.remaining) ...a.cells,
        })?.length ??
        0;
    _animation.duration = Duration(
      milliseconds: clear ? (1000 + steps * 50).clamp(1400, 2800) : 420,
    );
    _animation.forward(from: 0);
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final cell = side / (widget.game.level.size + 1);
        final margin = cell;
        Offset point(Cell c) =>
            Offset(margin + c.x * cell, margin + c.y * cell);
        // Fingers are wider than the small cells of large pictures.
        final reach = max(cell * .6, 18 / _scale);
        final board = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            // Whatever is closest to the finger wins, so taps on arrows
            // beside an animal never land on the animal by mistake.
            ArrowPiece? nearest;
            var distance = reach;
            for (final arrow in widget.game.remaining) {
              for (final c in arrow.cells) {
                final d = (point(c) - details.localPosition).distance;
                if (d < distance) {
                  nearest = arrow;
                  distance = d;
                }
              }
            }
            for (final target in widget.game.waitingAnimals) {
              final d = (point(target.cell) - details.localPosition).distance;
              if (d < max(distance, cell * .44)) {
                _rescue(target);
                return;
              }
            }
            if (nearest != null) _tap(nearest);
          },
          // The picture and arrows repaint only when they change; the
          // animals sit on their own layer and animate every frame. The
          // accessibility nodes are built once per change, not per frame.
          child: ClipRect(
            child: SizedBox(
              width: side,
              height: cell * (widget.game.level.rows + 1),
              child: Stack(
                children: [
                  for (final layer in [
                    _Layer.board,
                    _Layer.motion,
                    if (widget.game.isRescue) _Layer.animals,
                  ])
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _BoardPainter(
                            game: widget.game,
                            layer: layer,
                            flights: _flights,
                            flightTime: _flightTime,
                            blocked: _blocked,
                            shake: _shake,
                            escaping: _escaping,
                            blockedAnimal: _blockedAnimal,
                            motion: _animation,
                            idle: _ambient,
                            lunge: _hunt,
                            progress: _shown,
                            roaring: _roaring,
                            pounced: _pounced,
                          ),
                        ),
                      ),
                    ),
                  for (final target in widget.game.waitingAnimals)
                    Positioned(
                      left: point(target.cell).dx - cell / 2,
                      top: point(target.cell).dy - cell / 2,
                      width: cell,
                      height: cell,
                      child: Semantics(
                        label:
                            'Rescue ${widget.game.level.rescue!.preySingular}, escape ${target.exit.label}',
                        button: true,
                        onTap: () => _rescue(target),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  for (final arrow in widget.game.remaining)
                    Positioned(
                      left: point(arrow.head).dx - cell / 2,
                      top: point(arrow.head).dy - cell / 2,
                      width: cell,
                      height: cell,
                      child: Semantics(
                        label:
                            'Arrow ${arrow.id + 1}, pointing ${arrow.direction.label}',
                        button: true,
                        onTap: () => _tap(arrow),
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        return InteractiveViewer(
          transformationController: _zoom,
          maxScale: 3,
          panEnabled: _scale > 1.01,
          child: RepaintBoundary(child: board),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.game,
    required this.layer,
    required this.flights,
    required this.flightTime,
    required this.blocked,
    required this.shake,
    required this.escaping,
    required this.blockedAnimal,
    required this.motion,
    required this.idle,
    required this.lunge,
    required this.progress,
    required this.roaring,
    required this.pounced,
  }) : super(
         repaint: switch (layer) {
           // The still picture repaints only when the game changes.
           _Layer.board => game,
           _Layer.motion => Listenable.merge([shake, flightTime]),
           _Layer.animals => Listenable.merge([
             game,
             motion,
             idle,
             lunge,
             progress,
           ]),
         },
       );
  final PuzzleGame game;
  final _Layer layer;
  final List<_Flight> flights;
  final ValueListenable<Duration> flightTime;
  final int? blocked;
  final Animation<double> shake;
  final RescueTarget? escaping;
  final int? blockedAnimal;
  final Animation<double> motion;
  final Animation<double> idle;
  final Animation<double> lunge;
  final ValueListenable<double> progress;
  final bool roaring;
  final bool pounced;

  double get animation => motion.value;
  double get ambient => idle.value;
  // How far the hunter has come along its route, 1 meaning it has arrived.
  double get hunt => progress.value;
  // Progress of a lunge, 0 when the hunter is still.
  double get roar =>
      roaring && lunge.status == AnimationStatus.forward ? lunge.value : 0;
  // Progress of the final pounce, 0 while the prey is still safe.
  double get caught => pounced ? lunge.value : 0;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / (game.level.size + 1);
    Offset point(Cell c) => Offset(cell + c.x * cell, cell + c.y * cell);
    const arrowColor = ink;
    switch (layer) {
      case _Layer.animals:
        _drawAnimals(canvas, size, cell, point);
      case _Layer.motion:
        // Same colour as on the board, so nothing flickers at take-off.
        _drawMotion(canvas, size, cell, point, arrowColor);
      case _Layer.board:
        // A soft outline keeps the board's shape visible as arrows fly away.
        final silhouette = Path();
        for (final c in game.level.shape) {
          silhouette.addRect(
            Rect.fromCenter(
              center: point(c),
              width: cell + 1,
              height: cell + 1,
            ),
          );
        }
        canvas.drawPath(silhouette, Paint()..color = const Color(0xFFF2F4F8));
        final dot = Paint()..color = const Color(0xFFCFD6E0);
        for (final c in game.level.shape) {
          canvas.drawCircle(point(c), min(2, cell * .08), dot);
        }
        _drawRescuePaths(canvas, size, cell, point);
        for (final arrow in game.remaining) {
          // A bumping arrow is drawn on the motion layer instead.
          if (arrow.id == blocked) continue;
          final lit = arrow.id == game.highlightedId;
          _drawArrow(
            canvas,
            arrow,
            point,
            cell,
            lit ? mint : arrowColor,
            Offset.zero,
            lit,
          );
        }
    }
  }

  void _drawMotion(
    Canvas canvas,
    Size size,
    double cell,
    Offset Function(Cell) point,
    Color color,
  ) {
    final bumping = game.remaining.where((a) => a.id == blocked).firstOrNull;
    if (bumping != null) {
      // Lurch toward the blocker, then wobble back into place.
      final t = shake.value;
      final way = Offset(
        bumping.direction.dx.toDouble(),
        bumping.direction.dy.toDouble(),
      );
      _drawArrow(
        canvas,
        bumping,
        point,
        cell,
        const Color(0xFFE46662),
        way * cell * .3 * sin(t * pi * 3) * (1 - t),
        false,
      );
    }
    final now = flightTime.value;
    for (final flight in flights) {
      // An undo can bring an arrow back while it is still in flight.
      if (!game.removed.contains(flight.arrow.id)) continue;
      final t =
          ((now - flight.start).inMicroseconds / flight.duration.inMicroseconds)
              .clamp(0.0, 1.0);
      // Moves at once, then gathers speed; the body follows its own path
      // and straightens out as it leaves.
      final eased = .3 * t + .7 * t * t;
      _drawArrow(
        canvas,
        flight.arrow,
        point,
        cell,
        color.withValues(alpha: 1 - ((t - .75) / .25).clamp(0.0, 1.0)),
        Offset.zero,
        false,
        travel: max(.001, eased * flight.cells * cell),
      );
    }
  }

  void _drawRescuePaths(
    Canvas canvas,
    Size size,
    double cell,
    Offset Function(Cell) point,
  ) {
    final scene = game.level.rescue;
    if (scene == null) return;
    final walls = {for (final a in game.remaining) ...a.cells};
    for (final target in scene.targets) {
      if (game.rescued.contains(target.id)) continue;
      // Light up every cell the animal can already reach; once that touches
      // the edge of the maze, it is free.
      final open = game.level.reachable(target, walls);
      final safe = game.canRescue(target);
      final roads = Path();
      for (final c in open) {
        roads.addRect(
          Rect.fromCenter(center: point(c), width: cell + 1, height: cell + 1),
        );
      }
      canvas.drawPath(
        roads,
        Paint()..color = mint.withValues(alpha: safe ? .24 : .12),
      );
    }
  }

  // The point a fraction [t] of the way along a path of straight legs.
  static Offset _along(List<Offset> stops, double t) {
    var total = 0.0;
    for (var i = 1; i < stops.length; i++) {
      total += (stops[i] - stops[i - 1]).distance;
    }
    var left = t.clamp(0.0, 1.0) * total;
    for (var i = 1; i < stops.length; i++) {
      final leg = (stops[i] - stops[i - 1]).distance;
      if (leg > 0 && left <= leg) {
        return Offset.lerp(stops[i - 1], stops[i], left / leg)!;
      }
      left -= leg;
    }
    return stops.last;
  }

  void _drawAnimals(
    Canvas canvas,
    Size size,
    double cell,
    Offset Function(Cell) point,
  ) {
    final scene = game.level.rescue;
    if (scene == null) return;
    final wave = ambient * 2 * pi;
    // Animals stay a readable size even on large picture boards.
    final unit = max(cell, 34.0);
    final near = ((hunt - .6) / .4).clamp(0.0, 1.0);
    final danger = max((3 - game.lives) / 3, near);
    for (final target in scene.targets) {
      final rescued = game.rescued.contains(target.id);
      final fleeing = rescued && escaping?.id == target.id && animation < 1;
      if (rescued && !fleeing) continue;

      if (!rescued) {
        var position = point(target.cell);
        final highlighted = game.highlightedTargetId == target.id;
        if (target.id == blockedAnimal && animation < 1) {
          position += Offset(
            sin(animation * pi * 6) * cell * .1 * (1 - animation),
            0,
          );
        }
        // The prey trembles harder the closer the hunter gets.
        position += Offset(sin(wave * 7) * unit * (.008 + .025 * danger), 0);
        final scale = 1 - .75 * Curves.easeIn.transform(caught);
        if (danger > 0 && caught == 0) {
          canvas.drawCircle(
            position,
            unit * (.47 + .04 * sin(wave * 2)),
            Paint()
              ..color = const Color(0xFFE46662)
                  .withValues(alpha: .18 + .22 * danger)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(
          position,
          unit * .43 * scale,
          Paint()
            ..color = highlighted
                ? const Color(0xFFC9F2E5)
                : const Color(0xFFFFF2D9),
        );
        if ((highlighted || game.canRescue(target)) && caught == 0) {
          canvas.drawCircle(
            position,
            unit * .44,
            Paint()
              ..color = mint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        drawAnimalPortrait(canvas, position, unit * .36 * scale, scene.prey);
      }

      // The hunter is drawn last so it lands on top of its prey.
      var progress = hunt;
      var alpha = 1.0;
      if (fleeing) {
        // Outrun, the hunter slinks back the way it came.
        progress -= Curves.easeIn.transform(animation) * .25;
        alpha = 1 - animation;
      }
      // The snake keeps to its route: its head leads and the body follows
      // every bend behind it, all within the lane between the arrows.
      final (spot, heading) = _huntRoute(target, progress);
      var hunter = point(const Cell(0, 0)) + spot * cell;
      if (progress >= 1) hunter = point(target.cell);
      canvas.saveLayer(
        null,
        Paint()..color = Colors.black.withValues(alpha: alpha),
      );
      if (scene.predator == AnimalKind.snake) {
        _drawSnake(
          canvas,
          target,
          progress,
          hunter,
          heading,
          cell,
          point,
          wave,
        );
      } else {
        // Four-legged hunters and the owl pace their lane, seen from above.
        drawStalker(
          canvas,
          hunter,
          cell * 1.3,
          scene.predator,
          heading,
          wave * 5,
        );
      }
      if (roar > 0 && !fleeing) {
        final strength = sin(pi * roar);
        final waves = Paint()
          ..color = const Color(0xFFE46662).withValues(alpha: .7 * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        final prey = point(target.cell) - hunter;
        final facing = prey.distance < 1 ? 0.0 : prey.direction;
        for (var i = 0; i < 2; i++) {
          final r = unit * (.55 + i * .16 + roar * .1);
          canvas.drawArc(
            Rect.fromCircle(center: hunter, radius: r),
            facing - pi / 4,
            pi / 2,
            false,
            waves,
          );
        }
      }
      canvas.restore();
    }
    if (escaping != null &&
        animation < 1 &&
        game.rescued.contains(escaping!.id)) {
      // Hop along the road it found to the edge of the maze and out, then
      // celebrate there.
      final route =
          game.level.escapeRoute(escaping!, {
            for (final a in game.remaining) ...a.cells,
          }) ??
          [escaping!.cell];
      final way = game.level.exitFrom(route.last);
      final gate =
          point(route.last) +
          Offset(way.dx.toDouble(), way.dy.toDouble()) * cell * .9;
      final stops = [for (final c in route) point(c), gate];
      final run = Curves.easeInOutCubic.transform(
        (animation / .55).clamp(0, 1),
      );
      final hop = sin(run * pi * 6).abs() * unit * .3 * (1 - run);
      final party = ((animation - .5) / .5).clamp(0.0, 1.0);
      final position = _along(stops, run) - Offset(0, hop);
      if (party > 0) {
        const colors = [
          Color(0xFF15A581),
          Color(0xFFE8AA42),
          Color(0xFFE46682),
          Color(0xFF4264E9),
        ];
        final burst = Curves.easeOutCubic.transform(party);
        for (var i = 0; i < 12; i++) {
          final angle = i / 12 * 2 * pi;
          final spark =
              gate + Offset(cos(angle), sin(angle)) * unit * (.3 + 1.1 * burst);
          canvas.drawCircle(
            spark,
            unit * (i.isEven ? .09 : .06) * (1 - party * .5),
            Paint()
              ..color = colors[i % colors.length].withValues(alpha: 1 - party),
          );
        }
        canvas.drawCircle(
          gate,
          unit * (.5 + .3 * burst),
          Paint()
            ..color = mint.withValues(alpha: .35 * (1 - party))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      final scale = 1 - .35 * party;
      canvas.drawCircle(
        position,
        unit * .43 * scale,
        Paint()..color = const Color(0xFFC9F2E5),
      );
      drawAnimalPortrait(canvas, position, unit * .36 * scale, scene.prey);
    }
  }

  // The hunter walks the margin outside the grid from its corner, then
  // straight in to its prey. Returns the position in cell units from cell
  // (0, 0) and the direction of travel.
  double _huntRouteLength(RescueTarget target) {
    final route = game.level.hunterRoute(target);
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      total +=
          (route[i].$1 - route[i - 1].$1).abs() +
          (route[i].$2 - route[i - 1].$2).abs();
    }
    return total;
  }

  // A green striped snake, as thick as its lane allows, tapering to a thin
  // tail. Its body sways a little inside the lane and its tongue flicks.
  void _drawSnake(
    Canvas canvas,
    RescueTarget target,
    double progress,
    Offset head,
    Offset heading,
    double cell,
    Offset Function(Cell) point,
    double wave,
  ) {
    final total = max(1.0, _huntRouteLength(target));
    const bodyCells = 5.5, segments = 28;
    final origin = point(const Cell(0, 0));
    final body = Paint();
    for (var k = segments; k >= 1; k--) {
      final back = k / segments * bodyCells;
      final p = progress - back / total;
      if (p < 0) continue;
      final (spot, along) = _huntRoute(target, p);
      final side = Offset(-along.dy, along.dx);
      final sway = sin(back * 1.7 - wave * 3) * cell * .07 * (k / segments);
      final at = origin + spot * cell + side * sway;
      final thick = cell * (.13 + .17 * (1 - k / segments));
      body.color = k.isEven ? const Color(0xFF3E8E41) : const Color(0xFF2F6E33);
      canvas.drawCircle(at, thick, body);
    }
    // Head, pointing the way it is going.
    final angle = heading.direction;
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(angle);
    final h = cell * .34;
    if (sin(wave * 5) > .4) {
      final tongue = Paint()
        ..color = const Color(0xFFD9485F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, cell * .05)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(h * .9, 0)
          ..lineTo(h * 1.6, 0)
          ..lineTo(h * 1.9, -h * .25)
          ..moveTo(h * 1.6, 0)
          ..lineTo(h * 1.9, h * .25),
        tongue,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: h * 2.3, height: h * 1.7),
      Paint()..color = const Color(0xFF4CA14F),
    );
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(h * .35, s * h * .45),
        h * .26,
        Paint()..color = const Color(0xFFFFE27A),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(h * .38, s * h * .45),
          width: h * .1,
          height: h * .36,
        ),
        Paint()..color = const Color(0xFF1E2A1E),
      );
    }
    canvas.restore();
  }

  (Offset, Offset) _huntRoute(RescueTarget target, double progress) {
    final route = [
      for (final (x, y) in game.level.hunterRoute(target)) Offset(x, y),
    ];
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      total += (route[i] - route[i - 1]).distance;
    }
    var left = progress.clamp(0.0, 1.0) * total;
    for (var i = 1; i < route.length; i++) {
      final leg = route[i] - route[i - 1];
      if (leg.distance == 0) continue;
      if (left <= leg.distance || i == route.length - 1) {
        final heading = leg / leg.distance;
        return (route[i - 1] + heading * min(left, leg.distance), heading);
      }
      left -= leg.distance;
    }
    return (route.last, const Offset(1, 0));
  }

  void _drawArrow(
    Canvas canvas,
    ArrowPiece arrow,
    Offset Function(Cell) point,
    double cell,
    Color color,
    Offset offset,
    bool highlight, {
    double travel = 0,
  }) {
    final points = arrow.cells.map((c) => point(c) + offset).toList();
    final direction = Offset(
      arrow.direction.dx.toDouble(),
      arrow.direction.dy.toDouble(),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (cell * .14).clamp(2.2, 3.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    var path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    var head = points.last;
    if (travel > 0) {
      // Extend the route straight out past the head and show a window of the
      // body's length that has advanced [travel] pixels along it.
      final far = points.last + direction * (travel + cell);
      path.lineTo(far.dx, far.dy);
      final length = (points.length - 1) * cell;
      final metric = path.computeMetrics().first;
      path = metric.extractPath(travel, travel + length);
      head = metric.getTangentForOffset(travel + length)!.position;
    }
    if (highlight) {
      canvas.drawPath(
        path,
        Paint()
          ..color = mint.withValues(alpha: .14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * .48
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.drawPath(path, paint);
    final perpendicular = Offset(-direction.dy, direction.dx);
    final tip = head + direction * cell * .22;
    final back = tip - direction * max(cell * .3, 5);
    final wing = perpendicular * max(cell * .26, 4.5);
    canvas.drawPath(
      Path()
        ..moveTo((back + wing).dx, (back + wing).dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo((back - wing).dx, (back - wing).dy),
      paint,
    );
    canvas.drawLine(head, tip, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}

enum _Layer { board, motion, animals }

class _Flight {
  const _Flight({
    required this.arrow,
    required this.cells,
    required this.start,
    required this.duration,
    this.rescueAfter,
  });
  final ArrowPiece arrow;
  // How far it travels, in cells, until its tail is off the board.
  final int cells;
  final Duration start;
  final Duration duration;
  // The animal whose route this arrow was the last to clear.
  final RescueTarget? rescueAfter;
}
