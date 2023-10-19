local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local IDs = ReplicatedStorage.Config.GamepassData.IDs

return {
	[tostring(IDs.Scythe.Value)] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Scythe"))
		store:dispatch(actions.equipWeapon(player.Name, "Scythe"))
	end,
	[tostring(IDs.VIP.Value)] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Hero Blade"))
		store:dispatch(actions.equipWeapon(player.Name, "Hero Blade"))
	end,
	[tostring(IDs["50PetStorage"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetCount", 50))
	end,
	[tostring(IDs["100PetStorage"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetCount", 100))
	end,
	[tostring(IDs["2xLuck"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "Luck", 2))
	end,
	[tostring(IDs["3xLuck"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "Luck", 3))
	end,
	[tostring(IDs["1PetEquipped"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetEquipCount", 1))
	end,
	[tostring(IDs["2PetEquipped"].Value)] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetEquipCount", 2))
	end,

	[tostring(IDs["2xStrength"].Value)] = true,
	[tostring(IDs["2xFear"].Value)] = true,
	[tostring(IDs["2xGems"].Value)] = true,
	[tostring(IDs["2xSpeed"].Value)] = true,
	[tostring(IDs["2xAttackSpeed"].Value)] = true,
	[tostring(IDs["3xWorkoutSpeed"].Value)] = true,
	[tostring(IDs.FreeTeleporter.Value)] = true,
}
