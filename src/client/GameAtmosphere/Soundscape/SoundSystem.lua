local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local actions = require(StarterPlayer.StarterPlayerScripts.Client.State.Actions)

local player = Players.LocalPlayer
local playlists = ReplicatedStorage.Config.Audio.SoundRegionPlaylists

for _, playlistFolder in playlists:GetChildren() do
	local regionName, playlist = playlistFolder.Name, {}
	task.spawn(function()
		for i = 1, #playlistFolder:GetChildren() do
			playlist[i] = playlistFolder[tostring(i)].Value
		end

		while true do
			for _, soundID in ipairs(playlist) do
				local soundInstance = Instance.new "Sound"
				soundInstance.Volume = 0
				soundInstance.SoundId = "rbxassetid://" .. soundID
				soundInstance.Parent = script

				store:dispatch(actions.changeBackgroundTrack(player.Name, regionName, soundID))

				if not soundInstance.IsLoaded then
					soundInstance.Loaded:Wait()
				end

				local soundLength = soundInstance.TimeLength
				soundInstance:Destroy()
				task.wait(soundLength)
			end
		end
	end)
end

return 0
