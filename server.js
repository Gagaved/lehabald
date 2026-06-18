const http = require("http");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const os = require("os");

const port = Number(process.env.PORT || 4173);
const host = "0.0.0.0";
const root = __dirname;
const tickMs = 1000 / 60;
const roundDurationMs = 120_000;
const logoTimerReductionMs = 1_000;
const readyTimeoutMs = 30_000;
const powerDurationMs = 9_000;
const ghostDurationMs = 6_000;
const trapDurationMs = 10_000;
const trapCooldownMs = 10_000;
const trapStunMs = 1_000;
const baseSpeed = 4.41;
const turnWindow = 0.12;
const centerCrossBias = 0.000001;
const tunnelRows = new Set([4, 10, 20]);
const trailLifetimeMs = 2600;
const trailVisibilityRadius = 4;
const xrayRadius = 2;

const maze = [
  "#####################",
  "#.........#.........#",
  "#.###.###.#.###.###.#",
  "#o###.###.#.###.###o#",
  " ................... ",
  "#.###.#.#####.#.###.#",
  "#.....#...#...#.....#",
  "#####.### # ###.#####",
  "    #.#       #.#    ",
  "#####.# ## ## #.#####",
  "     .  #   #  .     ",
  "#####.# ##### #.#####",
  "    #.#       #.#    ",
  "#####.# ##### #.#####",
  "#.........#.........#",
  "#.###.###.#.###.###.#",
  "#o..#.....P.....#..o#",
  "###.#.#.#####.#.#.###",
  "#.....#...#...#.....#",
  "#.#######.#.#######.#",
  " ................... ",
  "#####################",
];
const blockedVoidSpaces = createBlockedVoidSpaces();

const starts = [
  { x: 10, y: 16 },
  { x: 10, y: 4 },
];
const startCells = new Set(starts.map((start) => `${start.x},${start.y}`));

const roles = ["leha", "bakhirkin"];
const superLogoCells = new Set(["1,3", "19,16", "10,20"]);

const directions = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
};

const mime = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".png": "image/png",
};

const clients = new Map();
let nextId = 1;
let logos = new Set();
let game = createGameState();

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const requestedPath = url.pathname === "/" ? "/index.html" : url.pathname;
  const filePath = path.normalize(path.join(root, requestedPath));

  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (error, content) => {
    if (error) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }

    res.writeHead(200, {
      "Content-Type": mime[path.extname(filePath)] || "application/octet-stream",
      "Cache-Control": "no-store",
    });
    res.end(content);
  });
});

server.on("upgrade", (req, socket) => {
  if (req.url !== "/ws") {
    socket.destroy();
    return;
  }

  acceptWebSocket(req, socket);
  const id = String(nextId);
  nextId += 1;

  const client = {
    id,
    slot: null,
    socket,
    buffer: Buffer.alloc(0),
    score: 0,
    role: "spectator",
    ready: false,
    readyTimeoutStartedAt: null,
    x: starts[0].x + 0.5,
    y: starts[0].y + 0.5,
    dir: { x: 0, y: 0 },
    nextDir: { x: 0, y: 0 },
    stopRequested: false,
    ghostUntil: 0,
    trapCooldownUntil: 0,
    stunnedUntil: 0,
    speed: baseSpeed,
  };

  clients.set(socket, client);
  socket.on("data", (chunk) => handleSocketData(client, chunk));
  socket.on("close", () => {
    clients.delete(socket);
    ensureRoundState();
    broadcastState();
  });
  socket.on("error", () => {
    clients.delete(socket);
    ensureRoundState();
    broadcastState();
  });
  ensureRoundState();
  broadcastState();
});

function acceptWebSocket(req, socket) {
  const key = req.headers["sec-websocket-key"];
  const accept = crypto
    .createHash("sha1")
    .update(`${key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11`)
    .digest("base64");

  socket.write([
    "HTTP/1.1 101 Switching Protocols",
    "Upgrade: websocket",
    "Connection: Upgrade",
    `Sec-WebSocket-Accept: ${accept}`,
    "",
    "",
  ].join("\r\n"));
}

function handleSocketData(client, chunk) {
  client.buffer = Buffer.concat([client.buffer, chunk]);

  while (client.buffer.length >= 2) {
    const secondByte = client.buffer[1];
    let offset = 2;
    let length = secondByte & 0x7f;

    if (length === 126) {
      if (client.buffer.length < 4) return;
      length = client.buffer.readUInt16BE(2);
      offset = 4;
    } else if (length === 127) {
      client.socket.end();
      return;
    }

    const masked = Boolean(secondByte & 0x80);
    const maskOffset = offset;
    const dataOffset = masked ? offset + 4 : offset;
    const frameLength = dataOffset + length;
    if (client.buffer.length < frameLength) return;

    const payload = client.buffer.subarray(dataOffset, frameLength);
    const message = Buffer.alloc(length);
    if (masked) {
      const mask = client.buffer.subarray(maskOffset, maskOffset + 4);
      for (let i = 0; i < length; i += 1) message[i] = payload[i] ^ mask[i % 4];
    } else {
      payload.copy(message);
    }

    client.buffer = client.buffer.subarray(frameLength);
    applyMessage(client, message.toString("utf8"));
  }
}

function applyMessage(client, raw) {
  let message;
  try {
    message = JSON.parse(raw);
  } catch {
    return;
  }

  if (message.type === "input" && directions[message.direction]) {
    if (client.slot === null || game.phase !== "playing") return;
    client.nextDir = { ...directions[message.direction] };
    client.stopRequested = false;
  }

  if (message.type === "stop") {
    if (client.slot === null) return;
    snapToCenter(client);
    client.dir = { x: 0, y: 0 };
    client.nextDir = { x: 0, y: 0 };
    client.stopRequested = false;
  }

  if (message.type === "selectRole") {
    selectRole(client, message.role);
  }

  if (message.type === "ready") {
    if (client.slot !== null) {
      client.ready = Boolean(message.ready);
      client.readyTimeoutStartedAt = null;
      ensureRoundState();
      broadcastState();
    }
  }

  if (message.type === "spectate") {
    becomeSpectator(client);
  }

  if (message.type === "placeTrap") {
    placeTrap(client);
  }

  if (message.type === "restart") {
    resetGame();
  }
}

function sendFrame(socket, text) {
  const payload = Buffer.from(text);
  const header = payload.length < 126
    ? Buffer.from([0x81, payload.length])
    : Buffer.from([0x81, 126, payload.length >> 8, payload.length & 0xff]);
  socket.write(Buffer.concat([header, payload]));
}

function resetGame() {
  logos = createLogos();
  game = createGameState();
  for (const client of clients.values()) {
    client.score = 0;
    client.ready = false;
    client.readyTimeoutStartedAt = null;
    const start = starts[client.slot ?? 0];
    client.x = start.x + 0.5;
    client.y = start.y + 0.5;
    client.dir = { x: 0, y: 0 };
    client.nextDir = { x: 0, y: 0 };
    client.stopRequested = false;
    client.ghostUntil = 0;
    client.trapCooldownUntil = 0;
    client.stunnedUntil = 0;
    client.speed = speedFor(client, Date.now());
  }
  ensureRoundState();
  broadcastState();
}

function createGameState() {
  return {
    phase: "waiting",
    startedAt: null,
    endedAt: null,
    winnerSlot: null,
    reason: "",
    lehaPowerUntil: 0,
    trap: null,
    trails: {
      0: [],
      1: [],
    },
  };
}

function selectRole(client, role) {
  if (game.phase !== "waiting") return;
  const slot = roles.indexOf(role);
  if (slot === -1) return;
  const occupied = [...clients.values()].some((other) => other !== client && other.slot === slot);
  if (occupied) return;

  client.slot = slot;
  client.role = roles[slot];
  client.ready = false;
  client.readyTimeoutStartedAt = null;
  client.score = 0;
  client.x = starts[slot].x + 0.5;
  client.y = starts[slot].y + 0.5;
  client.dir = { x: 0, y: 0 };
  client.nextDir = { x: 0, y: 0 };
  client.stopRequested = false;
  client.ghostUntil = 0;
  client.trapCooldownUntil = 0;
  client.stunnedUntil = 0;
  client.speed = speedFor(client, Date.now());
  ensureRoundState();
  broadcastState();
}

function becomeSpectator(client) {
  if (game.phase !== "waiting") return;
  client.slot = null;
  client.role = "spectator";
  client.ready = false;
  client.readyTimeoutStartedAt = null;
  client.score = 0;
  client.dir = { x: 0, y: 0 };
  client.nextDir = { x: 0, y: 0 };
  client.stopRequested = false;
  client.ghostUntil = 0;
  client.trapCooldownUntil = 0;
  client.stunnedUntil = 0;
  ensureRoundState();
  broadcastState();
}

function placeTrap(client) {
  const now = Date.now();
  if (game.phase !== "playing" || client.slot !== 1 || game.trap || isGhost(client, now)) return;
  if (now < client.trapCooldownUntil) return;
  const cell = centerCell(client);
  if (isWall(cell.x, cell.y)) return;
  game.trap = {
    x: cell.x,
    y: cell.y,
    placedAt: now,
    expiresAt: now + trapDurationMs,
  };
  broadcastState();
}

function lobbyState() {
  return {
    roles: roles.map((role, slot) => {
      const player = [...clients.values()].find((client) => client.slot === slot);
      return {
        role,
        slot,
        taken: Boolean(player),
        ready: Boolean(player?.ready),
        playerId: player?.id ?? null,
        readyTimeoutMs: readyTimeoutFor(player),
      };
    }),
    spectators: [...clients.values()].filter((client) => client.slot === null).length,
  };
}

function readyTimeoutFor(player) {
  if (!player || player.ready || player.readyTimeoutStartedAt === null) return null;
  return Math.max(0, readyTimeoutMs - (Date.now() - player.readyTimeoutStartedAt));
}

function releaseSlot(client) {
  client.slot = null;
  client.role = "spectator";
  client.ready = false;
  client.readyTimeoutStartedAt = null;
  client.score = 0;
  client.dir = { x: 0, y: 0 };
  client.nextDir = { x: 0, y: 0 };
  client.stopRequested = false;
  client.ghostUntil = 0;
  client.trapCooldownUntil = 0;
  client.stunnedUntil = 0;
}

function enforceReadyTimeout(now) {
  if (game.phase !== "waiting") return;
  const players = roles.map((_, slot) => [...clients.values()].find((client) => client.slot === slot));
  if (players.some((player) => !player)) {
    for (const player of players) {
      if (player) player.readyTimeoutStartedAt = null;
    }
    return;
  }
  for (const player of players) {
    if (player.ready) {
      player.readyTimeoutStartedAt = null;
      continue;
    }
    player.readyTimeoutStartedAt ??= now;
    if (now - player.readyTimeoutStartedAt >= readyTimeoutMs) {
      releaseSlot(player);
    }
  }
}

function ensureRoundState() {
  const activePlayers = [...clients.values()].filter((client) => client.slot !== null);
  const hasBothRoles = activePlayers.some((client) => client.slot === 0) &&
    activePlayers.some((client) => client.slot === 1);
  const bothReady = hasBothRoles && activePlayers
    .filter((client) => client.slot === 0 || client.slot === 1)
    .every((client) => client.ready);

  if (!hasBothRoles || !bothReady) {
    if (game.phase !== "ended") {
      game.phase = "waiting";
      game.startedAt = null;
    }
    return;
  }

  if (game.phase === "waiting") {
    game.phase = "playing";
    game.startedAt = Date.now();
    game.endedAt = null;
    game.winnerSlot = null;
    game.reason = "";
    game.lehaPowerUntil = 0;
    game.trap = null;
    game.trails = { 0: [], 1: [] };
    const bakhirkin = findPlayer(1);
    if (bakhirkin) {
      bakhirkin.ghostUntil = 0;
      bakhirkin.trapCooldownUntil = 0;
      bakhirkin.stunnedUntil = 0;
    }
    const leha = findPlayer(0);
    if (leha) leha.stunnedUntil = 0;
  }
}

function createLogos() {
  const nextLogos = new Set();
  for (let y = 0; y < maze.length; y += 1) {
    for (let x = 0; x < maze[y].length; x += 1) {
      const cell = maze[y][x];
      const logoKey = `${x},${y}`;
      if (!startCells.has(logoKey) && (cell === "." || superLogoCells.has(logoKey))) {
        nextLogos.add(logoKey);
      }
    }
  }
  return nextLogos;
}

function gameTick() {
  ensureRoundState();
  const now = Date.now();
  enforceReadyTimeout(now);
  if (game.phase !== "playing") {
    broadcastState();
    return;
  }

  expireTrap(now);
  for (const client of clients.values()) {
    if (client.slot === null) continue;
    updatePlayerState(client, now);
    movePlayer(client, tickMs / 1000);
    if (client.slot === 0) collectLogo(client);
  }

  const leha = findPlayer(0);
  const bakhirkin = findPlayer(1);
  if (leha) updateTrail(leha, now);
  if (bakhirkin) updateTrail(bakhirkin, now);
  resolveCollision(leha, bakhirkin, now);
  resolveTrap(leha, now);
  if (game.phase === "playing" && game.startedAt && now - game.startedAt >= roundDurationMs) {
    endGame(0, "Леха продержался 2 минуты.");
  }

  broadcastState();
}

function movePlayer(player, dt) {
  if (Date.now() < player.stunnedUntil) {
    snapToCenter(player);
    player.dir = { x: 0, y: 0 };
    player.nextDir = { x: 0, y: 0 };
    player.stopRequested = false;
    return;
  }

  const distance = player.speed * dt;

  if (player.dir.x === 0 && player.dir.y === 0) {
    snapToCenter(player);
    if (canMoveFrom(player, player.nextDir)) player.dir = { ...player.nextDir };
    return;
  }

  snapPerpendicularAxis(player);
  tryTurn(player);

  const before = { x: player.x, y: player.y };
  player.x += player.dir.x * distance;
  player.y += player.dir.y * distance;

  if (crossedCellCenter(before, player)) {
    snapToCenter(player);
    if (player.stopRequested) {
      player.dir = { x: 0, y: 0 };
      player.nextDir = { x: 0, y: 0 };
      player.stopRequested = false;
      return;
    }
    if (!canMoveFrom(player, player.dir)) {
      player.dir = { x: 0, y: 0 };
    }
    tryTurn(player);
  }

  wrapTunnel(player);
}

function updatePlayerState(player, now) {
  const wasGhost = isGhost(player, now - tickMs);
  const ghost = isGhost(player, now);
  if (player.slot === 1 && wasGhost && !ghost) {
    respawnBakhirkin(player);
  }
  player.speed = speedFor(player, now);
}

function speedFor(player, now) {
  if (player.slot === 0) return now < game.lehaPowerUntil ? baseSpeed * 1.2 : baseSpeed;
  if (player.slot === 1) return baseSpeed * 1.1;
  return baseSpeed;
}

function collectLogo(player) {
  const cell = centerCell(player);
  const logoKey = `${cell.x},${cell.y}`;
  if (!logos.has(logoKey)) return;
  logos.delete(logoKey);
  player.score += 10;
  if (game.phase === "playing" && game.startedAt) {
    game.startedAt -= logoTimerReductionMs;
  }
  if (superLogoCells.has(logoKey)) {
    game.lehaPowerUntil = Date.now() + powerDurationMs;
  }
}

function updateTrail(player, now) {
  const trail = game.trails[player.slot] || [];
  const last = trail[trail.length - 1];
  if (last && Math.hypot(last.x - player.x, last.y - player.y) < 0.12) {
    last.x = Number(player.x.toFixed(3));
    last.y = Number(player.y.toFixed(3));
    last.at = now;
    return;
  }

  trail.push({
    x: Number(player.x.toFixed(3)),
    y: Number(player.y.toFixed(3)),
    at: now,
  });
  game.trails[player.slot] = trail.filter((point) => now - point.at <= trailLifetimeMs);
}

function resolveCollision(leha, bakhirkin, now) {
  if (!leha || !bakhirkin) return;
  if (isGhost(bakhirkin, now)) return;
  const distance = Math.hypot(leha.x - bakhirkin.x, leha.y - bakhirkin.y);
  if (distance > 0.62) return;

  if (now < game.lehaPowerUntil) {
    killBakhirkin(bakhirkin, now);
  } else {
    endGame(1, "Бахиркин поймал Леху.");
  }
}

function expireTrap(now) {
  if (game.trap && now >= game.trap.expiresAt) {
    clearTrap(now);
  }
}

function resolveTrap(leha, now) {
  if (!leha || !game.trap || now >= game.trap.expiresAt) return;
  const cell = centerCell(leha);
  if (cell.x === game.trap.x && cell.y === game.trap.y) {
    leha.stunnedUntil = now + trapStunMs;
    leha.dir = { x: 0, y: 0 };
    leha.nextDir = { x: 0, y: 0 };
    leha.stopRequested = false;
    clearTrap(now);
  }
}

function clearTrap(now) {
  game.trap = null;
  const bakhirkin = findPlayer(1);
  if (bakhirkin) bakhirkin.trapCooldownUntil = now + trapCooldownMs;
}

function killBakhirkin(bakhirkin, now) {
  bakhirkin.ghostUntil = now + ghostDurationMs;
  bakhirkin.dir = { x: 0, y: 0 };
  bakhirkin.nextDir = { x: 0, y: 0 };
  bakhirkin.stopRequested = false;
}

function respawnBakhirkin(bakhirkin) {
  bakhirkin.x = starts[1].x + 0.5;
  bakhirkin.y = starts[1].y + 0.5;
  bakhirkin.dir = { x: 0, y: 0 };
  bakhirkin.nextDir = { x: 0, y: 0 };
  bakhirkin.stopRequested = false;
  bakhirkin.ghostUntil = 0;
}

function isGhost(player, now = Date.now()) {
  return player.slot === 1 && now < player.ghostUntil;
}

function findPlayer(slot) {
  return [...clients.values()].find((client) => client.slot === slot);
}

function endGame(winnerSlot, reason) {
  game.phase = "ended";
  game.endedAt = Date.now();
  game.winnerSlot = winnerSlot;
  game.reason = reason;
}

function centerCell(player) {
  return {
    x: Math.floor(player.x),
    y: Math.floor(player.y),
  };
}

function snapToCenter(player) {
  player.x = Math.floor(player.x) + 0.5;
  player.y = Math.floor(player.y) + 0.5;
}

function snapPerpendicularAxis(player) {
  if (player.dir.x !== 0) player.y = Math.floor(player.y) + 0.5;
  if (player.dir.y !== 0) player.x = Math.floor(player.x) + 0.5;
}

function tryTurn(player) {
  if (player.nextDir.x === 0 && player.nextDir.y === 0) return;
  if (player.nextDir.x === player.dir.x && player.nextDir.y === player.dir.y) return;
  const centerX = Math.floor(player.x) + 0.5;
  const centerY = Math.floor(player.y) + 0.5;
  const wantsVertical = player.nextDir.y !== 0;
  const wantsHorizontal = player.nextDir.x !== 0;
  const alignedForTurn = wantsVertical
    ? Math.abs(player.x - centerX) <= turnWindow
    : Math.abs(player.y - centerY) <= turnWindow;

  if (!alignedForTurn || !canMoveFrom(player, player.nextDir)) return;
  snapToCenter(player);
  player.dir = { ...player.nextDir };
}

function crossedCellCenter(before, player) {
  if (player.dir.x !== 0) {
    const centerX = Math.floor(before.x + player.dir.x * (0.5 + centerCrossBias)) + 0.5;
    return player.dir.x < 0 ? player.x <= centerX : player.x >= centerX;
  }

  if (player.dir.y !== 0) {
    const centerY = Math.floor(before.y + player.dir.y * (0.5 + centerCrossBias)) + 0.5;
    return player.dir.y < 0 ? player.y <= centerY : player.y >= centerY;
  }

  return false;
}

function wrapTunnel(player) {
  if (!tunnelRows.has(Math.floor(player.y))) return;
  if (player.x < -0.35) player.x = maze[0].length + 0.35;
  if (player.x > maze[0].length + 0.35) player.x = -0.35;
}

function canMoveFrom(player, dir) {
  if (dir.x === 0 && dir.y === 0) return false;
  const cell = centerCell(player);
  if (isGhost(player)) {
    const nextX = cell.x + dir.x;
    const nextY = cell.y + dir.y;
    return nextX >= 0 && nextX < maze[0].length && nextY >= 0 && nextY < maze.length;
  }
  return !isWall(cell.x + dir.x, cell.y + dir.y);
}

function isWall(x, y) {
  if (tunnelRows.has(y) && (x < 0 || x >= maze[0].length)) return false;
  const wrappedX = tunnelRows.has(y) ? (x + maze[0].length) % maze[0].length : x;
  if (wrappedX < 0 || wrappedX >= maze[0].length) return true;
  if (y < 0 || y >= maze.length) return true;
  const cell = maze[y][wrappedX];
  if (cell === "#") return true;
  if (cell === " " && blockedVoidSpaces.has(`${wrappedX},${y}`)) return true;
  return false;
}

function createBlockedVoidSpaces() {
  const blocked = new Set();
  const queue = [];
  const enqueue = (x, y) => {
    const cellKey = `${x},${y}`;
    if (blocked.has(cellKey) || tunnelRows.has(y) || maze[y]?.[x] !== " ") return;
    blocked.add(cellKey);
    queue.push({ x, y });
  };

  for (let x = 0; x < maze[0].length; x += 1) {
    enqueue(x, 0);
    enqueue(x, maze.length - 1);
  }
  for (let y = 0; y < maze.length; y += 1) {
    enqueue(0, y);
    enqueue(maze[0].length - 1, y);
  }

  while (queue.length) {
    const { x, y } = queue.shift();
    for (const dir of [{ x: 0, y: -1 }, { x: 0, y: 1 }, { x: -1, y: 0 }, { x: 1, y: 0 }]) {
      enqueue(x + dir.x, y + dir.y);
    }
  }

  return blocked;
}

function broadcastState() {
  const now = Date.now();
  for (const client of clients.values()) {
    const visiblePlayers = [...clients.values()]
      .filter((player) => player.slot !== null)
      .filter((player) => client.slot === null || player === client || canSeePlayer(client, player, now))
      .map(serializePlayer);

    const status = statusFor(client);
    const role = client.role;
    const isLeha = client.slot === 0;
    const timeLeftMs = game.startedAt && game.phase === "playing"
      ? Math.max(0, roundDurationMs - (now - game.startedAt))
      : roundDurationMs;
    const state = {
      type: "state",
      you: { id: client.id, slot: client.slot, role },
      rows: maze.length,
      cols: maze[0].length,
      maze,
      logos: visibleLogosFor(client).map((logoKey) => {
        const [x, y] = logoKey.split(",").map(Number);
        return { x, y, power: superLogoCells.has(logoKey) };
      }),
      traps: visibleTrapsFor(client, now),
      trail: trailForClient(client, now),
      players: visiblePlayers,
      scores: [...clients.values()].map((player) => ({
        id: player.id,
        slot: player.slot,
        role: roles[player.slot],
        score: player.score,
      })),
      connectedPlayers: clients.size,
      lobby: lobbyState(),
      game: {
        phase: game.phase,
        winnerSlot: game.winnerSlot,
        reason: game.reason,
        timeLeftMs,
        lehaPowered: now < game.lehaPowerUntil,
        powerLeftMs: Math.max(0, game.lehaPowerUntil - now),
        trapAvailable: client.slot === 1 &&
          game.phase === "playing" &&
          !game.trap &&
          !isGhost(client, now) &&
          now >= client.trapCooldownUntil,
        trapCooldownMs: client.slot === 1
          ? Math.max(0, client.trapCooldownUntil - now)
          : 0,
        trapActive: Boolean(game.trap),
      },
      status,
    };

    sendFrame(client.socket, JSON.stringify(state));
  }
}

function visibleLogosFor(client) {
  if (client.slot === null) return [...logos];
  if (client.slot === 0) return [...logos];
  return [...logos].filter((logoKey) => superLogoCells.has(logoKey));
}

function visibleTrapsFor(client, now) {
  if (!game.trap || now >= game.trap.expiresAt) return [];
  if (client.slot === null) return [{ ...game.trap }];
  const viewerCell = centerCell(client);
  const trapCell = { x: game.trap.x, y: game.trap.y };
  if (!hasCellLineOfSight(viewerCell, trapCell)) return [];
  return [{ ...game.trap }];
}

function serializePlayer(player) {
  const now = Date.now();
  return {
    id: player.id,
    slot: player.slot,
    role: roles[player.slot],
    x: Number(player.x.toFixed(3)),
    y: Number(player.y.toFixed(3)),
    score: player.score,
    powered: player.slot === 0 && now < game.lehaPowerUntil,
    ghost: isGhost(player, now),
  };
}

function statusFor(client) {
  if (game.phase === "waiting") return "Выберите персонажей и нажмите готовность.";
  if (game.phase === "ended") {
    const side = game.winnerSlot === 0 ? "Леха выиграл" : "Бахиркин выиграл";
    const personal = client.slot === null
      ? "Вы наблюдатель."
      : game.winnerSlot === client.slot ? "Ты выиграл." : "Ты проиграл.";
    return `${side}. ${game.reason} ${personal} Нажми ↻ для новой игры.`;
  }
  return "";
}

function trailForClient(viewer, now) {
  if (viewer.slot === null) return [];
  const sourceSlot = viewer.slot === 1 ? 0 : 1;
  if (viewer.slot === 0 && now >= game.lehaPowerUntil) return [];

  return trailPointsForSlot(sourceSlot, now)
    .filter((point) => canViewerSeeTrailPoint(viewer, point));
}

function trailPointsForSlot(slot, now) {
  return (game.trails[slot] || [])
    .map((point) => ({
      x: point.x,
      y: point.y,
      ageMs: now - point.at,
    }))
    .filter((point) => point.ageMs <= trailLifetimeMs)
    .map((point) => ({
    x: point.x,
    y: point.y,
    alpha: Math.max(0.12, 1 - point.ageMs / trailLifetimeMs),
  }));
}

function canViewerSeeTrailPoint(viewer, point) {
  const viewerCell = centerCell(viewer);
  const trailCell = {
    x: Math.floor(point.x),
    y: Math.floor(point.y),
  };

  if (Math.hypot(viewerCell.x - trailCell.x, viewerCell.y - trailCell.y) <= trailVisibilityRadius) {
    return true;
  }

  return hasCellLineOfSight(viewerCell, trailCell);
}

function hasCellLineOfSight(cellA, cellB) {
  if (cellA.y === cellB.y) {
    const from = Math.min(cellA.x, cellB.x) + 1;
    const to = Math.max(cellA.x, cellB.x);
    for (let x = from; x < to; x += 1) {
      if (isWall(x, cellA.y)) return false;
    }
    return true;
  }

  if (cellA.x === cellB.x) {
    const from = Math.min(cellA.y, cellB.y) + 1;
    const to = Math.max(cellA.y, cellB.y);
    for (let y = from; y < to; y += 1) {
      if (isWall(cellA.x, y)) return false;
    }
    return true;
  }

  return false;
}

function hasLineOfSight(a, b) {
  return hasCellLineOfSight(centerCell(a), centerCell(b));
}

function canSeePlayer(viewer, target, now) {
  if (viewer.slot === 1 && isGhost(viewer, now) && target.slot === 0) return true;
  if (viewer.slot === 0 && target.slot === 1 && isGhost(target, now)) return true;
  if (hasXrayVisibility(viewer, target)) return true;
  return hasLineOfSight(viewer, target);
}

function hasXrayVisibility(a, b) {
  const cellA = centerCell(a);
  const cellB = centerCell(b);
  return Math.max(Math.abs(cellA.x - cellB.x), Math.abs(cellA.y - cellB.y)) <= xrayRadius;
}

function lanAddresses() {
  return Object.values(os.networkInterfaces())
    .flat()
    .filter((entry) => entry && entry.family === "IPv4" && !entry.internal)
    .map((entry) => `http://${entry.address}:${port}/`);
}

resetGame();
setInterval(gameTick, tickMs);
server.listen(port, host, () => {
  console.log(`Local: http://127.0.0.1:${port}/`);
  for (const address of lanAddresses()) console.log(`LAN:   ${address}`);
});
