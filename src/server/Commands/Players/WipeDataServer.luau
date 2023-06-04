local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(_, player: Player)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end
	store:dispatch(actions.resetPlayerData(player.Name))
end
