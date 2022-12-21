local ranksAndRequirements: { [number]: number } = {
	[1] = 1,
	[2] = 100,
	[3] = 200,
	[4] = 300,
	-- EX will define these based on preference
	-- Highly customized, so math is undesirable
}

return function(strength): number
	local userRank: number = 0
	for rank, requirement in ranksAndRequirements do
		if strength >= requirement then
			userRank = rank
		end
	end
	return userRank
end
