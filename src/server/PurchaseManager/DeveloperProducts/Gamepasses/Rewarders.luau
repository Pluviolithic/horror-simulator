local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

return {
	-- scythe gamepass
	[104651443] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Scythe"))
		store:dispatch(actions.equipWeapon(player.Name, "Scythe"))
	end,
	-- vip gamepass
	[104648723] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Hero Blade"))
		store:dispatch(actions.equipWeapon(player.Name, "Hero Blade"))
	end,
	[104653111] = function(player: Player)
		store:dispatch(actions.increaseMaxPetCount(player.Name, 50))
	end,
	[104653130] = function(player: Player)
		store:dispatch(actions.increaseMaxPetCount(player.Name, 100))
	end,
}
