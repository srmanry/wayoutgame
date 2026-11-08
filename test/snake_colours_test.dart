import 'dart:typed_data';

import 'package:arrow_game/escape/snake_colours.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List scene(List<int> rgb) => Uint8List.fromList([
  for (var i = 0; i < 64; i++) ...[...rgb, 255],
]);

void main() {
  test('the snake keeps orange on green hedges', () {
    expect(standoutSnake(scene([0x5A, 0x91, 0x42])), snakeColourings.first);
  });

  test('the snake changes colour on a red-brown floor like level 117', () {
    final colouring = standoutSnake(scene([0xB0, 0x52, 0x2E]));
    expect(colouring, isNot(snakeColourings.first));
  });

  test('transparent pixels do not count', () {
    final clear = Uint8List(64 * 4);
    expect(standoutSnake(clear), snakeColourings.first);
  });
}
