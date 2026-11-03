import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/puzzle_rules.dart' show Cell;
import 'maze_escape.dart';
import 'maze_frame.dart';
import 'maze_theme.dart';
import 'maze_wall_art.dart';

export 'maze_frame.dart' show FrameStyle;

/// The ground around a maze.
enum GroundKind {
  meadow,
  tulipField,
  straw,
  sea,
  dunes,
  cave,
  street,
  leafLitter,
  raked,
  snowfield,
  checker,
  bricks,
  lagoon,
}

/// The surface of the rooms.
enum PathKind { earth, cobbles, tilled, sand, clay, slate, planks }

/// What moves over the maze.
enum LifeKind {
  butterflies,
  petals,
  bees,
  gulls,
  tumbleweeds,
  sparkles,
  snow,
  bubbles,
}

/// Extra landscaping for the hand-finished opening levels: ground around the
/// maze, a path surface, soft shadows under the walls, props in the empty
/// spots and a little life over it all. Each level has its own world. It
/// never touches the walls or rooms, so the routes read exactly as before.
class MazeDecor {
  const MazeDecor._({
    required this.groundKind,
    required this.ground,
    required this.groundDark,
    required this.pathKind,
    required this.path,
    required this.pathDark,
    required this.shade,
    required this.props,
    required this.lifeKind,
    required this.colours,
    required this.ink,
    required this.frame,
    this.dots,
    this.walls,
  });

  /// Level 1, the forest: a mossy clearing, pines and toadstools.
  static const forest = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF79AC57),
    groundDark: Color(0xFF5A9142),
    pathKind: PathKind.earth,
    path: Color(0xFFF1E3C2),
    pathDark: Color(0xFFDCC79C),
    shade: Color(0xFF1E3A1A),
    props: _forestProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFFFFB347), Color(0xFF8EC5FF), Color(0xFFFF8FB1)],
    ink: Colors.white,
    frame: FrameStyle.wood,
  );

  /// Level 2, the tulip fields: striped flower beds, a cobbled lane and
  /// windmills, with petals blowing across.
  static const tulips = MazeDecor._(
    groundKind: GroundKind.tulipField,
    ground: Color(0xFFB9DB8C),
    groundDark: Color(0xFF94C26A),
    pathKind: PathKind.cobbles,
    path: Color(0xFFF7EEE4),
    pathDark: Color(0xFFDCC8B8),
    shade: Color(0xFF4A2A3A),
    props: _tulipProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFF05A6E), Color(0xFFFFC94A), Color(0xFFFF9EC4)],
    ink: Color(0xFF34421F),
    frame: FrameStyle.awning,
  );

  /// Level 3, the orchard: late-summer straw, tilled soil, apple crates and
  /// hay bales, with bees about.
  static const orchard = MazeDecor._(
    groundKind: GroundKind.straw,
    ground: Color(0xFFE2C77A),
    groundDark: Color(0xFFC9A852),
    pathKind: PathKind.tilled,
    path: Color(0xFFB98A5E),
    pathDark: Color(0xFF8E6440),
    shade: Color(0xFF3D2410),
    props: _orchardProp,
    lifeKind: LifeKind.bees,
    colours: [Color(0xFFFFC928)],
    ink: Color(0xFF4A3212),
    frame: FrameStyle.crate,
  );

  /// Level 4, the beach: a turquoise lagoon around sandy paths, floats and
  /// rocks in the water, gulls overhead.
  static const beach = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF5CC9D0),
    groundDark: Color(0xFF2E9DB4),
    pathKind: PathKind.sand,
    path: Color(0xFFFBEBC5),
    pathDark: Color(0xFFE5CD94),
    shade: Color(0xFF6B4E1E),
    props: _beachProp,
    lifeKind: LifeKind.gulls,
    colours: [Colors.white],
    ink: Colors.white,
    frame: FrameStyle.driftwood,
  );

  /// Level 5, the desert: rippled red dunes, cracked clay, boulders and
  /// little cacti, with tumbleweeds rolling through.
  static const desert = MazeDecor._(
    groundKind: GroundKind.dunes,
    ground: Color(0xFFEDB27A),
    groundDark: Color(0xFFD48950),
    pathKind: PathKind.clay,
    path: Color(0xFFF5DDB4),
    pathDark: Color(0xFFD9B582),
    shade: Color(0xFF5A2A0E),
    props: _desertProp,
    lifeKind: LifeKind.tumbleweeds,
    colours: [Color(0xFFA9773F)],
    ink: Color(0xFF4A220C),
    frame: FrameStyle.sandstone,
  );

  /// Level 6, cherry blossoms: a pond bank under pink trees.
  static const blossom = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFFA9CF8A),
    groundDark: Color(0xFF8DBA6E),
    pathKind: PathKind.cobbles,
    path: Color(0xFFF7EEEA),
    pathDark: Color(0xFFDDC8C0),
    shade: Color(0xFF4A2A3A),
    props: _blossomProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFF7B6CB), Color(0xFFFBD3E0), Color(0xFFF59BB8)],
    dots: [Color(0xFFFBD3E0), Colors.white],
    ink: Color(0xFF3E5A2A),
    frame: FrameStyle(
      shape: FrameShape.driftwood,
      layout: HeaderLayout.badge,
      ornament: Ornament.blossom,
      board: Color(0xFFEBD3C4),
      boardDark: Color(0xFFD9B8A6),
      trim: Color(0xFFB08A78),
      stripe: Color(0xFFF7B6CB),
      ground: Color(0xFFF6DCE3),
      groundDark: Color(0xFFE9C2CC),
      accent: Color(0xFF8FCFE0),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFF28AA8),
        icon: Color(0xFFB54C6E),
        title: Color(0xFF7A2E48),
      ),
    ),
  );

  /// Level 7, the crystal valley: a dark cave glittering with gems.
  static const crystal = MazeDecor._(
    groundKind: GroundKind.cave,
    ground: Color(0xFF3A2D5E),
    groundDark: Color(0xFF221840),
    pathKind: PathKind.slate,
    path: Color(0xFFD9D0F2),
    pathDark: Color(0xFFB3A4DE),
    shade: Color(0xFF120A24),
    props: _crystalProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFF8FE3F0), Color(0xFFD9C8FF)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.tablet,
      ornament: Ornament.crystals,
      board: Color(0xFF4B3A78),
      boardDark: Color(0xFF3E3066),
      trim: Color(0xFF9B7BE0),
      stripe: Color(0xFF8FE3F0),
      ground: Color(0xFF3A2D5E),
      groundDark: Color(0xFF261C44),
      accent: Color(0xFF8FE3F0),
      look: FrameLook(
        face: Color(0xFFE6DDFB),
        rim: Color(0xFF7A5BC4),
        icon: Color(0xFF4B2F8A),
        title: Color(0xFFF3EEFF),
      ),
    ),
  );

  /// Level 8, natural grass: a sunny lawn with birch logs and clover.
  static const lawn = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF5FA048),
    groundDark: Color(0xFF4A8A38),
    pathKind: PathKind.earth,
    path: Color(0xFFEBDCB4),
    pathDark: Color(0xFFCDB98A),
    shade: Color(0xFF1E3A1A),
    props: _lawnProp,
    lifeKind: LifeKind.petals,
    colours: [Colors.white, Color(0xFFF4F4E4)],
    dots: [Colors.white, Color(0xFFFFE680)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.badge,
      ornament: Ornament.clover,
      board: Color(0xFFEDE2C8),
      boardDark: Color(0xFFD6C6A2),
      trim: Color(0xFF8C7A55),
      stripe: Color(0xFF5FA64A),
      ground: Color(0xFFF0E8D4),
      groundDark: Color(0xFF3A342A),
      accent: Color(0xFF4F9A48),
      look: FrameLook(
        face: Color(0xFFFFF8E8),
        rim: Color(0xFF6E8F3A),
        icon: Color(0xFF4E6B22),
        title: Color(0xFF3D4A1E),
      ),
    ),
  );

  /// Level 9, rooftop alleys: city streets, lamps and brick walls.
  static const city = MazeDecor._(
    groundKind: GroundKind.street,
    ground: Color(0xFF5C6470),
    groundDark: Color(0xFF444B55),
    pathKind: PathKind.cobbles,
    path: Color(0xFFE2DDD2),
    pathDark: Color(0xFFBDB5A6),
    shade: Color(0xFF1C2026),
    props: _cityProp,
    lifeKind: LifeKind.gulls,
    colours: [Color(0xFFB4BAC4)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.sign,
      ornament: Ornament.lamps,
      board: Color(0xFF3E4855),
      boardDark: Color(0xFF4E5968),
      trim: Color(0xFFF3B53A),
      stripe: Color(0xFFF3B53A),
      ground: Color(0xFFB5533C),
      groundDark: Color(0xFF8E3D2B),
      accent: Color(0xFFF3B53A),
      look: FrameLook(
        face: Color(0xFFF4F1EA),
        rim: Color(0xFF3C4654),
        icon: Color(0xFF2F3742),
        title: Colors.white,
      ),
    ),
  );

  /// Level 10, the autumn woods: fallen leaves, red trees and pumpkins.
  static const autumn = MazeDecor._(
    groundKind: GroundKind.leafLitter,
    ground: Color(0xFFB98A52),
    groundDark: Color(0xFF9A6E3C),
    pathKind: PathKind.earth,
    path: Color(0xFFEAD3A8),
    pathDark: Color(0xFFC9A774),
    shade: Color(0xFF3A1E0C),
    props: _autumnProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFE0782F), Color(0xFFC9452C), Color(0xFFF2B33D)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.tablet,
      ornament: Ornament.maple,
      board: Color(0xFF8A4B2A),
      boardDark: Color(0xFF6B3820),
      trim: Color(0xFF4E2814),
      stripe: Color(0xFFD9772B),
      ground: Color(0xFF6E4A33),
      groundDark: Color(0xFF4E3322),
      accent: Color(0xFFE0782F),
      look: FrameLook(
        face: Color(0xFFF6D7A8),
        rim: Color(0xFFA0522D),
        icon: Color(0xFF6B2E14),
        title: Color(0xFFFFEBD0),
        titleShadow: Color(0xFF4A2010),
      ),
    ),
  );

  /// Level 11, the daisy garden: a sunny yellow awning and daisy beds.
  static const daisies = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF8CC46A),
    groundDark: Color(0xFF72AD52),
    pathKind: PathKind.cobbles,
    path: Color(0xFFFBF6E6),
    pathDark: Color(0xFFE6DCBF),
    shade: Color(0xFF2E4A1E),
    props: _daisyProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFFF2C230), Colors.white, Color(0xFFFF9F45)],
    dots: [Colors.white, Color(0xFFF2C230)],
    ink: Color(0xFF2F4A1A),
    frame: FrameStyle(
      shape: FrameShape.awning,
      layout: HeaderLayout.awning,
      ornament: Ornament.daisies,
      board: Color(0xFFFFFDF2),
      boardDark: Color(0xFFFFF4D0),
      trim: Color(0xFFC99A12),
      stripe: Color(0xFFF2C230),
      ground: Color(0xFF6FA545),
      groundDark: Color(0xFF5A8E36),
      accent: Color(0xFFE5B21E),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFE5B21E),
        icon: Color(0xFF8A6A00),
        title: Color(0xFF6B5200),
      ),
    ),
  );

  /// Level 12, the grass meadow: white fences, sheep and swallows.
  static const meadow = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFFA6D07A),
    groundDark: Color(0xFF88BA5C),
    pathKind: PathKind.earth,
    path: Color(0xFFF2E6C4),
    pathDark: Color(0xFFD8C496),
    shade: Color(0xFF2E4A1E),
    props: _meadowProp,
    lifeKind: LifeKind.gulls,
    colours: [Color(0xFF34383F)],
    dots: [Colors.white, Color(0xFFFFE680), Color(0xFFC9B3F0)],
    ink: Color(0xFF2F4A1A),
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.dandelions,
      board: Color(0xFFF7F3E8),
      boardDark: Color(0xFFE2DCCB),
      trim: Color(0xFFA9A08A),
      stripe: Color(0xFF9CCB6A),
      ground: Colors.white,
      groundDark: Color(0xFFB9B3A0),
      accent: Color(0xFF6FAF4A),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF6FAF4A),
        icon: Color(0xFF3F7A2A),
        title: Color(0xFF2F5A1E),
      ),
    ),
  );

  /// Level 13, the rose garden: brick walls, a fountain and red roses.
  static const roses = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF6FA35A),
    groundDark: Color(0xFF558A44),
    pathKind: PathKind.cobbles,
    path: Color(0xFFEFD8C9),
    pathDark: Color(0xFFCFA28E),
    shade: Color(0xFF3A1A1A),
    props: _roseProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFD23B55), Color(0xFFF07A8C), Colors.white],
    dots: [Color(0xFFD23B55), Color(0xFFF7B6CB)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.badge,
      ornament: Ornament.roses,
      board: Color(0xFFEFE3D3),
      boardDark: Color(0xFFF6ECDF),
      trim: Color(0xFFB5523F),
      stripe: Color(0xFFD23B55),
      ground: Color(0xFFB9503C),
      groundDark: Color(0xFF8E3A2A),
      accent: Color(0xFFD23B55),
      look: FrameLook(
        face: Color(0xFFFFF6F0),
        rim: Color(0xFFC23A4F),
        icon: Color(0xFF8E1F33),
        title: Color(0xFF7A1C2E),
      ),
    ),
  );

  /// Level 14, the bamboo grove: stone paths, lanterns and fireflies.
  static const bamboo = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFFA9C98A),
    groundDark: Color(0xFF8BAE6C),
    pathKind: PathKind.slate,
    path: Color(0xFFE8E2D0),
    pathDark: Color(0xFFC9C1A8),
    shade: Color(0xFF2A3A1A),
    props: _bambooProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFFFF07A), Color(0xFFE8FF9A)],
    dots: [Color(0xFFE8F0C8)],
    ink: Color(0xFF2E4A1E),
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.sign,
      ornament: Ornament.bamboo,
      board: Color(0xFF7FB04E),
      boardDark: Color(0xFF5E8F36),
      trim: Color(0xFF3E6A24),
      stripe: Color(0xFFA9D07A),
      ground: Color(0xFF8DBB57),
      groundDark: Color(0xFF5E8A34),
      accent: Color(0xFF6DAA4A),
      look: FrameLook(
        face: Color(0xFFF2F7E4),
        rim: Color(0xFF5E8A34),
        icon: Color(0xFF3E6A24),
        title: Colors.white,
        titleShadow: Color(0xFF2E4F18),
      ),
    ),
  );

  /// Level 15, the flower hedges: a cottage garden with pots and birdbaths.
  static const garden = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF7DBB64),
    groundDark: Color(0xFF62A14C),
    pathKind: PathKind.cobbles,
    path: Color(0xFFF3EBDD),
    pathDark: Color(0xFFD9CCB4),
    shade: Color(0xFF2A3A1A),
    props: _gardenProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFFEE6FA0), Color(0xFF7DA7F0), Color(0xFFFFB347)],
    dots: [Color(0xFFEE6FA0), Color(0xFF7DA7F0), Color(0xFFFFE07A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.awning,
      layout: HeaderLayout.badge,
      ornament: Ornament.flowers,
      board: Colors.white,
      boardDark: Color(0xFFF0F7EC),
      trim: Color(0xFF3E8A5A),
      stripe: Color(0xFF6DBE8C),
      ground: Color(0xFFC9744A),
      groundDark: Color(0xFFA85A35),
      accent: Color(0xFFEE6FA0),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF3E8A5A),
        icon: Color(0xFF2E6B45),
        title: Color(0xFF1F5235),
      ),
    ),
  );

  /// Level 16, the lavender field: purple rows, beehives and a bench.
  static const lavender = MazeDecor._(
    groundKind: GroundKind.tulipField,
    ground: Color(0xFFB7C99A),
    groundDark: Color(0xFF9DB37E),
    pathKind: PathKind.earth,
    path: Color(0xFFF1E4C6),
    pathDark: Color(0xFFD6C39A),
    shade: Color(0xFF3A2A4A),
    props: _lavenderProp,
    lifeKind: LifeKind.bees,
    colours: [Color(0xFF8E6BC9), Color(0xFFA98BDB), Color(0xFF7A57B8)],
    ink: Color(0xFF3A2A5A),
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.tablet,
      ornament: Ornament.lavender,
      board: Color(0xFFE9DDF5),
      boardDark: Color(0xFFD4C2EA),
      trim: Color(0xFF8E6BC9),
      stripe: Color(0xFFC9B48A),
      ground: Color(0xFFF8F4FB),
      groundDark: Color(0xFFB9A5D8),
      accent: Color(0xFF8E6BC9),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF8E6BC9),
        icon: Color(0xFF5E3F99),
        title: Color(0xFF4A2F7E),
      ),
    ),
  );

  /// Level 17, the mushroom garden: a mossy dusk full of toadstools.
  static const mushrooms = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF3F6A3A),
    groundDark: Color(0xFF2C4E2A),
    pathKind: PathKind.earth,
    path: Color(0xFFD8C49E),
    pathDark: Color(0xFFB09A72),
    shade: Color(0xFF0E1A0C),
    props: _mushroomProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFC8FF7A), Color(0xFFFFF07A)],
    dots: [Color(0xFF9FD3F0), Color(0xFFF7B6CB)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.badge,
      ornament: Ornament.mushrooms,
      board: Color(0xFF5E4630),
      boardDark: Color(0xFF463322),
      trim: Color(0xFF2F2216),
      stripe: Color(0xFF7FB65A),
      ground: Color(0xFF5A4330),
      groundDark: Color(0xFF3A2A1C),
      accent: Color(0xFFE2463F),
      look: FrameLook(
        face: Color(0xFFF3E6CF),
        rim: Color(0xFF8A2E24),
        icon: Color(0xFF7A2018),
        title: Color(0xFFFFF0DA),
        titleShadow: Color(0xFF2A1A0E),
      ),
    ),
  );

  /// Level 18, the sunflower farm: tall sunflowers, crates and bees.
  static const sunflowers = MazeDecor._(
    groundKind: GroundKind.straw,
    ground: Color(0xFFE8C860),
    groundDark: Color(0xFFCFA640),
    pathKind: PathKind.tilled,
    path: Color(0xFFA97A4E),
    pathDark: Color(0xFF7E5634),
    shade: Color(0xFF3D2410),
    props: _sunflowerProp,
    lifeKind: LifeKind.bees,
    colours: [Color(0xFFF5B91E)],
    ink: Color(0xFF4A3212),
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.sign,
      ornament: Ornament.sunflowers,
      board: Color(0xFFF5C84C),
      boardDark: Color(0xFFE0AE2E),
      trim: Color(0xFFA8761A),
      stripe: Color(0xFFC79A3A),
      ground: Color(0xFFF7E2A6),
      groundDark: Color(0xFFC9A24E),
      accent: Color(0xFFF5B91E),
      look: FrameLook(
        face: Color(0xFFFFF8E1),
        rim: Color(0xFFD99A12),
        icon: Color(0xFF6B3F1E),
        title: Color(0xFF5A3412),
      ),
    ),
  );

  /// Level 19, the lotus pond: a boardwalk over still green water.
  static const lotus = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF5FAE98),
    groundDark: Color(0xFF3F8F7A),
    pathKind: PathKind.planks,
    path: Color(0xFFD8C39A),
    pathDark: Color(0xFFAE9668),
    shade: Color(0xFF2A3A30),
    props: _lotusProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFF4FC3D9), Color(0xFF7AD98A), Color(0xFF6E8BF0)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.driftwood,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.lotus,
      board: Color(0xFFCDBE94),
      boardDark: Color(0xFFB4A276),
      trim: Color(0xFF8C7B52),
      stripe: Color(0xFF7FB65A),
      ground: Color(0xFF8FBF7A),
      groundDark: Color(0xFF6FA05A),
      accent: Color(0xFF3F8F7A),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFF08DB4),
        icon: Color(0xFF2E6B5E),
        title: Color(0xFF2E5A50),
      ),
    ),
  );

  /// Level 20, the stone garden: raked gravel, mossy rocks and lanterns.
  static const zen = MazeDecor._(
    groundKind: GroundKind.raked,
    ground: Color(0xFFDAD5C7),
    groundDark: Color(0xFFBFB8A6),
    pathKind: PathKind.slate,
    // Pale sandstone flags so the grey pebble walls stand out.
    path: Color(0xFFEDE6D3),
    pathDark: Color(0xFFD6CCB2),
    shade: Color(0xFF2A2E28),
    props: _zenProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFF8BAE5A), Color(0xFFC9A25A)],
    ink: Color(0xFF3A3E36),
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.tablet,
      ornament: Ornament.pebbles,
      board: Color(0xFFB9BDB5),
      boardDark: Color(0xFFCDD1C9),
      trim: Color(0xFF7C8279),
      stripe: Color(0xFF9AA095),
      ground: Color(0xFF8E948C),
      groundDark: Color(0xFF6E746C),
      accent: Color(0xFF5E8A52),
      look: FrameLook(
        face: Color(0xFFEEF0EA),
        rim: Color(0xFF6E746C),
        icon: Color(0xFF3E443C),
        title: Color(0xFF2E332C),
      ),
    ),
  );

  /// Level 21, the coral lagoon: a deep blue reef with rising bubbles.
  static const reef = MazeDecor._(
    groundKind: GroundKind.lagoon,
    ground: Color(0xFF22B5C9),
    groundDark: Color(0xFF0E7F9E),
    pathKind: PathKind.sand,
    path: Color(0xFFFFF1CF),
    pathDark: Color(0xFFE8CF95),
    shade: Color(0xFF0A4A5E),
    props: _reefProp,
    lifeKind: LifeKind.bubbles,
    colours: [Colors.white],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.driftwood,
      layout: HeaderLayout.badge,
      ornament: Ornament.coral,
      board: Color(0xFFFFE3D6),
      boardDark: Color(0xFFF7C9B6),
      trim: Color(0xFFD9775F),
      stripe: Color(0xFFF27A6B),
      ground: Color(0xFFFFEFC9),
      groundDark: Color(0xFFE8CF95),
      accent: Color(0xFF2B7BB0),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFF27A6B),
        icon: Color(0xFF1F5C8A),
        title: Color(0xFF8E3626),
      ),
    ),
  );

  /// Level 22, the country farm: a red barn sign, chickens and hay.
  static const farm = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF4F9A3A),
    groundDark: Color(0xFF3D7F2C),
    pathKind: PathKind.earth,
    path: Color(0xFFA9794A),
    pathDark: Color(0xFF8A5E36),
    shade: Color(0xFF1E3410),
    props: _farmProp,
    lifeKind: LifeKind.gulls,
    colours: [Color(0xFF5A3A22)],
    dots: [Colors.white, Color(0xFFFFE07A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.sign,
      ornament: Ornament.clover,
      board: Color(0xFFB7412E),
      boardDark: Color(0xFF9C3524),
      trim: Color(0xFFF4EFE6),
      stripe: Color(0xFFE2C46A),
      ground: Color(0xFFFFFFFF),
      groundDark: Color(0xFFB7412E),
      accent: Color(0xFFB7412E),
      look: FrameLook(
        face: Color(0xFFFFF8EE),
        rim: Color(0xFFB7412E),
        icon: Color(0xFF8A2A1C),
        title: Colors.white,
        titleShadow: Color(0xFF5E1C12),
      ),
    ),
  );

  /// Level 23, the snowy forest: blue winter dusk, snowmen and snowfall.
  static const winter = MazeDecor._(
    groundKind: GroundKind.snowfield,
    ground: Color(0xFFF4F8FC),
    groundDark: Color(0xFFC7DCEC),
    pathKind: PathKind.earth,
    path: Color(0xFF9DBFD8),
    pathDark: Color(0xFF7FA6C4),
    shade: Color(0xFF2E5A82),
    props: _winterProp,
    lifeKind: LifeKind.snow,
    colours: [Colors.white],
    ink: Color(0xFF234A6B),
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.badge,
      ornament: Ornament.snowflakes,
      board: Color(0xFFDCEEF8),
      boardDark: Color(0xFFEAF5FB),
      trim: Color(0xFF5B8DB5),
      stripe: Color(0xFF8FBCDD),
      ground: Color(0xFFE8F2F8),
      groundDark: Color(0xFFA9C6DB),
      accent: Color(0xFF5B8DB5),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF5B8DB5),
        icon: Color(0xFF2E5B82),
        title: Color(0xFF234A6B),
      ),
    ),
  );

  /// Level 70: the snowy forest with a deep ice-blue wall along the bottom,
  /// so the controls stand out from the pale snow.
  static const frozenWall = MazeDecor._(
    groundKind: GroundKind.snowfield,
    ground: Color(0xFFF4F8FC),
    groundDark: Color(0xFFC7DCEC),
    pathKind: PathKind.earth,
    path: Color(0xFF9DBFD8),
    pathDark: Color(0xFF7FA6C4),
    shade: Color(0xFF2E5A82),
    props: _winterProp,
    lifeKind: LifeKind.snow,
    colours: [Colors.white],
    ink: Color(0xFF234A6B),
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.badge,
      ornament: Ornament.snowflakes,
      board: Color(0xFFDCEEF8),
      boardDark: Color(0xFFEAF5FB),
      trim: Color(0xFF3F75A3),
      stripe: Color(0xFF8FBCDD),
      ground: Color(0xFF6E9FC8),
      groundDark: Color(0xFF4E80AC),
      accent: Color(0xFF3F75A3),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF3F75A3),
        icon: Color(0xFF2E5B82),
        title: Color(0xFF234A6B),
      ),
    ),
  );

  /// Level 24, the pumpkin patch at dusk: dark soil and glowing lanterns.
  static const pumpkins = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF4E3826),
    groundDark: Color(0xFF3A281A),
    pathKind: PathKind.earth,
    path: Color(0xFFF0DCA6),
    pathDark: Color(0xFFCFB574),
    shade: Color(0xFF1A0E06),
    props: _pumpkinProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFFFB347), Color(0xFFFFE08A)],
    dots: [Color(0xFFE8822F), Color(0xFF7FB65A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.sign,
      ornament: Ornament.pumpkins,
      board: Color(0xFF6E4A30),
      boardDark: Color(0xFF52361F),
      trim: Color(0xFF2E1E10),
      stripe: Color(0xFF7FB65A),
      ground: Color(0xFF5A3C26),
      groundDark: Color(0xFF3A2616),
      accent: Color(0xFFE8822F),
      look: FrameLook(
        face: Color(0xFFFFE2B8),
        rim: Color(0xFFE8822F),
        icon: Color(0xFF8A3E10),
        title: Color(0xFFFFD58A),
        titleShadow: Color(0xFF2A1708),
      ),
    ),
  );

  /// Level 25, rooftops at night: navy streets under neon and lamplight.
  static const nightCity = MazeDecor._(
    // The city lights seen from above, with tidy brick walls in place of
    // the busy rooftop photos.
    groundKind: GroundKind.cave,
    ground: Color(0xFF232A4A),
    groundDark: Color(0xFF181D36),
    pathKind: PathKind.slate,
    path: Color(0xFF8E96BE),
    pathDark: Color(0xFF7880A8),
    walls: MazeWallArt.brick,
    shade: Color(0xFF080A16),
    props: _nightCityProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFFFE08A), Color(0xFFFF7FC8)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.lamps,
      board: Color(0xFF2E3660),
      boardDark: Color(0xFF262D52),
      trim: Color(0xFFFF7FC8),
      stripe: Color(0xFF6EE6F2),
      ground: Color(0xFF3A426E),
      groundDark: Color(0xFF252B4C),
      accent: Color(0xFFFF7FC8),
      look: FrameLook(
        face: Color(0xFFFFF5FB),
        rim: Color(0xFFFF4FAE),
        icon: Color(0xFF2E3660),
        title: Color(0xFF2E3660),
      ),
    ),
  );

  /// Level 26, the reed wetlands: dark water, stepping stones and ducks.
  static const marsh = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF2E6578),
    groundDark: Color(0xFF1F4A59),
    pathKind: PathKind.planks,
    path: Color(0xFFB98E5E),
    pathDark: Color(0xFF9A7046),
    shade: Color(0xFF0F2A33),
    props: _marshProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFF7AE0F0), Color(0xFFB8F07A), Color(0xFF8FA8FF)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.driftwood,
      layout: HeaderLayout.sign,
      ornament: Ornament.bamboo,
      board: Color(0xFFEFE2BC),
      boardDark: Color(0xFFDCCB9A),
      trim: Color(0xFF7A683C),
      stripe: Color(0xFF5E7A3A),
      ground: Color(0xFF8A9A5E),
      groundDark: Color(0xFF6E7E46),
      accent: Color(0xFF2E6578),
      look: FrameLook(
        face: Color(0xFFFFFBEE),
        rim: Color(0xFF5E7A3A),
        icon: Color(0xFF3E5424),
        title: Color(0xFF3A3218),
      ),
    ),
  );

  /// Level 27, the royal rose garden: navy and gold tiles, topiary and urns.
  static const palace = MazeDecor._(
    groundKind: GroundKind.checker,
    ground: Color(0xFF2E4280),
    groundDark: Color(0xFF26386E),
    pathKind: PathKind.cobbles,
    path: Color(0xFFFBF3E2),
    pathDark: Color(0xFFE2D2B0),
    shade: Color(0xFF0E1630),
    props: _palaceProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFFFB3C6), Colors.white, Color(0xFFE9C46A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.badge,
      ornament: Ornament.roses,
      board: Color(0xFFFFFBF2),
      boardDark: Color(0xFFF2E6CC),
      trim: Color(0xFFC9A23A),
      stripe: Color(0xFF2E4280),
      ground: Color(0xFFFFFBF2),
      groundDark: Color(0xFFC9A23A),
      accent: Color(0xFFC9A23A),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFC9A23A),
        icon: Color(0xFF2E4280),
        title: Color(0xFF26386E),
      ),
    ),
  );

  /// Level 28, the brick courtyards: terracotta, teal shutters and wells.
  static const courtyard = MazeDecor._(
    groundKind: GroundKind.bricks,
    ground: Color(0xFFC0623F),
    groundDark: Color(0xFF9A4A2E),
    pathKind: PathKind.slate,
    path: Color(0xFF9FB4BD),
    pathDark: Color(0xFF7F969F),
    shade: Color(0xFF2A1A12),
    props: _courtyardProp,
    lifeKind: LifeKind.gulls,
    colours: [Color(0xFFDDE3E8)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.flowers,
      board: Color(0xFF3E9A9A),
      boardDark: Color(0xFF2F8080),
      trim: Color(0xFF226666),
      stripe: Color(0xFFE6B85C),
      ground: Color(0xFFF7F1E3),
      groundDark: Color(0xFF3E9A9A),
      accent: Color(0xFF2F8080),
      look: FrameLook(
        face: Color(0xFFFFFBF2),
        rim: Color(0xFF2F8080),
        icon: Color(0xFF1E5E5E),
        title: Color(0xFF1E4E4E),
      ),
    ),
  );

  /// Level 29, the sunset beach: violet water, parasols and surfboards.
  static const sunset = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF6A4FA0),
    groundDark: Color(0xFF4A357A),
    pathKind: PathKind.sand,
    path: Color(0xFFFFE6C2),
    pathDark: Color(0xFFF0C58E),
    shade: Color(0xFF2A1A44),
    props: _sunsetProp,
    lifeKind: LifeKind.gulls,
    colours: [Colors.white],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.awning,
      layout: HeaderLayout.badge,
      ornament: Ornament.starfish,
      board: Color(0xFFFFF4E6),
      boardDark: Color(0xFFFFE6C2),
      trim: Color(0xFFD9573A),
      stripe: Color(0xFFFF8A5C),
      ground: Color(0xFFFFD3A8),
      groundDark: Color(0xFFF0A86E),
      accent: Color(0xFFFF8A5C),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFFF8A5C),
        icon: Color(0xFFB84A2A),
        title: Color(0xFF7A2E1A),
      ),
    ),
  );

  /// Level 30, lavender by moonlight: an indigo field full of fireflies.
  static const moonLavender = MazeDecor._(
    groundKind: GroundKind.tulipField,
    ground: Color(0xFF2A2650),
    groundDark: Color(0xFF1C1A3A),
    pathKind: PathKind.earth,
    path: Color(0xFFF2EAD8),
    pathDark: Color(0xFFD2C6A8),
    shade: Color(0xFF0C0A1C),
    props: _moonLavenderProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFB79CF2), Color(0xFFFFF0A0), Color(0xFF8E6BC9)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.badge,
      ornament: Ornament.lavender,
      board: Color(0xFF4A3A78),
      boardDark: Color(0xFF382B5E),
      trim: Color(0xFF241A40),
      stripe: Color(0xFF8E6BC9),
      ground: Color(0xFF3E3068),
      groundDark: Color(0xFF241A40),
      accent: Color(0xFFB79CF2),
      look: FrameLook(
        face: Color(0xFFEDE4FF),
        rim: Color(0xFF8E6BC9),
        icon: Color(0xFF4A2F8A),
        title: Color(0xFFF3EEFF),
        titleShadow: Color(0xFF1C1236),
      ),
    ),
  );

  /// Level 31, jungle ruins: an overgrown temple deep in the green.
  static const jungle = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF2F5A34),
    groundDark: Color(0xFF1F4024),
    pathKind: PathKind.slate,
    path: Color(0xFFF0DDB0),
    pathDark: Color(0xFFD2BB86),
    shade: Color(0xFF0E1E10),
    props: _jungleProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFF3FA9F5), Color(0xFF2E7BE0), Color(0xFFFFC94A)],
    dots: [Color(0xFFFF6B6B), Color(0xFFFFC94A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.leaves,
      board: Color(0xFFB9B397),
      boardDark: Color(0xFFCFC9AE),
      trim: Color(0xFF6E7A50),
      stripe: Color(0xFF4F7A3A),
      ground: Color(0xFF8E8A70),
      groundDark: Color(0xFF6A6650),
      accent: Color(0xFF4F7A3A),
      look: FrameLook(
        face: Color(0xFFF4F1E2),
        rim: Color(0xFF4F7A3A),
        icon: Color(0xFF3A5A28),
        title: Color(0xFF2E3A1E),
      ),
    ),
  );

  /// Level 32, the orange grove: red earth rows and baskets of oranges.
  static const grove = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF6DA845),
    groundDark: Color(0xFF558A34),
    pathKind: PathKind.tilled,
    path: Color(0xFFC46A3E),
    pathDark: Color(0xFF9A4E2C),
    shade: Color(0xFF3A1A0A),
    props: _groveProp,
    lifeKind: LifeKind.bees,
    colours: [Color(0xFFF59A1E)],
    dots: [Colors.white, Color(0xFFF59A1E)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.badge,
      ornament: Ornament.citrus,
      board: Color(0xFFF5D9A0),
      boardDark: Color(0xFFE2BE7A),
      trim: Color(0xFFC07A2A),
      stripe: Color(0xFF6DA845),
      ground: Color(0xFFFFF4DE),
      groundDark: Color(0xFFC07A2A),
      accent: Color(0xFFF59A1E),
      look: FrameLook(
        face: Color(0xFFFFF6E6),
        rim: Color(0xFFF59A1E),
        icon: Color(0xFFB0590E),
        title: Color(0xFF6B3410),
      ),
    ),
  );

  /// Level 33, the emerald mine: timber props, lanterns and green gems.
  static const mine = MazeDecor._(
    groundKind: GroundKind.cave,
    ground: Color(0xFF14382E),
    groundDark: Color(0xFF0A241D),
    pathKind: PathKind.planks,
    path: Color(0xFFE8CFA0),
    pathDark: Color(0xFFC7A874),
    shade: Color(0xFF040E0B),
    props: _mineProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFF5CF2A0), Color(0xFFFFD86A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.sign,
      ornament: Ornament.crystals,
      board: Color(0xFF6E4A2E),
      boardDark: Color(0xFF52361F),
      trim: Color(0xFF2E1E10),
      stripe: Color(0xFF3FA36E),
      ground: Color(0xFF5A3C24),
      groundDark: Color(0xFF3A2616),
      accent: Color(0xFF3FA36E),
      look: FrameLook(
        face: Color(0xFFE8F7EC),
        rim: Color(0xFF2E8A5A),
        icon: Color(0xFF1E5E3E),
        title: Color(0xFFFFE6B0),
        titleShadow: Color(0xFF241608),
      ),
    ),
  );

  /// Level 34, the lakeside golf course: sand bunkers, flags and a lake.
  static const golf = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF3F96CF),
    groundDark: Color(0xFF2A74A8),
    pathKind: PathKind.sand,
    path: Color(0xFFF6E7BC),
    pathDark: Color(0xFFDCC68A),
    shade: Color(0xFF1A3A1A),
    props: _golfProp,
    lifeKind: LifeKind.gulls,
    colours: [Colors.white],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.clover,
      board: Color(0xFFFFFFFF),
      boardDark: Color(0xFFE6F2E0),
      trim: Color(0xFF3E8A3A),
      stripe: Color(0xFF7CC35A),
      ground: Colors.white,
      groundDark: Color(0xFF3E8A3A),
      accent: Color(0xFF3E8A3A),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF3E8A3A),
        icon: Color(0xFF2E6A2A),
        title: Color(0xFF1E4A1E),
      ),
    ),
  );

  /// Level 35, the wheat harvest: green field edges, red poppies and crows.
  static const harvest = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF5E8F3A),
    groundDark: Color(0xFF4A752C),
    pathKind: PathKind.tilled,
    path: Color(0xFF7A5634),
    pathDark: Color(0xFF5A3E24),
    shade: Color(0xFF1E1408),
    props: _harvestProp,
    lifeKind: LifeKind.gulls,
    colours: [Color(0xFF2A2A2E)],
    dots: [Color(0xFFE23B3B), Color(0xFFE23B3B), Colors.white],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.badge,
      ornament: Ornament.wheat,
      board: Color(0xFFE8C470),
      boardDark: Color(0xFFD1A64E),
      trim: Color(0xFF8A6420),
      stripe: Color(0xFFE23B3B),
      ground: Color(0xFFC79A3A),
      groundDark: Color(0xFF8A6420),
      accent: Color(0xFFD9A93A),
      look: FrameLook(
        face: Color(0xFFFFF4D6),
        rim: Color(0xFFB8862E),
        icon: Color(0xFF7A4E10),
        title: Color(0xFF5A3A0E),
      ),
    ),
  );

  /// Level 36, the lantern pond: night water lit by floating lanterns.
  static const lanternPond = MazeDecor._(
    groundKind: GroundKind.sea,
    ground: Color(0xFF173352),
    groundDark: Color(0xFF0E2238),
    pathKind: PathKind.planks,
    path: Color(0xFFE2C394),
    pathDark: Color(0xFFBE9C68),
    shade: Color(0xFF050C16),
    props: _lanternPondProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFFFC46A), Color(0xFFFF8A5C)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.driftwood,
      layout: HeaderLayout.badge,
      ornament: Ornament.lotus,
      board: Color(0xFF2A4A70),
      boardDark: Color(0xFF203C5E),
      trim: Color(0xFFE9B85C),
      stripe: Color(0xFFE9B85C),
      ground: Color(0xFF2A4A70),
      groundDark: Color(0xFF1A3352),
      accent: Color(0xFFE9B85C),
      look: FrameLook(
        face: Color(0xFFFFF6E2),
        rim: Color(0xFFE9B85C),
        icon: Color(0xFF8A5A10),
        title: Color(0xFFFFE6B0),
      ),
    ),
  );

  /// Level 37, the red canyon: wagon wheels, barrels and tumbleweeds.
  static const canyon = MazeDecor._(
    groundKind: GroundKind.dunes,
    ground: Color(0xFFB4532E),
    groundDark: Color(0xFF8E3E20),
    pathKind: PathKind.clay,
    path: Color(0xFFE8B394),
    pathDark: Color(0xFFC48A6A),
    shade: Color(0xFF3A1408),
    props: _canyonProp,
    lifeKind: LifeKind.tumbleweeds,
    colours: [Color(0xFF8A5A2E)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.crate,
      layout: HeaderLayout.sign,
      ornament: Ornament.cactus,
      board: Color(0xFFD8B27A),
      boardDark: Color(0xFFBE9456),
      trim: Color(0xFF6E4A22),
      stripe: Color(0xFF8E3E20),
      ground: Color(0xFFE8CFA0),
      groundDark: Color(0xFF8A5E30),
      accent: Color(0xFFB4532E),
      look: FrameLook(
        face: Color(0xFFFFF0D8),
        rim: Color(0xFF8E3E20),
        icon: Color(0xFF6E2A10),
        title: Color(0xFF4A2410),
      ),
    ),
  );

  /// Level 38, the spring picnic: gingham blankets, baskets and kites.
  static const picnic = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFFC3DA78),
    groundDark: Color(0xFFA6C25A),
    pathKind: PathKind.cobbles,
    path: Color(0xFFEDB7A2),
    pathDark: Color(0xFFD08F78),
    shade: Color(0xFF3A2A1A),
    props: _picnicProp,
    lifeKind: LifeKind.butterflies,
    colours: [Color(0xFF5E8FD9), Color(0xFFFF8FB1), Color(0xFFFFC94A)],
    dots: [Colors.white, Color(0xFF8FB4F2)],
    ink: Color(0xFF2E4A1A),
    frame: FrameStyle(
      shape: FrameShape.awning,
      layout: HeaderLayout.badge,
      ornament: Ornament.daisies,
      board: Color(0xFFF4F8FF),
      boardDark: Color(0xFFE2ECFB),
      trim: Color(0xFF3E6AB8),
      stripe: Color(0xFF8FB4F2),
      ground: Color(0xFF8FB4F2),
      groundDark: Color(0xFF5E8FD9),
      accent: Color(0xFF3E6AB8),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFF3E6AB8),
        icon: Color(0xFF2A4E8E),
        title: Color(0xFF1E3A6E),
      ),
    ),
  );

  /// Level 39, the Moroccan riad: teal tiles, blue paths and brass lamps.
  static const riad = MazeDecor._(
    groundKind: GroundKind.checker,
    ground: Color(0xFF1F7A7A),
    groundDark: Color(0xFF176868),
    pathKind: PathKind.slate,
    path: Color(0xFF3A6EA5),
    pathDark: Color(0xFF2E5A8A),
    shade: Color(0xFF0A1A2A),
    props: _riadProp,
    lifeKind: LifeKind.petals,
    colours: [Color(0xFFFF9F45), Color(0xFFFF6F91), Color(0xFFE9C46A)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.sandstone,
      layout: HeaderLayout.sign,
      ornament: Ornament.flowers,
      board: Color(0xFFD9895A),
      boardDark: Color(0xFFE8A57A),
      trim: Color(0xFF2E5A8A),
      stripe: Color(0xFFE9C46A),
      ground: Color(0xFFC0623F),
      groundDark: Color(0xFF9A4A2E),
      accent: Color(0xFF2E5A8A),
      look: FrameLook(
        face: Color(0xFFFFF4E6),
        rim: Color(0xFF2E5A8A),
        icon: Color(0xFF1E3E6E),
        title: Color(0xFF4A1E0E),
      ),
    ),
  );

  /// Level 40, the fairy forest: a violet twilight wood full of fairy light.
  static const fairy = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFF2E2F5E),
    groundDark: Color(0xFF212246),
    pathKind: PathKind.earth,
    path: Color(0xFFF1E1C2),
    pathDark: Color(0xFFD2BE96),
    shade: Color(0xFF0A0A1E),
    props: _fairyProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFF7AF0F0), Color(0xFFFF9EE8), Color(0xFFFFF0A0)],
    dots: [Color(0xFF7AF0F0), Color(0xFFFF9EE8)],
    ink: Colors.white,
    frame: FrameStyle(
      shape: FrameShape.wood,
      layout: HeaderLayout.ribbon,
      ornament: Ornament.mushrooms,
      board: Color(0xFF3A3A70),
      boardDark: Color(0xFF2C2C58),
      trim: Color(0xFF7AF0F0),
      stripe: Color(0xFF6E9E5A),
      ground: Color(0xFF4A3A30),
      groundDark: Color(0xFF2E2420),
      accent: Color(0xFFFF9EE8),
      look: FrameLook(
        face: Color(0xFFF6F0FF),
        rim: Color(0xFF8E6BC9),
        icon: Color(0xFF4A2F8A),
        title: Color(0xFF3A2A6E),
      ),
    ),
  );

  /// Level 9, candy town: pastel pink ground, mint paths and sweets.
  static const candy = MazeDecor._(
    groundKind: GroundKind.meadow,
    ground: Color(0xFFF9C9DC),
    groundDark: Color(0xFFF2A6C4),
    pathKind: PathKind.cobbles,
    path: Color(0xFFE4F7EE),
    pathDark: Color(0xFFBFE6D3),
    shade: Color(0xFF7A3A5A),
    props: _candyProp,
    lifeKind: LifeKind.sparkles,
    colours: [Color(0xFFFFF4A8), Colors.white, Color(0xFFB8F0FF)],
    dots: [Colors.white, Color(0xFF8FD8F2), Color(0xFFFFE07A)],
    ink: Color(0xFF8E2452),
    walls: MazeWallArt.tulips,
    frame: FrameStyle(
      shape: FrameShape.awning,
      layout: HeaderLayout.badge,
      ornament: Ornament.flowers,
      board: Color(0xFFFFF7FB),
      boardDark: Color(0xFFFBE3EE),
      trim: Color(0xFFE0558E),
      stripe: Color(0xFF7FD8C0),
      ground: Color(0xFF9FE3CF),
      groundDark: Color(0xFF6CC9AE),
      accent: Color(0xFFE0558E),
      look: FrameLook(
        face: Colors.white,
        rim: Color(0xFFE0558E),
        icon: Color(0xFFB8306A),
        title: Color(0xFF8E2452),
      ),
    ),
  );

  static MazeDecor? forLevel(int level) => switch (level) {
    1 => forest,
    2 => tulips,
    3 => orchard,
    4 => beach,
    5 => desert,
    6 => blossom,
    7 => crystal,
    8 => lawn,
    9 => candy,
    10 => autumn,
    11 => daisies,
    12 => meadow,
    13 => roses,
    14 => bamboo,
    15 => garden,
    16 => lavender,
    17 => mushrooms,
    18 => sunflowers,
    19 => lotus,
    20 => zen,
    21 => reef,
    22 => farm,
    23 => winter,
    24 => pumpkins,
    25 => nightCity,
    26 => marsh,
    27 => palace,
    28 => courtyard,
    29 => sunset,
    30 => moonLavender,
    31 => jungle,
    32 => grove,
    33 => mine,
    34 => golf,
    35 => harvest,
    36 => lanternPond,
    37 => canyon,
    38 => picnic,
    39 => riad,
    40 => fairy,
    70 => frozenWall,
    > 40 && <= EscapeMaze.count => _generated.putIfAbsent(
      level,
      () => _seasoned(level),
    ),
    _ => null,
  };

  static final _generated = <int, MazeDecor>{};

  // The hand-finished worlds that suit each landscape. Where there are two,
  // levels take them in turn.
  static List<MazeDecor> _templatesFor(MazeTheme theme) => switch (theme) {
    MazeTheme.forest => [forest, fairy],
    MazeTheme.daisies => [daisies, picnic],
    MazeTheme.meadow => [meadow, farm],
    MazeTheme.roses => [roses, palace],
    MazeTheme.bamboo => [bamboo],
    MazeTheme.garden => [garden, picnic],
    MazeTheme.lavender => [lavender, moonLavender],
    MazeTheme.mushrooms => [mushrooms, fairy],
    MazeTheme.sunflowers => [sunflowers, harvest],
    MazeTheme.lotus => [lotus, lanternPond],
    MazeTheme.stone => [zen, jungle],
    MazeTheme.grass => [lawn, golf],
    MazeTheme.city => [city, nightCity],
    MazeTheme.orchard => [orchard, grove],
    MazeTheme.cactus => [desert, canyon],
    MazeTheme.palms => [beach, sunset],
    MazeTheme.snow => [winter],
    MazeTheme.crystal => [crystal, mine],
    MazeTheme.coral => [reef],
    MazeTheme.brick => [courtyard, riad],
    // Pale fences need the farm's dark dirt track to stand out.
    MazeTheme.fence => [farm],
    MazeTheme.wheat => [harvest, sunflowers],
    MazeTheme.pumpkins => [pumpkins, autumn],
    MazeTheme.tulips => [tulips, garden],
    MazeTheme.blossom => [blossom],
    MazeTheme.pots => [riad, courtyard],
    MazeTheme.reeds => [marsh, lotus],
    MazeTheme.ruins => [jungle, zen],
  };

  // Five seasons laid over the template: none, golden autumn, rose
  // evening, misty teal and violet twilight.
  static const _seasonTints = [
    null,
    Color(0xFFE6A04A),
    Color(0xFFE07A8A),
    Color(0xFF4FA3A0),
    Color(0xFF6E5AA8),
  ];

  /// A later level's world: the template for its landscape, tinted for a
  /// season so neighbouring levels look different. The path keeps almost
  /// its own colour so the walls always stand out against it.
  static MazeDecor _seasoned(int level) {
    final templates = _templatesFor(MazeTheme.forLevel(level));
    final base = templates[(level ~/ 3) % templates.length];
    final season = level % _seasonTints.length;
    final tint = _seasonTints[season];
    if (tint == null) return base;
    Color shift(Color c, double amount) => Color.lerp(c, tint, amount)!;
    final ground = shift(base.ground, .3);
    final f = base.frame;
    final frame = FrameStyle(
      shape: f.shape,
      layout: f.layout,
      ornament: f.ornament,
      board: shift(f.board, .18),
      boardDark: shift(f.boardDark, .18),
      trim: shift(f.trim, .15),
      stripe: shift(f.stripe, .15),
      ground: shift(f.ground, .2),
      groundDark: shift(f.groundDark, .2),
      accent: shift(f.accent, .15),
      look: FrameLook(
        face: f.look.face,
        rim: shift(f.look.rim, .15),
        icon: f.look.icon,
        title: f.look.title,
        titleShadow: f.look.titleShadow,
      ),
    );
    // Each season brings its own weather.
    final (life, colours) = switch (season) {
      1 => (
        LifeKind.petals,
        const [Color(0xFFE0782F), Color(0xFFC9452C), Color(0xFFF2B33D)],
      ),
      2 => (
        LifeKind.petals,
        const [Color(0xFFF7B6CB), Color(0xFFFBD3E0), Colors.white],
      ),
      3 => (LifeKind.sparkles, const [Color(0xFFFFF0A0), Color(0xFFC8FFE0)]),
      _ => (LifeKind.sparkles, const [Color(0xFFD9C8FF), Color(0xFFFFE0F5)]),
    };
    return MazeDecor._(
      groundKind: base.groundKind,
      ground: ground,
      groundDark: shift(base.groundDark, .3),
      pathKind: base.pathKind,
      path: shift(base.path, .08),
      pathDark: shift(base.pathDark, .08),
      shade: base.shade,
      props: base.props,
      // A tiled or striped ground keeps its own colours for its pattern.
      lifeKind:
          base.groundKind == GroundKind.tulipField ||
              base.groundKind == GroundKind.leafLitter ||
              base.groundKind == GroundKind.checker ||
              base.groundKind == GroundKind.cave
          ? base.lifeKind
          : life,
      colours:
          base.groundKind == GroundKind.tulipField ||
              base.groundKind == GroundKind.leafLitter ||
              base.groundKind == GroundKind.checker ||
              base.groundKind == GroundKind.cave
          ? base.colours
          : colours,
      ink: ground.computeLuminance() < .4 ? Colors.white : base.ink,
      frame: frame,
      dots: base.dots,
      walls: base.walls,
    );
  }

  final GroundKind groundKind;
  final PathKind pathKind;
  final LifeKind lifeKind;
  final Color ground, groundDark, path, pathDark, shade;
  final void Function(Canvas, Paint, int seed) props;
  final List<Color> colours;

  /// Text and icons drawn straight onto this world's ground.
  final Color ink;

  /// How the header and footer are built for this world.
  final FrameStyle frame;

  /// Tiny flowers dotted over a meadow; null keeps cream and pink.
  final List<Color>? dots;

  /// Drawn walls to use instead of the landscape's own, where a cleaner
  /// look suits this world better.
  final MazeWallArt? walls;
}

/// Where rooms sit on the board.
class MazeLayout {
  const MazeLayout(this.maze, this.origin, this.cellWidth, this.cellHeight);
  final EscapeMaze maze;
  final Offset origin;
  final double cellWidth, cellHeight;

  double get cell => math.min(cellWidth, cellHeight);
  Rect room(int x, int y) => Rect.fromLTWH(
    origin.dx + x * cellWidth,
    origin.dy + y * cellHeight,
    cellWidth,
    cellHeight,
  );
  Offset centre(double x, double y) =>
      origin + Offset((x + .5) * cellWidth, (y + .5) * cellHeight);
}

// A small, repeatable random number from a position.
int _hash(int x, int y, [int salt = 0]) =>
    ((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)).abs();

extension MazeDecorPainting on MazeDecor {
  /// The world the maze sits in, drawn first.
  ///
  /// The ground is one plain colour, the same as the screen, so the maze
  /// sits straight on the page with no card around it. Only a shore that
  /// follows the maze itself is drawn.
  void paintGround(Canvas canvas, Size size, MazeLayout layout, Path floor) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final cell = layout.cell;
    switch (groundKind) {
      case GroundKind.sea:
        // A crisp band of shallow water round the shore.
        canvas.drawPath(
          floor,
          Paint()
            ..color = Color.lerp(ground, Colors.white, .3)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .7
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          floor,
          Paint()
            ..color = Color.lerp(pathDark, Colors.white, .2)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .28
            ..strokeJoin = StrokeJoin.round,
        );
      case GroundKind.lagoon:
        // A clean white beach round the maze.
        canvas.drawPath(
          floor,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .5
            ..strokeJoin = StrokeJoin.round,
        );
      default:
    }
  }

  /// The old textured ground, kept for reference but no longer drawn.
  // ignore: unused_element
  void _texturedGround(
    Canvas canvas,
    Size size,
    MazeLayout layout,
    Path floor,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: .9,
          colors: [ground, groundDark],
        ).createShader(rect),
    );
    final cell = layout.cell;
    final step = cell * .55;
    // Points on a loose grid, the same every time.
    Iterable<(Offset, int)> scatter(double spacing, int salt) sync* {
      for (var gy = 0; gy * spacing < size.height; gy++) {
        for (var gx = 0; gx * spacing < size.width; gx++) {
          final h = _hash(gx, gy, salt);
          yield (
            Offset(
              (gx + (h % 100) / 100) * spacing,
              (gy + (h ~/ 100 % 100) / 100) * spacing,
            ),
            h,
          );
        }
      }
    }

    switch (groundKind) {
      case GroundKind.meadow:
        final tuft = Paint()
          ..color = groundDark
          ..strokeWidth = math.max(1, cell * .05)
          ..strokeCap = StrokeCap.round;
        for (final (p, h) in scatter(step, 3)) {
          if (h % 3 == 0) {
            for (final lean in const [-.35, 0.0, .35]) {
              canvas.drawLine(
                p,
                p + Offset(lean * cell * .2, -cell * .18),
                tuft,
              );
            }
          } else if (h % 11 == 0) {
            canvas.drawCircle(
              p,
              cell * .06,
              Paint()
                ..color = switch (dots) {
                  final dots? => dots[h % dots.length],
                  null =>
                    h.isEven
                        ? const Color(0xFFFFF4C2)
                        : const Color(0xFFFFD0DC),
                },
            );
          }
        }
      case GroundKind.tulipField:
        // Diagonal bands of colour, like bulb fields seen from the air.
        canvas.save();
        canvas.clipRect(rect);
        final band = cell * 1.1;
        final reach = size.width + size.height;
        for (var i = -reach / band; i < reach / band; i++) {
          final colour =
              colours[(i.round() % colours.length + colours.length) %
                  colours.length];
          final x = i * band;
          canvas.drawPath(
            Path()
              ..moveTo(x, 0)
              ..lineTo(x + band * .55, 0)
              ..lineTo(x + band * .55 - size.height, size.height)
              ..lineTo(x - size.height, size.height)
              ..close(),
            Paint()..color = colour.withValues(alpha: .38),
          );
        }
        canvas.restore();
        for (final (p, h) in scatter(cell * .32, 5)) {
          canvas.drawCircle(
            p,
            cell * .045,
            Paint()..color = colours[h % colours.length].withValues(alpha: .9),
          );
        }
      case GroundKind.straw:
        final hay = Paint()
          ..color = groundDark
          ..strokeWidth = math.max(1, cell * .04)
          ..strokeCap = StrokeCap.round;
        for (final (p, h) in scatter(cell * .4, 9)) {
          final angle = (h % 60 - 30) / 60;
          canvas.drawLine(
            p,
            p + Offset(math.cos(angle), math.sin(angle)) * cell * .22,
            hay,
          );
          if (h % 29 == 0) {
            canvas.drawCircle(
              p,
              cell * .08,
              Paint()..color = const Color(0xFFD8402F),
            );
          }
        }
      case GroundKind.sea:
        // A crisp band of shallow water round the shore, then wave lines.
        // (A blurred glow here made the whole board look misty.)
        canvas.drawPath(
          floor,
          Paint()
            ..color = Color.lerp(ground, Colors.white, .3)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .7
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          floor,
          Paint()
            ..color = Color.lerp(pathDark, Colors.white, .2)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .28
            ..strokeJoin = StrokeJoin.round,
        );
        final wave = Paint()
          ..color = Colors.white.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * .05)
          ..strokeCap = StrokeCap.round;
        for (final (p, h) in scatter(cell * .9, 13)) {
          if (h % 2 == 0) continue;
          canvas.drawArc(
            Rect.fromCenter(center: p, width: cell * .5, height: cell * .3),
            math.pi * 1.1,
            math.pi * .8,
            false,
            wave,
          );
        }
      case GroundKind.dunes:
        final ripple = Paint()
          ..color = groundDark.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * .045)
          ..strokeCap = StrokeCap.round;
        for (var y = cell * .3; y < size.height; y += cell * .38) {
          final line = Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += cell * .25) {
            line.lineTo(
              x,
              y + math.sin(x / cell * 1.7 + y / cell) * cell * .12,
            );
          }
          canvas.drawPath(line, ripple);
        }
        for (final (p, h) in scatter(cell * .7, 17)) {
          if (h % 4 != 0) continue;
          canvas.drawOval(
            Rect.fromCenter(center: p, width: cell * .14, height: cell * .09),
            Paint()..color = const Color(0xFF9C5B33).withValues(alpha: .6),
          );
        }
      case GroundKind.cave:
        // A dark cave floor glinting with crystal dust.
        for (final (p, h) in scatter(cell * .45, 23)) {
          canvas.drawCircle(
            p,
            cell * (.02 + (h % 3) * .012),
            Paint()
              ..color = (h.isEven ? colours.first : colours.last).withValues(
                alpha: .35 + (h % 5) * .1,
              ),
          );
        }
      case GroundKind.street:
        // Asphalt with dashed lane lines and the odd drain cover.
        final dash = Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..strokeWidth = math.max(1.5, cell * .07)
          ..strokeCap = StrokeCap.round;
        for (var y = cell * .9; y < size.height; y += cell * 2.4) {
          for (var x = 0.0; x < size.width; x += cell * .9) {
            canvas.drawLine(Offset(x, y), Offset(x + cell * .45, y), dash);
          }
        }
        for (final (p, h) in scatter(cell * 1.6, 29)) {
          if (h % 3 != 0) continue;
          canvas.drawCircle(p, cell * .16, Paint()..color = groundDark);
          canvas.drawCircle(
            p,
            cell * .16,
            Paint()
              ..color = Colors.black.withValues(alpha: .3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      case GroundKind.leafLitter:
        // Fallen leaves in autumn colours.
        for (final (p, h) in scatter(cell * .3, 31)) {
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(h % 7 * .9);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: cell * .2,
              height: cell * .11,
            ),
            Paint()..color = colours[h % colours.length].withValues(alpha: .75),
          );
          canvas.restore();
        }
      case GroundKind.raked:
        // Raked gravel: long parallel lines, rippling round a few stones.
        final rake = Paint()
          ..color = groundDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * .035);
        for (var y = cell * .2; y < size.height; y += cell * .22) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), rake);
        }
        for (final (p, h) in scatter(cell * 2.2, 37)) {
          if (h % 2 == 0) continue;
          for (var r = cell * .3; r < cell * .8; r += cell * .2) {
            canvas.drawCircle(p, r, Paint()..color = ground);
            canvas.drawCircle(p, r, rake);
          }
          canvas.drawOval(
            Rect.fromCenter(center: p, width: cell * .4, height: cell * .28),
            Paint()..color = const Color(0xFF7E847C),
          );
        }
      case GroundKind.snowfield:
        // Bright snow: drifts with a soft blue shadow on their lower side,
        // and a glitter of frost.
        for (final (p, h) in scatter(cell * 1.1, 43)) {
          final w = cell * (.7 + (h % 4) * .18);
          canvas.drawArc(
            Rect.fromCenter(center: p, width: w, height: cell * .34),
            0,
            math.pi,
            false,
            Paint()
              ..color = groundDark
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.5, cell * .07)
              ..strokeCap = StrokeCap.round,
          );
        }
        for (final (p, h) in scatter(cell * .4, 47)) {
          if (h % 3 != 0) continue;
          final r = cell * .05;
          final spark = Paint()
            ..color = const Color(0xFF9CC8E6)
            ..strokeWidth = math.max(1, cell * .025)
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(p - Offset(r, 0), p + Offset(r, 0), spark);
          canvas.drawLine(p - Offset(0, r), p + Offset(0, r), spark);
        }
      case GroundKind.checker:
        // Formal garden tiles in two tones with a thin gold seam.
        final tile = cell * .8;
        final seam = Paint()
          ..color = colours.last.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var y = 0; y * tile < size.height; y++) {
          for (var x = 0; x * tile < size.width; x++) {
            final r = Rect.fromLTWH(x * tile, y * tile, tile, tile);
            if ((x + y).isEven) canvas.drawRect(r, Paint()..color = groundDark);
            canvas.drawRect(r, seam);
          }
        }
      case GroundKind.bricks:
        // A herringbone of terracotta bricks.
        final mortar = Paint()
          ..color = groundDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * .04);
        final w = cell * .5, h = cell * .25;
        for (var y = 0.0; y < size.height; y += h * 2) {
          for (var x = 0.0; x < size.width + w; x += w * 2) {
            canvas.drawRect(Rect.fromLTWH(x, y, w, h), mortar);
            canvas.drawRect(Rect.fromLTWH(x + w, y, h, w), mortar);
            canvas.drawRect(Rect.fromLTWH(x + w * .5, y + h, w, h), mortar);
          }
        }
      case GroundKind.lagoon:
        // Clear turquoise water: bright ripple lines like sunlight on a
        // reef, and a clean white beach round the maze.
        final ripple = Paint()
          ..color = Colors.white.withValues(alpha: .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, cell * .05)
          ..strokeCap = StrokeCap.round;
        for (var y = cell * .4; y < size.height; y += cell * .55) {
          final line = Path()..moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += cell * .2) {
            line.lineTo(
              x,
              y + math.sin(x / cell * 2.4 + y / cell * 1.3) * cell * .14,
            );
          }
          canvas.drawPath(line, ripple);
        }
        canvas.drawPath(
          floor,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .5
            ..strokeJoin = StrokeJoin.round,
        );
        canvas.drawPath(
          floor,
          Paint()
            ..color = const Color(0xFFFFF1CF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .32
            ..strokeJoin = StrokeJoin.round,
        );
    }
  }

  /// The surface of the rooms, shaded where it meets the walls.
  void paintPath(
    Canvas canvas,
    Size size,
    MazeLayout layout,
    Path floor,
    Path walls,
  ) {
    canvas.drawPath(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [path, Color.lerp(path, pathDark, .45)!],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(floor);
    final cell = layout.cell;
    final dark = Paint()..color = pathDark;
    final line = Paint()
      ..color = pathDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cell * .035)
      ..strokeCap = StrokeCap.round;
    for (final room in layout.maze.cells) {
      final r = layout.room(room.x, room.y);
      final h = _hash(room.x, room.y, 7);
      Offset spot(int salt) {
        final k = _hash(room.x, room.y, salt);
        return r.topLeft +
            Offset(
              r.width * (.15 + (k % 70) / 100),
              r.height * (.15 + (k ~/ 70 % 70) / 100),
            );
      }

      switch (pathKind) {
        case PathKind.earth:
          if (h % 4 == 0) {
            canvas.drawOval(
              Rect.fromCenter(
                center: spot(1),
                width: cell * .16,
                height: cell * .1,
              ),
              dark,
            );
          }
          for (var i = 2; i < 4; i++) {
            canvas.drawCircle(
              spot(i),
              cell * .025,
              Paint()..color = pathDark.withValues(alpha: .7),
            );
          }
        case PathKind.cobbles:
          // Four rounded setts per room, each a slightly different shade.
          for (var i = 0; i < 4; i++) {
            final tile = Rect.fromLTWH(
              r.left + (i % 2) * r.width / 2,
              r.top + (i ~/ 2) * r.height / 2,
              r.width / 2,
              r.height / 2,
            ).deflate(cell * .045);
            canvas.drawRRect(
              RRect.fromRectAndRadius(tile, Radius.circular(cell * .1)),
              Paint()
                ..color = Color.lerp(
                  path,
                  pathDark,
                  .08 + (_hash(room.x, room.y, i) % 4) * .05,
                )!,
            );
          }
        case PathKind.tilled:
          // Furrows across each room.
          for (var i = 1; i < 4; i++) {
            final y = r.top + r.height * i / 4;
            canvas.drawLine(
              Offset(r.left + cell * .08, y),
              Offset(r.right - cell * .08, y),
              line,
            );
          }
        case PathKind.sand:
          for (var i = 1; i < 4; i++) {
            canvas.drawCircle(spot(i), cell * .022, Paint()..color = pathDark);
          }
          if (h % 6 == 0) _shell(canvas, spot(5), cell * .11, h);
        case PathKind.clay:
          // A crack or two through the baked clay.
          if (h % 2 == 0) {
            final a = spot(1), b = spot(2);
            final mid =
                Offset.lerp(a, b, .5)! + Offset(cell * .08, -cell * .06);
            canvas.drawPath(
              Path()
                ..moveTo(a.dx, a.dy)
                ..lineTo(mid.dx, mid.dy)
                ..lineTo(b.dx, b.dy)
                ..moveTo(mid.dx, mid.dy)
                ..lineTo(mid.dx + cell * .1, mid.dy + cell * .12),
              line,
            );
          }
        case PathKind.slate:
          // One large flagstone per room with a thin gap round it.
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              r.deflate(cell * .05),
              Radius.circular(cell * .08),
            ),
            Paint()..color = Color.lerp(path, pathDark, (h % 4) * .12)!,
          );
        case PathKind.planks:
          // Boardwalk planks running across each room.
          for (var i = 0; i < 3; i++) {
            final plank = Rect.fromLTWH(
              r.left,
              r.top + r.height * i / 3,
              r.width,
              r.height / 3,
            ).deflate(cell * .02);
            canvas.drawRect(
              plank,
              Paint()
                ..color = Color.lerp(
                  path,
                  pathDark,
                  (_hash(room.x, room.y, i) % 3) * .15,
                )!,
            );
          }
      }
    }
    // Soft shade along every wall so the path looks sunk between them.
    canvas.drawPath(
      walls,
      Paint()
        ..color = shade.withValues(alpha: .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * .55
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .18),
    );
    canvas.restore();
  }

  /// A drop shadow under the walls so they stand up off the ground.
  void paintWallShadow(Canvas canvas, MazeLayout layout, Path walls) {
    final cell = layout.cell;
    canvas.save();
    canvas.translate(cell * .06, cell * .1);
    canvas.drawPath(
      walls,
      Paint()
        ..color = shade.withValues(alpha: .32)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = cell * .36
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * .08),
    );
    canvas.restore();
  }

  /// Props on the empty ground inside the outline.
  void paintProps(Canvas canvas, MazeLayout layout) {
    final maze = layout.maze;
    final paint = Paint();
    final cell = layout.cell;
    for (var y = 0; y < maze.rows; y++) {
      for (var x = 0; x < maze.width; x++) {
        if (maze.inside(Cell(x, y))) continue;
        final h = _hash(x, y, 11);
        if (h % 3 == 2) continue;
        final at =
            layout.centre(x.toDouble(), y.toDouble()) +
            Offset(
              ((h % 40) - 20) / 100 * layout.cellWidth,
              ((h ~/ 40 % 40) - 20) / 100 * layout.cellHeight,
            );
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.scale(cell * .32);
        props(canvas, paint, h);
        canvas.restore();
      }
    }
  }

  // A soft-edged light for the per-frame layer, where a blur would be costly.
  void _softGlow(Canvas canvas, Offset at, double radius, Color colour) {
    if (radius <= 0) return;
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          at,
          radius,
          [colour, colour, colour.withValues(alpha: 0)],
          const [0, .55, 1],
        ),
    );
  }

  /// The moving touches, drawn every frame: a glow at the way out and the
  /// level's own wildlife or weather.
  void paintLife(Canvas canvas, Size size, MazeLayout layout, double time) {
    final maze = layout.maze;
    final cell = layout.cell;
    final exit = layout.centre(maze.exit.x + .7, maze.exit.y.toDouble());
    final pulse = .5 + .5 * math.sin(time * 3);
    _softGlow(
      canvas,
      exit,
      cell * (1.05 + .15 * pulse),
      const Color(0xFFFFF3A6).withValues(alpha: .25 + .2 * pulse),
    );
    switch (lifeKind) {
      case LifeKind.butterflies:
        for (var i = 0; i < colours.length; i++) {
          final speed = .07 + i * .025;
          final phase = i * 2.1;
          final p = Offset(
            size.width * (.5 + .42 * math.sin(time * speed * 2 + phase)),
            size.height *
                (.5 + .44 * math.sin(time * speed * 3.1 + phase * 1.7)),
          );
          final heading = math.cos(time * speed * 2 + phase) >= 0 ? 1.0 : -1.0;
          _butterfly(canvas, p, cell * .2, time * 14 + i, colours[i], heading);
        }
      case LifeKind.petals:
        // Petals blown down and across on a breeze.
        for (var i = 0; i < 12; i++) {
          final t = (time * (.05 + (i % 4) * .012) + i * .083) % 1.0;
          final p = Offset(
            size.width * ((i * .37 + t * .6) % 1.1 - .05),
            size.height * (t * 1.2 - .1) + math.sin(time * 2 + i) * cell * .3,
          );
          canvas.save();
          canvas.translate(p.dx, p.dy);
          canvas.rotate(time * (1 + i % 3) + i);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: cell * .22,
              height: cell * .12,
            ),
            Paint()..color = colours[i % colours.length].withValues(alpha: .9),
          );
          canvas.restore();
        }
      case LifeKind.bees:
        for (var i = 0; i < 4; i++) {
          final speed = .09 + i * .03;
          final phase = i * 1.7;
          final p = Offset(
            size.width * (.5 + .4 * math.sin(time * speed * 2.3 + phase)),
            size.height * (.5 + .42 * math.cos(time * speed * 1.9 + phase)) +
                math.sin(time * 9 + i) * cell * .12,
          );
          _bee(canvas, p, cell * .14, time * 30 + i);
        }
      case LifeKind.gulls:
        // Sunlight glinting on the water, and gulls gliding over.
        for (var i = 0; i < 14; i++) {
          final h = _hash(i, 3, 21);
          final glint = math.sin(time * 2 + i * 1.3);
          if (glint < .6) continue;
          final p = Offset(
            size.width * (h % 100) / 100,
            size.height * (h ~/ 100 % 100) / 100,
          );
          canvas.drawCircle(
            p,
            cell * .06 * (glint - .5) * 2,
            Paint()..color = Colors.white.withValues(alpha: .8),
          );
        }
        for (var i = 0; i < 2; i++) {
          final t = (time * (.035 + i * .015) + i * .5) % 1.0;
          final p = Offset(
            size.width * (t * 1.3 - .15),
            size.height * (.2 + i * .45) + math.sin(time * .8 + i) * cell * .8,
          );
          _gull(
            canvas,
            p,
            cell * .3,
            time * 5 + i,
            colours.first,
            Color.lerp(groundDark, Colors.black, .3)!,
          );
        }
      case LifeKind.tumbleweeds:
        for (var i = 0; i < 2; i++) {
          final t = (time * (.06 + i * .02) + i * .55) % 1.0;
          final bounce = (math.sin(t * math.pi * 10)).abs();
          final r = cell * (.22 + i * .05);
          final p = Offset(
            size.width * (t * 1.3 - .15),
            size.height * (.3 + i * .38) - bounce * cell * .3,
          );
          _tumbleweed(canvas, p, r, t * math.pi * 14, colours.first);
        }
      case LifeKind.sparkles:
        // Fireflies or crystal glints winking on and off as they drift.
        for (var i = 0; i < 14; i++) {
          final h = _hash(i, 9, 41);
          final glow = math.sin(time * (1.2 + (i % 3) * .4) + i * 1.7);
          if (glow < .1) continue;
          final p = Offset(
            size.width * ((h % 100) / 100 + math.sin(time * .2 + i) * .04),
            size.height *
                ((h ~/ 100 % 100) / 100 + math.cos(time * .17 + i) * .04),
          );
          final colour = colours[i % colours.length];
          _softGlow(
            canvas,
            p,
            cell * .22 * glow + cell * .1,
            colour.withValues(alpha: .25 * glow),
          );
          canvas.drawCircle(
            p,
            cell * .06,
            Paint()..color = colour.withValues(alpha: .9 * glow),
          );
        }
      case LifeKind.snow:
        // Snowflakes drifting down on a light breeze.
        for (var i = 0; i < 26; i++) {
          final h = _hash(i, 4, 51);
          final t = (time * (.04 + (h % 4) * .012) + (h % 100) / 100) % 1.0;
          final p = Offset(
            size.width * ((h ~/ 100 % 100) / 100) +
                math.sin(time * .8 + i) * cell * .4,
            size.height * (t * 1.1 - .05),
          );
          final r = cell * (.04 + (h % 3) * .02);
          canvas.drawCircle(
            p,
            r + 1,
            Paint()..color = const Color(0xFF7FA6C4).withValues(alpha: .5),
          );
          canvas.drawCircle(p, r, Paint()..color = Colors.white);
        }
      case LifeKind.bubbles:
        // Bubbles rising and wobbling through the water.
        for (var i = 0; i < 12; i++) {
          final h = _hash(i, 6, 53);
          final t = (time * (.05 + (h % 3) * .02) + (h % 100) / 100) % 1.0;
          final p = Offset(
            size.width * ((h ~/ 100 % 100) / 100) +
                math.sin(time * 2 + i) * cell * .15,
            size.height * (1.05 - t * 1.1),
          );
          final r = cell * (.06 + (h % 3) * .03);
          canvas.drawCircle(
            p,
            r,
            Paint()
              ..color = Colors.white.withValues(alpha: .7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1, r * .25),
          );
          canvas.drawCircle(
            p - Offset(r * .35, r * .35),
            r * .25,
            Paint()..color = Colors.white.withValues(alpha: .8),
          );
        }
    }
  }
}

void _butterfly(
  Canvas canvas,
  Offset at,
  double size,
  double flap,
  Color colour,
  double heading,
) {
  final open = .35 + .65 * (math.sin(flap).abs());
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.scale(size * heading, size);
  final wing = Paint()..color = colour.withValues(alpha: .9);
  for (final side in const [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side * open, 1);
    canvas.drawOval(const Rect.fromLTWH(.05, -1, 1.1, 1.05), wing);
    canvas.drawOval(
      const Rect.fromLTWH(.05, 0, .8, .8),
      wing..color = colour.withValues(alpha: .75),
    );
    canvas.restore();
    wing.color = colour.withValues(alpha: .9);
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-.1, -.8, .2, 1.5),
      const Radius.circular(.1),
    ),
    Paint()..color = const Color(0xFF3C2E24),
  );
  canvas.restore();
}

void _bee(Canvas canvas, Offset at, double size, double buzz) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.scale(size);
  final wing = Paint()
    ..color = Colors.white.withValues(alpha: .55 + .3 * math.sin(buzz).abs());
  canvas.drawOval(const Rect.fromLTWH(-.75, -1.3, .8, .9), wing);
  canvas.drawOval(const Rect.fromLTWH(-.05, -1.3, .8, .9), wing);
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(-.9, -.55, 1.8, 1.1),
    const Radius.circular(.55),
  );
  canvas.drawRRect(body, Paint()..color = const Color(0xFFFFC928));
  canvas.save();
  canvas.clipRRect(body);
  for (final x in const [-.3, .3]) {
    canvas.drawRect(
      Rect.fromLTWH(x - .13, -.6, .26, 1.2),
      Paint()..color = const Color(0xFF2E2416),
    );
  }
  canvas.restore();
  canvas.restore();
}

void _gull(
  Canvas canvas,
  Offset at,
  double size,
  double flap,
  Color colour,
  Color shadow,
) {
  final lift = math.sin(flap) * .35;
  final wing = Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * .16
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  // A soft shadow on the water below.
  canvas.drawOval(
    Rect.fromCenter(
      center: at + Offset(size * .3, size * 1.6),
      width: size * 1.4,
      height: size * .35,
    ),
    Paint()..color = shadow.withValues(alpha: .25),
  );
  canvas.drawPath(
    Path()
      ..moveTo(at.dx - size, at.dy - size * lift)
      ..quadraticBezierTo(
        at.dx - size * .45,
        at.dy - size * (.55 + lift * .3),
        at.dx,
        at.dy,
      )
      ..quadraticBezierTo(
        at.dx + size * .45,
        at.dy - size * (.55 + lift * .3),
        at.dx + size,
        at.dy - size * lift,
      ),
    wing,
  );
}

void _tumbleweed(
  Canvas canvas,
  Offset at,
  double radius,
  double spin,
  Color colour,
) {
  canvas.drawOval(
    Rect.fromCenter(
      center: at + Offset(0, radius * 1.3),
      width: radius * 1.6,
      height: radius * .4,
    ),
    Paint()..color = const Color(0xFF7A3E17).withValues(alpha: .22),
  );
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(spin);
  final twig = Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, radius * .12)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(math.cos(a), math.sin(a)) * radius * .25,
        radius: radius * .75,
      ),
      a,
      math.pi * 1.1,
      false,
      twig,
    );
  }
  canvas.restore();
}

void _shell(Canvas canvas, Offset at, double size, int seed) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(seed % 6 * .5);
  canvas.scale(size);
  if (seed.isEven) {
    // A scallop.
    canvas.drawPath(
      Path()
        ..moveTo(0, .7)
        ..lineTo(-.9, -.2)
        ..quadraticBezierTo(0, -1.2, .9, -.2)
        ..close(),
      Paint()..color = const Color(0xFFF7B9A6),
    );
  } else {
    // A starfish.
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 1.0 : .42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFF28C4B));
  }
  canvas.restore();
}

// Every prop rests on a soft shadow.
void _propShadow(Canvas canvas, Paint paint, Color colour) => canvas.drawOval(
  const Rect.fromLTWH(-.9, .55, 1.8, .55),
  paint..color = colour.withValues(alpha: .28),
);

// A pine, a round oak or a cluster of toadstools, in unit space.
void _forestProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2E5226));
  switch (seed % 4) {
    case 0:
      // Toadstools.
      for (final (dx, s) in const [(-.35, .8), (.4, .6)]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dx - .12 * s, .1, .24 * s, .6 * s),
            const Radius.circular(.08),
          ),
          paint..color = const Color(0xFFF7EBD8),
        );
        canvas.drawPath(
          Path()
            ..moveTo(dx - .55 * s, .15)
            ..quadraticBezierTo(dx, -.75 * s, dx + .55 * s, .15)
            ..close(),
          paint..color = const Color(0xFFE2463F),
        );
        for (final (sx, sy) in const [(-.22, -.05), (.18, -.2), (.05, .05)]) {
          canvas.drawCircle(
            Offset(dx + sx * s, sy * s),
            .07 * s,
            paint..color = Colors.white,
          );
        }
      }
    case 1:
      // A round oak.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.13, .1, .26, .7),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFF8A6440),
      );
      canvas.drawCircle(
        const Offset(0, -.25),
        .78,
        paint..color = const Color(0xFF3F7A45),
      );
      canvas.drawCircle(
        const Offset(-.18, -.42),
        .52,
        paint..color = const Color(0xFF63A35A),
      );
      canvas.drawCircle(
        const Offset(-.3, -.6),
        .18,
        paint..color = const Color(0xFFA9D48A),
      );
    default:
      // A tall pine in three tiers.
      canvas.drawRect(
        const Rect.fromLTWH(-.1, .45, .2, .4),
        paint..color = const Color(0xFF7A5634),
      );
      for (final (top, half, colour) in const [
        (-.2, .8, Color(0xFF2F6B4A)),
        (-.65, .62, Color(0xFF3C8158)),
        (-1.05, .44, Color(0xFF55A06C)),
      ]) {
        canvas.drawPath(
          Path()
            ..moveTo(0, top - .45)
            ..lineTo(half, top + .62)
            ..lineTo(-half, top + .62)
            ..close(),
          paint..color = colour,
        );
      }
  }
}

// A little windmill or a bunch of tulips.
void _tulipProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF4F6B2C));
  if (seed % 3 == 0) {
    // Windmill: a tapered tower, a cap and four sails.
    canvas.drawPath(
      Path()
        ..moveTo(-.42, .85)
        ..lineTo(-.28, -.35)
        ..lineTo(.28, -.35)
        ..lineTo(.42, .85)
        ..close(),
      paint..color = const Color(0xFFB0563F),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-.12, .45, .24, .4),
      paint..color = const Color(0xFF5A2E22),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-.38, -.33)
        ..lineTo(0, -.7)
        ..lineTo(.38, -.33)
        ..close(),
      paint..color = const Color(0xFF3E4B5A),
    );
    final sail = Paint()..color = const Color(0xFFF7F1E6);
    canvas.save();
    canvas.translate(0, -.45);
    canvas.rotate(seed % 7 * .3);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(const Rect.fromLTWH(-.09, -1.05, .18, .95), sail);
      canvas.rotate(math.pi / 2);
    }
    canvas.drawCircle(Offset.zero, .1, paint..color = const Color(0xFF3E4B5A));
    canvas.restore();
    return;
  }
  const colours = [Color(0xFFF05A6E), Color(0xFFFFC94A), Color(0xFFFF9EC4)];
  for (final (dx, dy) in const [(-.45, .1), (0.0, -.15), (.45, .1)]) {
    canvas.drawLine(
      Offset(dx, dy),
      Offset(dx * .5, .7),
      Paint()
        ..color = const Color(0xFF4E8A3A)
        ..strokeWidth = .12,
    );
    canvas.drawPath(
      Path()
        ..moveTo(dx - .24, dy - .3)
        ..lineTo(dx - .12, dy - .12)
        ..lineTo(dx, dy - .32)
        ..lineTo(dx + .12, dy - .12)
        ..lineTo(dx + .24, dy - .3)
        ..quadraticBezierTo(dx + .28, dy + .12, dx, dy + .12)
        ..quadraticBezierTo(dx - .28, dy + .12, dx - .24, dy - .3)
        ..close(),
      paint..color = colours[(seed + (dx * 10).round()).abs() % 3],
    );
  }
}

// An apple tree, a crate of apples or a hay bale.
void _orchardProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF6E4E1C));
  switch (seed % 3) {
    case 0:
      // Crate of apples.
      canvas.drawRect(
        const Rect.fromLTWH(-.75, -.15, 1.5, .9),
        paint..color = const Color(0xFFB07A44),
      );
      for (final y in const [.1, .45]) {
        canvas.drawRect(
          Rect.fromLTWH(-.75, y, 1.5, .08),
          paint..color = const Color(0xFF8A5A2E),
        );
      }
      for (final x in const [-.45, 0.0, .45]) {
        canvas.drawCircle(
          Offset(x, -.22),
          .26,
          paint..color = const Color(0xFFD8402F),
        );
        canvas.drawCircle(
          Offset(x - .08, -.3),
          .07,
          paint..color = Colors.white.withValues(alpha: .6),
        );
      }
    case 1:
      // A round hay bale.
      canvas.drawCircle(
        const Offset(0, .05),
        .72,
        paint..color = const Color(0xFFE8C45C),
      );
      final roll = Paint()
        ..color = const Color(0xFFC79A34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .08;
      for (final r in const [.22, .42, .6]) {
        canvas.drawCircle(const Offset(0, .05), r, roll);
      }
    default:
      // Apple tree.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.12, .1, .24, .7),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFF7E5530),
      );
      canvas.drawCircle(
        const Offset(0, -.25),
        .8,
        paint..color = const Color(0xFF4F8A3A),
      );
      canvas.drawCircle(
        const Offset(-.2, -.4),
        .5,
        paint..color = const Color(0xFF6FAE4E),
      );
      for (final (x, y) in const [
        (-.4, -.1),
        (.35, -.45),
        (.2, .1),
        (-.1, -.7),
      ]) {
        canvas.drawCircle(
          Offset(x, y),
          .13,
          paint..color = const Color(0xFFD8402F),
        );
      }
  }
}

// A rock with foam, a swim ring or a little sailboat, out in the water.
void _beachProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      canvas.drawOval(
        const Rect.fromLTWH(-.95, -.35, 1.9, 1.1),
        paint..color = Colors.white.withValues(alpha: .55),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.7, -.4, 1.4, .95),
        paint..color = const Color(0xFF8C8F8A),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.5, -.38, .7, .4),
        paint..color = const Color(0xFFB4B6AF),
      );
    case 1:
      // A striped swim ring.
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .32;
      for (var i = 0; i < 8; i++) {
        canvas.drawArc(
          const Rect.fromLTWH(-.55, -.55, 1.1, 1.1),
          i * math.pi / 4,
          math.pi / 4,
          false,
          ring..color = i.isEven ? const Color(0xFFE94B4B) : Colors.white,
        );
      }
    default:
      // Sailboat.
      canvas.drawPath(
        Path()
          ..moveTo(-.8, .25)
          ..lineTo(.8, .25)
          ..lineTo(.5, .6)
          ..lineTo(-.5, .6)
          ..close(),
        paint..color = const Color(0xFF8A5A33),
      );
      canvas.drawPath(
        Path()
          ..moveTo(.05, -.95)
          ..lineTo(.6, .15)
          ..lineTo(.05, .15)
          ..close(),
        paint..color = Colors.white,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-.05, -.6)
          ..lineTo(-.5, .15)
          ..lineTo(-.05, .15)
          ..close(),
        paint..color = const Color(0xFFFFB347),
      );
  }
}

// A boulder, a barrel cactus in flower or a spiky agave.
void _desertProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF7A3E17));
  switch (seed % 3) {
    case 0:
      canvas.drawPath(
        Path()
          ..moveTo(-.85, .7)
          ..quadraticBezierTo(-.9, -.3, -.2, -.45)
          ..quadraticBezierTo(.7, -.6, .85, .7)
          ..close(),
        paint..color = const Color(0xFFB0683C),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.5, -.35, .6, .3),
        paint..color = const Color(0xFFD08A58),
      );
    case 1:
      // Barrel cactus with a pink flower.
      canvas.drawOval(
        const Rect.fromLTWH(-.55, -.45, 1.1, 1.2),
        paint..color = const Color(0xFF4F9A5E),
      );
      final rib = Paint()
        ..color = const Color(0xFF357A45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .06;
      for (final x in const [-.25, 0.0, .25]) {
        canvas.drawLine(Offset(x, -.38), Offset(x, .68), rib);
      }
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5;
        canvas.drawCircle(
          Offset(math.cos(a) * .14, -.45 + math.sin(a) * .14),
          .12,
          paint..color = const Color(0xFFFF7FA8),
        );
      }
      canvas.drawCircle(
        const Offset(0, -.45),
        .07,
        paint..color = const Color(0xFFFFD84A),
      );
    default:
      // Agave: a fan of pointed leaves.
      for (var i = -2; i <= 2; i++) {
        canvas.save();
        canvas.translate(0, .6);
        canvas.rotate(i * .45);
        canvas.drawPath(
          Path()
            ..moveTo(-.16, 0)
            ..quadraticBezierTo(-.1, -.8, 0, -1.25)
            ..quadraticBezierTo(.1, -.8, .16, 0)
            ..close(),
          paint
            ..color = i.isEven
                ? const Color(0xFF6E9E7A)
                : const Color(0xFF86B592),
        );
        canvas.restore();
      }
  }
}

// Shared shapes for the props below, all in unit space.

void _roundTree(Canvas canvas, Paint paint, Color dark, Color light) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-.13, .1, .26, .7),
      const Radius.circular(.08),
    ),
    paint..color = const Color(0xFF7A5634),
  );
  canvas.drawCircle(const Offset(0, -.25), .8, paint..color = dark);
  canvas.drawCircle(const Offset(-.2, -.42), .52, paint..color = light);
  canvas.drawCircle(
    const Offset(-.32, -.6),
    .16,
    paint..color = Colors.white.withValues(alpha: .35),
  );
}

void _rock(Canvas canvas, Paint paint, Color colour, {bool moss = false}) {
  canvas.drawPath(
    Path()
      ..moveTo(-.85, .6)
      ..quadraticBezierTo(-.95, -.25, -.2, -.42)
      ..quadraticBezierTo(.75, -.55, .85, .6)
      ..close(),
    paint..color = colour,
  );
  canvas.drawOval(
    const Rect.fromLTWH(-.5, -.32, .6, .26),
    paint..color = Color.lerp(colour, Colors.white, .3)!,
  );
  if (moss) {
    canvas.drawOval(
      const Rect.fromLTWH(-.1, -.5, .7, .3),
      paint..color = const Color(0xFF6E9E48),
    );
  }
}

void _stoneLantern(Canvas canvas, Paint paint, {bool lit = false}) {
  const stone = Color(0xFF9EA39B);
  canvas.drawRect(const Rect.fromLTWH(-.15, 0, .3, .75), paint..color = stone);
  canvas.drawRect(
    const Rect.fromLTWH(-.4, .7, .8, .15),
    paint..color = const Color(0xFF7E847C),
  );
  canvas.drawRect(
    const Rect.fromLTWH(-.32, -.45, .64, .45),
    paint..color = stone,
  );
  canvas.drawRect(
    const Rect.fromLTWH(-.18, -.35, .36, .25),
    paint..color = lit ? const Color(0xFFFFE08A) : const Color(0xFF5E645C),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.6, -.45)
      ..lineTo(0, -.85)
      ..lineTo(.6, -.45)
      ..close(),
    paint..color = const Color(0xFF7E847C),
  );
}

void _flowerClump(Canvas canvas, Paint paint, List<Color> colours, int seed) {
  canvas.drawOval(
    const Rect.fromLTWH(-.8, -.1, 1.6, .8),
    paint..color = const Color(0xFF4E8A3A),
  );
  for (final (i, (x, y)) in const [
    (-.45, -.05),
    (0.0, -.3),
    (.45, -.05),
    (-.2, .3),
    (.25, .3),
  ].indexed) {
    final colour = colours[(seed + i) % colours.length];
    for (var k = 0; k < 5; k++) {
      final a = k * math.pi * 2 / 5;
      canvas.drawCircle(
        Offset(x + math.cos(a) * .12, y + math.sin(a) * .12),
        .11,
        paint..color = colour,
      );
    }
    canvas.drawCircle(
      Offset(x, y),
      .07,
      paint..color = const Color(0xFFFFE07A),
    );
  }
}

void _bench(Canvas canvas, Paint paint, Color wood) {
  canvas.drawRect(
    const Rect.fromLTWH(-.75, -.2, 1.5, .25),
    paint..color = wood,
  );
  canvas.drawRect(
    const Rect.fromLTWH(-.75, -.55, 1.5, .18),
    paint..color = Color.lerp(wood, Colors.black, .15)!,
  );
  for (final x in const [-.65, .55]) {
    canvas.drawRect(
      Rect.fromLTWH(x, .05, .1, .45),
      paint..color = const Color(0xFF3C3F46),
    );
  }
}

void _beehive(Canvas canvas, Paint paint) {
  for (var i = 0; i < 3; i++) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, .45 - i * .35),
          width: 1.3 - i * .3,
          height: .38,
        ),
        const Radius.circular(.18),
      ),
      paint
        ..color = i.isEven ? const Color(0xFFE6B34A) : const Color(0xFFD49A2E),
    );
  }
  canvas.drawCircle(
    const Offset(0, .5),
    .1,
    paint..color = const Color(0xFF3D2410),
  );
}

// Level 6: cherry trees, stone lanterns and benches.
void _blossomProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF4A5A2A));
  switch (seed % 3) {
    case 0:
      _stoneLantern(canvas, paint);
    case 1:
      _bench(canvas, paint, const Color(0xFFB07A55));
    default:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.12, .05, .24, .75),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFF6B4436),
      );
      for (final (x, y, r) in const [
        (-.45, -.2, .5),
        (.4, -.25, .5),
        (0.0, -.55, .55),
        (0.0, -.05, .5),
      ]) {
        canvas.drawCircle(
          Offset(x, y),
          r,
          paint..color = const Color(0xFFF59BB8),
        );
      }
      canvas.drawCircle(
        const Offset(-.25, -.5),
        .25,
        paint..color = const Color(0xFFFBD3E0),
      );
  }
}

// Level 7: crystal clusters and glowing cave mushrooms.
void _crystalProp(Canvas canvas, Paint paint, int seed) {
  canvas.drawCircle(
    Offset.zero,
    1.1,
    paint
      ..color =
          (seed.isEven ? const Color(0xFF8FE3F0) : const Color(0xFFB79CF2))
              .withValues(alpha: .18),
  );
  if (seed % 3 == 0) {
    for (final (x, h) in const [(-.35, .55), (0.0, .75), (.35, .5)]) {
      canvas.drawRect(
        Rect.fromLTWH(x - .05, .1, .1, .5),
        paint..color = const Color(0xFFE8E0FF),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .1 - h * .3), width: .5, height: .3),
        paint..color = const Color(0xFF8FE3F0),
      );
    }
    return;
  }
  for (final (x, h, turn) in const [
    (-.35, .9, -.35),
    (0.0, 1.25, 0.0),
    (.35, .8, .35),
  ]) {
    canvas.save();
    canvas.translate(x, .6);
    canvas.rotate(turn);
    final gem = Path()
      ..moveTo(-.18, 0)
      ..lineTo(-.18, -h + .25)
      ..lineTo(0, -h)
      ..lineTo(.18, -h + .25)
      ..lineTo(.18, 0)
      ..close();
    canvas.drawPath(
      gem,
      paint
        ..color = seed.isEven
            ? const Color(0xFFB79CF2)
            : const Color(0xFF8FE3F0),
    );
    canvas.drawLine(
      Offset(0, -h),
      Offset.zero,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..strokeWidth = .06,
    );
    canvas.restore();
  }
}

// Level 8: round bushes, mossy rocks and clover patches.
void _lawnProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF1E3A1A));
  switch (seed % 3) {
    case 0:
      _rock(canvas, paint, const Color(0xFF9A9E96), moss: true);
    case 1:
      _roundTree(
        canvas,
        paint,
        const Color(0xFF3D7A3A),
        const Color(0xFF66A84F),
      );
    default:
      for (final (x, y) in const [(-.4, .1), (.35, -.1), (0.0, .35)]) {
        for (var i = 0; i < 3; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 3;
          canvas.drawCircle(
            Offset(x + math.cos(a) * .15, y + math.sin(a) * .15),
            .15,
            paint..color = const Color(0xFF3F8A3A),
          );
        }
      }
  }
}

// Level 9: street lamps, benches and potted trees.
void _cityProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      canvas.drawCircle(
        const Offset(0, -.7),
        .55,
        paint..color = const Color(0xFFFFE08A).withValues(alpha: .35),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.06, -.6, .12, 1.4),
        paint..color = const Color(0xFF2F3742),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.22, -.95, .44, .4),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFFF3B53A),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.28, -1.02, .56, .1),
        paint..color = const Color(0xFF2F3742),
      );
    case 1:
      _bench(canvas, paint, const Color(0xFF8A5A3A));
    default:
      canvas.drawRect(
        const Rect.fromLTWH(-.45, .15, .9, .6),
        paint..color = const Color(0xFF9EA39B),
      );
      _roundTree(
        canvas,
        paint,
        const Color(0xFF3F7A45),
        const Color(0xFF63A35A),
      );
  }
}

// Level 10: red and orange trees, pumpkins and leaf piles.
void _autumnProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF3A1E0C));
  switch (seed % 3) {
    case 0:
      // A pumpkin.
      for (final (x, w) in const [(-.35, .6), (.35, .6), (0.0, .7)]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, .2), width: w, height: .85),
          paint..color = const Color(0xFFE8822F),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-.06, -.4, .12, .25),
        paint..color = const Color(0xFF4E6B22),
      );
    case 1:
      _roundTree(
        canvas,
        paint,
        const Color(0xFFB8452A),
        const Color(0xFFE0782F),
      );
    default:
      _roundTree(
        canvas,
        paint,
        const Color(0xFFC98A1E),
        const Color(0xFFF2B33D),
      );
  }
}

// Level 11: daisy beds, beehives and watering cans.
void _daisyProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2E4A1E));
  switch (seed % 3) {
    case 0:
      _beehive(canvas, paint);
    case 1:
      // Watering can.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.5, -.2, .8, .8),
          const Radius.circular(.12),
        ),
        paint..color = const Color(0xFF6FA8D9),
      );
      canvas.drawLine(
        const Offset(.3, .1),
        const Offset(.85, -.35),
        Paint()
          ..color = const Color(0xFF6FA8D9)
          ..strokeWidth = .14
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        const Rect.fromLTWH(-.4, -.55, .6, .6),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF4E86B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .1,
      );
    default:
      _flowerClump(canvas, paint, const [Colors.white], seed);
  }
}

// Level 12: sheep, haystacks and rocks.
void _meadowProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2E4A1E));
  switch (seed % 3) {
    case 0:
      // A woolly sheep.
      for (final (x, y) in const [
        (-.35, 0.0),
        (0.0, -.2),
        (.35, 0.0),
        (-.15, .25),
        (.2, .25),
      ]) {
        canvas.drawCircle(Offset(x, y), .32, paint..color = Colors.white);
      }
      canvas.drawOval(
        const Rect.fromLTWH(.45, -.3, .4, .5),
        paint..color = const Color(0xFF34383F),
      );
      canvas.drawCircle(
        const Offset(.62, -.12),
        .05,
        paint..color = Colors.white,
      );
      for (final x in const [-.3, .2]) {
        canvas.drawRect(
          Rect.fromLTWH(x, .45, .1, .25),
          paint..color = const Color(0xFF34383F),
        );
      }
    case 1:
      canvas.drawPath(
        Path()
          ..moveTo(-.85, .7)
          ..quadraticBezierTo(-.8, -.7, 0, -.75)
          ..quadraticBezierTo(.8, -.7, .85, .7)
          ..close(),
        paint..color = const Color(0xFFE8C45C),
      );
      for (final y in const [-.3, .1, .45]) {
        canvas.drawLine(
          Offset(-.6, y),
          Offset(.6, y),
          Paint()
            ..color = const Color(0xFFC79A34)
            ..strokeWidth = .06,
        );
      }
    default:
      _rock(canvas, paint, const Color(0xFFA8ABA2));
  }
}

// Level 13: rose bushes, a fountain and stone urns.
void _roseProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2A1A1A));
  switch (seed % 3) {
    case 0:
      // A round fountain.
      canvas.drawCircle(
        Offset.zero,
        .85,
        paint..color = const Color(0xFFD9D2C4),
      );
      canvas.drawCircle(
        Offset.zero,
        .68,
        paint..color = const Color(0xFF6FC3DF),
      );
      canvas.drawCircle(
        Offset.zero,
        .2,
        paint..color = const Color(0xFFD9D2C4),
      );
      canvas.drawCircle(
        const Offset(0, -.15),
        .12,
        paint..color = Colors.white.withValues(alpha: .8),
      );
    case 1:
      canvas.drawPath(
        Path()
          ..moveTo(-.4, .7)
          ..lineTo(-.55, -.1)
          ..lineTo(.55, -.1)
          ..lineTo(.4, .7)
          ..close(),
        paint..color = const Color(0xFFD9D2C4),
      );
      _flowerClump(canvas, paint, const [
        Color(0xFFD23B55),
        Color(0xFFF07A8C),
      ], seed);
    default:
      canvas.drawCircle(
        const Offset(0, -.1),
        .78,
        paint..color = const Color(0xFF3F7A3A),
      );
      for (final (x, y) in const [
        (-.4, -.3),
        (.3, -.45),
        (.1, .15),
        (-.25, .3),
      ]) {
        canvas.drawCircle(
          Offset(x, y),
          .2,
          paint..color = const Color(0xFFD23B55),
        );
      }
  }
}

// Level 14: bamboo clumps and lit stone lanterns.
void _bambooProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2A3A1A));
  if (seed % 3 == 0) {
    _stoneLantern(canvas, paint, lit: true);
    return;
  }
  for (final (x, h) in const [(-.4, 1.5), (0.0, 1.9), (.4, 1.3)]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - .1, .75 - h, .2, h),
        const Radius.circular(.08),
      ),
      paint..color = const Color(0xFF7DB84F),
    );
    for (var y = .75 - h + .35; y < .75; y += .45) {
      canvas.drawLine(
        Offset(x - .1, y),
        Offset(x + .1, y),
        Paint()
          ..color = const Color(0xFF4E8A33)
          ..strokeWidth = .05,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(x, .75 - h + .2)
        ..quadraticBezierTo(x + .3, .75 - h, x + .55, .75 - h + .15)
        ..quadraticBezierTo(x + .3, .75 - h + .25, x, .75 - h + .2),
      paint..color = const Color(0xFF5E9E40),
    );
  }
}

// Level 15: flower pots, birdbaths and mixed beds.
void _gardenProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2A3A1A));
  switch (seed % 3) {
    case 0:
      // A birdbath.
      canvas.drawRect(
        const Rect.fromLTWH(-.12, -.1, .24, .8),
        paint..color = const Color(0xFFD9D2C4),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.75, -.45, 1.5, .45),
        paint..color = const Color(0xFFD9D2C4),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.6, -.38, 1.2, .3),
        paint..color = const Color(0xFF8FD0EA),
      );
    case 1:
      canvas.drawPath(
        Path()
          ..moveTo(-.45, .75)
          ..lineTo(-.6, 0)
          ..lineTo(.6, 0)
          ..lineTo(.45, .75)
          ..close(),
        paint..color = const Color(0xFFC9744A),
      );
      _flowerClump(canvas, paint, const [
        Color(0xFFEE6FA0),
        Color(0xFF7DA7F0),
        Color(0xFFFFB347),
      ], seed);
    default:
      _flowerClump(canvas, paint, const [
        Color(0xFFB98AE6),
        Color(0xFFFFE07A),
        Color(0xFFEE6FA0),
      ], seed);
  }
}

// Level 16: lavender bushes, beehives and a bench.
void _lavenderProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF3A2A4A));
  switch (seed % 3) {
    case 0:
      _beehive(canvas, paint);
    case 1:
      _bench(canvas, paint, const Color(0xFFC9A77A));
    default:
      canvas.drawOval(
        const Rect.fromLTWH(-.85, .05, 1.7, .7),
        paint..color = const Color(0xFF6E8F5A),
      );
      for (var i = 0; i < 7; i++) {
        final x = -.6 + i * .2;
        for (var k = 0; k < 4; k++) {
          canvas.drawCircle(
            Offset(x, .1 - k * .2 - (i % 2) * .1),
            .09,
            paint..color = const Color(0xFF8E6BC9),
          );
        }
      }
  }
}

// Level 17: giant toadstools in red, blue and gold.
void _mushroomProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  const caps = [Color(0xFFE2463F), Color(0xFF5E8FD9), Color(0xFFE8A93A)];
  final cap = caps[seed % 3];
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-.2, -.1, .4, .85),
      const Radius.circular(.12),
    ),
    paint..color = const Color(0xFFF7EBD8),
  );
  canvas.drawPath(
    Path()
      ..moveTo(-.95, 0)
      ..quadraticBezierTo(0, -1.4, .95, 0)
      ..close(),
    paint..color = cap,
  );
  for (final (x, y) in const [(-.45, -.2), (.1, -.5), (.5, -.15)]) {
    canvas.drawCircle(Offset(x, y), .1, paint..color = Colors.white);
  }
  // A small glowing door in the stem of every third one.
  if (seed % 3 == 1) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.09, .35, .18, .3),
        const Radius.circular(.09),
      ),
      paint..color = const Color(0xFFFFE08A),
    );
  }
}

// Level 18: tall sunflowers, crates and a scarecrow.
void _sunflowerProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF3D2410));
  switch (seed % 3) {
    case 0:
      // A scarecrow.
      canvas.drawRect(
        const Rect.fromLTWH(-.05, -.5, .1, 1.3),
        paint..color = const Color(0xFF7A5634),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.7, -.25, 1.4, .1),
        paint..color = const Color(0xFF7A5634),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.35, -.3, .7, .6),
          const Radius.circular(.1),
        ),
        paint..color = const Color(0xFF5E8FD9),
      );
      canvas.drawCircle(
        const Offset(0, -.55),
        .22,
        paint..color = const Color(0xFFF2D7A6),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-.4, -.68)
          ..lineTo(0, -1.0)
          ..lineTo(.4, -.68)
          ..close(),
        paint..color = const Color(0xFFC9A24E),
      );
    case 1:
      canvas.drawRect(
        const Rect.fromLTWH(-.7, -.1, 1.4, .85),
        paint..color = const Color(0xFFB07A44),
      );
      for (final x in const [-.4, 0.0, .4]) {
        canvas.drawCircle(
          Offset(x, -.15),
          .22,
          paint..color = const Color(0xFFF5B91E),
        );
        canvas.drawCircle(
          Offset(x, -.15),
          .1,
          paint..color = const Color(0xFF6B3F1E),
        );
      }
    default:
      for (final (x, h) in const [(-.35, 1.1), (.35, 1.4)]) {
        canvas.drawLine(
          Offset(x, .75),
          Offset(x, .75 - h),
          Paint()
            ..color = const Color(0xFF4E8A33)
            ..strokeWidth = .1,
        );
        for (var k = 0; k < 12; k++) {
          final a = k * math.pi / 6;
          canvas.drawCircle(
            Offset(x + math.cos(a) * .25, .75 - h + math.sin(a) * .25),
            .12,
            paint..color = const Color(0xFFF5B91E),
          );
        }
        canvas.drawCircle(
          Offset(x, .75 - h),
          .18,
          paint..color = const Color(0xFF6B3F1E),
        );
      }
  }
}

// Level 19: lily pads, lotus flowers and a frog on a pad.
void _lotusProp(Canvas canvas, Paint paint, int seed) {
  final pad = Path()
    ..addArc(const Rect.fromLTWH(-.85, -.6, 1.7, 1.2), .25, math.pi * 2 - .5)
    ..lineTo(0, 0)
    ..close();
  canvas.drawPath(pad, paint..color = const Color(0xFF4F9A5A));
  canvas.drawPath(
    pad,
    Paint()
      ..color = const Color(0xFF3E7E48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .05,
  );
  switch (seed % 3) {
    case 0:
      // A frog.
      canvas.drawOval(
        const Rect.fromLTWH(-.4, -.35, .8, .6),
        paint..color = const Color(0xFF7CC24F),
      );
      for (final x in const [-.2, .2]) {
        canvas.drawCircle(
          Offset(x, -.35),
          .13,
          paint..color = const Color(0xFF7CC24F),
        );
        canvas.drawCircle(
          Offset(x, -.37),
          .06,
          paint..color = const Color(0xFF223018),
        );
      }
    case 1:
      for (final a in const [-.6, -.2, .2, .6]) {
        canvas.save();
        canvas.rotate(a);
        canvas.drawOval(
          const Rect.fromLTWH(-.15, -.7, .3, .65),
          paint..color = const Color(0xFFF08DB4),
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset.zero,
        .14,
        paint..color = const Color(0xFFFFD84A),
      );
    default:
      break;
  }
}

// Level 20: mossy rocks, stone lanterns and a little bonsai.
void _zenProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      _stoneLantern(canvas, paint);
    case 1:
      _rock(canvas, paint, const Color(0xFF7E847C), moss: true);
    default:
      // A bonsai in a shallow pot.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.6, .4, 1.2, .35),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFF6E4A3A),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, .4)
          ..quadraticBezierTo(-.3, 0, .1, -.3)
          ..lineTo(.2, -.25)
          ..quadraticBezierTo(-.15, 0, .1, .4)
          ..close(),
        paint..color = const Color(0xFF6B4436),
      );
      for (final (x, y, r) in const [
        (-.35, -.35, .32),
        (.3, -.5, .36),
        (0.0, -.7, .3),
      ]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: r * 2.2,
            height: r * 1.3,
          ),
          paint..color = const Color(0xFF4F7A3A),
        );
      }
  }
}

// Level 21: coral branches, sea anemones and shells on the sea floor.
void _reefProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      final branch = Paint()
        ..color = seed.isEven
            ? const Color(0xFFF27A6B)
            : const Color(0xFFFF9EC4)
        ..strokeWidth = .22
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(0, .8), const Offset(0, -.6), branch);
      canvas.drawLine(const Offset(0, .1), const Offset(-.6, -.6), branch);
      canvas.drawLine(const Offset(0, .3), const Offset(.6, -.4), branch);
      canvas.drawLine(const Offset(-.3, -.25), const Offset(-.75, -.1), branch);
    case 1:
      // A sea anemone.
      for (var i = 0; i < 9; i++) {
        final a = -math.pi + i * math.pi / 8;
        canvas.drawLine(
          const Offset(0, .3),
          Offset(math.cos(a) * .8, .3 + math.sin(a) * .8),
          Paint()
            ..color = const Color(0xFFB98AE6)
            ..strokeWidth = .14
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawOval(
        const Rect.fromLTWH(-.45, .15, .9, .5),
        paint..color = const Color(0xFF8E5BC9),
      );
    default:
      _shell(canvas, Offset.zero, .6, seed);
      canvas.drawCircle(
        const Offset(.5, .4),
        .14,
        paint..color = Colors.white.withValues(alpha: .7),
      );
  }
}

// Level 22: chickens, a red wheelbarrow and a haystack.
void _farmProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF1E3410));
  switch (seed % 3) {
    case 0:
      // A white hen.
      canvas.drawOval(
        const Rect.fromLTWH(-.6, -.3, 1.1, .85),
        paint..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(.45, -.35),
        .28,
        paint..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(.45, -.65),
        .12,
        paint..color = const Color(0xFFE2463F),
      );
      canvas.drawPath(
        Path()
          ..moveTo(.68, -.38)
          ..lineTo(.9, -.3)
          ..lineTo(.68, -.24)
          ..close(),
        paint..color = const Color(0xFFF2B33D),
      );
      canvas.drawCircle(
        const Offset(.5, -.4),
        .05,
        paint..color = const Color(0xFF222222),
      );
    case 1:
      // A wheelbarrow.
      canvas.drawPath(
        Path()
          ..moveTo(-.75, -.3)
          ..lineTo(.55, -.3)
          ..lineTo(.35, .3)
          ..lineTo(-.55, .3)
          ..close(),
        paint..color = const Color(0xFFC0392B),
      );
      canvas.drawCircle(
        const Offset(-.1, .5),
        .22,
        paint..color = const Color(0xFF3C3F46),
      );
      canvas.drawLine(
        const Offset(.45, -.2),
        const Offset(.95, .2),
        Paint()
          ..color = const Color(0xFF7A5634)
          ..strokeWidth = .1,
      );
    default:
      canvas.drawPath(
        Path()
          ..moveTo(-.85, .7)
          ..quadraticBezierTo(-.8, -.7, 0, -.75)
          ..quadraticBezierTo(.8, -.7, .85, .7)
          ..close(),
        paint..color = const Color(0xFFE8C45C),
      );
      for (final y in const [-.3, .1, .45]) {
        canvas.drawLine(
          Offset(-.6, y),
          Offset(.6, y),
          Paint()
            ..color = const Color(0xFFC79A34)
            ..strokeWidth = .06,
        );
      }
  }
}

// Level 23: snowy pines and snowmen.
void _winterProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF14283C));
  if (seed % 3 == 0) {
    // A snowman with a carrot nose and a red scarf.
    canvas.drawCircle(const Offset(0, .35), .45, paint..color = Colors.white);
    canvas.drawCircle(const Offset(0, -.3), .32, paint..color = Colors.white);
    canvas.drawRect(
      const Rect.fromLTWH(-.3, -.05, .6, .1),
      paint..color = const Color(0xFFD23B3B),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -.3)
        ..lineTo(.3, -.25)
        ..lineTo(0, -.2)
        ..close(),
      paint..color = const Color(0xFFF2852F),
    );
    for (final x in const [-.1, .1]) {
      canvas.drawCircle(
        Offset(x, -.4),
        .04,
        paint..color = const Color(0xFF222222),
      );
    }
    return;
  }
  canvas.drawRect(
    const Rect.fromLTWH(-.1, .45, .2, .4),
    paint..color = const Color(0xFF6B4436),
  );
  for (final (top, half) in const [(-.2, .8), (-.65, .62), (-1.05, .44)]) {
    final tier = Path()
      ..moveTo(0, top - .45)
      ..lineTo(half, top + .62)
      ..lineTo(-half, top + .62)
      ..close();
    canvas.drawPath(tier, paint..color = const Color(0xFF2F6B5A));
    // Snow resting on each tier.
    canvas.drawPath(
      Path()
        ..moveTo(0, top - .45)
        ..lineTo(half * .55, top + .05)
        ..lineTo(-half * .55, top + .05)
        ..close(),
      paint..color = Colors.white,
    );
  }
}

// Level 24: pumpkins, glowing jack-o'-lanterns and a lantern post.
void _pumpkinProp(Canvas canvas, Paint paint, int seed) {
  final lit = seed % 3 == 0;
  if (lit) {
    canvas.drawCircle(
      Offset.zero,
      1.1,
      paint..color = const Color(0xFFFFB347).withValues(alpha: .3),
    );
  }
  _propShadow(canvas, paint, Colors.black);
  for (final (x, w) in const [(-.35, .6), (.35, .6), (0.0, .7)]) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, .2), width: w, height: .85),
      paint..color = const Color(0xFFE8822F),
    );
  }
  canvas.drawRect(
    const Rect.fromLTWH(-.06, -.4, .12, .25),
    paint..color = const Color(0xFF4E6B22),
  );
  if (lit) {
    // A friendly carved face glowing from inside.
    final glow = Paint()..color = const Color(0xFFFFE08A);
    for (final x in const [-.2, .2]) {
      canvas.drawPath(
        Path()
          ..moveTo(x - .1, .1)
          ..lineTo(x, -.05)
          ..lineTo(x + .1, .1)
          ..close(),
        glow,
      );
    }
    canvas.drawArc(
      const Rect.fromLTWH(-.25, .1, .5, .3),
      0,
      math.pi,
      true,
      glow,
    );
  } else if (seed % 3 == 1) {
    canvas.drawLine(
      const Offset(.05, -.35),
      const Offset(.5, -.6),
      Paint()
        ..color = const Color(0xFF6E9E48)
        ..strokeWidth = .06,
    );
  }
}

// Level 25: lamp posts, parked cars and neon signs.
void _nightCityProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      canvas.drawCircle(
        const Offset(0, -.7),
        .7,
        paint..color = const Color(0xFFFFE08A).withValues(alpha: .35),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.06, -.6, .12, 1.4),
        paint..color = const Color(0xFF0E1226),
      );
      canvas.drawCircle(
        const Offset(0, -.75),
        .22,
        paint..color = const Color(0xFFFFE08A),
      );
    case 1:
      // A car seen from above.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.45, -.85, .9, 1.7),
          const Radius.circular(.25),
        ),
        paint
          ..color = seed.isEven
              ? const Color(0xFFF2C230)
              : const Color(0xFFE2463F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.32, -.45, .64, .7),
          const Radius.circular(.12),
        ),
        paint..color = const Color(0xFF2E3660),
      );
      for (final x in const [-.3, .3]) {
        canvas.drawCircle(
          Offset(x, -.78),
          .08,
          paint..color = const Color(0xFFFFF5C2),
        );
      }
    default:
      // A neon heart on a wall.
      final neon = Paint()
        ..color = const Color(0xFFFF4FAE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .12
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, .08);
      canvas.drawPath(
        Path()
          ..moveTo(0, .55)
          ..cubicTo(-.9, -.05, -.45, -.8, 0, -.3)
          ..cubicTo(.45, -.8, .9, -.05, 0, .55),
        neon,
      );
  }
}

// Level 26: cattails, ducks and lily pads in the marsh.
void _marshProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      for (final (x, h) in const [(-.35, 1.3), (0.0, 1.6), (.35, 1.2)]) {
        canvas.drawLine(
          Offset(x, .7),
          Offset(x, .7 - h),
          Paint()
            ..color = const Color(0xFF6E8F3A)
            ..strokeWidth = .08,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - .09, .7 - h + .1, .18, .45),
            const Radius.circular(.09),
          ),
          paint..color = const Color(0xFF7A4E2E),
        );
      }
    case 1:
      // A mallard paddling.
      canvas.drawOval(
        const Rect.fromLTWH(-.6, -.2, 1.1, .7),
        paint..color = const Color(0xFF9A7B5A),
      );
      canvas.drawCircle(
        const Offset(.45, -.3),
        .26,
        paint..color = const Color(0xFF2E7D4F),
      );
      canvas.drawPath(
        Path()
          ..moveTo(.66, -.32)
          ..lineTo(.95, -.25)
          ..lineTo(.66, -.18)
          ..close(),
        paint..color = const Color(0xFFF2B33D),
      );
      canvas.drawRect(
        const Rect.fromLTWH(.25, -.08, .35, .08),
        paint..color = Colors.white,
      );
    default:
      canvas.drawOval(
        const Rect.fromLTWH(-.7, -.4, 1.4, .8),
        paint..color = const Color(0xFF4F8A4A),
      );
      canvas.drawCircle(
        const Offset(.1, -.05),
        .16,
        paint..color = const Color(0xFFFFF5C2),
      );
  }
}

// Level 27: clipped topiary balls, gold-rimmed urns and a fountain.
void _palaceProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      canvas.drawRect(
        const Rect.fromLTWH(-.25, .3, .5, .45),
        paint..color = const Color(0xFFFBF3E2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.3, .3, .6, .08),
        paint..color = const Color(0xFFC9A23A),
      );
      canvas.drawCircle(
        const Offset(0, -.25),
        .55,
        paint..color = const Color(0xFF3F8A4A),
      );
      canvas.drawCircle(
        const Offset(-.18, -.4),
        .2,
        paint..color = const Color(0xFF66B06A),
      );
    case 1:
      canvas.drawPath(
        Path()
          ..moveTo(-.35, .75)
          ..lineTo(-.55, -.05)
          ..lineTo(.55, -.05)
          ..lineTo(.35, .75)
          ..close(),
        paint..color = const Color(0xFFFBF3E2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.6, -.12, 1.2, .1),
        paint..color = const Color(0xFFC9A23A),
      );
      for (final (x, y) in const [(-.3, -.35), (.05, -.5), (.35, -.3)]) {
        canvas.drawCircle(
          Offset(x, y),
          .2,
          paint..color = const Color(0xFFE85A7A),
        );
      }
    default:
      canvas.drawCircle(
        Offset.zero,
        .85,
        paint..color = const Color(0xFFFBF3E2),
      );
      canvas.drawCircle(
        Offset.zero,
        .7,
        paint..color = const Color(0xFF7FC8E8),
      );
      canvas.drawCircle(
        Offset.zero,
        .22,
        paint..color = const Color(0xFFC9A23A),
      );
  }
}

// Level 28: lemon trees in pots, a stone well and a blue bench.
void _courtyardProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      canvas.drawPath(
        Path()
          ..moveTo(-.4, .75)
          ..lineTo(-.5, .15)
          ..lineTo(.5, .15)
          ..lineTo(.4, .75)
          ..close(),
        paint..color = const Color(0xFF3E9A9A),
      );
      canvas.drawCircle(
        const Offset(0, -.35),
        .6,
        paint..color = const Color(0xFF3F7A3A),
      );
      for (final (x, y) in const [(-.25, -.45), (.25, -.2), (.1, -.65)]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: .22, height: .16),
          paint..color = const Color(0xFFF7D63A),
        );
      }
    case 1:
      // A round stone well with a little roof.
      canvas.drawCircle(
        Offset.zero,
        .65,
        paint..color = const Color(0xFFD9D2C4),
      );
      canvas.drawCircle(
        Offset.zero,
        .45,
        paint..color = const Color(0xFF2E5A6E),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.75, -.1, 1.5, .12),
        paint..color = const Color(0xFF7A5634),
      );
    default:
      _bench(canvas, paint, const Color(0xFF3E9A9A));
  }
}

// Level 29: striped parasols, surfboards and sandcastles.
void _sunsetProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      // A parasol seen from above.
      for (var i = 0; i < 8; i++) {
        canvas.drawArc(
          const Rect.fromLTWH(-.85, -.85, 1.7, 1.7),
          i * math.pi / 4,
          math.pi / 4,
          true,
          paint
            ..color = i.isEven
                ? const Color(0xFFFF8A5C)
                : const Color(0xFFFFF4E6),
        );
      }
      canvas.drawCircle(
        Offset.zero,
        .1,
        paint..color = const Color(0xFFB84A2A),
      );
    case 1:
      canvas.save();
      canvas.rotate(.5);
      canvas.drawOval(
        const Rect.fromLTWH(-.25, -.95, .5, 1.9),
        paint..color = const Color(0xFF4FC3D9),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.04, -.9, .08, 1.8),
        paint..color = Colors.white,
      );
      canvas.restore();
    default:
      // A little sandcastle on a sandbank.
      canvas.drawOval(
        const Rect.fromLTWH(-.95, .1, 1.9, .75),
        paint..color = const Color(0xFFFFE6C2),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.45, -.3, .9, .65),
        paint..color = const Color(0xFFE8C48E),
      );
      for (final x in const [-.45, -.15, .15]) {
        canvas.drawRect(
          Rect.fromLTWH(x, -.45, .2, .15),
          paint..color = const Color(0xFFE8C48E),
        );
      }
      canvas.drawLine(
        const Offset(0, -.3),
        const Offset(0, -.8),
        Paint()
          ..color = const Color(0xFF7A5634)
          ..strokeWidth = .05,
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -.8)
          ..lineTo(.3, -.7)
          ..lineTo(0, -.6)
          ..close(),
        paint..color = const Color(0xFFFF8A5C),
      );
  }
}

// Level 30: moonlit lavender bushes, a lit lantern and a beehive.
void _moonLavenderProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      _stoneLantern(canvas, paint, lit: true);
    case 1:
      _beehive(canvas, paint);
    default:
      canvas.drawOval(
        const Rect.fromLTWH(-.85, .05, 1.7, .7),
        paint..color = const Color(0xFF2E4A3A),
      );
      for (var i = 0; i < 7; i++) {
        final x = -.6 + i * .2;
        for (var k = 0; k < 4; k++) {
          canvas.drawCircle(
            Offset(x, .1 - k * .2 - (i % 2) * .1),
            .09,
            paint..color = const Color(0xFFB79CF2),
          );
        }
      }
  }
}

// Level 31: broken temple columns, a stone head and vine-wrapped rocks.
void _jungleProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      // A broken column with a fallen drum beside it.
      canvas.drawRect(
        const Rect.fromLTWH(-.3, -.6, .6, 1.35),
        paint..color = const Color(0xFFCFC9AE),
      );
      for (final x in const [-.15, 0.0, .15]) {
        canvas.drawLine(
          Offset(x, -.55),
          Offset(x, .7),
          Paint()
            ..color = const Color(0xFFA9A386)
            ..strokeWidth = .04,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(-.3, -.6)
          ..lineTo(-.1, -.8)
          ..lineTo(.1, -.62)
          ..lineTo(.3, -.75)
          ..lineTo(.3, -.6)
          ..close(),
        paint..color = const Color(0xFFCFC9AE),
      );
      _leaf(canvas, const Offset(.3, -.2), .3, .5, const Color(0xFF4F9A48));
    case 1:
      // A carved stone head.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.55, -.75, 1.1, 1.45),
          const Radius.circular(.25),
        ),
        paint..color = const Color(0xFF9EAB88),
      );
      for (final x in const [-.22, .22]) {
        canvas.drawRect(
          Rect.fromLTWH(x - .12, -.3, .24, .1),
          paint..color = const Color(0xFF5E6A48),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(-.2, .2, .4, .1),
        paint..color = const Color(0xFF5E6A48),
      );
      _leaf(canvas, const Offset(-.45, -.7), .3, -.4, const Color(0xFF4F9A48));
    default:
      _rock(canvas, paint, const Color(0xFF8E9A78), moss: true);
      _leaf(canvas, const Offset(.5, .2), .3, .9, const Color(0xFF3F8A3A));
  }
}

void _leaf(
  Canvas canvas,
  Offset at,
  double r,
  double turn, [
  Color colour = const Color(0xFF5E9E48),
]) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(turn);
  canvas.drawPath(
    Path()
      ..moveTo(-r, 0)
      ..quadraticBezierTo(0, -r * .9, r, 0)
      ..quadraticBezierTo(0, r * .9, -r, 0),
    Paint()..color = colour,
  );
  canvas.restore();
}

// Level 32: orange trees, woven baskets of oranges and a ladder.
void _groveProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF2A1A0A));
  switch (seed % 3) {
    case 0:
      _roundTree(
        canvas,
        paint,
        const Color(0xFF3F7A3A),
        const Color(0xFF63A35A),
      );
      for (final (x, y) in const [
        (-.45, -.2),
        (.3, -.45),
        (.15, .05),
        (-.15, -.65),
      ]) {
        canvas.drawCircle(
          Offset(x, y),
          .13,
          paint..color = const Color(0xFFF59A1E),
        );
      }
    case 1:
      canvas.drawPath(
        Path()
          ..moveTo(-.7, -.1)
          ..lineTo(.7, -.1)
          ..lineTo(.5, .65)
          ..lineTo(-.5, .65)
          ..close(),
        paint..color = const Color(0xFFC79A5A),
      );
      for (var y = .1; y < .65; y += .18) {
        canvas.drawLine(
          Offset(-.65, y),
          Offset(.65, y),
          Paint()
            ..color = const Color(0xFF9A7038)
            ..strokeWidth = .05,
        );
      }
      for (final x in const [-.35, 0.0, .35]) {
        canvas.drawCircle(
          Offset(x, -.2),
          .22,
          paint..color = const Color(0xFFF59A1E),
        );
      }
    default:
      // A wooden ladder leaning on its side.
      final wood = Paint()
        ..color = const Color(0xFF9A7038)
        ..strokeWidth = .1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-.4, -.9), const Offset(-.4, .8), wood);
      canvas.drawLine(const Offset(.4, -.9), const Offset(.4, .8), wood);
      for (var y = -.7; y < .8; y += .35) {
        canvas.drawLine(Offset(-.4, y), Offset(.4, y), wood);
      }
  }
}

// Level 33: a mine cart of gems, a lantern on a post and a gem cluster.
void _mineProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      _propShadow(canvas, paint, Colors.black);
      canvas.drawPath(
        Path()
          ..moveTo(-.75, -.3)
          ..lineTo(.75, -.3)
          ..lineTo(.55, .45)
          ..lineTo(-.55, .45)
          ..close(),
        paint..color = const Color(0xFF7E848C),
      );
      for (final x in const [-.4, .4]) {
        canvas.drawCircle(
          Offset(x, .55),
          .16,
          paint..color = const Color(0xFF3C3F46),
        );
      }
      for (final (x, c) in const [
        (-.35, Color(0xFF5CF2A0)),
        (0.0, Color(0xFF3FD18A)),
        (.35, Color(0xFF8FF2C8)),
      ]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, -.7)
            ..lineTo(x + .18, -.35)
            ..lineTo(x - .18, -.35)
            ..close(),
          paint..color = c,
        );
      }
    case 1:
      canvas.drawCircle(
        const Offset(0, -.6),
        .7,
        paint..color = const Color(0xFFFFD86A).withValues(alpha: .25),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.07, -.5, .14, 1.3),
        paint..color = const Color(0xFF6E4A2E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.2, -.85, .4, .45),
          const Radius.circular(.08),
        ),
        paint..color = const Color(0xFFFFD86A),
      );
    default:
      canvas.drawCircle(
        Offset.zero,
        1,
        paint..color = const Color(0xFF5CF2A0).withValues(alpha: .15),
      );
      for (final (x, h) in const [(-.3, .9), (0.0, 1.2), (.3, .8)]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - .15, .6)
            ..lineTo(x - .15, .6 - h + .25)
            ..lineTo(x, .6 - h)
            ..lineTo(x + .15, .6 - h + .25)
            ..lineTo(x + .15, .6)
            ..close(),
          paint..color = const Color(0xFF3FD18A),
        );
      }
  }
}

// Level 34: a flag on the green, golf balls and a little golf cart.
void _golfProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      // A putting green with a flag.
      canvas.drawOval(
        const Rect.fromLTWH(-.95, -.3, 1.9, 1.1),
        paint..color = const Color(0xFF7CC35A),
      );
      canvas.drawCircle(
        const Offset(0, .25),
        .1,
        paint..color = const Color(0xFF223018),
      );
      canvas.drawLine(
        const Offset(0, .25),
        const Offset(0, -.85),
        Paint()
          ..color = Colors.white
          ..strokeWidth = .06,
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -.85)
          ..lineTo(.5, -.7)
          ..lineTo(0, -.55)
          ..close(),
        paint..color = const Color(0xFFE2463F),
      );
    case 1:
      canvas.drawOval(
        const Rect.fromLTWH(-.9, -.4, 1.8, 1.0),
        paint..color = const Color(0xFF7CC35A),
      );
      for (final (x, y) in const [(-.3, 0.0), (.25, .2)]) {
        canvas.drawCircle(Offset(x, y), .14, paint..color = Colors.white);
      }
    default:
      // A golf cart seen from above.
      canvas.drawOval(
        const Rect.fromLTWH(-.95, -.4, 1.9, 1.1),
        paint..color = const Color(0xFF7CC35A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.35, -.55, .7, 1.1),
          const Radius.circular(.15),
        ),
        paint..color = Colors.white,
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.3, -.15, .6, .3),
        paint..color = const Color(0xFF3E8A3A),
      );
  }
}

// Level 35: hay rolls, grain sacks and clumps of poppies.
void _harvestProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, Colors.black);
  switch (seed % 3) {
    case 0:
      canvas.drawCircle(
        const Offset(0, .05),
        .72,
        paint..color = const Color(0xFFE8C45C),
      );
      final roll = Paint()
        ..color = const Color(0xFFC79A34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .08;
      for (final r in const [.22, .42, .6]) {
        canvas.drawCircle(const Offset(0, .05), r, roll);
      }
    case 1:
      // A tied grain sack.
      canvas.drawPath(
        Path()
          ..moveTo(-.2, -.55)
          ..quadraticBezierTo(-.75, -.2, -.6, .7)
          ..lineTo(.6, .7)
          ..quadraticBezierTo(.75, -.2, .2, -.55)
          ..close(),
        paint..color = const Color(0xFFE2CFA0),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.22, -.62, .44, .1),
        paint..color = const Color(0xFF8A6420),
      );
    default:
      for (final (x, y) in const [
        (-.4, .1),
        (.05, -.25),
        (.4, .15),
        (-.05, .4),
      ]) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, .75),
          Paint()
            ..color = const Color(0xFF4E7A2E)
            ..strokeWidth = .06,
        );
        for (var k = 0; k < 4; k++) {
          final a = k * math.pi / 2;
          canvas.drawCircle(
            Offset(x + math.cos(a) * .1, y + math.sin(a) * .1),
            .13,
            paint..color = const Color(0xFFE23B3B),
          );
        }
        canvas.drawCircle(
          Offset(x, y),
          .06,
          paint..color = const Color(0xFF222222),
        );
      }
  }
}

// Level 36: lotus flowers and paper lanterns floating on the night pond.
void _lanternPondProp(Canvas canvas, Paint paint, int seed) {
  if (seed % 2 == 0) {
    canvas.drawCircle(
      Offset.zero,
      1,
      paint..color = const Color(0xFFFFC46A).withValues(alpha: .25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.35, -.45, .7, .8),
        const Radius.circular(.2),
      ),
      paint..color = const Color(0xFFFF8A5C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-.25, -.35, .5, .6),
        const Radius.circular(.15),
      ),
      paint..color = const Color(0xFFFFE08A),
    );
    return;
  }
  canvas.drawOval(
    const Rect.fromLTWH(-.85, -.1, 1.7, .8),
    paint..color = const Color(0xFF2F6E4A),
  );
  for (final a in const [-.6, -.2, .2, .6]) {
    canvas.save();
    canvas.translate(0, .2);
    canvas.rotate(a);
    canvas.drawOval(
      const Rect.fromLTWH(-.15, -.75, .3, .65),
      paint..color = const Color(0xFFF7B6CB),
    );
    canvas.restore();
  }
}

// Level 37: wagon wheels, water barrels and flowering cacti.
void _canyonProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF3A1408));
  switch (seed % 3) {
    case 0:
      final wood = Paint()
        ..color = const Color(0xFF6E4A22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .12;
      canvas.drawCircle(Offset.zero, .7, wood);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(a), math.sin(a)) * .7,
          Offset(math.cos(a), math.sin(a)) * -.7,
          wood..strokeWidth = .07,
        );
      }
    case 1:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.5, -.6, 1.0, 1.35),
          const Radius.circular(.2),
        ),
        paint..color = const Color(0xFF9A6438),
      );
      for (final y in const [-.35, .45]) {
        canvas.drawRect(
          Rect.fromLTWH(-.52, y, 1.04, .1),
          paint..color = const Color(0xFF3C3F46),
        );
      }
    default:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.18, -.9, .36, 1.65),
          const Radius.circular(.18),
        ),
        paint..color = const Color(0xFF4F9A5E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.6, -.35, .3, .7),
          const Radius.circular(.15),
        ),
        paint..color = const Color(0xFF4F9A5E),
      );
      canvas.drawCircle(
        const Offset(0, -.95),
        .14,
        paint..color = const Color(0xFFFF7FA8),
      );
  }
}

// Level 38: gingham picnic blankets, a basket and a kite.
void _picnicProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      final blanket = const Rect.fromLTWH(-.9, -.6, 1.8, 1.2);
      canvas.drawRect(blanket, paint..color = Colors.white);
      for (var i = 0; i < 6; i++) {
        canvas.drawRect(
          Rect.fromLTWH(-.9 + i * .3, -.6, .15, 1.2),
          paint..color = const Color(0xFF5E8FD9).withValues(alpha: .55),
        );
        if (i < 4) {
          canvas.drawRect(
            Rect.fromLTWH(-.9, -.6 + i * .3, 1.8, .15),
            paint..color = const Color(0xFF5E8FD9).withValues(alpha: .55),
          );
        }
      }
    case 1:
      _propShadow(canvas, paint, Colors.black);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.6, -.2, 1.2, .8),
          const Radius.circular(.12),
        ),
        paint..color = const Color(0xFFC79A5A),
      );
      canvas.drawArc(
        const Rect.fromLTWH(-.45, -.65, .9, .9),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF9A7038)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .1,
      );
      canvas.drawCircle(
        const Offset(-.2, -.15),
        .14,
        paint..color = const Color(0xFFE2463F),
      );
    default:
      // A kite with a ribbon tail.
      canvas.drawPath(
        Path()
          ..moveTo(0, -.9)
          ..lineTo(.5, -.2)
          ..lineTo(0, .4)
          ..lineTo(-.5, -.2)
          ..close(),
        paint..color = const Color(0xFFFF8FB1),
      );
      canvas.drawLine(
        const Offset(0, -.9),
        const Offset(0, .4),
        Paint()
          ..color = Colors.white
          ..strokeWidth = .04,
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, .4)
          ..quadraticBezierTo(.3, .6, 0, .8)
          ..quadraticBezierTo(-.3, 1.0, 0, 1.1),
        Paint()
          ..color = const Color(0xFF5E8FD9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .06,
      );
  }
}

// Level 39: terracotta pots, brass lanterns and patterned rugs.
void _riadProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      _propShadow(canvas, paint, Colors.black);
      canvas.drawPath(
        Path()
          ..moveTo(-.3, .75)
          ..quadraticBezierTo(-.75, .2, -.3, -.3)
          ..lineTo(.3, -.3)
          ..quadraticBezierTo(.75, .2, .3, .75)
          ..close(),
        paint..color = const Color(0xFFD9895A),
      );
      for (var i = 0; i < 5; i++) {
        _leaf(
          canvas,
          Offset(-.3 + i * .15, -.5),
          .25,
          -1.2 + i * .6,
          const Color(0xFF3F8A4A),
        );
      }
    case 1:
      canvas.drawCircle(
        Offset.zero,
        .9,
        paint..color = const Color(0xFFFFD86A).withValues(alpha: .25),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -.75)
          ..lineTo(.4, -.2)
          ..lineTo(.3, .5)
          ..lineTo(-.3, .5)
          ..lineTo(-.4, -.2)
          ..close(),
        paint..color = const Color(0xFFC9A23A),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.15, -.2, .3, .5),
        paint..color = const Color(0xFFFFE08A),
      );
    default:
      // A patterned rug.
      canvas.drawRect(
        const Rect.fromLTWH(-.85, -.55, 1.7, 1.1),
        paint..color = const Color(0xFFB8402E),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-.7, -.4, 1.4, .8),
        Paint()
          ..color = const Color(0xFFE9C46A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .06,
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, -.3)
          ..lineTo(.35, 0)
          ..lineTo(0, .3)
          ..lineTo(-.35, 0)
          ..close(),
        paint..color = const Color(0xFF2E5A8A),
      );
  }
}

// Level 40: glowing fairy mushrooms, ferns and mossy stumps.
void _fairyProp(Canvas canvas, Paint paint, int seed) {
  switch (seed % 3) {
    case 0:
      canvas.drawCircle(
        Offset.zero,
        1,
        paint..color = const Color(0xFF7AF0F0).withValues(alpha: .2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-.15, -.1, .3, .8),
          const Radius.circular(.1),
        ),
        paint..color = const Color(0xFFF1E6FF),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-.8, 0)
          ..quadraticBezierTo(0, -1.2, .8, 0)
          ..close(),
        paint..color = const Color(0xFF7AF0F0),
      );
      for (final (x, y) in const [(-.35, -.2), (.2, -.45)]) {
        canvas.drawCircle(Offset(x, y), .09, paint..color = Colors.white);
      }
    case 1:
      // A fern.
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.translate(0, .6);
        canvas.rotate(-.9 + i * .45);
        canvas.drawPath(
          Path()
            ..moveTo(-.1, 0)
            ..quadraticBezierTo(-.15, -.7, 0, -1.2)
            ..quadraticBezierTo(.15, -.7, .1, 0)
            ..close(),
          paint..color = const Color(0xFF4F9A6A),
        );
        canvas.restore();
      }
    default:
      _propShadow(canvas, paint, Colors.black);
      canvas.drawOval(
        const Rect.fromLTWH(-.7, -.2, 1.4, .9),
        paint..color = const Color(0xFF7A5634),
      );
      canvas.drawOval(
        const Rect.fromLTWH(-.6, -.3, 1.2, .5),
        paint..color = const Color(0xFFD9B98A),
      );
      for (var r = .12; r < .5; r += .12) {
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(0, -.05),
            width: r * 2,
            height: r,
          ),
          Paint()
            ..color = const Color(0xFFB08A5A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .03,
        );
      }
      canvas.drawOval(
        const Rect.fromLTWH(.1, -.35, .5, .2),
        paint..color = const Color(0xFF6E9E48),
      );
  }
}

// Level 9: lollipops, cupcakes and candy canes.
void _candyProp(Canvas canvas, Paint paint, int seed) {
  _propShadow(canvas, paint, const Color(0xFF7A3A5A));
  switch (seed % 3) {
    case 0:
      // A swirly lollipop.
      canvas.drawLine(
        const Offset(0, .1),
        const Offset(0, .85),
        Paint()
          ..color = Colors.white
          ..strokeWidth = .12
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        const Offset(0, -.25),
        .55,
        paint
          ..color = seed.isEven
              ? const Color(0xFFFF7FB0)
              : const Color(0xFF7FD8F2),
      );
      final swirl = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = .09
        ..strokeCap = StrokeCap.round;
      for (var r = .14; r < .5; r += .14) {
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(0, -.25), radius: r),
          r * 8,
          math.pi * 1.3,
          false,
          swirl,
        );
      }
    case 1:
      // A cupcake with icing and a cherry.
      canvas.drawPath(
        Path()
          ..moveTo(-.5, .05)
          ..lineTo(.5, .05)
          ..lineTo(.38, .75)
          ..lineTo(-.38, .75)
          ..close(),
        paint..color = const Color(0xFF7FD8F2),
      );
      for (final x in const [-.25, 0.0, .25]) {
        canvas.drawLine(
          Offset(x, .1),
          Offset(x * .8, .7),
          Paint()
            ..color = const Color(0xFF4FB8D9)
            ..strokeWidth = .05,
        );
      }
      for (final (x, y, r) in const [
        (-.3, -.05, .28),
        (.3, -.05, .28),
        (0.0, -.25, .32),
      ]) {
        canvas.drawCircle(
          Offset(x, y),
          r,
          paint..color = const Color(0xFFFFF0F6),
        );
      }
      canvas.drawCircle(
        const Offset(0, -.6),
        .13,
        paint..color = const Color(0xFFE2463F),
      );
    default:
      // A striped candy cane.
      final cane = Path()
        ..moveTo(.1, .85)
        ..lineTo(.1, -.35)
        ..arcToPoint(
          const Offset(-.45, -.35),
          radius: const Radius.circular(.275),
          clockwise: false,
        );
      canvas.drawPath(
        cane,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = .22
          ..strokeCap = StrokeCap.round,
      );
      final stripe = Paint()
        ..color = const Color(0xFFE2463F)
        ..strokeWidth = .09
        ..strokeCap = StrokeCap.round;
      for (var y = .7; y > -.3; y -= .22) {
        canvas.drawLine(Offset(0, y), Offset(.2, y - .1), stripe);
      }
  }
}
