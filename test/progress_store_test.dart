import 'package:arrow_game/config/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('progress saved on the device comes back after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.init();
    expect(ProgressStore.load('escape'), isNull);

    ProgressStore.save('escape', level: 7, unlocked: 8, stars: {1: 3, 7: 2});
    ProgressStore.setString('character', 'female');
    await ProgressStore.init();

    final saved = ProgressStore.load('escape')!;
    expect(saved.level, 7);
    expect(saved.unlocked, 8);
    expect(saved.stars, {1: 3, 7: 2});
    expect(ProgressStore.getString('character'), 'female');
  });
}
