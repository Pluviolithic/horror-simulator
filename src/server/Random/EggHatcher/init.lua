local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local rarities = require(script.Rarities)
local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)

local eggGemPricesConfig = ReplicatedStorage.Config.Pets.Prices
local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3xHatch"].Value

local luckBoostedRarities = {
	Rare = true,
	Epic = true,
	Legendary = true,
}

local function getWeightedRandom(player: Player, weights: { [string]: { [string]: string | number } }): string
	local luck = selectors.getStat(store:getState(), player.Name, "Luck")
	local newWeights = {}

	if selectors.getActiveBoosts(store:getState(), player.Name)["LuckBoost"] then
		luck += 5
	end

	if selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "Lucky") > 0 then
		if luck == 0 then
			luck = 1
		end
		luck += 0.1 * selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "Lucky")
	end

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
		if petUtils.getPet(pet).RarityName.Value == "Legendary" then
			Remotes.Server:Get("LegendaryUnboxed"):SendToAllPlayers(player.Name, pet)
		end
		petsDict[pet] = (petsDict[pet] or 0) + 1
	end
	store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -eggGemPrice * #pets))
	store:dispatch(actions.givePlayerPets(player.Name, petsDict))
	store:dispatch(actions.logHatchedPetRarities(player.Name, petUtils.getPetRarities(pets)))

	local petsToEquip, counter = {}, 0
	local equippedPetsCount = petUtils.countPetsInDict(selectors.getEquippedPets(store:getState(), player.Name))
	for _, petName in petUtils.getBestPetNames(petsDict, #pets) do
		if equippedPetsCount + counter >= selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount") then
			break
		end
		counter += 1
		petsToEquip[petName] = if petsToEquip[petName] then petsToEquip[petName] + 1 else 1
	end
	if counter > 0 then
		store:dispatch(actions.equipPlayerPets(player.Name, petsToEquip))
		store:dispatch(actions.lockPlayerPets(player.Name, petsToEquip))
	end
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

	if not selectors.hasGamepass(store:getState(), player.Name, tripleHatchGamepassID) then
		return nil
	end

	local results = {}
	for i = 1, 3 do
		results[i] = getWeightedRandom(player, rarities[areaName])
	end
	awardPetsToPlayer(player, results, eggGemPrice)

	return results
end)

return 0
