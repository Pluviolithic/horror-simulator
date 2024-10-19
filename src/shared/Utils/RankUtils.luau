local ReplicatedStorage = game:GetService "ReplicatedStorage"

local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local strengthRanksFolder = ReplicatedStorage.Config.StrengthRanks

local strengthRanks = {}
local bestAreaName = "Clown Town"

for i = 1, #strengthRanksFolder:GetChildren() do
	strengthRanks[i] = strengthRanksFolder["Rank" .. i].RequiredStrength.Value
end

for _, requirement in areaRequirements:GetChildren() do
	if requirement.Value > areaRequirements[bestAreaName].Value then
		bestAreaName = requirement.Name
	end
end

local rankUtils
rankUtils = {
	getRankFromStrength = function(strength: number): number
		local userRank = 1
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
	getBestUnlockedArea = function(strength): string
		local biggestRequirement, bestUnlockedArea = -1, "Clown Town"
		for _, requirement in areaRequirements:GetChildren() do
			if requirement.Value <= strength and requirement.Value > biggestRequirement then
				biggestRequirement = requirement.Value
				bestUnlockedArea = requirement.Name
			end
		end
		return bestUnlockedArea
	end,
	hasBestAreaUnlocked = function(strength: number): boolean
		if rankUtils.getBestUnlockedArea(strength) == bestAreaName then
			return true
		else
			return false
		end
	end,
	getBestAreaName = function(): string
		return bestAreaName
	end,
}

return rankUtils
