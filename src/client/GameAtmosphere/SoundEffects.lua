local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local random = Random.new()
local player = Players.LocalPlayer

ReplicatedStorage.Config.Audio.SoundEffects:Clone().Parent = workspace

local function playSoundEffect(soundName: string)
	if
		not selectors.getSetting(store:getState(), player.Name, "SoundEffects")
		or workspace.SoundEffects[soundName].IsPlaying
	then
		return
	end
	if soundName == "Gems" then
		workspace.SoundEffects[soundName].PlaybackSpeed = random:NextNumber(0.97, 1.1)
	end
	workspace.SoundEffects[soundName]:Play()
end

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		if not selectors.isPlayerLoaded(oldState, player.Name) then
			return
		end
		if selectors.getStat(newState, player.Name, "Gems") > selectors.getStat(oldState, player.Name, "Gems") then
			playSoundEffect "Gems"
		end
	end)
end)

return playSoundEffect
