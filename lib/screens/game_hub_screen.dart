import 'package:flutter/material.dart';

import 'dart:math' as math;

import '../config/game_settings.dart';
import '../config/progress_store.dart';
import '../escape/maze_escape.dart' show EscapeMaze;
import '../multiplayer/competition_screen.dart';
import '../game/puzzle_rules.dart';
import '../widgets/critters.dart';
import '../widgets/character_art.dart';
import '../widgets/game_button.dart';
import '../widgets/player_avatar.dart';
import 'arrow_game_screen.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});
  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen>
    with TickerProviderStateMixin {
  int _selected = 0;
  // The mode the game screen shows, and the modes already played.
  PlayMode _mode = PlayMode.basic;
  final Set<PlayMode> _visited = {};
  void _open(PlayMode mode) => setState(() {
    _visited.add(mode);
    _mode = mode;
    _selected = 1;
    ProgressStore.setString('lastMode', mode.name);
  });
  void _home() => setState(() => _selected = 0);

  // One entrance played on start, and a slow loop for everything that
  // keeps moving (background and previews).
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (GameSettings.homeMotion) _loop.repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  static const _night = Color(0xFF1E1846);
  static const _gold = Color(0xFFFFC23D);

  static const _looks = {
    PlayMode.basic: (
      color: Color(0xFF4C6BFF),
      shade: Color(0xFF2E45C4),
      blurb: 'Tap arrows to slide them out. Clear the whole board.',
    ),
    PlayMode.rescue: (
      color: Color(0xFFFF8A3D),
      shade: Color(0xFFCC5F1A),
      blurb: 'Free the little animal before the hunter gets there.',
    ),
    PlayMode.escape: (
      color: Color(0xFF1DB98A),
      shade: Color(0xFF0F8662),
      blurb: 'Run for the exit. The hunter is right behind you!',
    ),
  };

  static int _levelCount(PlayMode mode) =>
      mode == PlayMode.escape ? EscapeMaze.count : PuzzleLevel.count;

  ({int level, int unlocked, int stars}) _progress(PlayMode mode) {
    final saved = ProgressStore.load(mode.name);
    return (
      level: saved?.level ?? 1,
      unlocked: saved?.unlocked ?? 1,
      stars: saved?.stars.values.fold<int>(0, (a, b) => a + b) ?? 0,
    );
  }

  // The game played last, or null before the first one.
  PlayMode? get _lastMode {
    final saved = ProgressStore.getString('lastMode');
    for (final mode in PlayMode.values) {
      if (mode.name == saved) return mode;
    }
    return _visited.isEmpty ? null : _mode;
  }

  // Slides and fades a piece in, each a little after the one before.
  Widget _enter(int order, Widget child) => AnimatedBuilder(
    animation: _intro,
    child: child,
    builder: (context, child) {
      final start = (order * .12).clamp(0.0, .6);
      final t = Curves.easeOutBack.transform(
        ((_intro.value - start) / (1 - start)).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: child,
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _selected == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _home();
    },
    child: IndexedStack(
      index: _selected,
      children: [
        _homeScreen(),
        // One game screen keeps every mode's progress; the card picks which
        // mode it shows.
        _visited.isNotEmpty
            ? GameScreen(mode: _mode, onHome: _home, active: _selected == 1)
            : const SizedBox.shrink(),
      ],
    ),
  );

  Widget _homeScreen() {
    final totalStars = PlayMode.values.fold<int>(
      0,
      (sum, m) => sum + _progress(m).stars,
    );
    return Scaffold(
      backgroundColor: _night,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HomeBackdrop(_loop)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _enter(0, _topBar(totalStars)),
                      // Only once something has been played: carry on there.
                      if (_lastMode case final last?) ...[
                        const SizedBox(height: 26),
                        _enter(1, _continueButton(last)),
                      ],
                      const SizedBox(height: 28),
                      _enter(
                        2,
                        const Text(
                          'CHOOSE A GAME',
                          style: TextStyle(
                            color: Color(0xFFB9B2E8),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 780;
                          final cards = [
                            for (final (i, mode) in PlayMode.values.indexed)
                              _enter(3 + i, _gameCard(mode)),
                          ];
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      if (i != 0) const SizedBox(width: 16),
                                      Expanded(child: cards[i]),
                                    ],
                                  ],
                                )
                              : Column(
                                  children: [
                                    for (final card in cards)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: card,
                                      ),
                                  ],
                                );
                        },
                      ),
                      if (GameSettings.showCompetition) ...[
                        const SizedBox(height: 4),
                        GameButton(
                          color: const Color(0xFF3A3170),
                          shade: const Color(0xFF241E52),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CompetitionScreen(),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: _gold,
                                  size: 28,
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Competition',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(int stars) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0xFFC98A00), offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.call_split_rounded, color: _night, size: 28),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Way'),
              TextSpan(
                text: 'Out',
                style: TextStyle(color: _gold),
              ),
            ],
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
      ),
      Semantics(
        label: '$stars stars earned',
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .28),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: _gold, size: 24),
              const SizedBox(width: 4),
              Text(
                '$stars',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _continueButton(PlayMode mode) {
    final level = _progress(mode).level;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: .16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GameButton(
        color: _gold,
        shade: const Color(0xFFBD791C),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE59A), Color(0xFFFFCB4B), Color(0xFFFFB52E)],
        ),
        radius: 26,
        depth: 4,
        onTap: () => _open(mode),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -42,
                child: ExcludeSemantics(
                  child: Container(
                    width: 178,
                    height: 178,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .22),
                        width: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JUMP BACK IN',
                            style: TextStyle(
                              color: Color(0xFF6C491E),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.7,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Continue',
                            style: TextStyle(
                              color: _night,
                              fontSize: 30,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.9,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                mode.title,
                                style: const TextStyle(
                                  color: Color(0xFF604521),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Level $level',
                                  style: const TextStyle(
                                    color: _night,
                                    fontSize: 11,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .5),
                        ),
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3C306A), _night],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x304D3014),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Color(0xFFFFD775),
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameCard(PlayMode mode) {
    final look = _looks[mode]!;
    final progress = _progress(mode);
    final count = _levelCount(mode);
    final done = ((progress.unlocked - 1) / count).clamp(0.0, 1.0);
    return GameButton(
      color: look.color,
      shade: look.shade,
      onTap: () => _open(mode),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: look.shade, offset: const Offset(0, 2)),
                ],
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GamePreview(mode, look.color, _loop),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0x33000000), offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    look.blurb,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: .9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: done,
                            minHeight: 9,
                            color: _gold,
                            backgroundColor: look.shade,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, color: _gold, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        '${progress.stars}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${progress.unlocked} / $count',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Night-sky backdrop: a faint maze grid and arrows drifting upward.
class _HomeBackdrop extends CustomPainter {
  _HomeBackdrop(this.loop) : super(repaint: loop);
  final Animation<double> loop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2266), Color(0xFF1A1440)],
        ).createShader(Offset.zero & size),
    );
    // Maze walls on a grid, picked by a fixed pattern so they never jump.
    const cell = 44.0;
    final wall = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var y = 0; y * cell < size.height + cell; y++) {
      for (var x = 0; x * cell < size.width + cell; x++) {
        final h = (x * 7 + y * 13 + x * y) % 5;
        final p = Offset(x * cell, y * cell);
        if (h < 2) canvas.drawLine(p, p + const Offset(cell, 0), wall);
        if (h == 3) canvas.drawLine(p, p + const Offset(0, cell), wall);
      }
    }
    // Arrows rising slowly, each on its own lane and pace.
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const colours = [
      Color(0xFFFFC23D),
      Color(0xFF6E8BFF),
      Color(0xFFFF8A3D),
      Color(0xFF1DB98A),
    ];
    for (var i = 0; i < 9; i++) {
      final lane = (i * .37 + .08) % 1.0;
      final speed = 1 + i % 3;
      final t = (loop.value * speed + i * .29) % 1.0;
      final x = lane * size.width;
      final y = size.height * (1.1 - t * 1.25);
      final len = 16.0 + (i % 3) * 6;
      arrow.color = colours[i % colours.length].withValues(
        alpha: .22 * math.sin(t * math.pi),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, y + len)
          ..lineTo(x, y)
          ..moveTo(x - len * .4, y + len * .4)
          ..lineTo(x, y)
          ..lineTo(x + len * .4, y + len * .4),
        arrow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeBackdrop oldDelegate) => false;
}

/// A small moving scene of each game on its card.
class _GamePreview extends CustomPainter {
  _GamePreview(this.mode, this.color, this.loop) : super(repaint: loop);
  final PlayMode mode;
  final Color color;
  final Animation<double> loop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 92, size.height / 92);
    final t = loop.value;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void arrowRight(double x, double y, double length, double alpha) {
      paint.color = color.withValues(alpha: alpha);
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + length, y)
          ..moveTo(x + length - 9, y - 8)
          ..lineTo(x + length, y)
          ..lineTo(x + length - 9, y + 8),
        paint,
      );
    }

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 92, 92),
        const Radius.circular(20),
      ),
    );
    switch (mode) {
      case PlayMode.basic:
        // The top arrow slides out to the right and comes back round.
        final slide = Curves.easeIn.transform((t * 3) % 1.0);
        arrowRight(18 + slide * 80, 28, 38, 1 - slide * .6);
        paint.color = color.withValues(alpha: .45);
        canvas.drawPath(
          Path()
            ..moveTo(70, 50)
            ..lineTo(26, 50)
            ..lineTo(26, 72)
            ..moveTo(18, 64)
            ..lineTo(26, 72)
            ..lineTo(34, 64),
          paint,
        );
      case PlayMode.rescue:
        // A chick hops inside a ring of arrows.
        arrowRight(16, 16, 52, .8);
        paint.color = color.withValues(alpha: .8);
        canvas.drawPath(
          Path()
            ..moveTo(16, 76)
            ..lineTo(16, 32)
            ..moveTo(76, 32)
            ..lineTo(76, 76)
            ..moveTo(68, 68)
            ..lineTo(76, 76)
            ..lineTo(84, 68),
          paint,
        );
        final hop = (math.sin(t * math.pi * 2 * 4)).abs();
        drawCritter(
          canvas,
          Offset(46, 56 - hop * 8),
          16,
          AnimalKind.chick,
          phase: t * 8,
          moving: true,
        );
      case PlayMode.escape:
        // The runner dashes through a tiny maze with the hunter behind.
        paint
          ..color = const Color(0xFF3E5468)
          ..strokeWidth = 4;
        canvas.drawPath(
          Path()
            ..moveTo(12, 12)
            ..lineTo(80, 12)
            ..lineTo(80, 40)
            ..moveTo(80, 60)
            ..lineTo(80, 80)
            ..lineTo(12, 80)
            ..lineTo(12, 12)
            ..moveTo(34, 12)
            ..lineTo(34, 54)
            ..moveTo(58, 36)
            ..lineTo(58, 80),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(80, 42, 9, 16),
            const Radius.circular(3),
          ),
          Paint()..color = color,
        );
        // A route: up the left, over the top, down and out the right.
        const route = [
          Offset(23, 68),
          Offset(23, 24),
          Offset(46, 24),
          Offset(46, 68),
          Offset(69, 68),
          Offset(69, 50),
          Offset(96, 50),
        ];
        Offset along(double f) {
          final scaled = f.clamp(0.0, 1.0) * (route.length - 1);
          final i = scaled.floor().clamp(0, route.length - 2);
          return Offset.lerp(route[i], route[i + 1], scaled - i)!;
        }

        final run = (t * 2) % 1.0;
        Offset headingAt(double fraction) {
          final segment = (fraction.clamp(0.0, 1.0) * (route.length - 1))
              .floor()
              .clamp(0, route.length - 2);
          return route[segment + 1] - route[segment];
        }

        if (!CharacterArt.drawActor(
          canvas,
          along(run - .2),
          11,
          'lion',
          heading: headingAt(run - .2),
          clock: t * 6,
          moving: GameSettings.homeMotion,
        )) {
          drawMazeAnimal(
            canvas,
            along(run - .2),
            9,
            AnimalKind.lion,
            hunter: true,
          );
        }
        if (!CharacterArt.drawActor(
          canvas,
          along(run),
          10,
          'male',
          heading: headingAt(run),
          clock: t * 6,
          moving: GameSettings.homeMotion,
        )) {
          drawPlayerPortrait(canvas, along(run), 9, PlayerCharacter.male);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GamePreview oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.color != color;
}
