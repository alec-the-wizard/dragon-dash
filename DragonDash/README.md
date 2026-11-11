# Dragon Dash Dungeons — Defold project

This folder is the Defold project root: open `game.project` in the Defold editor.

- Entry point: `main/main.collection`
- Shared game state and save/load: `main/global.lua`
- Screen/proxy coordinator: `main/main.script`
- Platform abstraction: `main/platform.lua` and `main/platform/`
- Screens: `scenes/` — reusable game objects: `components/`

Platform SDKs are isolated behind `main/platform.lua`. See the repository-level `AGENTS.md` for the platform interface, branch layout, and AI tooling.
