local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

--TODO: switch all the ids to reference the config folder

return {
	-- scythe gamepass
	["104651443"] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Scythe"))
		store:dispatch(actions.equipWeapon(player.Name, "Scythe"))
	end,
	-- vip gamepass
	["104648723"] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Hero Blade"))
		store:dispatch(actions.equipWeapon(player.Name, "Hero Blade"))
	end,
	-- increase pet storage by 50
	["104653111"] = function(player: Player)
		store:dispatch(actions.increaseMaxPetCount(player.Name, 50))
	end,
	-- increase pet storage by 100
	["104653130"] = function(player: Player)
		store:dispatch(actions.increaseMaxPetCount(player.Name, 100))
	end,
	-- increase player luck multiplier by 2
	["104655313"] = function(player: Player)
		store:dispatch(actions.increasePlayerLuck(player.Name, 2))
	end,
	-- increase player luck multiplier by 3
	["104655363"] = function(player: Player)
		store:dispatch(actions.increasePlayerLuck(player.Name, 3))
	end,
	-- increase pet equip limit by 1
	["104654015"] = function(player: Player)
		store:dispatch(actions.increaseMaxPetEquipCount(player.Name, 1))
	end,
	-- increase pet equip limit by 2
	["104654052"] = function(player: Player)
		store:dispatch(actions.increaseMaxPetEquipCount(player.Name, 2))
	end,
}
