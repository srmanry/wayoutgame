import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/puzzle.dart';
import '../widgets/puzzle_board.dart';
import 'match_client.dart';

class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key, this.client});
  final MatchClient? client;
  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen>
    with WidgetsBindingObserver {
  late final MatchClient client = widget.client ?? MatchClient();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _endpoint = TextEditingController(
    text: const String.fromEnvironment('MATCH_SERVER_URL'),
  );
  GameMode _mode = GameMode.basic;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted &&
          (client.phase == 'countdown' || client.phase == 'racing')) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !client.connected) {
      client.reconnect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _name.dispose();
    _code.dispose();
    _endpoint.dispose();
    if (widget.client == null) client.dispose();
    super.dispose();
  }

  Future<bool> _canLeave() async {
    if (client.roomCode == null || client.phase == 'finished') return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave this match?'),
            content: const Text('Your place in this match will be forfeited.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _exit() async {
    if (!await _canLeave() || !mounted) return;
    await client.leave();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: client,
    builder: (context, _) => PopScope(
      canPop: client.roomCode == null || client.phase == 'finished',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FC),
          leading: IconButton(
            onPressed: _exit,
            tooltip: 'Back to solo',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Competition',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 7,
                    color: client.connected ? mint : const Color(0xFFB2BAC7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    client.connecting
                        ? 'Connecting'
                        : client.connected
                        ? 'Online'
                        : 'Offline',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7B8597),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (client.error != null) _error(),
                    if (client.roomCode == null)
                      _setup()
                    else if (client.phase == 'lobby')
                      _lobby()
                    else if (client.phase == 'finished')
                      _result()
                    else
                      _race(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _error() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDE8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.error!,
          style: const TextStyle(
            color: Color(0xFFA4543E),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (client.roomCode != null && !client.connected)
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: client.connecting ? null : client.reconnect,
                child: const Text('Reconnect'),
              ),
              TextButton(
                onPressed: client.leave,
                child: const Text('Leave room'),
              ),
            ],
          ),
      ],
    ),
  );

  Widget _setup() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.emoji_events_rounded,
        size: 52,
        color: Color(0xFFE8AA42),
      ),
      const SizedBox(height: 12),
      const Text(
        'One puzzle. One winner.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: ink,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Play from your own phones. Start together.\nBe the first to clear the puzzle or save every animal.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Color(0xFF7B8597), height: 1.6),
      ),
      const SizedBox(height: 24),
      _field(_name, 'Player name', maxLength: 20),
      const SizedBox(height: 12),
      SegmentedButton<GameMode>(
        segments: const [
          ButtonSegment(value: GameMode.basic, label: Text('Basic')),
          ButtonSegment(value: GameMode.rescue, label: Text('Animal Rescue')),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: client.connecting
            ? null
            : (value) => setState(() => _mode = value.single),
        style: SegmentedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
      const SizedBox(height: 18),
      ExpansionTile(
        initiallyExpanded: _endpoint.text.isEmpty,
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Match server',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _endpoint.text.isEmpty
              ? 'Set the shared server address to play online'
              : 'All players must use the same server',
          style: const TextStyle(fontSize: 11, color: Color(0xFF7B8597)),
        ),
        children: [
          _field(
            _endpoint,
            'WebSocket address',
            hint: 'wss://your-server/ws',
            keyboardType: TextInputType.url,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Use the hosted match server address. For a local test, use the computer’s LAN address on the same Wi-Fi.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF7B8597),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: client.connecting ? null : () => _enter('quick'),
        icon: const Icon(Icons.bolt_rounded),
        label: const Text('Quick Match · 2 players'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: client.connecting ? null : () => _enter('create'),
        icon: const Icon(Icons.group_add_outlined, size: 20),
        label: const Text('Create Room · 2–4 players'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
      ),
      const SizedBox(height: 24),
      _field(
        _code,
        'Room code',
        maxLength: 6,
        capitalization: TextCapitalization.characters,
        hint: 'ABC234',
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: client.connecting ? null : () => _enter('join'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
        child: const Text('Join Room'),
      ),
      const SizedBox(height: 20),
      const Text(
        'Same board • 3 hearts • No hints or restarts\nThe server validates moves. First confirmed finish wins.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFF929BAC), height: 1.7),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
  }) => TextField(
    controller: controller,
    maxLength: maxLength,
    enabled: !client.connecting,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    autocorrect: false,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
      ),
    ),
  );

  void _enter(String action) => client.enter(
    endpoint: _endpoint.text,
    name: _name.text,
    action: action,
    mode: _mode,
    code: _code.text,
  );

  Widget _lobby() {
    final allReady =
        client.players.length >= 2 &&
        client.players.every(
          (p) => p['ready'] == true && p['connected'] == true,
        );
    final ready = client.me?['ready'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Your squad is gathering.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 16),
        _card(
          Column(
            children: [
              const Text(
                'ROOM CODE',
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 10,
                  color: Color(0xFF7B8597),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                client.roomCode!,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: client.roomCode!),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room code copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copy code'),
              ),
              Text(
                '${client.state?['mode'] == 'rescue' ? 'Animal Rescue' : 'Basic'} · Level ${client.game?.level.number ?? 1}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7B8597)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...client.players.map((p) => _player(p, racing: false)),
        const SizedBox(height: 14),
        Text(
          client.state?['quick'] == true
              ? 'Quick Match starts when both players are ready.'
              : 'Share the code. Everyone readies up, then the host starts.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7B8597),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: client.connected ? () => client.ready(!ready) : null,
          icon: Icon(
            ready ? Icons.check_circle_rounded : Icons.sports_esports_rounded,
          ),
          label: Text(ready ? 'Ready! Tap to unready' : 'I’m ready'),
        ),
        if (client.isHost && client.state?['quick'] != true) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: client.connected && allReady ? client.start : null,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
            child: const Text('Start Match'),
          ),
        ],
        TextButton(
          onPressed: () async {
            if (await _canLeave()) await client.leave();
          },
          child: const Text('Leave room'),
        ),
      ],
    );
  }

  Widget _race() {
    final game = client.game;
    if (game == null) return const Center(child: CircularProgressIndicator());
    final counting = client.phase == 'countdown';
    final count = max(1, ((client.startAt - client.serverNow) / 1000).ceil());
    final limit = client.state?['limitMs'] as int? ?? 300000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'RACE TO THE FINISH',
                style: TextStyle(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const Icon(Icons.timer_outlined, color: accent, size: 18),
            const SizedBox(width: 5),
            Text(
              _time(max(0, limit - client.elapsedMs)),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...client.players.map((p) => _player(p, racing: true)),
        const SizedBox(height: 12),
        _card(
          Column(
            children: [
              Text(
                game.isRescue
                    ? 'Save every animal · ${game.rescued.length}/${game.level.rescue!.targets.length} safe'
                    : '${game.remaining.length} arrows left',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  AbsorbPointer(
                    absorbing: !client.canPlay,
                    child: PuzzleBoard(
                      key: ValueKey(client.roomCode),
                      game: game,
                      onArrow: (id) => client.move('arrow', id),
                      onRescue: (id) => client.move('rescue', id),
                    ),
                  ),
                  if (counting || game.isGameOver || !client.connected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  counting
                                      ? '$count'
                                      : game.isGameOver
                                      ? 'Out of hearts'
                                      : 'Reconnecting…',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: counting ? 64 : 23,
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  counting
                                      ? 'Same puzzle. Get ready!'
                                      : game.isGameOver
                                      ? 'Watch the remaining players race.'
                                      : 'Your board is saved on the server.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF7B8597),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          client.feedback ??
              (game.isRescue
                  ? 'Clear the mint paths, then tap the animals.'
                  : 'Tap clear arrows. Finish before your opponents.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7B8597),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No pause, hints, undo, or restart during a match.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Color(0xFF929BAC)),
        ),
      ],
    );
  }

  Widget _result() {
    final winnerId = client.state?['winnerId'];
    final winner = client.players.where((p) => p['id'] == winnerId).firstOrNull;
    final won = winnerId != null && winnerId == client.playerId;
    final ordered = [...client.players]
      ..sort((a, b) {
        if (a['id'] == winnerId) return -1;
        if (b['id'] == winnerId) return 1;
        return (b['progress'] as num).compareTo(a['progress'] as num);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        const Icon(
          Icons.emoji_events_rounded,
          size: 68,
          color: Color(0xFFE8AA42),
        ),
        const SizedBox(height: 16),
        Text(
          winner == null
              ? 'No winner this time.'
              : won
              ? 'You won!'
              : '${winner['name']} wins!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            color: ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          winner == null
              ? (client.state?['reason'] == 'timeout'
                    ? 'Time is up. Nobody finished the puzzle.'
                    : 'All players were eliminated or left.')
              : 'First to finish · ${_time(winner['finishMs'] as int)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7B8597), fontSize: 13),
        ),
        const SizedBox(height: 26),
        ...ordered.map((p) => _player(p, racing: true)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: client.leave,
          child: const Text('Play another match'),
        ),
        TextButton(onPressed: _exit, child: const Text('Back to solo')),
      ],
    );
  }

  Widget _player(Map<String, dynamic> p, {required bool racing}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: p['id'] == client.playerId
            ? accent.withValues(alpha: .35)
            : const Color(0xFFE5E9F0),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFEBEEFE),
              child: Text(
                (p['name'] as String).characters.first,
                style: const TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${p['name']}${p['id'] == client.playerId ? ' (you)' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              p['left'] == true
                  ? 'Left'
                  : p['connected'] != true
                  ? 'Reconnecting'
                  : racing
                  ? '${((p['progress'] as num) * 100).round()}% · ${p['lives']} ♥'
                  : p['ready'] == true
                  ? 'Ready'
                  : 'Waiting',
              style: TextStyle(
                fontSize: 11,
                color: p['ready'] == true || racing
                    ? mint
                    : const Color(0xFF929BAC),
              ),
            ),
          ],
        ),
        if (racing) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (p['progress'] as num).toDouble(),
              color: mint,
              backgroundColor: const Color(0xFFEDF1F5),
              minHeight: 4,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE5E9F0)),
    ),
    child: child,
  );
  String _time(int ms) =>
      '${(ms ~/ 60000).toString().padLeft(2, '0')}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}.${(ms % 1000 ~/ 100)}';
}
