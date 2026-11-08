import 'dart:typed_data';
import 'dart:ui';

/// One way to colour the snake: body, a lighter head, a dark edge and the
/// diamonds along its back.
typedef SnakeColours = ({Color body, Color head, Color edge, Color spots});

const snakeColourings = <SnakeColours>[
  // Orange first: it suits most green and pale levels.
  (
    body: Color(0xFFEF6A1F),
    head: Color(0xFFF7843A),
    edge: Color(0xFF3A1E10),
    spots: Color(0xFFFFE066),
  ),
  (
    body: Color(0xFF8A3FD1),
    head: Color(0xFFA05FE0),
    edge: Color(0xFF26103C),
    spots: Color(0xFFFFD84D),
  ),
  (
    body: Color(0xFF2D6FE3),
    head: Color(0xFF4A86EE),
    edge: Color(0xFF0E2152),
    spots: Color(0xFFFFE066),
  ),
  (
    body: Color(0xFFF4C430),
    head: Color(0xFFF8D45A),
    edge: Color(0xFF3B2A05),
    spots: Color(0xFF5A3A08),
  ),
  (
    body: Color(0xFFE0367A),
    head: Color(0xFFEA5C93),
    edge: Color(0xFF3E0C22),
    spots: Color(0xFFFFE3EF),
  ),
];

/// The colouring that blends least with a scene, given as raw RGBA pixels:
/// every pixel near a colouring's body counts against it, the nearer the
/// more. Ties keep the earlier colouring.
SnakeColours standoutSnake(Uint8List rgba) {
  var best = snakeColourings.first;
  var bestCost = double.infinity;
  for (final colouring in snakeColourings) {
    final body = colouring.body;
    final r = body.r * 255, g = body.g * 255, b = body.b * 255;
    var cost = 0.0;
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      if (rgba[i + 3] < 128) continue;
      // Weighted RGB distance, closer to how different colours look.
      final dr = rgba[i] - r, dg = rgba[i + 1] - g, db = rgba[i + 2] - b;
      final distance = 2 * dr * dr + 4 * dg * dg + 3 * db * db;
      const near = 3 * 130.0 * 130.0;
      if (distance < near) cost += 1 - distance / near;
    }
    if (cost < bestCost) {
      best = colouring;
      bestCost = cost;
    }
  }
  return best;
}
