-- global.lua


-- Other modules import
local bridge = require("bridge.bridge")

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

local function save_game_default()
	local save_file = sys.get_save_file("dragon_dash_dungeons", "save_file")
	sys.save(save_file, {
		gold = M.gold,
		eggs = M.eggs,
		level_health = M.level_health,
		level_power = M.level_power,
		level_quantity = M.level_quantity,
		level_speed = M.level_speed,
		level_luck = M.level_luck,
		player_1_selected_skin = M.player_1_selected_skin,
		player_2_selected_skin = M.player_2_selected_skin,
		game_beaten = M.game_beaten,
		unlocked_skin_count = M.unlocked_skin_count,
		unlocked_skins = M.unlocked_skins,
		high_score_bosses_defeated = M.high_score_bosses_defeated,
		high_score_time = M.high_score_time,
	})
end

local function save_game_sdk()
	local save_data = {
		gold = M.gold,
		eggs = M.eggs,
		level_health = M.level_health,
		level_power = M.level_power,
		level_quantity = M.level_quantity,
		level_speed = M.level_speed,
		level_luck = M.level_luck,
		player_1_selected_skin = M.player_1_selected_skin,
		player_2_selected_skin = M.player_2_selected_skin,
		game_beaten = M.game_beaten,
		config_music = M.config_music,
		config_sound = M.config_sound,
		unlocked_skin_count = M.unlocked_skin_count,
		unlocked_skins = M.unlocked_skins,
		high_score_bosses_defeated = M.high_score_bosses_defeated,
		high_score_time = M.high_score_time,
	}
	local json_str = json.encode(save_data)
	crazygames.set_item("dragon_dungeons_save_file", json_str)
end

function M.save_game()
	if html5 and bridge and (bridge.storage.is_available("local_storage") or bridge.storage.is_available("internal_storage")) then
		save_game_sdk()
	else
		save_game_default()
	end
end

local function load_game_default()
	local save_file = sys.get_save_file("dragon_dash_dungeons", "save_file")
	local save_data = sys.load(save_file)
	M.gold = save_data.gold or M.gold
	M.eggs = save_data.eggs or M.eggs
	M.level_health = save_data.level_health or M.level_health
	M.level_power = save_data.level_power or M.level_power
	M.level_quantity = save_data.level_quantity or M.level_quantity
	M.level_speed = save_data.level_speed or M.level_speed
	M.level_luck = save_data.level_luck or M.level_luck
	M.high_score_bosses_defeated = save_data.high_score_bosses_defeated or M.high_score_bosses_defeated
	M.high_score_time = save_data.high_score_time or M.high_score_time
	M.player_1_selected_skin = save_data.player_1_selected_skin or M.player_1_selected_skin
	M.player_2_selected_skin = save_data.player_2_selected_skin or M.player_2_selected_skin
	M.game_beaten = (save_data.game_beaten == true) -- Looks weird to deal with nil values
	M.unlocked_skin_count = save_data.unlocked_skin_count or M.unlocked_skin_count
	-- Load unlocked skins in a way that doesn't break the save system if I add more skins in the future
	if save_data.unlocked_skins then -- If there is save data for unlocked skins in the first place
		for i = 1, #save_data.unlocked_skins do
			M.unlocked_skins[i] = save_data.unlocked_skins[i]
		end
	end
end

local function load_game_sdk()
	local json_str = crazygames.get_item("dragon_dungeons_save_file")
	if json_str then
		local save_data = json.decode(json_str)
		M.gold = save_data.gold or M.gold
		M.eggs = save_data.eggs or M.eggs
		M.level_health = save_data.level_health or M.level_health
		M.level_power = save_data.level_power or M.level_power
		M.level_quantity = save_data.level_quantity or M.level_quantity
		M.level_speed = save_data.level_speed or M.level_speed
		M.level_luck = save_data.level_luck or M.level_luck
		M.high_score_bosses_defeated = save_data.high_score_bosses_defeated or M.high_score_bosses_defeated
		M.high_score_time = save_data.high_score_time or M.high_score_time
		M.player_1_selected_skin = save_data.player_1_selected_skin or M.player_1_selected_skin
		M.player_2_selected_skin = save_data.player_2_selected_skin or M.player_2_selected_skin
		M.game_beaten = save_data.game_beaten
		M.game_beaten = (save_data.game_beaten == true) -- Looks weird to deal with nil values
		M.config_music = (save_data.config_music == true) -- Looks weird to deal with nil values
		M.config_sound = (save_data.config_sound == true) -- Looks weird to deal with nil values
		M.unlocked_skin_count = save_data.unlocked_skin_count or M.unlocked_skin_count
		-- Load unlocked skins without breaking if new skins are added later
		if save_data.unlocked_skins then
			for i = 1, #save_data.unlocked_skins do
				M.unlocked_skins[i] = save_data.unlocked_skins[i]
			end
		end
	end
end

function M.load_game()
	if html5 and bridge and (bridge.storage.is_available("local_storage") or bridge.storage.is_available("internal_storage")) then
		load_game_sdk()
	else
		load_game_default()
	end
end

-- Module return
return M
