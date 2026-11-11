-- main/platforms/playgama.lua
--
-- Playgama Bridge adapter.
--
-- Requires the bridge-defold dependency declared in game.project:
--   https://github.com/Playgama/bridge-defold/archive/refs/tags/v2.0.0.zip
--
-- This is the ONLY module allowed to require "bridge.bridge". Game code goes
-- through main/platform.lua instead.
--
-- Compatibility notes:
--   * v1.30 exposed page visibility on bridge.game and storage availability on
--     bridge.storage.is_available().
--   * v2.0 removed bridge.game and folds page visibility and ads into the
--     aggregated "pause_state_changed" event on bridge.platform.
-- The adapter probes for both shapes so the two SDK generations behave the same.

local bridge = require("bridge.bridge")
local fallback = require("main.platforms.none")

local M = {}

-- Playgama storage type used by v1.x. v2.x ignores the extra argument.
local STORAGE_TYPE = "local_storage"

-- Bridge is only active in the HTML5 build. On other platforms the Lua mock
-- of the SDK reports features as supported, so keep the check explicit.
local BRIDGE_READY = html5 ~= nil and bridge ~= nil

local function is_bridge_ready()
	return BRIDGE_READY
end

-- Lifecycle
-- Playgama aggregates interstitial/rewarded ads, page visibility, and platform
-- pauses into one pause state, so a single subscription is enough.

---@param callbacks table See main/platform.lua for the callback contract.
function M.init(callbacks)
	if not is_bridge_ready() then
		return
	end

	if callbacks.on_pause or callbacks.on_resume then
		bridge.platform.on("pause_state_changed", function (_, is_paused)
			if is_paused then
				if callbacks.on_pause then
					callbacks.on_pause()
				end
			else
				if callbacks.on_resume then
					callbacks.on_resume()
				end
			end
		end)
	end

	if callbacks.on_audio_enabled then
		bridge.platform.on("audio_state_changed", function (_, is_enabled)
			callbacks.on_audio_enabled(is_enabled)
		end)
	end

	-- Rewarded ads report "rewarded" when the player earned the reward and
	-- "closed" afterwards (which also resumes the game through pause state).
	bridge.advertisement.on("rewarded_state_changed", function (_, state)
		if state == "rewarded" and callbacks.on_rewarded then
			callbacks.on_rewarded()
		end
	end)
end

-- Readiness
-- Playgama expects "game_ready" once the game is actually interactive.

function M.ready()
	if not is_bridge_ready() then
		return
	end
	bridge.platform.send_message("game_ready")
end

-- Ads

M.ads = {}

---@return boolean
function M.ads.is_rewarded_supported()
	return is_bridge_ready() and bridge.advertisement.is_rewarded_supported()
end

---@return boolean
function M.ads.is_interstitial_supported()
	return is_bridge_ready() and bridge.advertisement.is_interstitial_supported()
end

function M.ads.show_rewarded()
	if M.ads.is_rewarded_supported() then
		bridge.advertisement.show_rewarded()
	end
end

function M.ads.show_interstitial()
	if M.ads.is_interstitial_supported() then
		bridge.advertisement.show_interstitial()
	end
end

-- Analytics / platform messages

M.analytics = {}

---@param event_name string "level_started", "level_completed", "player_got_achievement"
function M.analytics.send(event_name)
	if not is_bridge_ready() then
		return
	end
	bridge.platform.send_message(event_name)
end

-- Storage
-- Save data is a plain Lua table. Playgama serializes it to JSON, so nested
-- tables work; "unlocked_skins" is still written as a JSON string for
-- backwards compatibility with saves made before this adapter existed.

---@return boolean
local function is_storage_supported()
	if not is_bridge_ready() then
		return false
	end
	if bridge.storage.is_available then
		return bridge.storage.is_available("local_storage") or bridge.storage.is_available("internal_storage")
	end
	-- v2.x has no availability query; the storage API is always present.
	return bridge.storage.get ~= nil and bridge.storage.set ~= nil
end

M.storage = {}

---@return boolean Always true: Playgama storage falls back to the engine save file.
function M.storage.is_supported()
	return true
end

---@param data table
---@param on_success function|nil
---@param on_error function|nil
function M.storage.save(data, on_success, on_error)
	if not is_storage_supported() then
		fallback.storage.save(data, on_success, on_error)
		return
	end

	local payload = {}
	for key, value in pairs(data) do
		payload[key] = value
	end
	payload.unlocked_skins = json.encode(data.unlocked_skins)
	print("[platform] saving game to Playgama storage")
	bridge.storage.set(payload, on_success, on_error, STORAGE_TYPE)
end

---@param keys string[]
---@param on_success function Receives the loaded data table.
---@param on_error function|nil
function M.storage.load(keys, on_success, on_error)
	if not is_storage_supported() then
		fallback.storage.load(keys, on_success, on_error)
		return
	end

	bridge.storage.get(keys, function (_, data)
		data = data or {}
		-- Old saves stored the array as a JSON string. Decode it so the game
		-- always receives a table.
		if type(data.unlocked_skins) == "string" then
			local ok, decoded = pcall(json.decode, data.unlocked_skins)
			if ok and type(decoded) == "table" then
				data.unlocked_skins = decoded
			end
		end
		print("[platform] loaded game from Playgama storage")
		if on_success then
			on_success(data)
		end
	end, on_error, STORAGE_TYPE)
end

return M
