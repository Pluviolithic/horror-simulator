local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local zoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local actions = require(StarterPlayer.StarterPlayerScripts.Client.State.Actions)

local player = Players.LocalPlayer
local regionPriorities = ReplicatedStorage.Config.Audio.SoundRegionPriorities

local soundRegionZones = {}
local soundRegionContainers = {}

for _, regionPriority in ipairs(regionPriorities:GetChildren()) do
	soundRegionContainers[regionPriority.Name] = zoneUtils.getTaggedForZone(regionPriority.Name)
end

for soundRegionName, soundRegionContainer in soundRegionContainers do
	print(soundRegionName)
	print(#soundRegionContainer:GetChildren())
	local soundZone = Zone.new(soundRegionContainer)
	table.insert(soundRegionZones, soundZone)
	if soundZone:findLocalPlayer() then
		print "found local player"
		store:dispatch(actions.addOccupiedSoundRegion(player.Name, soundRegionName))
	end
	soundZone.localPlayerEntered:Connect(function()
		print "zone entered"
		store:dispatch(actions.addOccupiedSoundRegion(player.Name, soundRegionName))
	end)
	soundZone.localPlayerExited:Connect(function()
		store:dispatch(actions.removeOccupiedSoundRegion(player.Name, soundRegionName))
	end)
end

return soundRegionZones
