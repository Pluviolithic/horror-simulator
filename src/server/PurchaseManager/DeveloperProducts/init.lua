local MarketplaceService = game:GetService "MarketplaceService"

local gamepasses = require(script.Gamepasses)
local products = require(script.Products)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassID, purchased)
    if not purchased then
        return
    end

    local success, err = gamepasses(player, gamepassID)
	if success then
        return
    end

    if err then
        warn(err)
    else
        warn "No such product is indexed for purchasing."
    end
end)

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
