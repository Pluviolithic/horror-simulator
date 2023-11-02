local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(_, player: Player, name: string, amount: number)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end
	store:dispatch(actions.givePlayerPets(player.Name, { [name] = amount }))
end
