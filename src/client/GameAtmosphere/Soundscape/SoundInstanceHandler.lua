local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local crossfadeTime = ReplicatedStorage.Config.Audio.CrossfadeTime.Value

local player = Players.LocalPlayer
local soundFolder = Instance.new "Folder"
local volumeKnobs = {
	on = {},
	off = {},
}

local function createSoundInstance(name)
	-- include other relevant properties here
	if soundFolder:FindFirstChild(name) then
		return soundFolder[name]
	end

	local soundInstance = Instance.new "Sound"
	soundInstance.Volume = 0
	soundInstance.Looped = true
	soundInstance.Name = name
	soundInstance.Parent = soundFolder

	-- sounds should always be running so volume modulation
	-- will have instantaneous effect
	soundInstance:Play()
	return soundInstance
end

local function createKnob(soundInstance, on)
	return TweenService:Create(
		soundInstance,
		TweenInfo.new(crossfadeTime, Enum.EasingStyle.Linear),
		{ Volume = if on then 1 else 0 }
	)
end

-- all local sounds will go into this folder
soundFolder.Name = "AudioInstances"
soundFolder.Parent = workspace

store.changed:connect(function(newState, oldState)
	local oldPrimarySoundRegion = selectors.getAudioData(oldState, player.Name).PrimarySoundRegion
	local newPrimarySoundRegion = selectors.getAudioData(newState, player.Name).PrimarySoundRegion

	-- need to analyze this chunk of code to see if it's necessary or broken

	if oldPrimarySoundRegion ~= newPrimarySoundRegion then
		if newPrimarySoundRegion then
			local soundInstance = createSoundInstance(newPrimarySoundRegion)
			-- IDs are stored as just numbers to simplify things
			soundInstance.SoundId = "rbxassetid://"
				.. selectors.getAudioData(newState, player.Name).BackgroundTracks[newPrimarySoundRegion]

			-- can assume that all knobs exist if one knob exists
			if not volumeKnobs.on[newPrimarySoundRegion] then
				volumeKnobs.on[newPrimarySoundRegion] = createKnob(soundInstance, true)
				volumeKnobs.off[newPrimarySoundRegion] = createKnob(soundInstance, false)
			end

			-- disable previous region's sound track
			if oldPrimarySoundRegion then
				volumeKnobs.off[oldPrimarySoundRegion]:Play()
			end
		else
			-- old zone is gone, and there is no new zone, fade out all tracks
			volumeKnobs.on[oldPrimarySoundRegion]:Cancel()
			volumeKnobs.off[oldPrimarySoundRegion]:Play()
		end
	end

	-- The update cycle is such that newPrimarySoundRegion will either
	-- be uninitialized (e.g. muted) or same as oldPrimarySoundRegion

	if newPrimarySoundRegion and soundFolder[newPrimarySoundRegion].Volume == 0 then
		volumeKnobs.on[newPrimarySoundRegion]:Play()
	end
end)

return 0
