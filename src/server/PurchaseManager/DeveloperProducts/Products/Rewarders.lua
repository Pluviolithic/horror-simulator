local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local IDs = ReplicatedStorage.Config.DevProductData.IDs

return {
	[tostring(IDs.MissionSkip.Value)] = function(player: Player)
		local areaName = regionUtils.getPlayerLocationName(player.Name)
		local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[areaName]
		local gemReward =
			ReplicatedStorage.Missions[areaName][tostring(currentMissionData.CurrentMissionNumber)].Gems.Value
		store:dispatch(actions.completeMission(player.Name, areaName, gemReward, true))
		store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", gemReward))
	end,
}
