# Agent Instructions — Dragon Dash Dungeons

A browser-first (HTML5) bullet-hell game made with the **Defold** engine, prepared for ad-supported web game platforms.

The repository root contains the Defold project in `DragonDash/`. The folder that holds `game.project` (`DragonDash/`) is the **Defold project root** — all Defold commands and relative resource paths are relative to it. Agent tooling (`AGENTS.md`, `.agents/`) lives in the Git repository root.

## Project map

- **Defold project root**: `DragonDash/`
  - `game.project` — project config (display, html5, dependencies, app manifest).
  - `main/` — bootstrap collection (`main.collection`), `main.script` (screen/proxy coordinator), `global.lua` (shared game state + save/load), `device.lua` (platform/OS detection helper).
  - `main/platform.lua` — **platform abstraction facade** (see below).
  - `main/platforms/` — platform SDK adapters (`none.lua` on all branches, `playgama.lua` only on the `playgama` branch).
  - `scenes/` — screens, each a collection with its own `.script` / `.gui_script` (`battle`, `main_menu`, `results`, `eggs`, `skins`, `upgrades`).
  - `components/` — reusable game objects (bosses, bullets, particles, collectables, parallax, player bullet).
  - `assets/` — images, atlases, fonts, sounds, shaders, materials.
  - `res/` — web bundle resources (`bundle_resources`), used only by the Playgama branch for `res/web/playgama-bridge-config.json`.
  - `default.appmanifest` — excluded engine libs per platform.
- **AI tooling**: `AGENTS.md`, `.agents/skills/` (skills adapted from [indiesoftby/defold-agent-config](https://github.com/indiesoftby/defold-agent-config), CC0).
- **Dependencies**: `DragonDash/.deps/` (gitignored, read-only context). Created by the `defold-project-setup` skill.

Key `game.project` settings:

- Bootstrap collection: `/main/main.collection`
- `script.shared_state = 1` — all scripts and GUI scripts share one Lua context, so modules are singleton-like.
- Display: 1280x720, high dpi, dynamic orientation.
- `bundle_resources = /res` (Playgama branch only).

**Resource paths** in `game.project` use Defold resource identifiers. A trailing `c` suffix denotes a compiled resource and is expected (`/main/main.collectionc`).

## Branches

- `main` — platform-agnostic. **No platform SDK library, dependency, setting, or import.**
- `playgama` — `main` plus the existing [Playgama Bridge](https://github.com/Playgama/bridge-defold) integration: `game.project` dependency, `htmlfile = /bridge/engine_template.html`, `bundle_resources = /res`, `res/web/playgama-bridge-config.json`, and `main/platforms/playgama.lua`.

Do not add SDK code or platform settings to `main`. Do platform-specific work on the matching platform branch.

## Platform abstraction (IMPORTANT)

Game code must never `require` a platform SDK directly. Everything platform-specific is behind `main/platform.lua`:

```lua
local platform = require("main.platform")
```

### Interface

| Member | Function | Contract |
|---|---|---|
| `platform.init(callbacks)` | sets up SDK event wiring | `callbacks` may contain `on_pause`, `on_resume`, `on_audio_enabled(is_enabled)`, `on_rewarded` |
| `platform.ads.is_rewarded_supported()` | boolean | whether a rewarded ad can be shown |
| `platform.ads.is_interstitial_supported()` | boolean | whether an interstitial ad can be shown |
| `platform.ads.show_rewarded()` | — | show rewarded ad; success arrives through `on_rewarded` |
| `platform.ads.show_interstitial()` | — | show interstitial ad |
| `platform.storage.is_supported()` | boolean | whether platform storage is available |
| `platform.storage.save(data, on_success, on_error)` | — | persist a plain Lua table of save data |
| `platform.storage.load(keys, on_success, on_error)` | — | load save data; `on_success(data)` receives a table |
| `platform.analytics.send(event_name)` | — | send a game event to the platform |

Documented `analytics.send` event names: `game_ready`, `level_started`, `level_completed`, `player_got_achievement`.

### Rules for platform code

1. Only modules under `main/platforms/` may require an SDK (`bridge.bridge`, extension modules, etc.).
2. Match the interface above exactly; the game code in `main/` and `scenes/` depends on it.
3. Platform implementations emit **generic events through the callbacks** passed to `init()`. They must not `msg.post()` to screens or know screen IDs — `main.script` owns that translation.
4. Keep implementations tolerant of missing SDK features: return `false` from `is_*_supported()` instead of erroring, and fall back to the `none` implementation when the SDK is unavailable.
5. Never hardcode `html5`/platform checks in game code. Platform detection belongs in the implementation.

### Adding a platform

1. Copy `main/platforms/none.lua` to `main/platforms/<platform>.lua`.
2. Implement the interface; wrap the SDK's events into `callbacks.on_pause`, `on_resume`, `on_audio_enabled`, `on_rewarded`.
3. Change the single static `require()` near the top of `main/platform.lua` from `"main.platforms.none"` to `"main.platforms.<platform>"`.
4. Add the SDK dependency/settings only on that platform branch (never on `main`).

`none.lua` is the reference implementation: no ads, no analytics, and save/load via `sys.save` / `sys.load`.

## Dependencies and `.deps/`

- Run the `defold-project-setup` skill after changing dependency URLs. From the repository root:

  ```powershell
  cd DragonDash
  python ../.agents/skills/defold-project-setup/scripts/fetch_deps.py
  ```

- `.deps/` is an include directory for resolving modules and dependency APIs.
- **NEVER modify anything inside `.deps/`** — it is generated, read-only context.
- `.deps/**` is gitignored but deliberately kept visible to search tools via `.ignore` / `.cursorignore`.

## Defold file formats

- **Lua**: `.lua`, `.script`, `.gui_script`, `.render_script`, `.editor_script`.
- **Metadata assets** (Protobuf Text Format): `.collection`, `.go`, `.sprite`, `.tilemap`, `.tilesource`, `.atlas`, `.font`, `.particlefx`, `.sound`, `.label`, `.gui`, `.model`, `.mesh`, `.material`, `.collisionobject`, `.texture_profiles`, `.display_profiles`.
- **Manifests** (YAML): `.appmanifest`, `.manifest`.
- **Buffers** (JSON): `.buffer`.
- **Shaders** (GLSL): `.vp`, `.fp`, `.glsl`.
- **Project config** (INI): `game.project`.
- **2D assets**: `.png`, `.jpg`. **Sound**: `.ogg`, `.wav`.

When creating or editing a Defold asset file, load the matching `defold-*-editing` skill **before** writing it.

## Code style guidelines

### Lua (`.lua`, `.script`, `.gui_script`, `.render_script`)

- **Indentation**: 1 tab. **Naming**: `snake_case` for variables, functions, files, and folders.
- **Comments**: LuaCATS (`---@...`) annotations for public module APIs; `print()` for transactions, initialization, and important events.
- Empty lines must be truly empty; no trailing whitespace.
- Follow the documented Defold API only. Use `defold-api-fetch` for signatures, `defold-docs-fetch` for concepts, `defold-examples-fetch` for patterns.
- **No metatables or class emulation.** Functional, data-based structures only.
- **Script instance state** lives in `self`, never in module-level locals (locals are shared by all instances).
- **Local functions** only at module scope. Inline anonymous callbacks are fine.
- `require("module.path")` — always parentheses, dot notation, no leading slash (`require("main.global")`).
- **Hash values**: inline `hash("...")` is fine; promote to `UPPER_CASE` constants only when reused.
- **GUI separation**: GUI scripts should not reach into game logic; prefer message-based communication (`msg.post()`), with `main.script` as the coordinator.
- `msg.url` format: `[socket:][path][#fragment]`; shorthands `.` and `#` are relative to the sender.

### Git

- Commit messages: short English description only.

## Build and validation

- Build through the running Defold editor with the `defold-project-build` skill (reads `DragonDash/.internal/editor.port`, POSTs to `/command/build`).
- Validation checklist: the editor build succeeds with no errors, and the game launches from the bootstrap collection.
- Do not commit `.internal/`, `build/`, `.editor_settings/`, or `.deps/`.
