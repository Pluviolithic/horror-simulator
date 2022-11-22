local ranksAndRequirements = {
	[1] = 1,
	[2] = 100,
	[3] = 200,
	[4] = 300,
	-- EX will define these based on preference
	-- Highly customized, so math is undesirable
}

return function(strength)
	local userRank = 0
	for rank, requirement in ipairs(ranksAndRequirements) do
		if strength >= requirement then
			userRank = rank
		end
	end
	return userRank
end
