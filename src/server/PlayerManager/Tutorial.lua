local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

Remotes.Server:Get("IncrementTutorialStep"):Connect(function(player)
	if selectors.getTutorialStep(store:getState(), player.Name) < 11 then
		store:dispatch(actions.incrementTutorialStep(player.Name))
	end
end)

return 0
