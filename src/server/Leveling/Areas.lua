local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local actions = require(ServerScriptService.Server.State.Actions)
local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local teleporterPrices = ReplicatedStorage.Config.Teleports
local areaRequirements = ReplicatedStorage.Config.AreaRequirements

Remotes.Server:Get("PurchaseTeleporter"):Connect(function(player, areaName)
	if not teleporterPrices:FindFirstChild(areaName) then
		return 1
	end

	local price = teleporterPrices[areaName].Value
	local hasFreeTeleporters = selectors.hasGamepass(store:getState(), player.Name, "FreeTeleporters")
	if
		(selectors.getStat(store:getState(), player.Name, "Gems") < price and not hasFreeTeleporters)
		or selectors.getStat(store:getState(), player.Name, "Strength") < areaRequirements[areaName].Value
		or selectors.hasTeleporter(store:getState(), player.Name, areaName)
	then
		return 1
	end

	if not hasFreeTeleporters then
		store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -price))
	end
	store:dispatch(actions.givePlayerTeleporter(player.Name, areaName))

	return 0
end)

return 0
