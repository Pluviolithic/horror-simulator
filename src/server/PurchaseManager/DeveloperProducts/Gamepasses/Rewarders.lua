local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)

local IDs = ReplicatedStorage.Config.GamepassData.IDs

return {
	[IDs.Scythe.Value] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Scythe"))
		store:dispatch(actions.equipWeapon(player.Name, "Scythe"))
	end,
	[IDs.VIP.Value] = function(player: Player)
		store:dispatch(actions.givePlayerWeapon(player.Name, "Hero Blade"))
		store:dispatch(actions.equipWeapon(player.Name, "Hero Blade"))
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "Training DummyFearMultiplier", 0.5))
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "PunchingBagStrengthMultiplier", 0.2))
		player:SetAttribute("isVIP", true)
	end,
	[IDs["50PetStorage"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetCount", 50))
	end,
	[IDs["100PetStorage"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetCount", 100))
	end,
	[IDs["2xLuck"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "Luck", 2))
	end,
	[IDs["3xLuck"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "Luck", 3))
	end,
	[IDs["1PetEquipped"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetEquipCount", 1))
	end,
	[IDs["2PetEquipped"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetEquipCount", 2))
	end,
	[IDs["2xStrength"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "StrengthMultiplier", 2))
	end,
	[IDs["2xFear"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "FearMultiplier", 2))
	end,
	[IDs["2xGems"].Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "GemsMultiplier", 2))
	end,
	[IDs["2xFearMeter"].Value] = function(player: Player)
		store:dispatch(
			actions.setPlayerStat(
				player.Name,
				"MaxFearMeter",
				rankUtils.getMaxFearMeterFromRank(selectors.getStat(store:getState(), player.Name, "Rank") * 2)
			)
		)
		store:dispatch(actions.incrementPlayerMultiplier(player.Name, "MaxFearMeterMultiplier", 2))
	end,
	[IDs["2xSpeed"].Value] = function(player: Player)
		local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
		if humanoid then
			humanoid.WalkSpeed *= 2
		end
	end,
	[IDs["3xHatch"].Value] = true,
	[IDs["AutoHatch"].Value] = true,
	[IDs["FasterHatch"].Value] = true,
	[IDs["2xAttackSpeed"].Value] = true,
	[IDs["3xWorkoutSpeed"].Value] = true,
	[IDs.FreeTeleporters.Value] = true,
}
