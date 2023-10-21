local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(_, player: Player, stat: string, value: number)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end
	store:dispatch(actions.setPlayerMultiplier(player.Name, stat .. "Multiplier", value))
end
