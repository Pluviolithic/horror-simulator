local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local IDs = ReplicatedStorage.Config.DevProductData.IDs

local function awardPetsToPlayer(player: Player, petsDict: { [string]: number }): ()
	store:dispatch(actions.givePlayerPets(player.Name, petsDict))
	store:dispatch(actions.lockPlayerPets(player.Name, petsDict))

	local petsToEquip, counter = {}, 0
	local equippedPetsCount = petUtils.countPetsInDict(selectors.getEquippedPets(store:getState(), player.Name))
	for _, petName in petUtils.getBestPetNames(petsDict, petUtils.countPetsInDict(petsDict)) do
		if equippedPetsCount + counter >= selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount") then
			break
		end
		counter += 1
		petsToEquip[petName] = if petsToEquip[petName] then petsToEquip[petName] + 1 else 1
	end
	if counter > 0 then
		store:dispatch(actions.equipPlayerPets(player.Name, petsToEquip))
	end
end

return {
	[IDs.MissionSkip.Value] = function(player: Player)
		local areaName = regionUtils.getPlayerLocationName(player.Name)
		local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[areaName]
		local gemReward = ReplicatedStorage.Missions[areaName][currentMissionData.CurrentMissionNumber].Gems.Value
		store:dispatch(actions.completeMission(player.Name, areaName, gemReward, true))
		store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", gemReward))
	end,
	[IDs["1GoldenDominus"].Value] = function(player: Player)
		awardPetsToPlayer(player, { ["Golden Dominus"] = 1 })
	end,
	[IDs["3GoldenDominus"].Value] = function(player: Player)
		awardPetsToPlayer(player, { ["Golden Dominus"] = 3 })
	end,
	[IDs["1Reaper"].Value] = function(player: Player)
		awardPetsToPlayer(player, { Reaper = 1 })
	end,
	[IDs["3Reaper"].Value] = function(player: Player)
		awardPetsToPlayer(player, { Reaper = 3 })
	end,
}
