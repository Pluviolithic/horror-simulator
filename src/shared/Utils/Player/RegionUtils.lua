local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local missionZones = {}

for _, areaZoneModel in workspace.AreaZoneModels:GetChildren() do
	missionZones[areaZoneModel.Name] = Zone.new(areaZoneModel)
end

return {
	getPlayerLocationName = function(playerName: string)
		local player = Players:FindFirstChild(playerName)
		if not player then
			return nil
		end

		for areaName, zone in missionZones do
			if zone:findPlayer(player) then
				return areaName
			end
		end

		return nil
	end,
	getRegions = function()
		return missionZones
	end,
	getLocationNameForPoint = function(point: Vector3)
		for areaName, zone in missionZones do
			if zone:findPoint(point) then
				return areaName
			end
		end

		return nil
	end,
}
