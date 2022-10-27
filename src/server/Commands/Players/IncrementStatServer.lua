local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)

return function(_, player, stat, amount)
	local playerData = store:getState().Players[player.Name]
	if not playerData then
		return
	end
	store:dispatch(actions.incrementPlayerStat(player.Name, stat, amount))
end
