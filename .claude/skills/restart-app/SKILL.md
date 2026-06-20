---
name: restart-app
description: ALWAYS use after editing Leha Bald code. Rebuilds the Flutter web front and/or restarts the Dart server so the running app matches the code on disk. Trigger after any change under client/ (frontend) or server/ + packages/shared/ (backend), and whenever the user says the app "didn't change", "still old", "не обновилось", "перезапусти", "пересобери", or reports behavior that contradicts a fix you just made.
---

# Restart Leha Bald after changes

The Dart server (`server/bin/server.dart`) serves **both** the WebSocket
endpoint (`/ws`) **and** the built Flutter web client (`client/build/web`) on one
port (default **4173**). Because the client is a *built artifact*, code edits are
NOT live — they only take effect after a rebuild/restart.

## The rule

After editing code, you MUST update the running app before testing or claiming a
change works. The browser shows a stale build until you do.

| You changed… | What's required |
| --- | --- |
| `client/**` (frontend) | rebuild web (`-Target front`), then refresh browser |
| `server/**` (backend) | restart server (`-Target back`) |
| `packages/shared/**` (DTOs/protocol) | both — it affects client and server |
| Not sure | do `-Target all` |

If you edited `packages/shared` DTO classes, also regenerate mappers first:
`cd packages/shared && fvm dart run build_runner build`.

## How to run it

Always use the project toolchain (fvm-pinned Flutter 3.41.7 — never the global
`C:\tools\flutter`, which is broken):

This machine has only Windows PowerShell 5.1 (no `pwsh`), so invoke with
`powershell`:

```powershell
powershell -ExecutionPolicy Bypass -File tools\dev.ps1                 # rebuild front + restart back (default)
powershell -ExecutionPolicy Bypass -File tools\dev.ps1 -Target front   # frontend changes only
powershell -ExecutionPolicy Bypass -File tools\dev.ps1 -Target back    # backend changes only
powershell -ExecutionPolicy Bypass -File tools\dev.ps1 -Port 4174      # alternate port
```

The script kills the process holding the port (and any lingering
`dart … server.dart`), starts the server detached, and waits until
`http://127.0.0.1:<port>/` answers HTTP 200. Server logs go to
`server/server.run.log` and `server/server.err.log`.

## After restarting

- For frontend changes the browser must be hard-refreshed (the server serves the
  new files but the page caches the old bundle). Tell the user to reload.
- Verify the server answered 200 (the script does this) before saying it's ready.
- Don't claim a fix is verifiable in the running app until the rebuild/restart
  has actually happened.
