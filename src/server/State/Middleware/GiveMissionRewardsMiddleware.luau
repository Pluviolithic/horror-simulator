local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local missionRequirements = ReplicatedStorage.Missions

return function(nextDispatch, store)
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
