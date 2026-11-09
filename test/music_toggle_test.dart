import 'package:arrow_game/config/game_sounds.dart';
import 'package:arrow_game/screens/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => GameSounds.enabled = true);

  testWidgets('the home screen turns the level-clear music off and on', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: GameHubScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Music on'));
    await tester.pump();
    expect(GameSounds.enabled, isFalse);
    expect(find.byTooltip('Music off'), findsOneWidget);

    await tester.tap(find.byTooltip('Music off'));
    await tester.pump();
    expect(GameSounds.enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
