local rewarders = require(script.Rewarders)

return function(player, gamepassID)
	if not rewarders[gamepassID] then
		return
	end

	return pcall(rewarders[gamepassID], player)
end
