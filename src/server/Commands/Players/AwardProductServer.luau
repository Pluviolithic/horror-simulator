local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local server = ServerScriptService.Server

local store = require(server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local products = require(server.PurchaseManager.DeveloperProducts.Products)
local gamepasses = require(server.PurchaseManager.DeveloperProducts.Gamepasses)

return function(_, player: Player, ID: number)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end
	if not products(player, ID) then
		if selectors.hasGamepass(store:getState(), player.Name, ID) then
			return
		end
		gamepasses(player, ID)
	end
end
