local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rarities = require(script.Rarities)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local eggGemPrice: number = 50
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

local function getMaxHatches(gems: number, areaName: string): { string }
	local results: { string } = {}
	for i = 1, math.min(3, math.floor(gems / 50)) do
		results[i] = getWeightedRandom(rarities[areaName])
	end
	return results
end

local function awardPetsToPlayer(player: Player, pets: { string }): ()
	store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -eggGemPrice * #pets))
	local newPets = {}
	for _, pet in pets do
		newPets[pet] = true
	end
	store:dispatch(actions.givePlayerPets(player.Name, newPets))
end

Remotes.Server
	:Get("HatchEggs")
	:SetCallback(function(player: Player, count: number, auto: boolean, areaName: string): { string }?
		local playerState = store:getState().Players[player.Name]
		if not playerState.UnlockedAreas[areaName] or playerState.Gems < eggGemPrice then
			return
		end

		if count == 1 then
			local results = { getWeightedRandom(rarities[areaName]) }
			awardPetsToPlayer(player, results)
			return results
		end

		local success, message = pcall(MarketplaceService.HasPass, MarketplaceService, tripleHatchGamepassID)

		if not success then
			warn("Failed to verify 3x gamepass ownership: " .. message)
			return nil
		end

		if auto then
			task.spawn(function()
				while playerState.Gems >= eggGemPrice and Players:FindFirstChild(player.Name) do
					local results: { string } = getMaxHatches(playerState.Gems, areaName)
					awardPetsToPlayer(player, results)
					Remotes.Server:Get("AutoHatchResponses"):SendToClient(player, results)

					task.wait(1)

					playerState = store:getState().Players[player.Name]
				end
			end)
			return nil
		end

		if not message then
			return nil
		end
		local results: { string } = getMaxHatches(playerState.Gems, areaName)
		awardPetsToPlayer(player, results)
		return results
	end)

return 0
