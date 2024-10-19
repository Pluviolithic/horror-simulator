local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer
local reverbActive = false
local reverb = ReplicatedStorage.Config.Audio.ScaredSoundEffects.Reverb

local function isScared(state)
	if selectors.getActiveBoosts(state, player.Name)["FearlessBoost"] then
		return false
	end
	return selectors.getStat(state, player.Name, "CurrentFearMeter")
			== selectors.getStat(state, player.Name, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, player.Name, "LastScaredTimestamp")) < 121
end

local function applyReverb(sounds, yes)
	reverbActive = yes
	for _, sound in sounds:GetChildren() do
		local existingReverb = sound:FindFirstChild "Reverb"
		if yes then
			if not existingReverb then
				reverb:Clone().Parent = sound
			end
		elseif existingReverb then
			existingReverb:Destroy()
		end
	end
end

playerStatePromise:andThen(function()
	local soundFolder = workspace:WaitForChild "AudioInstances"
	applyReverb(soundFolder, isScared(store:getState()))
	store.changed:connect(function(newState, oldState)
		if selectors.isPlayerLoaded(oldState, player.Name) and isScared(newState) == isScared(oldState) then
			return
		end
		if isScared(newState) then
			applyReverb(soundFolder, true)
		else
			applyReverb(soundFolder, false)
		end
	end)

	soundFolder.ChildAdded:Connect(function(child)
		if reverbActive then
			reverb:Clone().Parent = child
		end
	end)
end)

return applyReverb
