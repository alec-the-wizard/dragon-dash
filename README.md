# Dragon Dash Dungeons

An action bullet hell game.

You can play the most stable version [clicking here](https://alec-the-wizard.itch.io/dragon-dash).

## Development

The Defold project lives in `DragonDash/` (the folder containing `game.project`).

- `main` — platform-agnostic game code. No portal SDKs, dependencies, or settings.
- `playgama` — the same game plus the Playgama Bridge integration.
- `wavedash` — the same game plus the Wavedash SDK integration (cloud saves, `wavedash.toml`).

All platform SDK access goes through `DragonDash/main/platform.lua`. Game scripts never import a platform SDK directly, which keeps `main` buildable and runnable without any portal integration. See [AGENTS.md](AGENTS.md) for the interface and for guidance on adding a new platform.

## AI-assisted development

`AGENTS.md` and `.agents/skills/` contain Defold-specific instructions and skills adapted from [indiesoftby/defold-agent-config](https://github.com/indiesoftby/defold-agent-config) (CC0): API/manual/example fetching, proto and script editing, shader editing, project setup, and editor-based builds.

## Building

Open `DragonDash/game.project` in the Defold editor and build/run as usual. From an AI agent session, the `defold-project-build` skill builds through the running editor and returns compile errors.
