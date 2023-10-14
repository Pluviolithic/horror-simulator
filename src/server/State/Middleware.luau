local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local actions = require(server.State.Actions)
--local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
--local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

local missionRequirements = ReplicatedStorage.Missions
local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value

local function getFilteredState(playerName, state)
	local filteredState = {
		Stats = selectors.getStats(state, playerName),
		PetData = selectors.getPetData(state, playerName),
		WeaponData = selectors.getWeaponData(state, playerName),
		PurchaseData = selectors.getPurchaseData(state, playerName),
	}
	for field, entry in filteredState do
		for key in entry do
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
		if replicationRule == Enum.ReplicationRules.All then
			Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		elseif replicationRule ~= Enum.ReplicationRules.None then
			Remotes.Server:Get("SendRoduxAction"):SendToPlayer(Players[action.playerName], action)
		end
		nextDispatch(action)
	end
end

local function savePlayerDataMiddleware(nextDispatch, store)
	return function(action)
		local oldState = store:getState()
		nextDispatch(action)
		if not action.shouldSave then
			return
		end

		local newState = store:getState()
		local profileData = profiles[action.playerName].Data

		local filteredOldState = getFilteredState(action.playerName, oldState)
		local filteredNewState = getFilteredState(action.playerName, newState)

		--print(action)
		--print(filteredOldState)
		--print(filteredNewState)

		for key, value in filteredNewState do
			if filteredOldState[key] ~= value then
				--print "passing"
				--print(key, value)
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

local function giveMissionRewards(nextDispatch, store)
	return function(action)
		local oldState = store:getState()
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

return {
	giveMissionRewards,
	updateClientMiddleware,
	savePlayerDataMiddleware,
	updateLeaderstatsMiddleware,
	--instantiatePetsMiddleware,
	--trackPlayerScaredStatusMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
