-- main/platform/none.lua
--
-- Default platform implementation: no SDK, no ads, no analytics.
-- Uses the engine's own save file for persistence.
--
-- Copy this file when adding a new platform integration and implement the
-- same interface. See main/platform.lua for the contract.

local M = {}

local SAVE_FILE = sys.get_save_file("dragon_dash_dungeons", "save_file")

-- Ads
-- There is no ad provider on the default platform, so every ad entry point
-- reports "not supported". Game code checks these before showing ad UI.

M.ads = {}

---@return boolean
function M.ads.is_rewarded_supported()
	return false
end

---@return boolean
function M.ads.is_interstitial_supported()
	return false
end

function M.ads.show_rewarded()
	-- No ad provider. Nothing to do.
end

function M.ads.show_interstitial()
	-- No ad provider. Nothing to do.
end

-- Storage
-- Stores the complete save table in the Defold save directory. The engine
-- handles serialization, so no platform storage is needed.

M.storage = {}

---@return boolean
function M.storage.is_supported()
	return true
end

---@param data table Plain table with the game state to persist.
---@param on_success function|nil
---@param on_error function|nil
function M.storage.save(data, on_success, on_error)
	print("[platform] saving game to " .. SAVE_FILE)
	if sys.save(SAVE_FILE, data) then
		if on_success then
			on_success()
		end
	else
		print("[platform] failed to save game")
		if on_error then
			on_error()
		end
	end
end

---@param keys string[]|nil Keys requested by the game. Ignored here: the whole file is loaded.
---@param on_success function Receives the loaded data table.
---@param on_error function|nil
function M.storage.load(keys, on_success, on_error)
	local data = sys.load(SAVE_FILE)
	print("[platform] loaded game from " .. SAVE_FILE)
	if on_success then
		on_success(data)
	end
end

-- Analytics
-- Nothing to report to on the default platform. Keep the log so game events
-- are still visible in the console.

M.analytics = {}

---@param event_name string One of the game events documented in main/platform.lua.
function M.analytics.send(event_name)
	print("[platform] event: " .. event_name)
end

-- Lifecycle
-- The engine does not pause the game when the window loses focus, so the
-- default implementation has no lifecycle wiring.

---@param callbacks table See main/platform.lua for the available callbacks.
function M.init(callbacks)
	-- No lifecycle events to wire up.
end

return M
