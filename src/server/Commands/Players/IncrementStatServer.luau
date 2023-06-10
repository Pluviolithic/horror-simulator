local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local profileTemplate = require(server.PlayerManager.ProfileTemplate)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(_, player: Player, stat: string, amount: number)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) or not profileTemplate.Stats[stat] then
		return
	end
	store:dispatch(actions.incrementPlayerStat(player.Name, stat, amount))
end
