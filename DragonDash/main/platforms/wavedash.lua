-- main/platforms/wavedash.lua
--
-- Wavedash SDK adapter.
--
-- Requires the Wavedash SDK for Defold dependency declared in game.project:
--   https://github.com/wvdsh/sdk-defold/archive/refs/tags/1.3.1.zip
--
-- This is the ONLY module allowed to touch the `wavedash` global. Game code
-- goes through main/platform.lua instead.
--
-- Wavedash notes:
--   * wavedash.init() is mandatory: it dismisses the Wavedash loading screen
--     and must run before any async SDK call. It is called from init().
--   * Cloud saves live in the SDK's own local file store plus remote files.
--     They are unrelated to the engine's sys.save() files.
--   * Async SDK calls must run inside a coroutine; this adapter wraps them.
--   * Wavedash does not serve rewarded or interstitial ads.

local fallback = require("main.platforms.none")

local M = {}

local SAVE_FILE = "saves/dragon_dash_dungeons.json"

-- Achievement identifiers must be created in the Wavedash Developer Portal.
-- Set this to the identifier of the "beat the game" achievement to enable it;
-- leave nil to only log the event.
local GAME_BEATEN_ACHIEVEMENT = nil -- e.g. "GAME_BEATEN"

local IS_HTML5 = html5 ~= nil
local sdk_checked = false
local sdk_present = false

-- The Lua binding exists in every HTML5 build with the dependency, but the
-- JavaScript SDK is only injected when the game runs on Wavedash (or through
-- `wavedash dev`). Detect the injected SDK so HTML5 builds served elsewhere
-- fall back to the engine save file instead of throwing in JS.
local function is_sdk_available()
	if not sdk_checked then
		sdk_checked = true
		if IS_HTML5 and _G.wavedash ~= nil then
			local ok, result = pcall(html5.run, "typeof window.Wavedash !== 'undefined'")
			sdk_present = ok and result == "true"
		end
	end
	return sdk_present
end

local function run_async(body)
	local co = coroutine.create(body)
	local ok, err = coroutine.resume(co)
	if not ok then
		print("[platform] Wavedash async error: " .. tostring(err))
	end
	return ok
end

-- read_local_file_async returns the file as a JSON object with keys
-- "0".."n-1" (a serialized Uint8Array) instead of a Lua string.
local function bytes_to_string(bytes)
	if type(bytes) ~= "table" or bytes.success == false then
		return nil
	end
	local count = 0
	for key in pairs(bytes) do
		local index = tonumber(key)
		if index and index + 1 > count then
			count = index + 1
		end
	end
	if count == 0 then
		return nil
	end
	local chars = {}
	for i = 0, count - 1 do
		local byte = bytes[i] or bytes[tostring(i)]
		if type(byte) ~= "number" then
			return nil
		end
		chars[i + 1] = string.char(byte)
	end
	return table.concat(chars)
end

-- Lifecycle
-- Wavedash does not expose pause/visibility/audio events. The SDK binding
-- needs init() before any async call (its JS callback pointer is only set
-- there), so it is initialized from init(), before game state is loaded.

local initialized = false

local function ensure_initialized()
	if initialized or not is_sdk_available() then
		return
	end
	initialized = true
	-- Required: enables the SDK and dismisses the Wavedash loading screen.
	wavedash.init({}, function (_, event, payload)
		if event == wavedash.EVENT_BACKEND_CONNECTED then
			print("[platform] Wavedash backend connected")
		elseif event == wavedash.EVENT_BACKEND_DISCONNECTED then
			print("[platform] Wavedash backend disconnected")
		elseif event == wavedash.EVENT_BACKEND_RECONNECTING then
			print("[platform] Wavedash backend reconnecting")
		end
	end)
	print("[platform] Wavedash initialized")
end

---@param callbacks table See main/platform.lua for the callback contract.
function M.init(callbacks)
	ensure_initialized()
end

function M.ready()
	ensure_initialized()
	if not initialized then
		return
	end
	-- init() already calls load_complete(); repeat it (it is idempotent) so
	-- the readiness contract stays explicit and the bar is fully filled.
	wavedash.update_load_progress_zero_to_one(1)
	wavedash.load_complete()
end

-- Ads
-- Wavedash does not serve rewarded or interstitial ads, so the ad UI stays
-- disabled and the full gold reward is always granted.

M.ads = {}

function M.ads.is_rewarded_supported()
	return false
end

function M.ads.is_interstitial_supported()
	return false
end

function M.ads.show_rewarded()
end

function M.ads.show_interstitial()
end

-- Analytics
-- Wavedash has no generic analytics endpoint. Game events are logged, and
-- player_got_achievement can unlock an achievement once one is configured.

M.analytics = {}

---@param event_name string "level_started", "level_completed", "player_got_achievement"
function M.analytics.send(event_name)
	print("[platform] event: " .. event_name)
	if event_name == "player_got_achievement" and GAME_BEATEN_ACHIEVEMENT and is_sdk_available() then
		wavedash.set_achievement(GAME_BEATEN_ACHIEVEMENT, true)
	end
end

-- Storage
-- One JSON file in the Wavedash local store, uploaded after each save and
-- downloaded before loading so progress follows the player across devices.

M.storage = {}

---@return boolean Always true: falls back to the engine save file when the
--- Wavedash SDK is not injected.
function M.storage.is_supported()
	return true
end

---@param data table
---@param on_success function|nil
---@param on_error function|nil
function M.storage.save(data, on_success, on_error)
	if not is_sdk_available() then
		fallback.storage.save(data, on_success, on_error)
		return
	end

	run_async(function ()
		local wrote = wavedash.write_local_file_async(SAVE_FILE, json.encode(data))
		local wrote_ok = (wrote == true) or (type(wrote) == "table" and wrote.success == true)
		if not wrote_ok then
			print("[platform] Wavedash local save failed")
			if on_error then on_error() end
			return
		end

		if on_success then on_success() end

		-- Cloud upload is best effort: the local copy is already persisted,
		-- and the SDK rate limits uploads (30/min, 300/hour per player).
		local uploaded = wavedash.upload_remote_file_async(SAVE_FILE)
		if type(uploaded) == "table" and uploaded.success then
			print("[platform] Wavedash cloud save uploaded")
		else
			print("[platform] Wavedash cloud save upload failed")
		end
	end)
end

---@param keys string[]|nil Ignored: the whole JSON file is loaded.
---@param on_success function
---@param on_error function|nil
function M.storage.load(keys, on_success, on_error)
	if not is_sdk_available() then
		fallback.storage.load(keys, on_success, on_error)
		return
	end

	run_async(function ()
		-- Pull the cloud copy first. If it is missing or the player is
		-- offline, the local copy from the current device is used.
		local downloaded = wavedash.download_remote_file_async(SAVE_FILE)
		if type(downloaded) == "table" and downloaded.success then
			print("[platform] Wavedash cloud save downloaded")
		else
			print("[platform] Wavedash cloud save unavailable, using local copy")
		end

		local bytes = wavedash.read_local_file_async(SAVE_FILE)
		local encoded = bytes_to_string(bytes)
		local data = nil
		if encoded and encoded ~= "" then
			local ok, decoded = pcall(json.decode, encoded)
			if ok and type(decoded) == "table" then
				data = decoded
			end
		end

		if data then
			print("[platform] loaded game from Wavedash storage")
			if on_success then on_success(data) end
		else
			print("[platform] no Wavedash save found")
			if on_success then on_success({}) end
		end
	end)
end

return M
