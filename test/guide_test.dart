import 'package:arrow_game/config/game_settings.dart';
import 'package:arrow_game/config/progress_store.dart';
import 'package:arrow_game/screens/arrow_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    GameSettings.showGuides = true;
  });
  tearDown(() => GameSettings.showGuides = false);

  for (final (mode, title) in [
    (PlayMode.basic, 'Clear every arrow!'),
    (PlayMode.rescue, 'Save the animal!'),
    (PlayMode.escape, 'Run for the way out!'),
  ]) {
    testWidgets('${mode.name} shows its guide once on level 1', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: GameScreen(mode: mode)));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.text('Let’s play'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(key: UniqueKey(), mode: mode),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
    });
  }
}
