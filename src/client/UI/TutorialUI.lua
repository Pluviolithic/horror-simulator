local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
-- local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local function handleTutorialStep(state)
	local step = selectors.getTutorialStep(state, player.Name)

	if step == 1 and selectors.getStat(state, player.Name, "Kills") > 1 then
		Remotes.Client:Get("IncrementTutorialStep"):FireServer()
	elseif step == 2 then
		local starterStrength = selectors.getStat(state, player.Name, "Strength")
		local connection
		connection = store.changed:connect(function(newState)
			local newStrength = selectors.getStat(newState, player.Name, "Strength")
			if newStrength - starterStrength >= 20 then
				connection:Disconnect()
				Remotes.Client:Get("IncrementTutorialStep"):FireServer()
			end
		end)
	elseif step == 3 then
		print "step 3 is here"
	end
end

playerStatePromise:andThen(function()
	local tutorialStep = selectors.getTutorialStep(store:getState(), player.Name)
	if tutorialStep > 10 then
		return
	end
	handleTutorialStep(store:getState())
	store.changed:connect(function(newState, oldState)
		local newTutorialStep = selectors.getTutorialStep(newState, player.Name)
		local oldTutorialStep = selectors.getTutorialStep(oldState, player.Name)
		if newTutorialStep ~= oldTutorialStep then
			handleTutorialStep(newState)
		end
	end)
end)

return 0
