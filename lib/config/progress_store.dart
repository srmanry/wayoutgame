import 'package:shared_preferences/shared_preferences.dart';

/// Saved progress for each game kept on the device: the last level played,
/// the furthest level unlocked and the stars earned, plus a few choices.
/// Before [init] (as in tests) it reads nothing and saves nothing.
class ProgressStore {
  ProgressStore._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Without storage the game still plays; progress lasts the session.
      _prefs = null;
    }
  }

  static ({int level, int unlocked, Map<int, int> stars})? load(String game) {
    final prefs = _prefs;
    if (prefs == null) return null;
    final unlocked = prefs.getInt('$game.unlocked');
    if (unlocked == null) return null;
    return (
      level: prefs.getInt('$game.level') ?? 1,
      unlocked: unlocked,
      stars: {
        for (final entry in prefs.getStringList('$game.stars') ?? const [])
          if (_starEntry(entry) case final (int, int) pair) pair.$1: pair.$2,
      },
    );
  }

  static void save(
    String game, {
    required int level,
    required int unlocked,
    required Map<int, int> stars,
  }) {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt('$game.level', level);
    prefs.setInt('$game.unlocked', unlocked);
    prefs.setStringList('$game.stars', [
      for (final MapEntry(:key, :value) in stars.entries) '$key:$value',
    ]);
  }

  static String? getString(String key) => _prefs?.getString(key);
  static void setString(String key, String value) =>
      _prefs?.setString(key, value);
  static bool? getBool(String key) => _prefs?.getBool(key);
  static void setBool(String key, bool value) => _prefs?.setBool(key, value);

  static (int, int)? _starEntry(String entry) {
    final parts = entry.split(':');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[0]), stars = int.tryParse(parts[1]);
    return level == null || stars == null ? null : (level, stars);
  }
}
