local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local actions = require(StarterPlayer.StarterPlayerScripts.Client.State.Actions)

local player = Players.LocalPlayer

for soundRegionName, soundZone in regionUtils.getRegions() do
	if soundZone:findLocalPlayer() then
		store:dispatch(actions.addOccupiedSoundRegion(player.Name, soundRegionName))
	end
	soundZone.localPlayerEntered:Connect(function()
		store:dispatch(actions.addOccupiedSoundRegion(player.Name, soundRegionName))
	end)
	soundZone.localPlayerExited:Connect(function()
		store:dispatch(actions.removeOccupiedSoundRegion(player.Name, soundRegionName))
	end)
end

return 0
