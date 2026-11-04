import 'package:arrow_game/escape/escape_board.dart';
import 'package:arrow_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show openMode;

void main() {
  SystemUiOverlayStyle shown(WidgetTester tester) => tester
      .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byWidgetPredicate(
          (w) => w is AnnotatedRegion<SystemUiOverlayStyle>,
          skipOffstage: true,
        ),
      )
      .first
      .value;

  testWidgets('status bar icons contrast with the screen behind them', (
    tester,
  ) async {
    await tester.pumpWidget(const ArrowGameApp());
    await tester.pumpAndSettle();
    expect(shown(tester).statusBarBrightness, Brightness.dark);
    expect(shown(tester).statusBarIconBrightness, Brightness.light);

    await openMode(tester, 'Maze Escape');
    final game = tester.widget<EscapeBoard>(find.byType(EscapeBoard)).game;
    Finder region() => find.ancestor(
      of: find.byType(EscapeBoard),
      matching: find.byWidgetPredicate(
        (w) => w is AnnotatedRegion<SystemUiOverlayStyle>,
      ),
    );
    SystemUiOverlayStyle onLevel() => tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(region())
        .first
        .value;

    // Level 12's pale green against level 40's night sky.
    game.selectLevel(12);
    await tester.pumpAndSettle();
    expect(onLevel().statusBarIconBrightness, Brightness.dark);
    game.selectLevel(40);
    await tester.pumpAndSettle();
    expect(onLevel().statusBarIconBrightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });
}
