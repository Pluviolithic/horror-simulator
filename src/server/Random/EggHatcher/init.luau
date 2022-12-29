local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rarities = require(script.Rarities)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)

local eggGemPrice: number = 50
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value

local function getWeightedRandom(weights): string
	local sum = 0
	for _, weight in weights do
		sum += weight
	end

	local random = math.random() * sum
	for pet, weight in weights do
		random -= weight
		if random <= 0 then
			return pet
		end
	end
end

Remotes.Server
	:Get("HatchEggs")
	:SetCallback(function(player: Player, count: number, auto: boolean, areaName: string): { string }?
		local playerState = store:getState().Players[player.Name]
		if not playerState.UnlockedAreas[areaName] or playerState.Gems < eggGemPrice then
			return
		end

		if count == 1 then
			return { getWeightedRandom(rarities[areaName]) }
		end

		local success, message = pcall(MarketplaceService.HasPass, MarketplaceService, tripleHatchGamepassID)

		if not success then
			warn("Failed to verify 3x gamepass ownership: " .. message)
			return nil
		end

		if auto then
			return nil
		end

		if not message then
			return nil
		end

		local results: { string } = {}
		for i = 1, math.min(3, math.floor(playerState.Cash / 50)) do
			results[i] = getWeightedRandom(rarities[areaName])
		end
		return results
	end)
