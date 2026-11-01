# Real-time competition server

Players use their own phones and connect to the same WebSocket server. Private rooms support 2–4 players. Quick Match pairs two waiting players of the same mode. No bots or simulated opponents are used.

## Run locally

From the project root, with the Dart SDK installed:

```sh
dart run server/match_server.dart
```

The server binds `0.0.0.0:8080`, supports `PORT`, and exposes `/health` and `/ws`. It runs without Flutter or third-party server packages.

For two physical phones on the same Wi-Fi, run the server on a computer, allow inbound TCP port 8080, and use `ws://COMPUTER_LAN_IP:8080/ws` on **both** phones. `localhost` on a phone refers to that phone. Android debug builds allow cleartext LAN testing; release builds should use a hosted `wss://` address.

Open **Competition · Play with friends**, enter a name and the server address, and choose Quick Match or Create Room. The other player enters the same server address and room code. Everyone taps Ready; the private room host taps Start Match. Quick Match starts when both players are ready.

## Host for internet play

Build this repository with the Dockerfile at `server/Dockerfile`, using the repository root as the build context:

```sh
docker build -f server/Dockerfile -t arrow-match .
docker run --rm -p 8080:8080 -e PORT=8080 arrow-match
```

Deploy the container to a host supporting long-lived WebSockets. Route HTTPS/WSS traffic to its configured `PORT`, preserve the `/ws` path, enable WebSocket upgrades, and use a proxy idle timeout longer than five minutes. Set a health check to `/health`.

Use **one running instance**: active room state lives in this process. Autoscaling to multiple independent instances will separate players into different room registries. A process restart clears rooms and active matches. Durable rooms, account authentication, cross-instance pub/sub, moderation, and ranked matchmaking are future work.

Configure the app's default address at build/run time:

```sh
flutter run --dart-define=MATCH_SERVER_URL=wss://YOUR_HOST/ws
flutter build apk --dart-define=MATCH_SERVER_URL=wss://YOUR_HOST/ws
flutter build web --dart-define=MATCH_SERVER_URL=wss://YOUR_HOST/ws
```

Both clients must use the same deployed server. An HTTPS web app needs `wss://`; browsers block insecure mixed-content sockets. The app's Match server field also permits setting the address manually.

**No public server has been deployed by this change.** Internet matches require provisioning hosting and configuring its public WSS address. No Firebase project, paid account, database, or secret is embedded in the app.

## Match rules

- Everyone receives the exact same board serialized by the server, including animal positions.
- At least two connected players must be Ready before the common countdown starts.
- The server rejects moves before the start and after the match ends.
- Each player gets three hearts. A blocked action costs one. No pause, hints, undo, restart, or level changes are allowed in a competition.
- The server checks every arrow/animal action and computes progress itself. Clients cannot submit a finish time or declare a winner.
- The first valid completion **received and verified by the server** wins. Messages are processed serially, so one winner is selected even for near-simultaneous finishes. Network latency can affect close races.
- If nobody finishes within five minutes, or everyone is eliminated/leaves, the match ends without a winner.
- A dropped connection has a 30-second reconnection grace period. A per-player secret token restores the authoritative board and sequence counter. Tokens remain in the running app's memory; fully closing the app loses the session.
- Disconnecting during countdown cancels the countdown and requires players to ready up again. A disconnected lobby host is replaced after the grace period. Leaving forfeits the place.
- Basic and Animal Rescue solo progress is independent of online matches.

The service includes message size/rate and room/connection limits. Server validation prevents forged finish events and invalid moves; it does not prevent automated solvers or provide identity-based anti-cheat.

## Verify

```sh
flutter test test/match_server_test.dart
```

These tests use real loopback WebSockets, independent player connections, both board modes, Quick Match, ready checks, room capacity, duplicate sequence rejection, credential-protected reconnection, and the actual Flutter client controller.
