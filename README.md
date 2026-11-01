# Arrow Escape

A Flutter puzzle collection for mobile, desktop, and web. The home screen offers three separate game choices, with in-session boards preserved when switching between them:

- **Arrow Escape:** Basic arrow puzzles and Animal Rescue, with the existing online competition.
- **Math Crossword:** 30 connected arithmetic crosswords. Select a blank and place a number from the finite tile tray. Every crossing agrees, and every puzzle can be solved by successive single-unknown equations.
- **Sudoku:** 30 classic 9×9 puzzles with exactly one solution each, across Easy, Medium, and Hard groups. Includes pencil notes, conflict highlighting, erase, undo, check, hints, pause, and timer.

Use **All games** to return to the home screen. Progress and current entries are kept while the app is running; hidden number games pause their clocks. Math Crossword and Sudoku are offline solo games; online competition currently uses Arrow Escape boards.

Arrow Escape modes:

- **Basic:** the original 30 arrow escape levels. Clear every arrow to finish.
- **Animal Rescue:** 30 additional stages alternating lion/deer and cat/mice scenes. Clear arrows from the mint routes, then tap the animals to send them to the safe exits on the right. Rescue both animals to win; unrelated arrows can remain.

Hunters and waiting animals block arrow exits. Each blocked arrow or attempted rescue costs a heart and brings the hunters closer. Three mistakes end the attempt. Undo restores the last cleared arrow or rescued animal, while hints highlight either a safe arrow or an animal ready to escape. Each mode has separate level and star progress; switching modes preserves both puzzles.

- 60 Arrow Escape levels, 30 Math Crosswords, and 30 unique-solution Sudoku puzzles
- Three hearts and three hints per attempt
- Animated exits, blocked-move feedback, undo, and restart
- Level selection, star ratings, pause, and optional haptics
- Responsive phone and desktop layouts; accessible arrow actions
- Keyboard shortcuts: **H** hint, **R** restart, **Esc** pause/resume

Progress and settings last for the current app session. Restarting the app resets them. Solo modes work offline. Online competition uses the included WebSocket server and the `web_socket_channel` client package. A public match server has not been deployed.

## Maze Escape

Maze Escape has 200 distinct, repeatable silhouettes and route layouts. Shape
parameters, alcoves, courtyards and bridges vary each blueprint, built from:
Garden, Cloud, Fortress, Star, Islands, Ruins, Canyon, River, Crossroads and Ring.
Winding corridors, branching paths, horizontal galleries, vertical lanes and open
rooms vary how each maze plays. White cutouts are outside the playable area.
Five 40-level difficulty tiers increase board size, route length, decisions and
hunter speed while reducing shortcuts and time to think at each crossing.
Hunter release timing is checked against the solution so every level remains
winnable. All 200 layouts are covered by connectivity and chase simulations.

All 200 mazes have themed scenery: 28 landscape families include tropical
beaches, desert cacti, snow-covered forests, crystal valleys, coral lagoons,
orchards, rooftop alleys, country fences, ancient ruins and flower gardens.
Later visits vary seasonal colours and planting patterns. Ground, entrance,
exit and level-picker colours follow the landscape. Image textures are bundled
offline; static scenery recordings are reused while characters move.


## Run

```sh
flutter pub get
flutter run
```

The standard entry point is `lib/main.dart`. The root `main.dart` also forwards to the same app.

## Competition on separate phones

Open **Competition · Play with friends**. Create a 2–4 player room and share its code, or use two-player Quick Match. Players ready up, start together, see live progress, and race to finish first. Both Basic and Animal Rescue boards are supported. The server validates every move and selects one winner; reconnecting restores the board.

Run the server from this repository:

```sh
dart run server/match_server.dart
```

Every phone needs the same reachable server address. A hosted WSS endpoint is needed for internet play. The full requirements, LAN testing instructions, Dockerfile, hosting setup, match rules, and current limitations are in [server/README.md](server/README.md).

```sh
flutter run --dart-define=MATCH_SERVER_URL=wss://YOUR_HOST/ws
```

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

`lib/game/puzzle_rules.dart` contains the shared board models and deterministic generator; `lib/game/puzzle.dart` manages solo state. Each arrow is placed with an unobstructed exit among existing arrows and reserved animal cells, so reverse placement order guarantees a solution. Rescue routes are initially blocked; after clearing the arrows, all waiting animals can escape. `lib/widgets/animal_avatar.dart` draws scalable animal portraits, `lib/widgets/puzzle_board.dart` draws and animates the board, `lib/screens/` provides the game hub and Arrow interface; `lib/number_games/` contains the arithmetic/Sudoku models and screens, and `lib/multiplayer/` contains the online client and competition screen.

## Temporary test access

All Basic, Animal Rescue, Math Crossword and Sudoku levels are currently accessible for app testing. Set `GameSettings.unlockAllLevelsForTesting` to `false` in `lib/config/game_settings.dart`, then hot restart, to restore sequential level locks. Stars and completed-level counts still reflect actual play. Multiplayer match rules are unchanged.

## Learning while playing

Math Crossword and Sudoku include a **Learn a thinking step** card. It first offers a prompt; **Explain the step** opens the reasoning without changing the board or spending a hint. Players can then try independently or explicitly choose **Place answer**, which uses one of the existing hints. **Check** reviews a misplaced entry with a rule or equation to reconsider.

Crossword coaching explains single-unknown equations and inverse operations. Sudoku coaching uses naked singles or hidden singles when supported by the current board. If a longer chain is needed, the explanation labels the answer as a full-solution hint. Wrong entries are reviewed before any new deduction is offered. These features practise the puzzle's arithmetic and logic skills; no IQ or cognitive-health score is generated.

## Distinct number-game interfaces

Math Crossword uses a warm workbook design with serif number tiles, free-standing arithmetic operators, round tray pieces, and a chapter-based level picker. Sudoku uses a blue focus banner, a sharp 3×3-box grid, a dedicated number dock with digit counts, and an Easy/Medium/Hard puzzle library. Both retain the existing puzzle rules, learning explanations and temporary unlocked-level setting.

## Number-game feedback and results

Math Crossword and Sudoku check each number immediately. A fixed feedback bar shows correct cells, wrong cells, empty cells, and cumulative mistakes. Its progress bar measures correct entries; printed clues are excluded. Pencil notes and hints do not count as mistakes. Repeating the same value in the same cell is ignored.

Three wrong placements end the attempt. Undo, Erase and later corrections update the board counts while keeping the cumulative mistake count. Completing every blank correctly opens a Success result; reaching the mistake limit opens a Try Again result. Both results show cell totals, mistakes, elapsed time and hints. Failed attempts can review a mistake and restart the same puzzle. Restarting or selecting a new level resets attempt counts.
