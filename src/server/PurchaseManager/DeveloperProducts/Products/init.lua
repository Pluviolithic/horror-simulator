local rewarders = require(script.Rewarders)

return function(player: Player, productID: number): (boolean, string?)
	if not rewarders[productID] then
		return false, "No rewarder for product ID " .. tostring(productID)
	end

	return pcall(rewarders[productID], player)
end
