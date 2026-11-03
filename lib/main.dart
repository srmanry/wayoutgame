import 'package:flutter/material.dart';

import 'config/progress_store.dart';
import 'widgets/character_art.dart';
import 'widgets/puzzle_board.dart';
import 'screens/game_hub_screen.dart';
export 'screens/arrow_game_screen.dart' show GameScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ProgressStore.init(),
    CharacterArt.load().catchError((Object error) {
      debugPrint('Character portraits unavailable: $error');
    }),
  ]);
  runApp(const ArrowGameApp());
}

class ArrowGameApp extends StatelessWidget {
  const ArrowGameApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WayOut: Arrow & Maze Puzzles',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        surface: Colors.white,
      ),
      fontFamily: 'Helvetica',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Helvetica',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: Colors.white,
          minimumSize: const Size(46, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    ),
    home: const GameHubScreen(),
  );
}
