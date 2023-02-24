local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value

local function updateClientMiddleware(nextDispatch)
	return function(action)
		local replicationRule = replicationRules[action.type]
		if replicationRule == Enum.ReplicationRules.All then
			Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		elseif replicationRule ~= Enum.ReplicationRules.None then
			Remotes.Server:Get("SendRoduxAction"):SendToPlayer(Players[action.playerName], action)
		end
		return nextDispatch(action)
	end
end

-- will want to come up with a more generalized function to
-- simplify this middleware and allow for expansion to other
-- save values
local function savePlayerDataMiddleware(nextDispatch)
	return function(action)
		if profiles[action.playerName] then
			local data = profiles[action.playerName].Data
			if action.type == "incrementPlayerStat" then
				data[action.statName] += (action.incrementAmount or 1)
			elseif action.type == "givePlayerWeapon" then
				data.OwnedWeapons[action.weaponName] = true
			elseif action.type == "givePlayerPets" then
				for _, petName in pairs(action.petNames) do
					if not petName:match "Evolved" then
						data.FoundPets[petName] = true
					end
					data.OwnedPets[petName] = if data.OwnedPets[petName] then data.OwnedPets[petName] + 1 else 1
				end
				data.CurrentPetCount = data.CurrentPetCount + #action.petNames
			elseif action.type == "deletePet" then
				data.OwnedPets[action.petName] -= math.min(data.OwnedPets[action.petName], action.quantity)
				if data.OwnedPets[action.petName] <= 0 then
					data.OwnedPets[action.petName] = nil
				end
				data.CurrentPetCount -= math.min(data.OwnedPets[action.petName], action.quantity)
			elseif action.type == "lockPet" then
				data.LockedPets[action.petName] = if data.LockedPets[action.petName]
					then data.LockedPets[action.petName] + 1
					else 1
			elseif action.type == "unlockPet" then
				if data.LockedPets[action.petName] then
					data.LockedPets[action.petName] -= math.min(data.LockedPets[action.petName], action.quantity)
					if data.LockedPets[action.petName] <= 0 then
						data.LockedPets[action.petName] = nil
					end
				end
			elseif action.type == "equipPet" then
				data.EquippedPets[action.petName] = if data.EquippedPets[action.petName]
					then data.EquippedPets[action.petName] + 1
					else 1
				data.CurrentPetEquipCount += 1
				data.PetFearMultiplier = data.PetFearMultiplier
					+ (petUtils.getPet(action.petName) :: any).Multiplier.Value
			elseif action.type == "unequipPet" then
				data.EquippedPets[action.petName] -= 1
				if data.EquippedPets[action.petName] <= 0 then
					data.EquippedPets[action.petName] = nil
				end
				data.CurrentPetEquipCount -= 1
				data.PetFearMultiplier = data.PetFearMultiplier
					- (petUtils.getPet(action.petName) :: any).Multiplier.Value
			elseif action.type == "increaseMaxPetCount" then
				data.MaxPetCount += action.amount
			elseif action.type == "increaseMaxPetEquipCount" then
				data.MaxPetEquipCount += action.amount
			elseif action.type == "awardGamepassToPlayer" then
				data.AwardedGamepasses[action.gamepassID] = true
			elseif action.type == "equipWeapon" then
				data.EquippedWeapon = action.weaponName
			elseif action.type == "increasePlayerLuck" then
				data.Luck += action.amount
			elseif action.type == "resetPlayerData" then
				profiles[action.playerName].Data = table.clone(profileTemplate)
			end
		end
		return nextDispatch(action)
	end
end

local function updateLeaderboardMiddleware(nextDispatch)
	return function(action)
		if action.type == "incrementPlayerStat" then
			local player = Players:FindFirstChild(action.playerName)
			local stat: StringValue? = if player and player:FindFirstChild "leaderstats"
				then player.leaderstats:FindFirstChild(action.statName)
				else nil
			if stat then
				stat.Value = formatter.formatNumberWithSuffix(profiles[action.playerName].Data[action.statName])
			end
		end
		return nextDispatch(action)
	end
end

return {
	savePlayerDataMiddleware,
	updateLeaderboardMiddleware,
	updateClientMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
