# Flame client architecture

The server remains authoritative. The client converts each network snapshot
into a Flame Component System (FCS) tree and interpolates only presentation.

## Current tree

```text
LehaBaldGame
├── CameraComponent (Flame default; world migration is pending)
├── World (Flame default; world migration is pending)
├── GameSceneComponent
│   ├── LegacyTerrainComponent       priority 0
│   ├── PortalLayerComponent         priority 10
│   │   └── PortalComponent(s)       PositionComponent + ScaleEffect
│   └── LegacyActorsComponent        priority 20
└── GameInputController              KeyboardHandler
```

## Rules

- `LehaBaldGame` owns shared assets and top-level lifecycle only.
- Network DTO reconciliation belongs to a layer component.
- A persistent visual/game entity is a `Component`, usually a
  `PositionComponent`; it must not become another branch in the game renderer.
- Appearance/disappearance uses Flame effects and component lifecycle.
- Keyboard focus and propagation stay inside Flame (`KeyboardHandler`).
- Flutter overlays remain Flutter widgets; world entities remain Flame
  components.
- Per-frame render methods should reuse paints and vectors where practical.

## Roadmap: убираем legacy и ручной код

Цель — удалить `_LegacyTerrainComponent` и `_LegacyActorsComponent` и вынести
все ~25 `_drawX`-методов и состояние из `LehaBaldGame` в компоненты FCS.
Делаем семействами сущностей, по одному за слайс, чтобы тесты и сборка
оставались зелёными после каждого шага.

### Фаза 0 — фундамент (делать первым, разблокирует остальное)

- **Камера/мир.** Перенести `_GameSceneComponent` под типизированный `World`,
  а ручной `_layout` (fit + центрирование + `_hudInset`) заменить на
  `CameraComponent` с `FixedResolutionViewport`/`FixedAspectRatioViewport` и
  `viewfinder`. HUD-инсет задаётся `Viewport.margin`/смещением `viewfinder`.
  Это снимает ручной `scale.setAll(fit)` и `position.setValues(...)`.
- **Мировые координаты.** После камеры дети работают в координатах
  tile→pixel через `anchor: Anchor.center` и `position`, а не через ручные
  `(x + 0.5) * tile` в каждом painter'е.
- **Палитру** (`_palette`, `_paletteBiome`, `_paletteSeed`, `_syncPalette`)
  вынести в отдельный сервис/компонент `BiomeTheme`, чтобы painter'ы и
  будущие компоненты брали цвета оттуда, а не из `game`.

### Фаза 1 — игроки и интерполяция

- `PlayerComponent extends PositionComponent with HasPaint`.
- Спрайт головы — `SpriteComponent`/`Sprite` вместо ручного `_drawImage`
  (`canvas.drawImageRect`). `_imageForPlayer`/`_sizeForPlayer` → выбор Sprite
  и `size` компонента.
- Сглаживание (`_updatePlayerSmoothing`, `_PlayerRenderState`) остаётся
  кастомным (экстраполяция по скорости — оправдана), но живёт внутри
  `PlayerComponent`; снап-телепорт — мгновенная установка `position`, обычное
  движение — лерп в `update`. Реконсиляция DTO→компонент по `player.id`
  (как уже сделано для порталов в `_PortalLayerComponent`).
- Оверлеи игрока (`_drawStun`, `_drawFacingIndicator`, кольцо
  `invulnerable`, ghost-прозрачность) — дочерние компоненты или
  `OpacityEffect`/`ColorEffect` на `HasPaint`.
- Femboy-аура и сердечки (`_drawFemboyAura`, `_drawHearts`) → дочерний
  `ParticleSystemComponent` + пульс через `ScaleEffect` с бесконечным
  альтернирующим `EffectController` вместо `sin(DateTime.now())`.

### Фаза 2 — актёры (traps, barrels, mummies, illusions, collectibles)

- Каждое семейство — свой reconciled layer по образцу
  `_PortalLayerComponent`, дети — `PositionComponent`/`SpriteComponent`.
- Бочка (`_drawBarrels`): ручной `canvas.save/rotate/restore` → свойство
  `angle` у `PositionComponent` (опц. `RotateEffect`).
- Иллюзии (`_drawIllusions`) переиспользуют `PlayerComponent` с пониженным
  `opacity`.
- Логотипы/рафаэлки/клатч (`_drawLogos`, `_drawClutch`) — `SpriteComponent`
  с ростом через `ScaleEffect`.
- Триггер-вспышки ловушек (`_drawTraps`) — `ParticleSystemComponent` или
  `CircleComponent` с `ScaleEffect`+`OpacityEffect`.

### Фаза 3 — статический terrain

- Стены/фон (`_drawBoard`), трещины (`_drawCrackedWalls`), кусты
  (`_drawBushes`), декор биома: это статика на карту — перерисовывать каждый
  кадр расточительно. Запекать один раз в `dart:ui` `Picture`/`Image`
  (через `PictureRecorder`) при смене карты/биома и рисовать как
  `SpriteComponent`. Перестраивать только когда меняется `maze`/`stoneSeed`.
- Анимированный «живой» terrain (споры `_drawSpores`, магические цепи
  `_drawMagicChains`, кристаллы, химы `_drawChimes`) остаётся динамическим —
  перевести в `ParticleSystemComponent` (см. список ниже).

### Фаза 4 — финал

- Удалить `_LegacyTerrainComponent` и `_LegacyActorsComponent`.
- `LehaBaldGame` сводится к загрузке ассетов, камере и lifecycle; `render()`
  больше не содержит `_drawX`. Состояние (`_renderPlayers`, `_palette`,
  `_visualTime`) уезжает в соответствующие компоненты/сервисы.
- `_visualTime` заменить на `game.currentTime()`/локальный таймер компонента.

## Что делаем вручную, а есть инструмент Flame

| Сейчас вручную | Инструмент Flame |
| --- | --- |
| `_layout`: fit-scale, центрирование, `_hudInset` | `CameraComponent` + `Viewport` (`FixedResolutionViewport`) + `viewfinder` |
| `(x+0.5)*tile` смещения по всему коду | `anchor: Anchor.center` + мировые координаты |
| `_drawImage` (`canvas.drawImageRect`) | `SpriteComponent` / `Sprite` |
| `canvas.save/rotate` для бочки | свойство `angle` у `PositionComponent` |
| Прозрачность ghost/иллюзий в `Paint` | `HasPaint` + `opacity` / `OpacityEffect` |
| Пульс/мигание через `sin(DateTime.now())` (аура, химы, химы-кольца, waiting-портал) | `ScaleEffect`/`OpacityEffect`/`ColorEffect` с бесконечным альтернирующим `EffectController` |
| Вращение портала через `_visualTime` | `RotateEffect` (infinite) или `angle += spin*dt` |
| Партиклы вручную: `_drawSpores`, `_drawTrail`, `_drawHearts`, `_drawChimes`, burst кристаллов | `ParticleSystemComponent` + `Particle` (`CircleParticle`, `MovingParticle`, `AcceleratedParticle`, `ComputedParticle`) |
| `MaskFilter.blur` для свечения в Paint | `PaintDecorator.blur` / decorator на компоненте |
| `_visualTime += dt`, `DateTime.now()` для фаз анимаций | `game.currentTime()`, `Timer`/`TimerComponent`, `dt` в `update` |
| Ручная реконсиляция DTO для каждого семейства | паттерн `_PortalLayerComponent` (map по id) — обобщить в `ReconciledLayer<TDto>` |
| Кэш статической карты отсутствует (рисуем каждый кадр) | запечь в `Picture`/`Image` через `PictureRecorder`, рисовать `SpriteComponent` |
| Клавиатура (есть) | `KeyboardHandler` — готово |
| Тач-управление (нет, но нужно для мобилок) | `JoystickComponent` + `HudButtonComponent`; `TapCallbacks`/`DragCallbacks` |

### О хиттестах и хитбоксах

Коллизии на клиенте сейчас **не нужны** — сервер авторитетен по
геймплею, поэтому `HasCollisionDetection`/`CircleHitbox`/`RectangleHitbox`
для физики заводить не стоит (это была бы дублирующая логика).

Где хиттест реально пригодится — **ввод**, особенно тач:

- `TapCallbacks` / `DragCallbacks` на компонентах вместо ручного разбора
  координат — например tap-to-move или тап по способности.
- `camera.viewfinder.globalToLocal` / `componentsAtPoint` — перевод точки
  экрана в мир и поиск компонента под пальцем.
- `HudButtonComponent` для кнопок способностей (space/E/Q/C/F сейчас только
  с клавиатуры) и `JoystickComponent` для направления на телефоне.

То есть хитбоксы вводим только под интеракцию (`Hitbox` нужен
`TapCallbacks`/`DragCallbacks` для определения попадания), а не под
симуляцию столкновений.
