FROM dart:stable AS build
WORKDIR /app
COPY server/match_server.dart server/match_server.dart
COPY lib/game/puzzle_rules.dart lib/game/puzzle_rules.dart
COPY lib/game/level_themes.dart lib/game/level_themes.dart
COPY lib/multiplayer/race_rules.dart lib/multiplayer/race_rules.dart
RUN dart compile exe server/match_server.dart -o /app/match-server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/match-server /app/match-server
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app/match-server"]
