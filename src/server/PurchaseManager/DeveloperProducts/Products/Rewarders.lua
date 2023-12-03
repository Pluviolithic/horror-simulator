local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local IDs = ReplicatedStorage.Config.DevProductData.IDs
local packs = ReplicatedStorage.Config.DevProductData.Packs
local boosts = ReplicatedStorage.Config.DevProductData.Boosts

local function notifyClientOfAward(player: Player, item: string): ()
	if item:match "Boost" then
		local multiplierAmount = "2x "
		if item:match "Luck" then
			multiplierAmount = "5x "
		elseif item:match "Fearless" then
			multiplierAmount = ""
		end
		Remotes.Server
			:Get("SendPopupMessage")
			:SendToPlayer(player, `You Have Received A {multiplierAmount}{item:match "(%u.+)%u"} Boost!`)
	else
		local wordsInItemName = {}
		for word in item:gmatch "%u%l+" do
			table.insert(wordsInItemName, word)
		end
		Remotes.Server
			:Get("SendPopupMessage")
			:SendToPlayer(player, `You Have Received A {table.concat(wordsInItemName, " ")}!`)
	end
end

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

local productRewarders = {
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

for _, pack in packs.Fear:GetChildren() do
	productRewarders[pack.Value] = function(player: Player)
		local areaName = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
		areaName = areaName:gsub(" ", "_")
		store:dispatch(actions.incrementPlayerStat(player.Name, "Fear", pack:GetAttribute(areaName), "Pack", true))
		notifyClientOfAward(player, pack.Name)
	end
end

for _, pack in packs.Gems:GetChildren() do
	productRewarders[pack.Value] = function(player: Player)
		local areaName = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
		areaName = areaName:gsub(" ", "_")
		store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", pack:GetAttribute(areaName), "Pack", true))
		notifyClientOfAward(player, pack.Name)
	end
end

for _, boost in boosts:GetChildren() do
	productRewarders[boost.Value] = function(player: Player)
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, boost.Name))
		notifyClientOfAward(player, boost.Name)
	end
end

return productRewarders
