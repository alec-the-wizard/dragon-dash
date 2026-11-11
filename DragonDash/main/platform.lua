-- main/platform.lua
--
-- Platform abstraction facade.
--
-- Game code (scripts, GUI scripts, other modules) talks ONLY to this module.
-- Everything that depends on a specific portal, SDK, or distribution platform
-- lives in an implementation under main/platform/.
--
-- When adding a platform:
--   1. Copy main/platform/none.lua to main/platform/<platform>.lua.
--   2. Implement the interface documented below.
--   3. Point IMPLEMENTATION at the new module.
--   4. Add the SDK dependency/settings only on that platform's branch.
--
-- Interface
-- ---------
--   platform.init(callbacks)
--     Wires up SDK lifecycle events. `callbacks` may contain:
--       on_pause()                 game should freeze (ad opened, page hidden, ...)
--       on_resume()                game may continue
--       on_audio_enabled(enabled)  platform-wide audio switch
--       on_rewarded()              a rewarded ad completed successfully
--
--   platform.ads
--     is_rewarded_supported() -> boolean
--     is_interstitial_supported() -> boolean
--     show_rewarded()            -> success is reported through on_rewarded
--     show_interstitial()
--
--   platform.storage
--     is_supported() -> boolean
--     save(data, on_success, on_error)       data is a plain Lua table
--     load(keys, on_success, on_error)        on_success receives a table
--
--   platform.analytics
--     send(event_name)
--       Game events: "game_ready", "level_started", "level_completed",
--       "player_got_achievement".
--
-- Implementations must not post messages to screens and must not reference
-- screen IDs. main.script translates platform callbacks into game messages.

-- The single line to change when enabling a platform integration.
-- It must name a module under main/platform/.
local IMPLEMENTATION = "main.platform.none"

local impl = require(IMPLEMENTATION)

local M = {
	ads = impl.ads,
	storage = impl.storage,
	analytics = impl.analytics,
}

---@param callbacks table Lifecycle callbacks (see the header comment).
function M.init(callbacks)
	if impl.init then
		impl.init(callbacks)
	end
end

return M
