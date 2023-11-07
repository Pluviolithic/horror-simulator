local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local volumeKnobs = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.Soundscape.SoundInstanceHandler)

local player = Players.LocalPlayer

store.changed:connect(function(newState, oldState)
	local oldPrimarySoundRegion = selectors.getAudioData(oldState, player.Name).PrimarySoundRegion
	local newPrimarySoundRegion = selectors.getAudioData(newState, player.Name).PrimarySoundRegion

	if oldPrimarySoundRegion ~= newPrimarySoundRegion then
		print "new primary region"
		print("name: " .. tostring(newPrimarySoundRegion))
		if newPrimarySoundRegion then
			if oldPrimarySoundRegion then
				print "turning off music from previous primary region"
				print("name: " .. tostring(oldPrimarySoundRegion))
				volumeKnobs.off[oldPrimarySoundRegion]:Play()
			end
			print "turning on music for new primary region"
			print("name: " .. tostring(newPrimarySoundRegion))
			volumeKnobs.on[newPrimarySoundRegion]:Play()
		else
			print "not currently in a region"
			print "turning off all sound"
			volumeKnobs.on[oldPrimarySoundRegion]:Cancel()
			volumeKnobs.off[oldPrimarySoundRegion]:Play()
		end
	end
end)

return 0
