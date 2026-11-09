import 'package:arrow_game/config/progress_store.dart';
import 'package:arrow_game/game/puzzle.dart';
import 'package:arrow_game/screens/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('finishing every level fills the home progress bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    ProgressStore.save(
      'basic',
      level: PuzzleLevel.count,
      unlocked: PuzzleLevel.count,
      stars: {for (var i = 1; i <= PuzzleLevel.count; i++) i: 3},
    );
    await tester.pumpWidget(const MaterialApp(home: GameHubScreen()));
    await tester.pumpAndSettle();
    final bars = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bars.map((bar) => bar.value), [1.0, 0.0, 0.0]);
    expect(tester.takeException(), isNull);
  });
}
