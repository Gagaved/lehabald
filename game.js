const canvas = document.querySelector("#game");
const ctx = canvas.getContext("2d");
const scoreEl = document.querySelector("#score");
const remainingEl = document.querySelector("#remaining");
const scoreLabelEl = document.querySelector("#score-label");
const remainingLabelEl = document.querySelector("#remaining-label");
const messageEl = document.querySelector("#message");
const restartButtons = document.querySelectorAll(".js-restart");
const trapButton = document.querySelector("#trap");
const lobbyEl = document.querySelector("#lobby");
const lobbyStatusEl = document.querySelector("#lobby-status");
const readyButton = document.querySelector("#ready");
const spectatorButton = document.querySelector("#spectate");
const roleButtons = document.querySelectorAll("[data-role]");

const tile = 32;
const assets = {
  0: loadImage("./assets/player-head.png"),
  1: loadImage("./assets/chaser-head.png"),
  powered: loadImage("./assets/leha-powered.png"),
  logo: loadImage("./assets/tiktok-logo.png"),
};

let socket;
let reconnectTimer = null;
let clientId = null;
let mySlot = 0;
let maze = [];
let walls = new Set();
let logos = [];
let traps = [];
let visiblePlayers = [];
let scores = [];
let trail = [];
let game = {
  phase: "waiting",
  timeLeftMs: 180_000,
  lehaPowered: false,
  powerLeftMs: 0,
};
let lobby = { roles: [], spectators: 0 };
let connectedPlayers = 0;
let statusText = "Подключение к серверу...";
let activeDirection = null;
const heldKeys = new Map();

const directions = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
};

function loadImage(src) {
  const image = new Image();
  image.src = src;
  return image;
}

function connect() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }

  const protocol = location.protocol === "https:" ? "wss:" : "ws:";
  socket = new WebSocket(`${protocol}//${location.host}/ws`);
  const activeSocket = socket;

  socket.addEventListener("open", () => {
    statusText = "Ожидание второго игрока...";
  });

  socket.addEventListener("message", (event) => {
    const data = JSON.parse(event.data);
    if (data.type === "state") applyState(data);
    if (data.type === "full") {
      statusText = "Сервер уже занят двумя игроками.";
      showMessage(statusText);
    }
  });

  socket.addEventListener("close", () => {
    if (socket !== activeSocket) return;
    statusText = "Связь потеряна. Переподключение...";
    showMessage(statusText);
    reconnectTimer = setTimeout(connect, 900);
  });
}

function applyState(data) {
  clientId = data.you.id;
  mySlot = data.you.slot;
  maze = data.maze;
  logos = data.logos;
  traps = data.traps || [];
  trail = data.trail || [];
  visiblePlayers = data.players;
  scores = data.scores;
  game = data.game || game;
  lobby = data.lobby || lobby;
  connectedPlayers = data.connectedPlayers;
  statusText = data.status;

  if (canvas.width !== data.cols * tile || canvas.height !== data.rows * tile) {
    canvas.width = data.cols * tile;
    canvas.height = data.rows * tile;
    rebuildWalls();
  }

  updateHud();
  updateLobby();

  if (statusText && game.phase !== "waiting") {
    showMessage(statusText);
  } else {
    messageEl.classList.add("hidden");
  }
}

function updateHud() {
  const isLeha = mySlot === 0;
  const isBakhirkin = mySlot === 1;
  const myScore = scores.find((score) => score.id === clientId)?.score ?? 0;
  scoreLabelEl.textContent = "Роль";
  scoreEl.textContent = isLeha ? `Леха ${myScore}` : isBakhirkin ? "Бахиркин" : "Наблюдатель";
  remainingLabelEl.textContent = isLeha ? "Время / TikTok" : isBakhirkin ? "Охота" : "Просмотр";

  const time = formatTime(game.timeLeftMs);
  trapButton.disabled = !(mySlot === 1 && game.phase === "playing" && game.trapAvailable);
  trapButton.textContent = "Капкан";
  if (mySlot === 1 && game.phase === "playing") {
    if (game.trapActive) {
      trapButton.textContent = "Капкан стоит";
    } else if ((game.trapCooldownMs ?? 0) > 0) {
      trapButton.textContent = `Капкан ${Math.ceil(game.trapCooldownMs / 1000)}с`;
    }
  }
  if (isLeha) {
    const power = game.lehaPowered ? ` BIG ${Math.ceil(game.powerLeftMs / 1000)}с` : "";
    remainingEl.textContent = `${time} / ${logos.length}${power}`;
  } else if (isBakhirkin) {
    remainingEl.textContent = time;
  } else {
    remainingEl.textContent = `${lobby.spectators ?? 0} зр.`;
  }
}

function updateLobby() {
  const waiting = game.phase === "waiting";
  lobbyEl.classList.toggle("hidden", !waiting);

  const myRole = mySlot === 0 ? "leha" : mySlot === 1 ? "bakhirkin" : "spectator";
  for (const button of roleButtons) {
    const roleState = lobby.roles?.find((role) => role.role === button.dataset.role);
    const mine = roleState?.playerId === clientId;
    button.disabled = Boolean(roleState?.taken && !mine) || game.phase === "playing";
    button.classList.toggle("selected", mine);
    button.textContent = `${button.dataset.role === "leha" ? "Леха" : "Бахиркин"}${roleState?.ready ? " ✓" : ""}`;
  }

  const myRoleState = lobby.roles?.find((role) => role.playerId === clientId);
  readyButton.disabled = !myRoleState || game.phase === "playing";
  readyButton.classList.toggle("ready", Boolean(myRoleState?.ready));
  readyButton.textContent = myRoleState?.ready ? "Готов: да" : "Готов";
  spectatorButton.disabled = myRole === "spectator" || game.phase === "playing";

  const leha = lobby.roles?.find((role) => role.role === "leha");
  const bakhirkin = lobby.roles?.find((role) => role.role === "bakhirkin");
  const readyText = (role) => {
    if (role?.ready) return "готов";
    if (role?.readyTimeoutMs !== null && role?.readyTimeoutMs !== undefined) {
      return `не готов, освободится через ${Math.ceil(role.readyTimeoutMs / 1000)}с`;
    }
    return "не готов";
  };
  const slotText = (role) => role?.taken ? readyText(role) : "свободен";
  lobbyStatusEl.textContent = myRole === "spectator"
    ? `Вы наблюдатель. Леха: ${slotText(leha)}, Бахиркин: ${slotText(bakhirkin)}.`
    : `Леха ${readyText(leha)}, Бахиркин ${readyText(bakhirkin)}. Наблюдатели: ${lobby.spectators ?? 0}.`;
}

function formatTime(ms) {
  const totalSeconds = Math.max(0, Math.ceil(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function rebuildWalls() {
  walls = new Set();
  for (let y = 0; y < maze.length; y += 1) {
    for (let x = 0; x < maze[y].length; x += 1) {
      if (maze[y][x] === "#") walls.add(key(x, y));
    }
  }
}

function key(x, y) {
  return `${x},${y}`;
}

function showMessage(text) {
  messageEl.textContent = text;
  messageEl.classList.remove("hidden");
}

function send(type, payload = {}) {
  if (!socket || socket.readyState !== WebSocket.OPEN) return;
  socket.send(JSON.stringify({ type, ...payload }));
}

function setDirection(name) {
  if (mySlot === null || game.phase !== "playing") return;
  if (!directions[name]) return;
  activeDirection = name;
  send("input", { direction: name });
}

function stopDirection(name = activeDirection) {
  if (mySlot === null) return;
  if (name && activeDirection && name !== activeDirection) return;
  activeDirection = null;
  send("stop");
}

function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawMaze();
  drawTrail();
  drawLogos();
  drawTraps();
  drawPlayers();
  requestAnimationFrame(draw);
}

function drawTraps() {
  for (const trap of traps) {
    const cx = trap.x * tile + tile / 2;
    const cy = trap.y * tile + tile / 2;
    const pulse = 0.55 + Math.sin(Date.now() / 140) * 0.2;

    ctx.save();
    ctx.strokeStyle = `rgba(255, 0, 80, ${0.55 + pulse * 0.28})`;
    ctx.fillStyle = "rgba(255, 0, 80, 0.18)";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(cx, cy, tile * 0.36, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.strokeStyle = "#f7fbff";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(cx - tile * 0.26, cy - tile * 0.08);
    ctx.lineTo(cx, cy + tile * 0.18);
    ctx.lineTo(cx + tile * 0.26, cy - tile * 0.08);
    ctx.stroke();
    ctx.restore();
  }
}

function drawTrail() {
  if (trail.length < 2) return;

  const orderedTrail = [...trail].sort((a, b) => a.alpha - b.alpha);
  ctx.save();
  ctx.lineCap = "round";
  ctx.lineJoin = "round";

  for (let i = 1; i < orderedTrail.length; i += 1) {
    const prev = orderedTrail[i - 1];
    const point = orderedTrail[i];
    const alpha = Math.min(prev.alpha ?? 0.5, point.alpha ?? 0.5);
    ctx.strokeStyle = `rgba(255, 0, 80, ${0.2 + alpha * 0.24})`;
    ctx.lineWidth = tile * (0.52 + alpha * 0.38);
    ctx.beginPath();
    ctx.moveTo(prev.x * tile, prev.y * tile);
    ctx.lineTo(point.x * tile, point.y * tile);
    ctx.stroke();
  }

  for (const point of orderedTrail) {
    const px = point.x * tile;
    const py = point.y * tile;
    const alpha = point.alpha ?? 0.6;
    const radius = tile * (0.55 + alpha * 0.55);

    const gradient = ctx.createRadialGradient(px, py, 1, px, py, radius);
    gradient.addColorStop(0, `rgba(255, 0, 80, ${0.5 * alpha})`);
    gradient.addColorStop(0.45, `rgba(255, 42, 72, ${0.28 * alpha})`);
    gradient.addColorStop(1, "rgba(255, 0, 80, 0)");
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(px, py, radius, 0, Math.PI * 2);
    ctx.fill();
  }

  ctx.restore();
}

function drawMaze() {
  ctx.fillStyle = "#090d17";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  for (let y = 0; y < maze.length; y += 1) {
    for (let x = 0; x < maze[y].length; x += 1) {
      if (!walls.has(key(x, y))) continue;
      const px = x * tile;
      const py = y * tile;
      const gradient = ctx.createLinearGradient(px, py, px + tile, py + tile);
      gradient.addColorStop(0, "#123869");
      gradient.addColorStop(1, "#071b3d");
      ctx.fillStyle = gradient;
      roundRect(px + 2, py + 2, tile - 4, tile - 4, 7);
      ctx.fill();
      ctx.strokeStyle = "rgba(0, 242, 234, 0.28)";
      ctx.lineWidth = 1;
      ctx.stroke();
    }
  }
}

function drawLogos() {
  for (const logo of logos) {
    const size = logo.power ? tile * 0.92 : tile * 0.5;
    const px = logo.x * tile + tile / 2 - size / 2;
    const py = logo.y * tile + tile / 2 - size / 2;
    if (logo.power) {
      const cx = logo.x * tile + tile / 2;
      const cy = logo.y * tile + tile / 2;
      const pulse = 0.5 + Math.sin(Date.now() / 160) * 0.18;
      const gradient = ctx.createRadialGradient(cx, cy, 2, cx, cy, tile * 0.86);
      gradient.addColorStop(0, `rgba(255, 255, 255, ${0.22 + pulse * 0.18})`);
      gradient.addColorStop(0.45, "rgba(0, 242, 234, 0.24)");
      gradient.addColorStop(1, "rgba(255, 0, 80, 0)");
      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.arc(cx, cy, tile * 0.86, 0, Math.PI * 2);
      ctx.fill();

      ctx.strokeStyle = `rgba(255, 0, 80, ${0.55 + pulse * 0.25})`;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(cx, cy, tile * 0.56, 0, Math.PI * 2);
      ctx.stroke();
    }

    if (assets.logo.complete) {
      ctx.drawImage(assets.logo, px, py, size, size);
    } else {
      ctx.fillStyle = "#fff";
      ctx.beginPath();
      ctx.arc(logo.x * tile + tile / 2, logo.y * tile + tile / 2, size / 3, 0, Math.PI * 2);
      ctx.fill();
    }
  }
}

function drawPlayers() {
  for (const player of visiblePlayers) {
    const isMe = player.id === clientId;
    const size = player.powered ? tile * 1.72 : (isMe ? tile * 1.08 : tile * 1.02);
    const image = player.powered ? assets.powered : assets[player.slot];
    drawHead(image, player.x, player.y, size, player.ghost ? 0.42 : 1);
  }
}

function drawHead(image, gridX, gridY, size, alpha = 1) {
  const px = gridX * tile;
  const py = gridY * tile;
  if (image.complete) {
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.drawImage(image, px - size / 2, py - size / 2, size, size);
    ctx.restore();
  }
}

function roundRect(x, y, width, height, radius) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.arcTo(x + width, y, x + width, y + height, radius);
  ctx.arcTo(x + width, y + height, x, y + height, radius);
  ctx.arcTo(x, y + height, x, y, radius);
  ctx.arcTo(x, y, x + width, y, radius);
  ctx.closePath();
}

const keyMap = {
  ArrowUp: "up",
  Up: "up",
  w: "up",
  W: "up",
  KeyW: "up",
  ArrowDown: "down",
  Down: "down",
  s: "down",
  S: "down",
  KeyS: "down",
  ArrowLeft: "left",
  Left: "left",
  a: "left",
  A: "left",
  KeyA: "left",
  ArrowRight: "right",
  Right: "right",
  d: "right",
  D: "right",
  KeyD: "right",
};

window.addEventListener("keydown", (event) => {
  if (event.code === "Space" || event.key === " ") {
    event.preventDefault();
    send("placeTrap");
    return;
  }

  if (event.code === "KeyE" || event.key === "e" || event.key === "E") {
    event.preventDefault();
    send("placeTrap");
    return;
  }

  const direction = keyMap[event.code] || keyMap[event.key];
  if (!direction) return;
  event.preventDefault();
  heldKeys.set(event.code || event.key, direction);
  setDirection(direction);
});

window.addEventListener("keyup", (event) => {
  const direction = keyMap[event.code] || keyMap[event.key];
  if (!direction) return;
  event.preventDefault();
  heldKeys.delete(event.code || event.key);
  const fallback = Array.from(heldKeys.values()).pop();
  if (fallback) {
    setDirection(fallback);
  } else {
    stopDirection(direction);
  }
});

window.addEventListener("blur", () => {
  heldKeys.clear();
  stopDirection();
});

document.querySelectorAll("[data-dir]").forEach((button) => {
  const start = (event) => {
    event.preventDefault();
    button.setPointerCapture?.(event.pointerId);
    setDirection(button.dataset.dir);
  };
  const stop = (event) => {
    event.preventDefault();
    stopDirection(button.dataset.dir);
  };

  button.addEventListener("pointerdown", start);
  button.addEventListener("pointerup", stop);
  button.addEventListener("pointercancel", stop);
  button.addEventListener("lostpointercapture", () => stopDirection(button.dataset.dir));
});

restartButtons.forEach((button) => {
  button.addEventListener("click", () => send("restart"));
});
trapButton.addEventListener("click", () => send("placeTrap"));

roleButtons.forEach((button) => {
  button.addEventListener("click", () => send("selectRole", { role: button.dataset.role }));
});

readyButton.addEventListener("click", () => {
  const myRoleState = lobby.roles?.find((role) => role.playerId === clientId);
  if (!myRoleState) return;
  send("ready", { ready: !myRoleState.ready });
});

spectatorButton.addEventListener("click", () => send("spectate"));

connect();
draw();
