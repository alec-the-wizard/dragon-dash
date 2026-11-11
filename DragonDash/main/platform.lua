-- main/platform.lua
--
-- Platform abstraction facade.
--
-- Game code (scripts, GUI scripts, other modules) talks ONLY to this module.
-- Everything that depends on a specific portal, SDK, or distribution platform
-- lives in an implementation under main/platforms/.
--
-- When adding a platform:
--   1. Copy main/platforms/none.lua to main/platforms/<platform>.lua.
--   2. Implement the interface documented below.
--   3. Change the single require() below to the new module.
--   4. Add the SDK dependency/settings only on that platform's branch.
--
-- Note: the require() must stay static (a literal module name). Defold only
-- bundles Lua modules that are statically reachable from a script, so a
-- dynamically built module name would not be included in the build.
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
--   platform.ready()
--     Called once, when the first screen is loaded and the game is actually
--     interactive. Use it to dismiss platform loading screens or report
--     readiness. SDKs that must be initialized before async calls can do so
--     earlier, in init().
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
--       Game events: "level_started", "level_completed",
--       "player_got_achievement".
--
-- Implementations must not post messages to screens and must not reference
-- screen IDs. main.script translates platform callbacks into game messages.

-- The single line to change when enabling a platform integration.
-- Keep the module name literal: Defold only bundles statically required Lua.
local impl = require("main.platforms.playgama")

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

-- Called once the first screen is loaded and the game is interactive.
function M.ready()
	if impl.ready then
		impl.ready()
	end
end

return M
