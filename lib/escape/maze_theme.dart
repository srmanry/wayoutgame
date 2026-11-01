/// A shared landscape plan keeps scenery, ground, gates and the picker in sync.
enum MazeTheme {
  forest('Woodland'),
  daisies('Daisy garden'),
  meadow('Grass meadow'),
  roses('Rose garden'),
  bamboo('Bamboo grove'),
  garden('Flower hedges'),
  lavender('Lavender field'),
  mushrooms('Mushroom garden'),
  sunflowers('Sunflower garden'),
  lotus('Lotus garden'),
  stone('Stone garden'),
  grass('Natural grass'),
  city('Rooftop alleys'),
  orchard('Fruit orchard'),
  cactus('Desert oasis'),
  palms('Palm beach'),
  snow('Snowy forest'),
  crystal('Crystal valley'),
  coral('Coral lagoon'),
  brick('Brick courtyards'),
  fence('Country fences'),
  wheat('Golden wheat'),
  pumpkins('Pumpkin patch'),
  tulips('Tulip garden'),
  blossom('Cherry blossoms'),
  pots('Terracotta garden'),
  reeds('Reed wetlands'),
  ruins('Ancient ruins');

  const MazeTheme(this.label);
  final String label;

  static MazeTheme forLevel(int level) {
    RangeError.checkValueInInterval(level, 1, 200, 'level');
    // Retain the original approved sample landscapes at levels 8–20.
    if (level >= 8 && level <= 20) return _samples[level - 8];
    if (level <= 7) return _opening[level - 1];
    final index = level - 21;
    final chapter = index ~/ _journey.length;
    return _journey[(index + chapter * 9) % _journey.length];
  }

  /// Later visits have different seasonal colours and planting patterns.
  static int variationForLevel(int level) =>
      level <= 20 ? 0 : ((level - 21) ~/ _journey.length) % 5;

  static const _opening = [
    forest,
    tulips,
    orchard,
    palms,
    cactus,
    blossom,
    crystal,
  ];
  static const _samples = [
    grass,
    city,
    forest,
    daisies,
    meadow,
    roses,
    bamboo,
    garden,
    lavender,
    mushrooms,
    sunflowers,
    lotus,
    stone,
  ];
  static const _journey = [
    coral,
    fence,
    snow,
    pumpkins,
    city,
    reeds,
    roses,
    brick,
    palms,
    lavender,
    ruins,
    orchard,
    crystal,
    grass,
    wheat,
    lotus,
    cactus,
    daisies,
    pots,
    forest,
    tulips,
    stone,
    meadow,
    blossom,
    bamboo,
    sunflowers,
    mushrooms,
    garden,
  ];
}
