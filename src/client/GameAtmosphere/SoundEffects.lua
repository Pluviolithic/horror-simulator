local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local lastInCombat = -1
local random = Random.new()
local player = Players.LocalPlayer

ReplicatedStorage.Config.Audio.SoundEffects:Clone().Parent = workspace

local function playSoundEffect(soundName: string)
	if
		not selectors.isPlayerLoaded(store:getState(), player.Name)
		or not selectors.getSetting(store:getState(), player.Name, "SoundEffects")
		or (workspace.SoundEffects[soundName].IsPlaying and soundName ~= "Gems")
	then
		return
	end
	if soundName == "Gems" then
		task.spawn(function()
			local newSound = workspace.SoundEffects[soundName]:Clone()
			newSound.PlaybackSpeed = random:NextNumber(0.97, 1.1)
			newSound.Parent = workspace.SoundEffects
			newSound:Play()
			newSound.Ended:Wait()
			newSound:Destroy()
		end)
		return
	end
	workspace.SoundEffects[soundName]:Play()
end

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		if not selectors.isPlayerLoaded(oldState, player.Name) then
			return
		end
		if selectors.getCurrentTarget(newState, player.Name) or selectors.getCurrentTarget(oldState, player.Name) then
			lastInCombat = os.time()
		end
		if
			selectors.getStat(newState, player.Name, "Gems") > selectors.getStat(oldState, player.Name, "Gems")
			and os.time() - lastInCombat > 1
		then
			playSoundEffect "Gems"
		end
	end)
end)

return playSoundEffect
