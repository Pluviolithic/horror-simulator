local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- local Remotes = require(ReplicatedStorage.Common.Remotes)
-- local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

-- local function handleTutorialStep(stepNumber)
-- end

playerStatePromise:andThen(function(playerState)
	local tutorialStep = selectors.getTutorialStep(playerState, Players.LocalPlayer.Name)
	if tutorialStep > 10 then
		return
	end
end)

return 0
