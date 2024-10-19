local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local volumeKnobs, switches =
	table.unpack(require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.Soundscape.SoundInstanceHandler))

local player = Players.LocalPlayer

store.changed:connect(function(newState, oldState)
	local newPrimarySoundRegion = if selectors.isPlayerLoaded(newState, player.Name)
		then selectors.getAudioData(newState, player.Name).PrimarySoundRegion
		else "Clown Town"
	local newBackgroundMusicSetting = if selectors.isPlayerLoaded(newState, player.Name)
		then selectors.getSetting(newState, player.Name, "BackgroundMusic")
		else true
	local oldBackgroundMusicSetting = if selectors.isPlayerLoaded(oldState, player.Name)
		then selectors.getSetting(oldState, player.Name, "BackgroundMusic")
		else true

	if not newBackgroundMusicSetting then
		volumeKnobs.on[newPrimarySoundRegion]:Cancel()
		volumeKnobs.off[newPrimarySoundRegion]:Play()
		return
	end

	if oldBackgroundMusicSetting ~= newBackgroundMusicSetting then
		volumeKnobs.off[newPrimarySoundRegion]:Cancel()
		switches.play[newPrimarySoundRegion]()
		volumeKnobs.on[newPrimarySoundRegion]:Play()
		return
	end
end)

store.changed:connect(function(newState, oldState)
	local oldPrimarySoundRegion = if selectors.isPlayerLoaded(oldState, player.Name)
		then selectors.getAudioData(oldState, player.Name).PrimarySoundRegion
		else "Clown Town"
	local newPrimarySoundRegion = if selectors.isPlayerLoaded(newState, player.Name)
		then selectors.getAudioData(newState, player.Name).PrimarySoundRegion
		else "Clown Town"

	if oldPrimarySoundRegion ~= newPrimarySoundRegion then
		if newPrimarySoundRegion then
			if oldPrimarySoundRegion and oldPrimarySoundRegion ~= newPrimarySoundRegion then
				volumeKnobs.off[oldPrimarySoundRegion]:Play()
			end
			switches.play[newPrimarySoundRegion]()
			volumeKnobs.on[newPrimarySoundRegion]:Play()
		elseif oldPrimarySoundRegion then
			volumeKnobs.on[oldPrimarySoundRegion]:Cancel()
			volumeKnobs.off[oldPrimarySoundRegion]:Play()
		end
	end
end)

return 0
