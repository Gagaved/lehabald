# Dart + Flutter Flame migration

Проект разложен на три части:

- `packages/shared` - общий JSON-протокол и DTO на `dart_mappable`.
- `server` - авторитетный Dart WebSocket backend.
- `client` - Flutter Flame клиент.

Старые `server.js`, `index.html`, `game.js`, `styles.css` оставлены на месте как рабочая HTML-версия.

## Генерация mapper-файлов

`dart_mappable` требует build step:

```bash
cd /Users/ignatmorozov/Documents/LehaBald/packages/shared
fvm dart pub get
fvm dart run build_runner build
```

## Запуск Dart-сервера

```bash
cd /Users/ignatmorozov/Documents/LehaBald/server
fvm dart pub get
fvm dart run bin/server.dart
```

Если порт занят:

```bash
PORT=4174 fvm dart run bin/server.dart
```

## Запуск Flutter Flame клиента

```bash
cd /Users/ignatmorozov/Documents/LehaBald/client
fvm flutter pub get
fvm flutter run -d chrome --dart-define=SERVER_URL=ws://127.0.0.1:4173/ws
```

Для телефона в локальной сети нужно указать LAN IP сервера:

```bash
fvm flutter run --dart-define=SERVER_URL=ws://10.53.213.23:4173/ws
```

## Архитектура

- `GameEngine` владеет правилами игры и состоянием матча.
- `MazeService` владеет стенами, тоннелями, xray и line-of-sight.
- `GameServer` владеет только HTTP/WebSocket транспортом.
- `GameNetworkClient` владеет сетевым подключением Flutter-клиента.
- `LehaBaldGame` только рендерит snapshot и отправляет ввод.
- `GameOverlay` содержит Flutter UI: лобби, HUD, кнопки, мобильное управление.

## Атрибуция ассетов

Иконки капкана, портала и паутины — на основе работ автора **Lorc** с
[game-icons.net](https://game-icons.net), лицензия **CC BY 3.0**
(перекрашены и отрендерены в PNG).
