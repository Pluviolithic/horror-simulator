local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local gamepasses = require(server.PurchaseManager.DeveloperProducts.Gamepasses)

return function(_, player: Player)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end

	for _, ID in ReplicatedStorage.Config.GamepassData.IDs:GetChildren() do
		if selectors.hasGamepass(store:getState(), player.Name, ID.Value) then
			continue
		end
		gamepasses(player, ID.Value)
	end
end
