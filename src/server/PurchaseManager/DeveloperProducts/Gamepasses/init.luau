local rewarders = require(script.Rewarders)

return function(player: Player, gamepassID: number): boolean | string?
	if not rewarders[gamepassID] then
		return
	end

	return pcall(rewarders[gamepassID], player)
end
