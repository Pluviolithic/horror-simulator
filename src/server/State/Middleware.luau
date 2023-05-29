local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)

local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value

local function getFilteredState(playerName, state)
	local filteredState = {}
	for key in profileTemplate do
		filteredState[key] = state.Players[playerName][key]
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
		if not action.playerName or not store:getState().Players[action.playerName] then
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

local function instantiatePetsMiddleware(nextDispatch, store)
	return function(action)
		local oldState = store:getState()
		nextDispatch(action)
		if not action.playerName or not selectors.isPlayerLoaded(store:getState(), action.playerName) then
			if action.playerName and workspace.PetModels:FindFirstChild(action.playerName) then
				workspace.PetModels[action.playerName]:Destroy()
			end
			return
		end
		if
			not selectors.isPlayerLoaded(oldState, action.playerName)
			or Sift.Dictionary.equalsDeep(
				selectors.getEquippedPets(oldState, action.playerName),
				selectors.getEquippedPets(store:getState(), action.playerName)
			)
		then
			return
		end
		petUtils.instantiatePets(action.playerName, selectors.getEquippedPets(store:getState(), action.playerName))
	end
end

return {
	updateClientMiddleware,
	--savePlayerDataMiddleware,
	updateLeaderstatsMiddleware,
	instantiatePetsMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
