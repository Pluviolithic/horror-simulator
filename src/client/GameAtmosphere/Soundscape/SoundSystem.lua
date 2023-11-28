local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local volumeKnobs, switches =
	table.unpack(require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.Soundscape.SoundInstanceHandler))

local player = Players.LocalPlayer

store.changed:connect(function(newState, oldState)
	local oldPrimarySoundRegion = selectors.getAudioData(oldState, player.Name).PrimarySoundRegion
	local newPrimarySoundRegion = selectors.getAudioData(newState, player.Name).PrimarySoundRegion

	if not selectors.getSetting(newState, player.Name, "BackgroundMusic") then
		newPrimarySoundRegion = nil
	end

	if oldPrimarySoundRegion ~= newPrimarySoundRegion then
		if newPrimarySoundRegion then
			if oldPrimarySoundRegion then
				volumeKnobs.off[oldPrimarySoundRegion]:Play()
			end
			switches.play[newPrimarySoundRegion]()
			volumeKnobs.on[newPrimarySoundRegion]:Play()
		else
			volumeKnobs.on[oldPrimarySoundRegion]:Cancel()
			volumeKnobs.off[oldPrimarySoundRegion]:Play()
		end
	end
end)

return 0
