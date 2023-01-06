local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rarities = require(script.Rarities)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local eggGemPrice: number = 50
local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value

local function getWeightedRandom(weights: { [string]: { [string]: string | number } }): string
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

local function awardPetsToPlayer(player: Player, pets: { string }): ()
	store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -eggGemPrice * #pets))
	store:dispatch(actions.givePlayerPets(player.Name, pets))
end

Remotes.Server:Get("HatchEggs"):SetCallback(function(player: Player, count: number, areaName: string): { string }?
	local playerState = store:getState().Players[player.Name]

	if areaRequirements[areaName].Value > playerState.Strength or playerState.Gems < eggGemPrice then
		return nil
	end

	if playerState.CurrentPetCount + count > playerState.MaxPetCount then
		return nil
	end

	if count == 1 or playerState.Gems < 3 * eggGemPrice then
		local results = { getWeightedRandom(rarities[areaName]) }
		awardPetsToPlayer(player, results)
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
		results[i] = getWeightedRandom(rarities[areaName])
	end
	awardPetsToPlayer(player, results)

	return results
end)

return 0
