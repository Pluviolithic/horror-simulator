local rewarders = require(script.Rewarders)

return function(player: Player, productID: number): (boolean, string?)
	if not rewarders[productID] then
		return
	end

	return pcall(rewarders[productID], player)
end
