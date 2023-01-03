local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local products = require(script.Products)
local gamepasses = require(script.Gamepasses)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(
	function(player: Player, gamepassID: number, purchased: boolean)
		if not purchased then
			return
		end

		local success, err = gamepasses(player, gamepassID)
		if success then
			store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
			return
		end

		if err then
			warn(err)
		else
			warn "No such product is indexed for purchasing."
		end
	end
)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, err = products(player, receiptInfo.ProductId)
	if not success then
		if err then
			warn(err)
		else
			warn "No such product is indexed for purchasing."
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

return 0
