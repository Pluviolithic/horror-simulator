local rewarders = require(script.Rewarders)

return function(player: Player, productID: number): (boolean, string?)
	if not rewarders[tostring(productID)] then
		return
	end

	return pcall(rewarders[tostring(productID)], player)
end
