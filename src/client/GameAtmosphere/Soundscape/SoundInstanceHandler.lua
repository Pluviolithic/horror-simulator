local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local player = Players.LocalPlayer
local soundFolder = Instance.new "Folder"

local playlists = ReplicatedStorage.Config.Audio.SoundRegionPlaylists
local crossfadeTime = ReplicatedStorage.Config.Audio.CrossfadeTime.Value

local volumeKnobs = {
	on = {},
	off = {},
}

local function createKnob(soundInstance, on)
	return TweenService:Create(
		soundInstance,
		TweenInfo.new(crossfadeTime, Enum.EasingStyle.Linear),
		{ Volume = if on then soundInstance.Volume else 0 }
	)
end

soundFolder.Name = "AudioInstances"
soundFolder.Parent = workspace

for _, playlistFolder in playlists:GetChildren() do
	task.spawn(function()
		while true do
			for i = 1, #playlistFolder:GetChildren() do
				if soundFolder:FindFirstChild(playlistFolder.Name) then
					soundFolder[playlistFolder.Name]:Destroy()
				end

				local nextAudioInstance = playlistFolder[tostring(i)]:Clone()

				if volumeKnobs.on[playlistFolder.Name] then
					volumeKnobs.on[playlistFolder.Name]:Destroy()
					volumeKnobs.off[playlistFolder.Name]:Destroy()
				end

				volumeKnobs.on[playlistFolder.Name] = createKnob(nextAudioInstance, true)
				volumeKnobs.off[playlistFolder.Name] = createKnob(nextAudioInstance, false)

				if
					not selectors.isPlayerLoaded(store:getState(), player.Name)
					or selectors.getAudioData(store:getState(), player.Name).PrimarySoundRegion
						~= playlistFolder.Name
				then
					nextAudioInstance.Volume = 0
				end

				nextAudioInstance.Name = playlistFolder.Name
				nextAudioInstance.Parent = soundFolder
				nextAudioInstance:Play()
				nextAudioInstance.Ended:Wait()
			end
		end
	end)
end

return volumeKnobs
