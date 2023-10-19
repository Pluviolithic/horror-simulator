local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local missionRequirements = ReplicatedStorage.Missions

Remotes.Server:Get("StartMission"):Connect(function(player: Player)
	local areaName = regionUtils.getPlayerLocationName(player.Name)
	if not selectors.getMissionData(store:getState(), player.Name)[areaName].Active then
		store:dispatch(actions.startMission(player.Name, areaName))
	end
end)

Remotes.Server:Get("CompleteMission"):SetCallback(function(player: Player)
	local areaName = regionUtils.getPlayerLocationName(player.Name)
	local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[areaName]

	local currentMissionRequirements = missionRequirements[areaName][tostring(currentMissionData.CurrentMissionNumber)]
	if currentMissionRequirements.Requirements.Value ~= currentMissionData.CurrentMissionProgress then
		return false
	end

	store:dispatch(actions.completeMission(player.Name, areaName, currentMissionRequirements.Gems.Value))

	return true
end)

Remotes.Server:Get("DisableMissionRewardPopup"):Connect(function(player: Player)
	local areaName = regionUtils.getPlayerLocationName(player.Name)
	if not selectors.getMissionData(store:getState(), player.Name)[areaName].ViewedRewardPopup then
		store:dispatch(actions.disableMissionRewardPopup(player.Name, areaName))
		store:dispatch(actions.incrementPlayerStat(player.Name, "FearMultiplier", 0.1))
	end
end)

return 0
