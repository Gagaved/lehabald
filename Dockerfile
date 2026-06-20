# syntax=docker/dockerfile:1

# --- Stage 1: build the Flutter web client ---
FROM ghcr.io/cirruslabs/flutter:3.41.7 AS client
WORKDIR /app
# shared is a path dependency of the client (../packages/shared)
COPY packages/shared packages/shared
COPY client client
WORKDIR /app/client
RUN flutter pub get
RUN flutter build web --release

# --- Stage 2: compile the Dart server to a native binary ---
FROM dart:stable AS server
WORKDIR /app
COPY packages/shared packages/shared
COPY server server
WORKDIR /app/server
RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/server/server_bin

# --- Stage 3: minimal runtime image ---
FROM scratch
# Shared libs needed by AOT-compiled Dart binaries (provided by dart:stable)
COPY --from=server /runtime/ /
COPY --from=server /app/server/server_bin /app/server/server_bin
# The server resolves the web client at ../client/build/web relative to its cwd
COPY --from=client /app/client/build/web /app/client/build/web
WORKDIR /app/server
ENV PORT=4173
EXPOSE 4173
CMD ["/app/server/server_bin"]
