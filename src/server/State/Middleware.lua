local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local actions = require(server.State.Actions)
--local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
--local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

local missionRequirements = ReplicatedStorage.Missions
local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value
local doubleSpeedGamepassID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xSpeed"].Value)

local applyMultiplierToNegativeWhitelist = {}

local function getFilteredState(playerName, state)
	state = table.clone(state)
	local filteredState = {
		Stats = selectors.getStats(state, playerName),
		PetData = selectors.getPetData(state, playerName),
		WeaponData = selectors.getWeaponData(state, playerName),
		PurchaseData = selectors.getPurchaseData(state, playerName),
		MissionData = selectors.getMissionData(state, playerName),
		MultiplierData = selectors.getMultiplierData(state, playerName),
	}
	for field, entry in filteredState do
		for key in entry do
			if key:match "Multiplier" then
				continue
			end
			if not profileTemplate[field][key] then
				entry[key] = nil
			end
		end
	end
	return filteredState
end

local function updateClientMiddleware(nextDispatch)
	return function(action)
		local replicationRule = replicationRules[action.type]
		if replicationRule == Enum.ReplicationRules.All or not action.playerName then
			Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		elseif replicationRule ~= Enum.ReplicationRules.None then
			Remotes.Server:Get("SendRoduxAction"):SendToPlayer(Players[action.playerName], action)
		end
		nextDispatch(action)
	end
end

local function savePlayerDataMiddleware(nextDispatch, store)
	return function(action)
		local oldState = table.clone(store:getState())
		nextDispatch(action)
		if not action.shouldSave then
			return
		end

		local newState = store:getState()
		local profileData = profiles[action.playerName].Data

		local filteredOldState = getFilteredState(action.playerName, oldState)
		local filteredNewState = getFilteredState(action.playerName, newState)

		for key, value in filteredNewState do
			if filteredOldState[key] ~= value then
				profileData[key] = value
			end
		end
	end
end

local function updateLeaderstatsMiddleware(nextDispatch, store)
	return function(action)
		nextDispatch(action)
		if not action.playerName or not selectors.isPlayerLoaded(store:getState(), action.playerName) then
			return
		end

		local player = Players:FindFirstChild(action.playerName)
		local leaderstats = player:FindFirstChild "leaderstats"

		if leaderstats then
			for _, stat in pairs(leaderstats:GetChildren()) do
				stat.Value =
					formatter.formatNumberWithSuffix(selectors.getStat(store:getState(), player.Name, stat.Name))
			end
		end
	end
end

local function updateWalkSpeedMiddleware(nextDispatch, store)
	return function(action)
		local oldWalkSpeed, newWalkSpeed
		if selectors.isPlayerLoaded(store:getState(), action.playerName) then
			oldWalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
		end
		nextDispatch(action)
		if selectors.isPlayerLoaded(store:getState(), action.playerName) then
			newWalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
		else
			return
		end
		local player = Players[action.playerName]
		local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
		if humanoid and oldWalkSpeed ~= newWalkSpeed then
			humanoid.WalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
			if selectors.hasGamepass(store:getState(), action.playerName, doubleSpeedGamepassID) then
				humanoid.WalkSpeed *= 2
			end
		end
	end
end

local function giveMissionRewards(nextDispatch, store)
	return function(action)
		local oldState = table.clone(store:getState())
		nextDispatch(action)
		if action.type ~= "logKilledEnemyType" then
			return
		end
		local oldMissionData = selectors.getMissionData(oldState, action.playerName)
		local newMissionData = selectors.getMissionData(store:getState(), action.playerName)

		if oldMissionData == newMissionData then
			return
		end

		if oldMissionData.CurrentMissionNumber ~= newMissionData.CurrentMissionNumber then
			local missionReward =
				missionRequirements[regionUtils.getPlayerLocationName(action.playerName)][oldMissionData.CurrentMissionNumber].Gems.Value
			store:dispatch(actions.incrementPlayerStat(action.playerName, "Gems", missionReward))
		end
	end
end

local function applyMultipliers(nextDispatch, store)
	return function(action)
		if action.statName and action.incrementAmount then
			if action.incrementAmount > 0 or applyMultiplierToNegativeWhitelist[action.statName] then
				local multiplierData = selectors.getMultiplierData(store:getState(), action.playerName)
				local multiplier = multiplierData[action.statName .. "Multiplier"] or 0
				local multiplierCount = multiplierData[action.statName .. "MultiplierCount"] or 0

				if action.source then
					local sourceMultiplier = multiplierData[action.source .. action.statName .. "Multiplier"] or 0
					local sourceMultiplierCount = multiplierData[action.source .. action.statName .. "MultiplierCount"]
						or 0

					multiplier += sourceMultiplier
					multiplierCount += sourceMultiplierCount
				end

				if multiplierCount < 1 then
					action.incrementAmount *= (1 + multiplier)
				else
					action.incrementAmount *= multiplier
				end
			end
		end
		nextDispatch(action)
		if action.statName == "Strength" then
			local multiplier = selectors.getMultiplierData(store:getState(), action.playerName).MaxFearMeterMultiplier
				or 1
			store:dispatch(
				actions.setPlayerStat(
					action.playerName,
					"MaxFearMeter",
					rankUtils.getMaxFearMeterFromRank(selectors.getStat(store:getState(), action.playerName, "Rank"))
						* multiplier
				)
			)
		end
	end
end

return {
	applyMultipliers,
	giveMissionRewards,
	updateClientMiddleware,
	savePlayerDataMiddleware,
	updateLeaderstatsMiddleware,
	updateWalkSpeedMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
