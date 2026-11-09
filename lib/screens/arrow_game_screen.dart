import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../escape/escape_board.dart';
import '../escape/maze_decor.dart';
import '../escape/maze_escape.dart';
import '../escape/maze_frame.dart';
import '../escape/maze_pad.dart';
import '../escape/maze_palette.dart';
import '../escape/maze_theme.dart';
import '../game/puzzle.dart';
import '../config/game_settings.dart';
import '../config/game_sounds.dart';
import '../config/progress_store.dart';
// Restore this import when enabling the competition button below.
// import '../multiplayer/competition_screen.dart';
import '../widgets/status_bar_tone.dart';
import '../widgets/animal_avatar.dart';
import '../widgets/character_art.dart';
import '../widgets/celebration.dart';
import '../widgets/game_button.dart';
import '../widgets/scene_backdrop.dart';
import '../widgets/critters.dart' show MazeAnimalAvatar;
import '../widgets/player_avatar.dart';
import '../widgets/puzzle_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.mode = PlayMode.basic,
    this.onHome,
    this.active = true,
  });
  // Which of the three ways to play is on screen; picked on the home screen.
  final PlayMode mode;
  final VoidCallback? onHome;
  final bool active;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

// The three ways to play: the two arrow modes and the Escape maze.
enum PlayMode {
  basic('Arrow Escape', Icons.north_east_rounded),
  rescue('Animal Rescue', Icons.pets_rounded),
  escape('Maze Escape', Icons.directions_run_rounded);

  const PlayMode(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // Built when their mode is first opened: a board can take a moment to make.
  PuzzleGame? _basic, _rescue;
  PuzzleGame get _basicGame => _basic ??= _restoredPuzzle('basic');
  PuzzleGame get _rescueGame => _rescue ??= _restoredPuzzle('rescue');
  final _escapeGame = EscapeGame(
    initialLevel: ProgressStore.startLevel('escape', EscapeMaze.count),
  );
  late PlayMode _view = widget.mode;
  GameMode get _mode =>
      _view == PlayMode.rescue ? GameMode.rescue : GameMode.basic;
  bool get _escaping => _view == PlayMode.escape;
  // A hand-finished maze level dresses the whole screen in its own world.
  MazeDecor? get _decor =>
      _escaping ? MazeDecor.forLevel(_escapeGame.maze.number) : null;
  // Level 170 is shown on a plain white screen; every other level keeps
  // its own world round the board.
  bool get _plainMaze => _escaping && _escapeGame.maze.number == 170;
  Color get _mazeInk =>
      _plainMaze ? MazePalette.text : _decor?.ink ?? MazePalette.text;
  // Animal Rescue has its own warm, game-like look.
  bool get _rescueLook => !_escaping && game.isRescue;
  // What fills the screen behind the game; null is the theme's own colour.
  Color? get _screenColour => _escaping
      ? _plainMaze
            ? Colors.white
            : _decor?.ground ?? _mazePalette.canvas
      : _rescueLook
      ? const Color(0xFFFFF4E6)
      : null;
  static const _sun = Color(0xFFFF8A3D);
  static const _sunShade = Color(0xFFCC5F1A);
  static const _sunInk = Color(0xFF5A2E0E);
  MazePalette get _mazePalette => MazePalette.forMaze(_escapeGame.maze);
  PuzzleGame get game => _mode == GameMode.basic ? _basicGame : _rescueGame;
  // The game on screen and its current attempt, for the confetti.
  Listenable get _current => _escaping ? _escapeGame : game;
  int get _currentRevision => _escaping ? _escapeGame.revision : game.revision;
  String? _feedback;
  ({int id, Listenable game, int revision, String? subtitle, bool banner})?
  _party;
  int _parties = 0;
  bool _paused = false;
  int _modalDepth = 0;
  bool get _inputBlocked =>
      !widget.active || _paused || _choosingCharacter || _modalDepth > 0;
  PlayerCharacter _character = PlayerCharacter.male;
  bool _choosingCharacter = false;
  // A maze pause leaves the maze in view so the way can be studied; it
  // counts down from a minute and then play carries on by itself.
  static const _peekLimit = 60;
  int? _peekLeft;
  Timer? _peekTimer;
  // Maze controls: tap the maze, or the arrow pad. Saved on the device.
  static bool _touchControls = false;
  static const _maxLives = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreProgress();
    _maybeGuide();
  }

  // Picks up where the player left off, then saves as progress is made.
  PuzzleGame _restoredPuzzle(String key) {
    final puzzle = PuzzleGame(
      mode: key == 'rescue' ? GameMode.rescue : GameMode.basic,
      initialLevel: ProgressStore.startLevel(key, PuzzleLevel.count),
      unlockAllLevels: GameSettings.unlockAllLevelsForTesting,
    );
    if (ProgressStore.load(key) case final saved?) {
      puzzle.unlockedLevel = saved.unlocked;
      puzzle.stars.addAll(saved.stars);
    }
    var last = '';
    puzzle.addListener(() {
      final now =
          '${puzzle.level.number}|${puzzle.unlockedLevel}|${puzzle.stars}';
      if (now == last) return;
      last = now;
      ProgressStore.save(
        key,
        level: puzzle.level.number,
        unlocked: puzzle.unlockedLevel,
        stars: puzzle.stars,
      );
    });
    return puzzle;
  }

  void _restoreProgress() {
    final maze = _escapeGame;
    if (ProgressStore.load('escape') case final saved?) {
      maze.unlockedLevel = saved.unlocked;
      maze.stars.addAll(saved.stars);
    }
    var last = '';
    maze.addListener(() {
      final now = '${maze.maze.number}|${maze.unlockedLevel}|${maze.stars}';
      if (now == last) return;
      last = now;
      ProgressStore.save(
        'escape',
        level: maze.maze.number,
        unlocked: maze.unlockedLevel,
        stars: maze.stars,
      );
    });
    _character = PlayerCharacter.values.firstWhere(
      (c) => c.name == ProgressStore.getString('character'),
      orElse: () => _character,
    );
    _touchControls = ProgressStore.getBool('touchControls') ?? _touchControls;
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _view = widget.mode;
      _feedback = null;
      _paused = false;
      _stopPeek();
    }
    if (widget.mode != oldWidget.mode || widget.active && !oldWidget.active) {
      _maybeGuide();
    }
    if (!widget.active) {
      _paused = true;
      _stopPeek();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _peekTimer?.cancel();
    _basic?.dispose();
    _rescue?.dispose();
    _escapeGame.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Leaving the app brings up the full pause menu instead.
      setState(() {
        _paused = true;
        _stopPeek();
      });
    }
  }

  void _startPeek() {
    if (_escapeGame.isOver) return;
    _peekTimer?.cancel();
    setState(() {
      _paused = true;
      _peekLeft = _peekLimit;
    });
    _peekTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_peekLeft! <= 1) {
        _resumePeek();
      } else {
        setState(() => _peekLeft = _peekLeft! - 1);
      }
    });
  }

  void _resumePeek() => setState(() {
    _paused = false;
    _stopPeek();
  });

  void _stopPeek() {
    _peekTimer?.cancel();
    _peekTimer = null;
    _peekLeft = null;
  }

  void _tap(int id) {
    final result = game.tap(id);
    if (game.haptics) {
      if (result == MoveResult.blocked) {
        HapticFeedback.mediumImpact();
      }
      if (result == MoveResult.cleared) {
        HapticFeedback.selectionClick();
      }
    }
    setState(() {
      _feedback = result == MoveResult.blocked
          ? 'That path is blocked! ${_chancesLeft()}'
          : null;
      // The result card already says well done; confetti joins it.
      if (result == MoveResult.cleared && game.isComplete) {
        _celebrate(banner: false);
        if (!game.isRescue) GameSounds.levelClear();
      }
    });
  }

  void _rescueAnimal(int id) {
    final result = game.rescueAnimal(id);
    if (game.haptics) {
      if (result == MoveResult.cleared) HapticFeedback.lightImpact();
      if (result == MoveResult.blocked) HapticFeedback.mediumImpact();
    }
    final prey = game.level.rescue!.preySingular;
    setState(() {
      _feedback = result == MoveResult.cleared
          ? game.isComplete
                ? 'Safe at last! The $prey made it home.'
                : 'The $prey is safe! Now clear every arrow to finish.'
          : 'Still wrapped in arrows! ${_chancesLeft()}';
      if (result == MoveResult.cleared) {
        _celebrate(subtitle: 'You saved the $prey!', banner: !game.isComplete);
      }
    });
  }

  // How many more mistakes the player can make, after one just happened.
  String _chancesLeft() => switch (game.lives) {
    0 => 'No chances left.',
    1 => 'Last chance left!',
    final left => '$left chances left.',
  };

  void _hint() {
    final shown = game.hint();
    setState(
      () => _feedback = shown
          ? game.highlightedTargetId != null
                ? 'The route is clear. Tap the ${game.level.rescue!.preySingular} to rescue it!'
                : 'Follow the green arrow. Its path is clear.'
          : 'No hints left. Look for a clear path to the edge.',
    );
  }

  void _restart() {
    game.restart();
    setState(() => _feedback = null);
  }

  void _escapeHint() {
    final shown = _escapeGame.hint();
    setState(
      () => _feedback = shown
          ? 'Run that way: it leads toward the way out.'
          : 'No hints left. Look for the green gap on the right.',
    );
  }

  Future<void> _confirmRestart() async {
    if (_escaping) {
      _escapeGame.restart();
      setState(() => _feedback = null);
      return;
    }
    if (game.moves == 0 || game.isGameOver || game.isComplete) {
      _restart();
      return;
    }
    final restart = await _withModalPause(
      () => showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .35),
        builder: (context) => game.isRescue
            ? _rescueRestartDialog(context)
            : AlertDialog(
                title: const Text('Start fresh?'),
                content: const Text(
                  'Your moves in this level will be reset. You’ll get three lives and three hints again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep playing'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Restart'),
                  ),
                ],
              ),
      ),
    );
    if (restart == true && mounted) _restart();
  }

  // Animal Rescue's restart question, in the warm card and chunky buttons of
  // its own controls.
  Widget _rescueRestartDialog(BuildContext context) {
    Widget refill(IconData icon, Color color, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D9C2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _sunInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    return Dialog(
      backgroundColor: const Color(0xFFFFF7EE),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFF3D3B4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _sun.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _sunShade,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Start fresh?',
              style: TextStyle(
                color: _sunInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your moves in this level will be reset, and you get everything back:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _sunInk.withValues(alpha: .72),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                refill(
                  Icons.favorite_rounded,
                  const Color(0xFFE5484D),
                  '3 lives',
                ),
                refill(Icons.lightbulb_rounded, _sun, '3 hints'),
              ],
            ),
            const SizedBox(height: 20),
            GameButton(
              color: _sun,
              shade: _sunShade,
              radius: 18,
              depth: 3,
              onTap: () => Navigator.pop(context, true),
              child: const SizedBox(
                height: 50,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Restart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GameButton(
              color: Colors.white,
              shade: const Color(0xFFE8C9AE),
              radius: 18,
              depth: 3,
              onTap: () => Navigator.pop(context, false),
              child: const SizedBox(
                height: 46,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Keep playing',
                    style: TextStyle(
                      color: _sunInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The first time a game's level 1 opens, its guide shows once.
  void _maybeGuide() {
    if (!GameSettings.showGuides || !widget.active) return;
    final level = _escaping ? _escapeGame.maze.number : game.level.number;
    final key = 'guide.${_view.name}';
    if (level != 1 || (ProgressStore.getBool(key) ?? false)) return;
    ProgressStore.setBool(key, true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) _showHelp();
    });
  }

  // Dialogs cover the controls, so the current attempt must wait for them.
  // Keep this separate from the player's pause and lifecycle pause state.
  Future<T> _withModalPause<T>(Future<T> Function() show) async {
    setState(() => _modalDepth++);
    try {
      return await show();
    } finally {
      if (mounted) setState(() => _modalDepth--);
    }
  }

  Future<void> _showHelp() {
    final (title, colour, steps) = _escaping
        ? (
            'Run for the way out!',
            _mazePalette.accent,
            const [
              (
                Icons.swipe_rounded,
                'Swipe or tap the arrow buttons. You run along the path until the next turn.',
              ),
              (
                Icons.pest_control_rounded,
                'A snake comes in from the left after your first move and follows you.',
              ),
              (
                Icons.keyboard_double_arrow_right_rounded,
                'Reach the green arrows on the right to escape. A hint shows which way to run.',
              ),
            ],
          )
        : game.isRescue
        ? (
            'Save the animal!',
            _sun,
            const [
              (
                Icons.pets_rounded,
                'An animal is trapped among the arrows, and a hunter is on its way.',
              ),
              (
                Icons.touch_app_rounded,
                'Tap arrows to send them off the board and open a path to the animal’s gate.',
              ),
              (
                Icons.favorite_rounded,
                'A blocked arrow costs a heart and brings the hunter closer. Be quick!',
              ),
            ],
          )
        : (
            'Clear every arrow!',
            accent,
            const [
              (
                Icons.touch_app_rounded,
                'Tap an arrow and it slides off the board the way it points.',
              ),
              (
                Icons.block_rounded,
                'Its path to the edge must be clear. A blocked arrow costs a heart.',
              ),
              (
                Icons.lightbulb_rounded,
                'Stuck? A hint shows a safe move, and Undo brings your last arrow back.',
              ),
            ],
          );
    return _withModalPause(
      () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    color: colour,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 18),
                for (final (i, (icon, text)) in steps.indexed) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colour.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: colour, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: colour),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Let’s play'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _tileExtent = 64.0, _tileGap = 10.0;

  // Scroll offset that puts [level]'s row one row below the top of a grid
  // laid out like the level picker in [width].
  static double _pickerOffset(double width, int level) {
    final columns = (width / (_tileExtent + _tileGap)).ceil();
    final tile = (width - _tileGap * (columns - 1)) / columns;
    final row = (level - 1) ~/ columns;
    return math.max(0, (row - 1) * (tile + _tileGap));
  }

  Future<void> _showLevels() => _withModalPause(
    () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _escaping
          ? _mazePalette.canvas
          : const Color(0xFFF7F8FC),
      builder: (context) {
        final stars = _escaping ? _escapeGame.stars : game.stars;
        final count = _escaping ? EscapeMaze.count : PuzzleLevel.count;
        final current = _escaping ? _escapeGame.maze.number : game.level.number;
        final done = stars.length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _escaping
                              ? 'Maze runs'
                              : game.isRescue
                              ? 'Rescue adventures'
                              : 'Your little escape',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      // Stars earned so far.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFE8AA42),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stars.values.fold(0, (a, b) => a + b)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB57A12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: done / count,
                            minHeight: 6,
                            color: _escaping ? _mazePalette.accent : mint,
                            backgroundColor: const Color(0xFFE6EAF2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$done / $count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF748094),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                        // Open with the level being played in view, a row down
                        // from the top, so long level lists need no hunting.
                        controller: ScrollController(
                          initialScrollOffset: _pickerOffset(
                            constraints.maxWidth,
                            current,
                          ),
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: _tileExtent,
                              mainAxisSpacing: _tileGap,
                              crossAxisSpacing: _tileGap,
                            ),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          final level = index + 1;
                          final landscape = _escaping
                              ? MazePalette.forLevel(level)
                              : null;
                          return _LevelTile(
                            highlight: landscape?.accent ?? accent,
                            themeLabel: _escaping
                                ? MazeTheme.forLevel(level).label
                                : null,
                            showOpenLocks: !_escaping,
                            level: level,
                            locked: _escaping
                                ? !_escapeGame.isLevelUnlocked(level)
                                : !game.isLevelUnlocked(level),
                            current: level == current,
                            stars: stars[level],
                            onTap: () {
                              _escaping
                                  ? _escapeGame.selectLevel(level)
                                  : game.selectLevel(level);
                              setState(() => _feedback = null);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyH): () {
        if (_inputBlocked) return;
        if (_escaping) {
          if (!_escapeGame.isOver) _escapeHint();
        } else if (!game.isComplete && !game.isGameOver) {
          _hint();
        }
      },
      if (_escaping && !_inputBlocked)
        for (final (key, direction) in const [
          (LogicalKeyboardKey.arrowUp, Direction.up),
          (LogicalKeyboardKey.arrowRight, Direction.right),
          (LogicalKeyboardKey.arrowDown, Direction.down),
          (LogicalKeyboardKey.arrowLeft, Direction.left),
        ])
          SingleActivator(key): () => _escapeGame.swipe(direction),
      if (widget.active && _modalDepth == 0 && !_choosingCharacter) ...{
        const SingleActivator(LogicalKeyboardKey.keyR): _confirmRestart,
        const SingleActivator(LogicalKeyboardKey.escape): () => _escaping
            ? (_paused ? _resumePeek() : _startPeek())
            : setState(() => _paused = !_paused),
      },
    },
    child: Focus(
      autofocus: widget.active,
      canRequestFocus: widget.active,
      child: AnimatedBuilder(
        animation: _current,
        builder: (context, _) => StatusBarTone(
          background:
              _screenColour ?? Theme.of(context).scaffoldBackgroundColor,
          child: Scaffold(
            backgroundColor: _screenColour,
            body: _withParty(
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final landscape =
                            constraints.maxWidth > constraints.maxHeight &&
                            constraints.maxHeight < 500;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            _escaping ? 2 : 16,
                            12,
                            _escaping ? 2 : 16,
                            _escaping ? 0 : 12,
                          ),
                          child: landscape
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(width: 300, child: _navigation()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _playArea()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _navigation(),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 480,
                                          ),
                                          child: _playArea(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Confetti over the whole screen when an animal is saved or a level is won.
  Widget _withParty(Widget child) {
    final party = _party;
    final live =
        party != null &&
        identical(party.game, _current) &&
        party.revision == _currentRevision;
    return Stack(
      children: [
        if (_rescueLook) const Positioned.fill(child: SceneBackdrop.rescue()),
        // A dressed level shows its plain ground colour instead of a sky.
        if (_escaping && !_plainMaze && _decor == null)
          Positioned.fill(
            child: switch (_decor) {
              final decor? => SceneBackdrop.ground(
                decor.ground,
                decor.groundDark,
                decor.colours.first,
              ),
              null => SceneBackdrop.tinted(_mazePalette.accent),
            },
          ),
        child,
        if (live)
          Positioned.fill(
            child: RepaintBoundary(
              child: Celebration(
                key: ValueKey(party.id),
                title: 'Congratulations!',
                subtitle: party.subtitle,
                banner: party.banner,
              ),
            ),
          ),
      ],
    );
  }

  void _celebrate({String? subtitle, bool banner = true}) {
    if (_escaping || game.haptics) HapticFeedback.heavyImpact();
    _party = (
      id: ++_parties,
      game: _current,
      revision: _currentRevision,
      subtitle: subtitle,
      banner: banner,
    );
  }

  Widget _header() => Row(
    children: [
      if (widget.onHome != null) ...[
        IconButton(
          onPressed: widget.onHome,
          tooltip: 'All games',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 2),
      ],
      // Arrow Escape and Animal Rescue keep their header to the back arrow and
      // the title; Maze Escape shows its icon bare, in the maze's own colour.
      if (_escaping) ...[
        SizedBox(
          width: 26,
          height: 42,
          child: Icon(_view.icon, color: _mazePalette.accent, size: 26),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Text(
          _escaping || _rescueLook ? _view.title : _view.title.toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: _escaping || _rescueLook ? 20 : 18,
            color: _escaping
                ? _mazeInk
                : _rescueLook
                ? _sunInk
                : ink,
            fontWeight: _escaping || _rescueLook
                ? FontWeight.w900
                : FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
      ),
      // Maze escape shows its level picker here in place of the help button.
      if (_escaping)
        _mazeLevelButton()
      else if (!_rescueLook)
        IconButton(
          onPressed: _showHelp,
          tooltip: 'How to play',
          icon: const Icon(Icons.question_mark_rounded, size: 20),
        ),
      // Maze escape keeps its pause button inside the maze card.
      if (!_escaping) ...[
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => setState(() => _paused = true),
          tooltip: 'Pause game',
          icon: const Icon(Icons.pause_rounded),
        ),
      ],
    ],
  );

  // The mode is chosen on the home screen, so only the header sits here.
  Widget _navigation() => Padding(
    padding: EdgeInsets.symmetric(horizontal: _escaping ? 6 : 0),
    child: switch (_decor) {
      final decor? => _framedHeader(
        MazeDecor.headerFrame(_escapeGame.maze.number) ?? decor.frame,
      ),
      null => _header(),
    },
  );

  // A dressed maze level's header. Each world lays it out its own way:
  // a hanging sign, an awning, a big badge, a ribbon, a stone tablet.
  Widget _framedHeader(FrameStyle style) {
    final look = FrameLook.of(style);
    final number = _escapeGame.maze.number.toString().padLeft(2, '0');
    final back = widget.onHome == null
        ? const SizedBox(width: 44)
        : Tooltip(
            message: 'All games',
            child: FrameButton(
              style: style,
              onTap: widget.onHome,
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded, color: look.icon),
            ),
          );
    Text title(Color colour, {double size = 18}) => Text(
      _view.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        color: colour,
        fontWeight: FontWeight.w900,
        letterSpacing: -.4,
        shadows: [
          if (look.titleShadow case final shadow?)
            Shadow(color: shadow, offset: const Offset(0, 1.5)),
        ],
      ),
    );
    Widget levelButton({double width = 52, double height = 52}) => Tooltip(
      message: 'Choose a level',
      child: FrameButton(
        style: style,
        onTap: _showLevels,
        width: width,
        height: height,
        // A small LEVEL caption so the number explains itself.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL',
              style: TextStyle(
                color: look.icon.withValues(alpha: .75),
                fontSize: 7.5,
                height: 1,
                letterSpacing: .8,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              number,
              style: TextStyle(
                color: look.icon,
                fontSize: 17,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );

    switch (style.layout) {
      case HeaderLayout.sign:
        // A sign hung in the middle, the level on a tag at the side.
        return SizedBox(
          height: 64,
          child: Row(
            children: [
              back,
              Expanded(
                child: Center(
                  child: FramePlaque(
                    style: style,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 11,
                    ),
                    child: title(look.title, size: 20),
                  ),
                ),
              ),
              levelButton(),
            ],
          ),
        );
      case HeaderLayout.awning:
        // The shop awning across the top, a flower badge for the level.
        return MazeHeaderFrame(
          style: style,
          child: Row(
            children: [
              back,
              Expanded(
                child: Center(
                  child: HangingSign(
                    style: style,
                    child: title(look.title, size: 16),
                  ),
                ),
              ),
              levelButton(width: 50, height: 50),
            ],
          ),
        );
      case HeaderLayout.badge:
        // A wide board with the world's ornaments resting along its top.
        return SizedBox(
          height: 72,
          child: Row(
            children: [
              back,
              Expanded(
                child: Center(
                  // Stripes would run behind the title, so an awning world
                  // hangs a plain sign instead.
                  child: style.shape == FrameShape.awning
                      ? HangingSign(
                          style: style,
                          child: title(look.title, size: 17),
                        )
                      : FramePlaque(
                          style: style,
                          ropes: false,
                          crown: true,
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                          child: title(
                            style.darkBoard ? look.title : look.icon,
                            size: 18,
                          ),
                        ),
                ),
              ),
              levelButton(),
            ],
          ),
        );
      case HeaderLayout.ribbon:
        // The title on a ribbon, the level inside a big life ring.
        return SizedBox(
          height: 64,
          child: Row(
            children: [
              back,
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: RibbonBanner(
                    edge: style.accent,
                    fill: look.face,
                    ornament: style.ornament,
                    child: title(
                      look.title.computeLuminance() > .5
                          ? look.icon
                          : look.title,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              levelButton(width: 56, height: 56),
            ],
          ),
        );
      case HeaderLayout.tablet:
        // A carved stone plaque with the title, the level on a stone at the
        // side, like the other worlds.
        return SizedBox(
          height: 64,
          child: Row(
            children: [
              back,
              Expanded(
                child: Center(
                  child: FramePlaque(
                    style: style,
                    padding: const EdgeInsets.fromLTRB(26, 11, 26, 15),
                    child: title(
                      style.darkBoard ? look.title : look.icon,
                      size: 19,
                    ),
                  ),
                ),
              ),
              levelButton(),
            ],
          ),
        );
    }
  }

  Widget _playArea() => _escaping ? _escapeArea() : _puzzleArea();

  Widget _puzzleArea() => Column(
    children: [
      Row(
        children: [
          if (_rescueLook)
            GameButton(
              color: _sun,
              shade: _sunShade,
              radius: 14,
              depth: 2,
              onTap: _showLevels,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LEVEL ${game.level.number.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _showLevels,
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: Text(
                'LEVEL ${game.level.number.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  letterSpacing: 1.5,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: ink,
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
          const SizedBox(width: 8),
          // Mistakes so far, out of the three allowed; shortened on narrow
          // screens rather than crowding the hearts.
          Expanded(
            child: Text(
              'Mistakes ${_maxLives - game.lives}/$_maxLives',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: game.lives < _maxLives
                    ? const Color(0xFFD9485F)
                    : const Color(0xFF9AA4B2),
              ),
            ),
          ),
          Semantics(
            label:
                '${_maxLives - game.lives} of $_maxLives mistakes made, ${game.lives} left',
            child: Row(
              children: [
                for (var i = 0; i < _maxLives; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    // A lost heart pops as it empties.
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: Tween(begin: 1.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: child,
                      ),
                      child: Icon(
                        i < game.lives
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(i < game.lives),
                        color: i < game.lives
                            ? (_rescueLook
                                  ? const Color(0xFFF2545B)
                                  : const Color(0xFFEF878B))
                            : const Color(0xFFD7DDE6),
                        size: _rescueLook ? 24 : 21,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Boards are portrait. Around the board the card adds 112 pixels
            // of height (title, time bar, padding, progress) and 22 of width.
            final aspect = (game.level.size + 1) / (game.level.rows + 1);
            // The rescue card's chips, thicker border and progress bar add
            // a little more.
            // A bar with bigger animal tokens takes its extra height too.
            final around =
                (_rescueLook ? 126.0 : 112.0) + _TimeBar.iconFor(game) - 18;
            final cardWidth = math.min(
              constraints.maxWidth,
              math.max(
                0.0,
                (constraints.maxHeight - around) * aspect +
                    (_rescueLook ? 24 : 22),
              ),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: cardWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _rescueLook
                          ? const Color(0xFFFFD2AE)
                          : const Color(0xFFE6EAF2),
                      width: _rescueLook ? 2 : 1,
                    ),
                    // A soft shadow all round; the border already frames
                    // the board, so no thicker edge along the bottom.
                    boxShadow: [
                      BoxShadow(
                        color: (_rescueLook ? _sunShade : ink).withValues(
                          alpha: _rescueLook ? .08 : .035,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                        child: Row(
                          children: [
                            if (cardWidth >= 220) ...[
                              if (_rescueLook)
                                const Icon(
                                  Icons.pets_rounded,
                                  size: 14,
                                  color: _sun,
                                )
                              else
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const SizedBox(width: 7),
                            ],
                            Expanded(
                              child: Text(
                                game.level.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _rescueLook ? 12 : 11,
                                  fontWeight: _rescueLook
                                      ? FontWeight.w800
                                      : FontWeight.w400,
                                  color: _rescueLook
                                      ? _sunInk
                                      : const Color(0xFF7B8597),
                                ),
                              ),
                            ),
                            // Tiny cards keep just the time bar below.
                            if (cardWidth >= 120) _Countdown(game),
                            // The countdown matters more on narrow cards.
                            if (cardWidth >= 240) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: _rescueLook
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      )
                                    : EdgeInsets.zero,
                                decoration: _rescueLook
                                    ? BoxDecoration(
                                        color: const Color(0xFFE5F6EC),
                                        borderRadius: BorderRadius.circular(10),
                                      )
                                    : null,
                                child: Text(
                                  game.isRescue
                                      ? '${game.rescued.length}/${game.level.rescue!.targets.length} safe'
                                      : '${game.remaining.length} left',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _rescueLook
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: _rescueLook
                                        ? const Color(0xFF16855E)
                                        : ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: _TimeBar(game),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: Stack(
                            children: [
                              PuzzleBoard(
                                key: ValueKey(
                                  '${game.mode.name}-${game.revision}',
                                ),
                                game: game,
                                onArrow: _tap,
                                onRescue: _rescueAnimal,
                                chase: true,
                                timed: true,
                                paused: _inputBlocked,
                              ),
                              if (_paused || game.isComplete || game.isGameOver)
                                Positioned.fill(
                                  child: _DelayedReveal(
                                    key: ValueKey(
                                      '${game.revision}-$_paused-${game.isGameOver}-${game.isComplete}',
                                    ),
                                    // Let the pounce or the run home play first.
                                    delay: !game.isRescue || _paused
                                        ? Duration.zero
                                        : game.isGameOver
                                        ? const Duration(milliseconds: 1000)
                                        // The run home and the arrows
                                        // flying off play first.
                                        : const Duration(milliseconds: 2200),
                                    child: _overlay(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: game.progress,
                            minHeight: _rescueLook ? 8 : 4,
                            color: _rescueLook ? _sun : mint,
                            backgroundColor: _rescueLook
                                ? const Color(0xFFFFE6D1)
                                : const Color(0xFFF0F2F7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      if (_feedback != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            _feedback!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.4, color: accent),
          ),
        ),
      ],
      const SizedBox(height: 8),
      if (_rescueLook)
        _rescueControls()
      else
        Row(
          children: [
            _tool(Icons.refresh_rounded, 'Restart', _confirmRestart),
            const SizedBox(width: 10),
            _tool(
              Icons.undo_rounded,
              'Undo',
              game.canUndo && !_paused
                  ? () {
                      game.undo();
                      setState(() => _feedback = null);
                    }
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    !_paused &&
                        !game.isComplete &&
                        !game.isGameOver &&
                        game.hints > 0
                    ? _hint
                    : null,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 19),
                label: Text('Hint · ${game.hints} left'),
              ),
            ),
          ],
        ),
    ],
  );

  // A deeper shade of the maze's colour for the base of chunky buttons.
  Color get _mazeShade => Color.lerp(_mazePalette.accent, Colors.black, .28)!;

  Widget _mazeLevelButton() => GameButton(
    color: _mazePalette.accent,
    shade: _mazeShade,
    radius: 14,
    depth: 2,
    onTap: _showLevels,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grid_view_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'LEVEL ${_escapeGame.maze.number.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 1.2,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );

  // Seconds left on a maze pause; tap to carry on early.
  Widget _peekCountdown() => Tooltip(
    message: 'Resume now',
    child: Material(
      color: _mazePalette.accent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: _resumePeek,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Text(
                '${_peekLeft! ~/ 60}:${(_peekLeft! % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _escapeArea() {
    final run = _escapeGame;
    final maze = run.maze;
    final palette = _mazePalette;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Compact padding leaves almost the full screen for the maze.
              final cardWidth = constraints.maxWidth;
              // Use the available width even when a tall level cannot fit
              // square rooms vertically. The board adapts room spacing.
              final aspect = math.max(
                EscapeBoard.aspectOf(maze),
                (cardWidth - 8) / math.max(1.0, constraints.maxHeight - 56),
              );
              return Align(
                alignment: run.isOver ? Alignment.center : Alignment.topCenter,
                child: SizedBox(
                  width: cardWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      // Around a dressed level the card is the same ground.
                      color: _plainMaze
                          ? Colors.white
                          : _decor?.ground ?? Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      // The board has no outline or drop shadow.
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: Row(
                            children: [
                              _mazeRole(maze.prey, hunter: false),
                              const SizedBox(width: 6),
                              _mazeRole(maze.hunter, hunter: true),
                              const Spacer(),
                              if (_decor != null)
                                _frameCorner(
                                  icon: _touchControls
                                      ? Icons.pan_tool_alt_rounded
                                      : Icons.gamepad_rounded,
                                  tooltip: _touchControls
                                      ? 'Touch controls (tap to use arrows)'
                                      : 'Arrow controls (tap to use touch)',
                                  onTap: _switchControls,
                                )
                              else
                                IconButton(
                                  onPressed: _switchControls,
                                  tooltip: _touchControls
                                      ? 'Touch controls (tap to use arrows)'
                                      : 'Arrow controls (tap to use touch)',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 26,
                                  ),
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: palette.accent,
                                  ),
                                  iconSize: 18,
                                  icon: Icon(
                                    _touchControls
                                        ? Icons.pan_tool_alt_outlined
                                        : Icons.gamepad_outlined,
                                  ),
                                ),
                              SizedBox(width: _decor != null ? 8 : 2),
                              if (_peekLeft != null)
                                _peekCountdown()
                              else if (_decor != null)
                                _frameCorner(
                                  icon: Icons.pause_rounded,
                                  tooltip: 'Pause game',
                                  onTap: run.isOver ? null : _startPeek,
                                )
                              else
                                IconButton(
                                  onPressed: run.isOver ? null : _startPeek,
                                  tooltip: 'Pause game',
                                  // Kept as small as the old Exit chip so the
                                  // card height (and the maze fit) is unchanged.
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 26,
                                  ),
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  iconSize: 18,
                                  icon: const Icon(Icons.pause_rounded),
                                ),
                            ],
                          ),
                        ),
                        // Flexible lets the board shrink rather than
                        // overflow when the card header runs taller.
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: AspectRatio(
                              aspectRatio: aspect,
                              child: Stack(
                                // A gate's ring may reach past the board.
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: ClipRect(
                                      clipper: const _BoardClip(),
                                      child: EscapeBoard(
                                        key: ValueKey('escape-${run.revision}'),
                                        game: run,
                                        character: _character,
                                        paused: _inputBlocked,
                                        tapToMove: _touchControls,
                                        onEscaped: () {
                                          GameSounds.levelClear();
                                          setState(() {
                                            _feedback = null;
                                            _celebrate(banner: false);
                                          });
                                        },
                                        onCaught: () {
                                          HapticFeedback.mediumImpact();
                                          setState(() => _feedback = null);
                                        },
                                      ),
                                    ),
                                  ),
                                  if ((_paused && _peekLeft == null) ||
                                      run.isOver)
                                    Positioned.fill(
                                      child: _DelayedReveal(
                                        key: ValueKey(
                                          'escape-${run.revision}-$_paused-${run.state}',
                                        ),
                                        // Let the dash out or the bite play first.
                                        delay: _paused
                                            ? Duration.zero
                                            : const Duration(milliseconds: 900),
                                        child: _escapeOverlay(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _feedback!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.4, color: accent),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // A dressed level stands its controls on its own ground.
        switch (_decor) {
          final decor? => MazeFooterFrame(
            style: decor.frame,
            plain: _plainMaze,
            scene: MazeDecor.footerScene(run.maze.number),
            child: Visibility(
              visible: !_paused && !run.isOver,
              // The result uses the space previously occupied by the controls.
              maintainSize: !run.isOver,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _escapeAction(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Hint',
                      count: run.hints,
                      onPressed: !_paused && !run.isOver && run.hints > 0
                          ? _escapeHint
                          : null,
                    ),
                    // Hint on one side, Restart on the other, the pad between.
                    Expanded(
                      child: Center(
                        child: _touchControls && run.maze.number == 70
                            ? AnimatedOpacity(
                                opacity: run.moves == 0 ? 1 : 0,
                                duration: const Duration(milliseconds: 350),
                                child: MazeTouchHint(
                                  // Frosted ice that matches the snowfield.
                                  colours: const PadColours(
                                    plate: Color(0xFFDCEEF8),
                                    plateEdge: Color(0xFF8DB6D6),
                                    key: Color(0xFFEAF4FB),
                                    keyEdge: Color(0xFF8DB6D6),
                                    arrow: Color(0xFF2E5B82),
                                    glow: Color(0xFF4F86B4),
                                  ),
                                  face: const [
                                    Color(0xFFF7FBFE),
                                    Color(0xFFD9EAF6),
                                  ],
                                  ornament: Icons.ac_unit_rounded,
                                  ink: decor.frame.look.title,
                                ),
                              )
                            : _touchControls
                            ? _tapToMoveCue(visible: run.moves == 0)
                            : _arrowPad(enabled: !_paused && !run.isOver),
                      ),
                    ),
                    _escapeAction(
                      icon: Icons.refresh_rounded,
                      label: 'Restart',
                      onPressed: _confirmRestart,
                    ),
                  ],
                ),
              ),
            ),
          ),
          null => Visibility(
            visible: !_paused && !run.isOver,
            // The result uses the space previously occupied by the controls.
            maintainSize: !run.isOver,
            maintainAnimation: true,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _escapeAction(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hint',
                    count: run.hints,
                    onPressed: !_paused && !run.isOver && run.hints > 0
                        ? _escapeHint
                        : null,
                  ),
                  // Hint on one side, Restart on the other, the pad between.
                  Expanded(
                    child: Center(
                      child: _touchControls
                          ? _tapToMoveCue(visible: run.moves == 0)
                          : _arrowPad(enabled: !_paused && !run.isOver),
                    ),
                  ),
                  _escapeAction(
                    icon: Icons.refresh_rounded,
                    label: 'Restart',
                    onPressed: _confirmRestart,
                  ),
                ],
              ),
            ),
          ),
        },
      ],
    );
  }

  void _switchControls() => setState(() {
    _touchControls = !_touchControls;
    ProgressStore.setBool('touchControls', _touchControls);
  });

  // A small button cut from the level's own frame, like Hint and Restart.
  Widget _frameCorner({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final style = _decor!.frame;
    const side = 34.0;
    return Tooltip(
      message: tooltip,
      child: FrameButton(
        style: style,
        onTap: onTap,
        width: side,
        height: side,
        child: Icon(icon, size: 18, color: style.look.icon),
      ),
    );
  }

  // A short tap reminder on the same dark tag as Hint and Restart, in line
  // with them so it reads on any footer; the first step fades it out.
  Widget _tapToMoveCue({required bool visible}) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 350),
    child: Padding(
      padding: const EdgeInsets.only(top: 51),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pan_tool_alt_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Tap to move',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // A small drop-down under the You badge; picking a look applies it.
  Future<void> _chooseCharacter(BuildContext anchor) async {
    if (_choosingCharacter) return;
    final box = anchor.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    setState(() => _choosingCharacter = true);
    final selected = await showMenu<PlayerCharacter>(
      context: context,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        for (final character in PlayerCharacter.values)
          PopupMenuItem(
            value: character,
            height: 44,
            child: Row(
              children: [
                PlayerAvatar(character: character, size: 28),
                const SizedBox(width: 10),
                Text(
                  character.label,
                  style: const TextStyle(
                    color: MazePalette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: character == _character
                      ? MazePalette.player
                      : Colors.transparent,
                ),
              ],
            ),
          ),
      ],
    );
    if (!mounted) return;
    setState(() {
      if (selected != null) {
        _character = selected;
        ProgressStore.setString('character', selected.name);
      }
      _choosingCharacter = false;
    });
  }

  Widget _mazeRole(AnimalKind kind, {required bool hunter}) {
    final color = hunter ? MazePalette.hunter : MazePalette.player;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, .94),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (CharacterArt.ready)
            SizedBox.square(
              dimension: 30,
              child: CustomPaint(
                painter: _FacePainter(
                  hunter ? kind.name : _character.name,
                  hunter ? MazePalette.hunter : MazePalette.player,
                ),
              ),
            )
          else if (hunter)
            MazeAnimalAvatar(kind: kind, hunter: hunter, size: 26)
          else
            PlayerAvatar(character: _character, size: 26),
          const SizedBox(width: 4),
          Text(
            hunter
                ? '${kind.name[0].toUpperCase()}${kind.name.substring(1)}'
                : 'You',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!hunter) Icon(Icons.expand_more_rounded, color: color, size: 14),
        ],
      ),
    );
    if (hunter) return badge;
    return Tooltip(
      message: 'Choose character',
      child: Semantics(
        button: true,
        label: 'Choose character. ${_character.label} selected',
        child: Builder(
          builder: (anchor) => InkWell(
            onTap: () => _chooseCharacter(anchor),
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Center(child: badge),
            ),
          ),
        ),
      ),
    );
  }

  Widget _escapeAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    int? count,
  }) => Tooltip(
    message: count == null ? label : '$label · $count left',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (_decor case final decor?)
              FrameButton(
                style: decor.frame,
                onTap: onPressed,
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  size: 23,
                  color: FrameLook.of(decor.frame).icon,
                ),
              )
            else
              GameButton(
                color: Colors.white,
                shade: _mazePalette.border,
                radius: 16,
                depth: 3,
                onTap: onPressed,
                child: SizedBox(
                  width: 50,
                  height: 44,
                  child: Icon(
                    icon,
                    size: 23,
                    color: label == 'Hint'
                        ? (_plainMaze ? null : _decor?.ink) ??
                              _mazePalette.accent
                        : MazePalette.secondary,
                  ),
                ),
              ),
            if (count != null)
              Positioned(
                right: -5,
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _mazePalette.accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$count',
                    semanticsLabel: '$count hints left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        // On a dressed level the label sits on a dark tag so it reads on
        // wood, fence, sand or brick alike.
        Container(
          padding: _decor == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: _decor == null
              ? null
              : BoxDecoration(
                  color: Colors.black.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: _decor == null ? _mazeInk : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  // The pad's colours come from the world's sign and buttons.
  PadColours _padColours() {
    final decor = _plainMaze ? null : _decor;
    final palette = _mazePalette;
    return decor == null
        ? PadColours(
            plate: Colors.white.withValues(alpha: .9),
            plateEdge: palette.border,
            key: Colors.white,
            keyEdge: palette.border,
            arrow: palette.accent,
            glow: palette.accent,
          )
        : PadColours(
            plate: decor.frame.board,
            plateEdge: decor.frame.trim,
            key: decor.frame.look.face,
            keyEdge: decor.frame.look.rim,
            arrow: decor.frame.look.icon,
            glow: decor.frame.accent,
          );
  }

  // The direction pad, dressed in the world's sign and button colours.
  Widget _arrowPad({required bool enabled}) {
    final colours = _padColours();
    return ListenableBuilder(
      listenable: _escapeGame,
      builder: (context, _) {
        final run = _escapeGame;
        return MazeDirectionPad(
          colours: colours,
          running: run.running ? run.facing : null,
          hint: run.hintDirection,
          idle: run.moves == 0,
          onDirection: enabled ? (d) => _escapeGame.swipe(d) : null,
        );
      },
    );
  }

  Widget _escapeOverlay() {
    final run = _escapeGame;
    final won = run.state == EscapeState.escaped;
    final last = run.maze.number == EscapeMaze.count;
    final decor = _decor;
    final look = decor == null ? null : FrameLook.of(decor.frame);
    final (heading, body) = decor == null
        ? (ink, const Color(0xFF7B8597))
        : MazePanelFrame.textColours(decor.frame);
    final resultColor =
        look?.rim ??
        (won && !_paused ? MazePalette.player : _mazePalette.accent);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: _escapeResult(run, won, last, resultColor, heading, body),
    );
    if (decor != null && run.maze.number == 115) {
      // Level 115 tries a compact card over the dimmed maze instead of a
      // panel covering the whole board.
      final rim = look!.rim;
      return ColoredBox(
        color: Colors.black.withValues(alpha: .3),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: BoxDecoration(
                color: Color.lerp(rim, Colors.white, .93),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: rim, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(rim, Colors.black, .35)!,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      );
    }
    if (decor != null) {
      // A dressed level shows its result on a panel of its own material.
      return Padding(
        padding: const EdgeInsets.all(6),
        child: MazePanelFrame(
          style: decor.frame,
          child: Center(child: SingleChildScrollView(child: content)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .99),
            _mazePalette.tint.withValues(alpha: .99),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(child: SingleChildScrollView(child: content)),
    );
  }

  List<Widget> _escapeResult(
    EscapeGame run,
    bool won,
    bool last,
    Color resultColor,
    Color heading,
    Color body,
  ) {
    final decor = _decor;
    void act() {
      if (_paused) {
        _resumePeek();
      } else if (won && !last) {
        run.selectLevel(run.maze.number + 1);
        setState(() => _feedback = null);
      } else {
        run.restart();
        setState(() => _feedback = null);
      }
    }

    final label = _paused
        ? 'Keep playing'
        : won && !last
        ? 'Next level →'
        : won
        ? 'Play again'
        : 'Try again';
    return [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: decor == null
              ? resultColor.withValues(alpha: .09)
              : Colors.white.withValues(alpha: .85),
          shape: BoxShape.circle,
          border: run.maze.number == 115 && decor != null
              ? Border.all(color: resultColor.withValues(alpha: .35), width: 2)
              : null,
        ),
        // On level 115 the snake that caught you looks back at you.
        child: run.maze.number == 115 && !won && !_paused && CharacterArt.ready
            ? CustomPaint(
                painter: _FacePainter(run.maze.hunter.name, MazePalette.hunter),
              )
            : Icon(
                _paused
                    ? Icons.coffee_rounded
                    : won
                    ? Icons.emoji_events_rounded
                    : Icons.favorite_border_rounded,
                color: resultColor,
                size: 38,
              ),
      ),
      const SizedBox(height: 18),
      if (won && !_paused) ...[
        Text(
          'LEVEL ${run.maze.number.toString().padLeft(2, '0')} COMPLETE',
          style: const TextStyle(
            color: mint,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
      ],
      Text(
        _paused
            ? 'A moment for you.'
            : won
            ? 'Congratulations!'
            : 'The ${run.maze.hunter.name} caught you!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: heading,
          letterSpacing: -.6,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        _paused
            ? 'The ${run.maze.hunter.name} waits while you rest.'
            : won
            ? 'You found the way out in ${run.moves} swipes.'
            : 'Find the road to the green gap before the ${run.maze.hunter.name} catches up. Try again!',
        textAlign: TextAlign.center,
        style: TextStyle(color: body, fontSize: 13, height: 1.5),
      ),
      if (won && !_paused)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(
                  i < math.max(1, run.hints)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFE8AA42),
                  size: 36,
                ),
            ],
          ),
        ),
      const SizedBox(height: 16),
      if (decor == null)
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: resultColor,
              minimumSize: const Size(0, 54),
            ),
            onPressed: act,
            child: Text(label),
          ),
        )
      else
        FrameButton(
          style: decor.frame,
          onTap: act,
          width: double.infinity,
          height: 54,
          child: Text(
            label,
            style: TextStyle(
              color: FrameLook.of(decor.frame).icon,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
    ];
  }

  Widget _rescueControls() {
    final hintable =
        !_paused && !game.isComplete && !game.isGameOver && game.hints > 0;
    Widget round(IconData icon, String label, VoidCallback? onTap) => Tooltip(
      message: label,
      child: GameButton(
        color: Colors.white,
        shade: const Color(0xFFE8C9AE),
        radius: 18,
        depth: 3,
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 48,
          child: Icon(icon, color: _sunInk, size: 24),
        ),
      ),
    );
    return Row(
      children: [
        round(Icons.refresh_rounded, 'Restart', _confirmRestart),
        const SizedBox(width: 10),
        round(
          Icons.undo_rounded,
          'Undo',
          game.canUndo && !_paused
              ? () {
                  game.undo();
                  setState(() => _feedback = null);
                }
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GameButton(
            color: _sun,
            shade: _sunShade,
            radius: 18,
            depth: 3,
            onTap: hintable ? _hint : null,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Hint · ${game.hints} left',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback? onPressed) => Column(
    children: [
      IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(icon, size: 21),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF929BAC), fontSize: 9),
      ),
    ],
  );

  Widget _overlay() {
    final complete = game.isComplete;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _paused
                    ? Icons.coffee_rounded
                    : complete
                    ? Icons.auto_awesome_rounded
                    : game.timeUp && !game.caught
                    ? Icons.timer_off_rounded
                    : Icons.favorite_border_rounded,
                color: complete ? mint : accent,
                size: 40,
              ),
              const SizedBox(height: 14),
              Text(
                _paused
                    ? 'A moment for you.'
                    : complete
                    ? 'Congratulations!'
                    : game.caught
                    ? 'The ${game.level.rescue!.predatorName} caught the ${game.level.rescue!.preySingular}!'
                    : game.timeUp
                    ? 'Time\'s up!'
                    : game.isRescue
                    ? 'The ${game.level.rescue!.predatorName} caught the ${game.level.rescue!.preySingular}!'
                    : 'A fresh perspective?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _paused
                    ? 'Your puzzle will be right here.'
                    : complete
                    ? game.isRescue
                          ? 'You saved the ${game.level.rescue!.preySingular} and cleared every arrow in ${clock(game.elapsed.inSeconds)}.'
                          : 'Level ${game.level.number} cleared in ${clock(game.elapsed.inSeconds)} with ${game.moves} moves.'
                    : game.caught && game.lives == 0
                    ? 'All $_maxLives mistakes used, so the ${game.level.rescue!.predatorName} pounced. Try again!'
                    : game.caught
                    ? 'Open its way home before the ${game.level.rescue!.predatorName} walks its trail, within ${clock(game.timeLimit)}. Try again!'
                    : game.timeUp
                    ? 'Clear every arrow within ${clock(game.timeLimit)}. Try again!'
                    : game.isRescue
                    ? 'Be quick: open a safe route before the ${game.level.rescue!.predatorName} arrives.'
                    : 'All $_maxLives mistakes used. Try again with a fresh board.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7B8597),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (complete && !_paused)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < game.earnedStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFE8AA42),
                          size: 32,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (_paused) {
                    setState(() => _paused = false);
                  } else if (complete &&
                      game.level.number < PuzzleLevel.count) {
                    game.selectLevel(game.level.number + 1);
                    setState(() => _feedback = null);
                  } else {
                    _restart();
                  }
                },
                child: Text(
                  _paused
                      ? 'Keep playing'
                      : complete && game.level.number < PuzzleLevel.count
                      ? 'Next level →'
                      : complete
                      ? 'Play again'
                      : 'Try again',
                ),
              ),
              if (_paused) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: game.toggleHaptics,
                  icon: Icon(
                    game.haptics
                        ? Icons.vibration_rounded
                        : Icons.smartphone_rounded,
                    size: 17,
                  ),
                  label: Text('Haptics ${game.haptics ? "on" : "off"}'),
                ),
              ],
              if (complete && game.level.number == PuzzleLevel.count)
                TextButton(
                  onPressed: _showLevels,
                  child: const Text(
                    'All ${PuzzleLevel.count} levels complete · Explore levels',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DelayedReveal extends StatefulWidget {
  const _DelayedReveal({super.key, required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<_DelayedReveal>
    with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 250);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _fade,
  )..forward();
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _fade).inMilliseconds,
      1,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.delay == Duration.zero
      ? widget.child
      : FadeTransition(opacity: _opacity, child: widget.child);
}

String clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

// The level countdown; it turns amber, then red, as time runs short.
class _Countdown extends StatelessWidget {
  const _Countdown(this.game);
  final PuzzleGame game;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: game.secondsLeft,
    builder: (context, left, _) {
      final color = left <= 10
          ? const Color(0xFFD9485F)
          : left <= 30
          ? const Color(0xFFDB8B14)
          : ink;
      return Semantics(
        label: '${clock(left)} left',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              clock(left),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Time remaining as a bar that shrinks smoothly between whole seconds and
// changes colour with the countdown.
class _TimeBar extends StatelessWidget {
  /// The animals' size on a rescue's bar. Level 7 tries the board's round
  /// tokens here too, a size up.
  static double iconFor(PuzzleGame game) =>
      game.level.rescue != null && game.level.number == 7 ? 30 : 18;

  const _TimeBar(this.game);
  final PuzzleGame game;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: game.secondsLeft,
    builder: (context, left, _) {
      final share = game.timeLimit == 0 ? 0.0 : left / game.timeLimit;
      final color = left <= 10
          ? const Color(0xFFD9485F)
          : left <= 30
          ? const Color(0xFFDB8B14)
          : mint;
      final bar = TweenAnimationBuilder<double>(
        tween: Tween(end: share),
        // The clock reports whole seconds; glide across each one.
        duration: const Duration(seconds: 1),
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            color: color,
            backgroundColor: const Color(0xFFF0F2F7),
            semanticsLabel: 'Time left',
          ),
        ),
      );
      final scene = game.level.rescue;
      if (scene == null) return bar;
      // In a rescue the hunter walks the bar toward its prey at the far
      // end, in step with the hunter on the board: time running out and the
      // hunter arriving are the same moment, and a mistake's leap shows here
      // too.
      final tokens = game.level.number == 7;
      final icon = iconFor(game);
      return SizedBox(
        height: icon + 4,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: icon / 2,
                right: 0,
                top: (icon + 4 - 4) / 2,
                child: bar,
              ),
              Positioned(
                left: 0,
                top: 2,
                child: tokens
                    ? AnimalToken(
                        kind: scene.prey,
                        ring: rescueGreen,
                        size: icon,
                      )
                    : AnimalAvatar(kind: scene.prey, size: icon),
              ),
              if (!game.allRescued)
                TweenAnimationBuilder<double>(
                  tween: Tween(end: 1 - game.huntProgress),
                  duration: const Duration(seconds: 1),
                  builder: (context, ahead, child) => Positioned(
                    left: (constraints.maxWidth - icon) * ahead.clamp(0.0, 1.0),
                    top: 2,
                    child: child!,
                  ),
                  child: tokens
                      ? AnimalToken(
                          kind: scene.predator,
                          ring: rescueDanger,
                          hunter: true,
                          size: icon,
                        )
                      : AnimalAvatar(kind: scene.predator, size: icon),
                ),
            ],
          ),
        ),
      );
    },
  );
}

// One level in the picker: locked, open, played (with its stars) or the one
// on the board now.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.locked,
    required this.current,
    required this.stars,
    required this.onTap,
    this.highlight = accent,
    this.showOpenLocks = true,
    this.themeLabel,
  });
  final int level;
  final bool locked;
  final bool current;
  final int? stars;
  final VoidCallback onTap;
  final Color highlight;
  final bool showOpenLocks;
  final String? themeLabel;

  @override
  Widget build(BuildContext context) {
    final played = stars != null;
    final background = current
        ? highlight
        : locked
        ? const Color(0xFFEDEFF4)
        : played
        ? const Color(0xFFE8F6F1)
        : themeLabel == null
        ? Colors.white
        : Color.lerp(highlight, Colors.white, .95)!;
    final foreground = current
        ? Colors.white
        : locked
        ? const Color(0xFFB4BCC8)
        : ink;
    return Semantics(
      button: !locked,
      label:
          'Level $level${themeLabel == null ? "" : ", $themeLabel"}${locked
              ? ", locked"
              : played
              ? ", $stars stars"
              : ""}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: current
                ? highlight
                : played
                ? mint.withValues(alpha: .35)
                : themeLabel == null
                ? const Color(0xFFE3E7EF)
                : highlight.withValues(alpha: .23),
          ),
          boxShadow: [
            if (current && themeLabel == null)
              BoxShadow(
                color: highlight.withValues(alpha: .22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else if (!locked && themeLabel == null)
              BoxShadow(
                color: ink.withValues(alpha: .05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: locked ? null : onTap,
            child: Stack(
              children: [
                if (themeLabel != null && !locked)
                  Positioned(
                    left: 13,
                    right: 13,
                    bottom: 4,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: current
                            ? Colors.white.withValues(alpha: .65)
                            : highlight.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // Lock state in the corner: shut, or open and ready to play.
                if (current || locked || played || showOpenLocks)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Icon(
                      current
                          ? Icons.play_arrow_rounded
                          : locked
                          ? Icons.lock_rounded
                          : played
                          ? Icons.check_circle_rounded
                          : Icons.lock_open_rounded,
                      size: 11,
                      color: current
                          ? Colors.white
                          : locked
                          ? const Color(0xFF9AA4B2)
                          : played
                          ? mint
                          : const Color(0xFF8FA0B8),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (locked)
                        const Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: Color(0xFFB4BCC8),
                        )
                      else
                        Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                            letterSpacing: -.5,
                          ),
                        ),
                      if (locked)
                        Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      if (played) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Icon(
                                i < stars!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 10,
                                color: current
                                    ? Colors.white
                                    : const Color(0xFFE8AA42),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A character's round face token, for the legend above the maze.
class _FacePainter extends CustomPainter {
  const _FacePainter(this.character, this.ring);
  final String character;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) => CharacterArt.drawFace(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2 - 1,
    character,
    ring,
  );

  @override
  bool shouldRepaint(covariant _FacePainter old) =>
      old.character != character || old.ring != ring;
}

// Clips the board a little outside itself, so the rings round the gates at
// its edges are drawn whole.
class _BoardClip extends CustomClipper<Rect> {
  const _BoardClip();

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(24);

  @override
  bool shouldReclip(_BoardClip oldClipper) => false;
}
