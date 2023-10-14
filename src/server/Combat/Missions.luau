local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local missionRequirements = ReplicatedStorage.Missions

Remotes.Server:Get("StartMission"):Connect(function(player: Player, areaName: string)
	if not missionRequirements:FindFirstChild(areaName) then
		return
	end
	if not selectors.getMissionData(store:getState(), player.Name)[areaName].Active then
		store:dispatch(actions.startMission(player.Name, areaName))
	end
end)

Remotes.Server:Get("CompleteMission"):Connect(function(player: Player, areaName: string)
	if not missionRequirements:FindFirstChild(areaName) then
		return
	end
	local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[areaName]
	local currentMissionRequirements = missionRequirements[areaName][tostring(currentMissionData.CurrentMissionNumber)]
	if currentMissionRequirements.Requirements.Value ~= currentMissionData.CurrentMissionProgress then
		return
	end

	store:dispatch(actions.completeMission(player.Name, areaName, currentMissionRequirements.Gems.Value))
end)

return 0
