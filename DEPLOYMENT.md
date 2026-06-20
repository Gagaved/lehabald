# Деплой и инфраструктура

Как Leha Bald хостится и выкатывается в прод.

## Обзор

| Что | Где |
|-----|-----|
| Игра (прод) | http://37.230.168.117:4173 |
| Хостинг | Yandex Cloud — одна виртуальная машина (Compute Cloud), Ubuntu |
| Рантайм | один Docker-контейнер `lehabald` |
| Репозиторий | https://github.com/Gagaved/lehabald |
| CI/CD | GitHub Actions, триггер по тегу `v*.*.*` |
| Уведомления | Telegram-бот `@lehabald_notifier_bot` в тред группы |

## Архитектура

Один Dart-процесс делает всё сразу на порту **4173**:

- отдаёт собранный Flutter-web клиент (статику);
- держит игровой WebSocket на `/ws`.

Клиент сам вычисляет адрес сокета из origin страницы (`ws://<host>:<port>/ws`),
поэтому фронт и бэк живут на одном адресе — никакой отдельной настройки URL,
CORS или mixed-content не требуется. Фронт и бэк запечены в **один** Docker-образ.

```
Браузер ──HTTP──>  :4173  ──>  Dart-сервер  ──>  отдаёт client/build/web
        ──WS────>  :4173/ws ─>               ──>  игровой движок
```

## Docker

Многоступенчатый [`Dockerfile`](Dockerfile):

1. **client** — образ Flutter собирает `flutter build web --release`.
2. **server** — образ Dart компилирует сервер в нативный бинарник (`dart compile exe`).
3. **runtime** — финальный `scratch`-образ (~98 МБ): только бинарник + статика, без SDK.

Локальный запуск:

```bash
docker compose up -d --build   # собрать и поднять
docker compose logs -f         # логи
docker compose down            # остановить
```

## CI/CD — выкат по тегу

Workflow [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) срабатывает
на push тега вида `vX.Y.Z` и делает:

1. собирает Docker-образ;
2. сохраняет в файл и заливает по SSH на ВМ (`docker save | gzip` → `scp`);
3. на сервере: `docker load`, пересоздаёт контейнер `lehabald`, чистит старый образ;
4. шлёт уведомление в Telegram (успех/падение).

### Как выкатить релиз

Тег можно повесить на любой коммит — едет именно он.

**Автоматический changelog (из коммитов):**
```bash
git tag v1.0.2
git push origin v1.0.2
```

**Своё описание релиза (аннотированный тег):**
```bash
git tag -a v1.0.2 -m "Добавил порталы, починил лаги"
git push origin v1.0.2
```

Прогон виден во вкладке **Actions**. Повторно тот же тег не сработает.

### Секреты GitHub

`Settings → Secrets and variables → Actions`. Значения в репозиторий не коммитятся.

| Имя | Назначение |
|-----|------------|
| `SSH_PRIVATE_KEY` | приватный SSH-ключ для входа на ВМ |
| `SSH_HOST` | IP виртуальной машины |
| `SSH_USER` | пользователь на ВМ |
| `TG_BOT_TOKEN` | токен Telegram-бота |
| `TG_CHAT_ID` | id группы (со знаком `-`) |
| `TG_THREAD_ID` | id треда (топика) для уведомлений |

## Telegram-уведомления

Бот `@lehabald_notifier_bot` пишет в заданный тред группы. Сообщение об успехе
содержит номер версии, changelog и ссылку на игру; при падении — ссылку на логи прогона.

Чтобы бот мог писать в тред: он должен быть участником группы, а `TG_THREAD_ID`
указывает на нужный топик. Аватарка бота ставится вручную через @BotFather
(`/mybots → Edit Bot → Edit Botpic`) — Bot API это не умеет.

## Управление на сервере

Доступ: `ssh <SSH_USER>@<SSH_HOST>` с приватным ключом.

```bash
sudo docker ps                 # что запущено
sudo docker logs -f lehabald   # логи в реальном времени
sudo docker restart lehabald   # перезапуск
sudo docker stop lehabald      # остановить
```

Контейнер запущен с `--restart unless-stopped` — поднимается сам после перезагрузки
ВМ и после падения. Сервис управляется через Docker (старый вариант на systemd
отключён).

## TODO / на будущее

- HTTPS + домен (сейчас голый `http://IP`): DNS-зона → домен на IP, поставить Caddy
  (автоматический Let's Encrypt) перед контейнером.
