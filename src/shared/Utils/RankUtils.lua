local ReplicatedStorage = game:GetService "ReplicatedStorage"

local strengthRanksFolder = ReplicatedStorage.Config.StrengthRanks

local strengthRanks = {}

for i = 1, #strengthRanksFolder:GetChildren() do
	strengthRanks[i] = strengthRanksFolder["Rank" .. i].RequiredStrength.Value
end

return {
	getRankFromStrength = function(strength: number): number
		local userRank: number = 1
		for rank, requirement in strengthRanks do
			if strength >= requirement then
				userRank = rank
			end
		end
		return userRank
	end,
	getMaxFearMeterFromRank = function(rank: number): number
		return strengthRanksFolder["Rank" .. rank].MaxMeter.Value
	end,
	getRankRequirement = function(rank: number): number
		return strengthRanks[rank]
	end,
}
