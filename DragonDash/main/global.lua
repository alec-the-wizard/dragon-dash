-- global.lua


-- Other modules import
local platform = require("main.platform")

-- Module initialize
local M = {}

-- Constants
M.SCREEN_WIDTH = 1280
M.SCREEN_HEIGHT = 720
M.MAX_EGGS = 75
M.STARTING_SKIN_COST = 100
M.SKIN_COST_INCREMENT = 10
M.STARTING_BOSS_HEALTH = 100
M.BOSS_HEALTH_INCREMENT = 50
M.STARTING_BOSS_POSITION = vmath.vector3(1060, 360, 0)
M.BOSS_Y_POSITIONS = {128, 360, 592}
M.UPGRADE_COST = {1, 1, 2, 2, 3, 3, 3, 9999} -- Very high last number is for upgrade cost logic
M.LEVEL_COLORS = {
	vmath.vector4(0.6, 0.4, 0.4, 1.0), -- red
	vmath.vector4(0.4, 0.6, 0.4, 1.0), -- green
	vmath.vector4(0.4, 0.4, 0.6, 1.0), -- blue
	vmath.vector4(0.6, 0.6, 0.3, 1.0), -- yellow
	vmath.vector4(0.6, 0.3, 0.6, 1.0), -- 
	vmath.vector4(0.3, 0.6, 0.6, 1.0), -- 
	vmath.vector4(0.5, 0.5, 0.5, 1.0), -- gray
	vmath.vector4(0.6, 0.4, 0.4, 1.0), -- red
	vmath.vector4(0.4, 0.6, 0.4, 1.0), -- green
	vmath.vector4(0.4, 0.4, 0.6, 1.0), -- blue
	vmath.vector4(0.6, 0.6, 0.3, 1.0), -- yellow
	vmath.vector4(0.5, 0.5, 0.5, 1.0), -- gray
}
M.RAINBOW_COLORS = {
	vmath.vector4(1.0, 0.0, 0.0, 1.0),
	vmath.vector4(1.0, 0.502, 0.0, 1.0),
	vmath.vector4(1.0, 1.0, 0.0, 1.0),
	vmath.vector4(0.0, 1.0, 0.0, 1.0),
	vmath.vector4(0.0, 0.502, 1.0, 1.0),
	vmath.vector4(0.0, 0.0, 1.0, 1.0),
	vmath.vector4(0.502, 0.0, 1.0, 1.0),
}
M.COLOR_GRAY_OPAQUE = vmath.vector4(0.4, 0.4, 0.4, 1.0)
M.COLOR_GRAY_TRANSPARENT = vmath.vector4(0.4, 0.4, 0.4, 0.75)

-- Variables
M.player_hearts = 5
M.gold = 100 -- 100 is default. Change for testing upgrades
M.eggs = 3 -- 3 is default. Change for testing upgrandes
M.unlocked_skin_count = 0
M.player_position = vmath.vector3(200, 360, 0)
M.player_1_selected_skin = 3
M.player_2_selected_skin = 2
M.high_score_bosses_defeated = 0
M.high_score_time = 0
M.last_battle_bosses_defeated = 1
M.last_battle_time = 120 -- Time in seconds
M.level_health = 0
M.level_power = 0
M.level_quantity = 0
M.level_speed = 0
M.level_luck = 0
M.game_beaten = false
M.config_music = true
M.config_sound = true
M.unlocked_skins = {
	true, true, true, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false, false, false, false, false, false,
	false, false, false, false, false,
}
M.last_game_speed = 1

-- Keys that make up a saved game. Platform storage implementations may need
-- the key list up front (key/value stores), so keep it here as the single
-- source of truth next to get_save_data().
M.SAVE_KEYS = {
	"gold",
	"eggs",
	"level_health",
	"level_power",
	"level_quantity",
	"level_speed",
	"level_luck",
	"high_score_bosses_defeated",
	"high_score_time",
	"player_1_selected_skin",
	"player_2_selected_skin",
	"game_beaten",
	"unlocked_skin_count",
	"unlocked_skins",
}

-- Functions
function M.next_egg_cost()
	return M.STARTING_SKIN_COST + (M.SKIN_COST_INCREMENT * (M.unlocked_skin_count * (M.unlocked_skin_count-1)))
end

function M.next_upgrade_cost()
	return math.min(M.UPGRADE_COST[M.level_health+1], M.UPGRADE_COST[M.level_power+1], M.UPGRADE_COST[M.level_quantity+1], M.UPGRADE_COST[M.level_speed+1], M.UPGRADE_COST[M.level_luck+1])
end

function M.all_eggs_bought()
	return M.unlocked_skin_count + 3 >= M.MAX_EGGS
end

function M.all_upgrades_bought()
	return (M.level_health >= 7) and (M.level_power >= 7) and (M.level_quantity >= 7) and (M.level_speed >= 7) and (M.level_luck >= 7) 
end

function M.can_buy_egg()
	return M.gold >= M.next_egg_cost() and not M.all_eggs_bought()
end

function M.can_buy_upgrade()
	return M.eggs >= M.next_upgrade_cost() and not M.all_upgrades_bought()
end

---Build the complete table persisted by the platform storage.
---@return table
function M.get_save_data()
	return {
		gold = M.gold,
		eggs = M.eggs,
		level_health = M.level_health,
		level_power = M.level_power,
		level_quantity = M.level_quantity,
		level_speed = M.level_speed,
		level_luck = M.level_luck,
		high_score_bosses_defeated = M.high_score_bosses_defeated,
		high_score_time = M.high_score_time,
		player_1_selected_skin = M.player_1_selected_skin,
		player_2_selected_skin = M.player_2_selected_skin,
		game_beaten = M.game_beaten,
		unlocked_skin_count = M.unlocked_skin_count,
		unlocked_skins = M.unlocked_skins,
	}
end

---Apply loaded save data on top of the current defaults.
---Missing fields keep their current value, so old or partial saves stay valid.
---@param data table
function M.apply_save_data(data)
	if data.gold then
		M.gold = data.gold
	end
	if data.eggs then
		M.eggs = data.eggs
	end
	if data.level_health then
		M.level_health = data.level_health
	end
	if data.level_power then
		M.level_power = data.level_power
	end
	if data.level_quantity then
		M.level_quantity = data.level_quantity
	end
	if data.level_speed then
		M.level_speed = data.level_speed
	end
	if data.level_luck then
		M.level_luck = data.level_luck
	end
	if data.high_score_bosses_defeated then
		M.high_score_bosses_defeated = data.high_score_bosses_defeated
	end
	if data.high_score_time then
		M.high_score_time = data.high_score_time
	end
	if data.player_1_selected_skin then
		M.player_1_selected_skin = data.player_1_selected_skin
	end
	if data.player_2_selected_skin then
		M.player_2_selected_skin = data.player_2_selected_skin
	end
	if data.game_beaten ~= nil then
		M.game_beaten = (data.game_beaten == true) -- Looks weird to deal with nil values
	end
	if data.unlocked_skin_count then
		M.unlocked_skin_count = data.unlocked_skin_count
	end
	-- Load unlocked skins in a way that doesn't break the save system if I add more skins in the future
	if data.unlocked_skins then -- If there is save data for unlocked skins in the first place
		for i = 1, #data.unlocked_skins do
			M.unlocked_skins[i] = data.unlocked_skins[i]
		end
	end
end

function M.save_game()
	platform.storage.save(M.get_save_data())
end

function M.load_game()
	platform.storage.load(M.SAVE_KEYS, M.apply_save_data)
end

-- Module return
return M
