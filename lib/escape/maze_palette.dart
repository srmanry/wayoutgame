import 'package:flutter/material.dart';

import 'maze_escape.dart';
import 'maze_theme.dart';

/// Restrained surface colours with dark walls and readable action colours.
class MazePalette {
  const MazePalette(this.accent, this.wall, this.floorTop, this.floorBottom);

  final Color accent;
  final Color wall;
  final Color floorTop;
  final Color floorBottom;

  static const player = Color(0xFF16775F);
  static const hunter = Color(0xFFAD4C57);
  static const text = Color(0xFF263D46);
  static const secondary = Color(0xFF60747C);

  Color get canvas => Color.lerp(accent, Colors.white, .965)!;
  Color get tint => Color.lerp(accent, Colors.white, .92)!;
  Color get border => Color.lerp(accent, Colors.white, .84)!;

  static MazePalette forMaze(EscapeMaze maze) => forLevel(maze.number);

  static MazePalette forLevel(int level) {
    final base = _landscapes[MazeTheme.forLevel(level)]!;
    final variation = MazeTheme.variationForLevel(level);
    if (variation == 0) return base;
    final season = _seasons[variation];
    return MazePalette(
      Color.lerp(base.accent, season, .12)!,
      Color.lerp(base.wall, season, .16)!,
      Color.lerp(base.floorTop, season, .055)!,
      Color.lerp(base.floorBottom, season, .09)!,
    );
  }

  /// A restrained seasonal tint affects scenery, leaving role colours intact.
  static ColorFilter? sceneryFilterForLevel(int level) {
    final variation = MazeTheme.variationForLevel(level);
    if (variation == 0) return null;
    final tint = _seasons[variation];
    const mix = .14, keep = 1 - mix;
    return ColorFilter.matrix([
      keep,
      0,
      0,
      0,
      tint.r * 255 * mix,
      0,
      keep,
      0,
      0,
      tint.g * 255 * mix,
      0,
      0,
      keep,
      0,
      tint.b * 255 * mix,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  static const _seasons = [
    Color(0xFFFFFFFF),
    Color(0xFFE6C286),
    Color(0xFFD5A28B),
    Color(0xFFAFCBC0),
    Color(0xFFC9B8D7),
  ];

  static const _landscapes = <MazeTheme, MazePalette>{
    MazeTheme.grass: MazePalette(
      Color(0xFF527A32),
      Color(0xFF527A32),
      Color(0xFFFAF3DF),
      Color(0xFFEFE5C9),
    ),
    MazeTheme.city: MazePalette(
      Color(0xFF687D87),
      Color(0xFF7E7B70),
      Color(0xFFEFEDE7),
      Color(0xFFDEDFDA),
    ),
    MazeTheme.forest: MazePalette(
      Color(0xFF356D4C),
      Color(0xFF3E6B47),
      Color(0xFFFAF9EE),
      Color(0xFFEEF2DF),
    ),
    MazeTheme.daisies: MazePalette(
      Color(0xFF82914A),
      Color(0xFF6F8145),
      Color(0xFFFFFCED),
      Color(0xFFF2F0D8),
    ),
    MazeTheme.meadow: MazePalette(
      Color(0xFF668C46),
      Color(0xFF587843),
      Color(0xFFFAFCEC),
      Color(0xFFEDF3D8),
    ),
    MazeTheme.roses: MazePalette(
      Color(0xFFA56B80),
      Color(0xFF7B6F6B),
      Color(0xFFFFF9F6),
      Color(0xFFF5E7E5),
    ),
    MazeTheme.bamboo: MazePalette(
      Color(0xFF718747),
      Color(0xFF62734C),
      Color(0xFFFAF9ED),
      Color(0xFFEEECD8),
    ),
    MazeTheme.garden: MazePalette(
      Color(0xFF397B69),
      Color(0xFF477E69),
      Color(0xFFFFFAF3),
      Color(0xFFF7EEE6),
    ),
    MazeTheme.lavender: MazePalette(
      Color(0xFF8D76A4),
      Color(0xFF776E87),
      Color(0xFFFCF9FD),
      Color(0xFFEEE8F2),
    ),
    MazeTheme.mushrooms: MazePalette(
      Color(0xFFA37957),
      Color(0xFF82765A),
      Color(0xFFFCF7EC),
      Color(0xFFF0E8D8),
    ),
    MazeTheme.sunflowers: MazePalette(
      Color(0xFFA68A38),
      Color(0xFF847742),
      Color(0xFFFFFBEA),
      Color(0xFFF5ECCA),
    ),
    MazeTheme.lotus: MazePalette(
      Color(0xFF4E9390),
      Color(0xFF53817C),
      Color(0xFFF4FBF7),
      Color(0xFFE3F0E8),
    ),
    MazeTheme.stone: MazePalette(
      Color(0xFF617A80),
      Color(0xFF63767B),
      Color(0xFFFFFBF0),
      Color(0xFFF1EBD9),
    ),
    MazeTheme.orchard: MazePalette(
      Color(0xFF6D8647),
      Color(0xFF567948),
      Color(0xFFFFF9E9),
      Color(0xFFF0EBD4),
    ),
    MazeTheme.cactus: MazePalette(
      Color(0xFFA58550),
      Color(0xFF7B8A66),
      Color(0xFFFFF4DC),
      Color(0xFFF2E0BC),
    ),
    MazeTheme.palms: MazePalette(
      Color(0xFF458A81),
      Color(0xFF537F64),
      Color(0xFFFFF8DF),
      Color(0xFFF3E8C5),
    ),
    MazeTheme.snow: MazePalette(
      Color(0xFF608C9E),
      Color(0xFF7997A0),
      Color(0xFFF4FAFC),
      Color(0xFFE2EFF3),
    ),
    MazeTheme.crystal: MazePalette(
      Color(0xFF827EA6),
      Color(0xFF8295AF),
      Color(0xFFFAF9FD),
      Color(0xFFE9EAF4),
    ),
    MazeTheme.coral: MazePalette(
      Color(0xFF518F99),
      Color(0xFF8C9894),
      Color(0xFFF4FCFA),
      Color(0xFFDEEFEB),
    ),
    MazeTheme.brick: MazePalette(
      Color(0xFFA47763),
      Color(0xFFAA8773),
      Color(0xFFFBF6ED),
      Color(0xFFEDE4D8),
    ),
    MazeTheme.fence: MazePalette(
      Color(0xFF8B8D59),
      Color(0xFF9B8B65),
      Color(0xFFFBF9EC),
      Color(0xFFECEBD5),
    ),
    MazeTheme.wheat: MazePalette(
      Color(0xFFA38C43),
      Color(0xFFA49966),
      Color(0xFFFFFAE6),
      Color(0xFFF1E7C4),
    ),
    MazeTheme.pumpkins: MazePalette(
      Color(0xFFAB8353),
      Color(0xFF8C9061),
      Color(0xFFFFF8E9),
      Color(0xFFF0E8D3),
    ),
    MazeTheme.tulips: MazePalette(
      Color(0xFFA0798B),
      Color(0xFF789572),
      Color(0xFFFFF8F3),
      Color(0xFFF2E9E3),
    ),
    MazeTheme.blossom: MazePalette(
      Color(0xFFA77991),
      Color(0xFFA18A8D),
      Color(0xFFFFF8FA),
      Color(0xFFF3E5EB),
    ),
    MazeTheme.pots: MazePalette(
      Color(0xFFA67F64),
      Color(0xFFA79981),
      Color(0xFFFCF6EE),
      Color(0xFFEEE3D5),
    ),
    MazeTheme.reeds: MazePalette(
      Color(0xFF588C81),
      Color(0xFF6F9584),
      Color(0xFFF5FAF3),
      Color(0xFFE2EDE1),
    ),
    MazeTheme.ruins: MazePalette(
      Color(0xFF8B8C6C),
      Color(0xFF92967C),
      Color(0xFFFCF8ED),
      Color(0xFFEAE6D6),
    ),
  };
}
