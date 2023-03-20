local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local actions = require(ServerScriptService.Server.State.Actions)
local store = require(ServerScriptService.Server.State.Store)

local teleporterPrices = ReplicatedStorage.Config.Teleports
local areaRequirements = ReplicatedStorage.Config.AreaRequirements

Remotes.Server:Get("PurchaseTeleporter"):Connect(function(player, areaName)
	local playerState = store:getState().Players[player.Name]
	if not teleporterPrices:FindFirstChild(areaName) then
		return 1
	end

	local price = teleporterPrices[areaName].Value
	if
		playerState.Gems < price
		or playerState.Strength < areaRequirements[areaName].Value
		or playerState.PurchasedTeleporters[areaName]
	then
		return 1
	end

	store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -price))
	store:dispatch(actions.givePlayerTeleporter(player.Name, areaName))

	return 0
end)

return 0
