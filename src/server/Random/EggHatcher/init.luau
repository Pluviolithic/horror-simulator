local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rarities = require(script.Rarities)
local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local eggGemPricesConfig = ReplicatedStorage.Config.Pets.Prices
local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value

local luckBoostedRarities = {
	Rare = true,
	Epic = true,
	Legendary = true,
}

local function getWeightedRandom(player: Player, weights: { [string]: { [string]: string | number } }): string
	local luck = selectors.getStat(store:getState(), player.Name, "Luck")
	local newWeights = {}

	if luck ~= 0 then
		local normalRarity = 0
		local boostedRarity = 0
		local boostedPetCount = 0
		for pet, weight in weights do
			if luckBoostedRarities[weight.RarityName] then
				boostedPetCount += 1
				normalRarity += weight.Rarity
				boostedRarity += weight.Rarity * luck
				newWeights[pet] = {
					Rarity = weight.Rarity * luck,
					RarityName = weight.RarityName,
				}
			end
		end

		local rarityReduceAmount = (boostedRarity - normalRarity) / (Sift.Dictionary.count(weights) - boostedPetCount)
		for pet, weight in weights do
			if not luckBoostedRarities[weight.RarityName] then
				newWeights[pet] = {
					Rarity = weight.Rarity - rarityReduceAmount,
					RarityName = weight.RarityName,
				}
			end
		end
	end

	if luck ~= 0 then
		weights = newWeights
	end

	local sum = 0
	for _, weight in weights do
		sum += weight.Rarity
	end

	local random = math.random() * sum
	for pet, weight in weights do
		random -= weight.Rarity
		if random <= 0 then
			return pet
		end
	end

	return next(weights) :: string
end

local function awardPetsToPlayer(player: Player, pets: { string }, eggGemPrice): ()
	local petsDict = {}
	for _, pet in pets do
		petsDict[pet] = (petsDict[pet] or 0) + 1
	end
	store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -eggGemPrice * #pets))
	store:dispatch(actions.givePlayerPets(player.Name, petsDict))
end

Remotes.Server:Get("HatchEggs"):SetCallback(function(player: Player, count: number, areaName: string)
	local eggGemPrice = eggGemPricesConfig[areaName].Value
	if
		areaRequirements[areaName].Value > selectors.getStat(store:getState(), player.Name, "Strength")
		or selectors.getStat(store:getState(), player.Name, "Gems") < eggGemPrice
	then
		return nil
	end

	if
		selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + count
		> selectors.getStat(store:getState(), player.Name, "MaxPetCount")
	then
		return nil
	end

	if count == 1 or selectors.getStat(store:getState(), player.Name, "Gems") < 3 * eggGemPrice then
		local results = { getWeightedRandom(player, rarities[areaName]) }
		awardPetsToPlayer(player, results, eggGemPrice)
		return results
	end

	local success, message =
		pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, tripleHatchGamepassID)

	if not success then
		warn("Failed to verify 3x gamepass ownership: " .. message)
		return nil
	elseif not message then
		return nil
	end

	local results: { string } = {}
	for i = 1, 3 do
		results[i] = getWeightedRandom(player, rarities[areaName])
	end
	awardPetsToPlayer(player, results, eggGemPrice)

	return results
end)

return 0
