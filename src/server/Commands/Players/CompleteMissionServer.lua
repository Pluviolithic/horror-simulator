local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

return function(_, player: Player, gemReward: number)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end
	store:dispatch(actions.completeMission(player.Name, regionUtils.getPlayerLocationName(player.Name), gemReward))
end
