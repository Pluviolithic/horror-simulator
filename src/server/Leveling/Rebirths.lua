local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local upgrades = ReplicatedStorage.Config.Rebirth.Upgrades
local exchangeAmount = ReplicatedStorage.Config.Rebirth.Exchange.Value

Remotes.Server:Get("Rebirth"):SetCallback(function(player)
	if selectors.getStat(store:getState(), player.Name, "Strength") < exchangeAmount then
		return
	end

	local equippedPets = selectors.getEquippedPets(store:getState(), player.Name)
	local rebirthIncrement = math.floor(selectors.getStat(store:getState(), player.Name, "Strength") / exchangeAmount)

	store:dispatch(actions.incrementPlayerStat(player.Name, "Rebirths", rebirthIncrement))
	store:dispatch(actions.incrementPlayerStat(player.Name, "RebirthTokens", rebirthIncrement))

	store:dispatch(actions.unlockPlayerPets(player.Name, equippedPets))
	store:dispatch(actions.unequipPlayerPets(player.Name, equippedPets))

	local ownedPets = table.clone(selectors.getOwnedPets(store:getState(), player.Name))
	local lockedPets = selectors.getLockedPets(store:getState(), player.Name)
	for petName, count in ownedPets do
		ownedPets[petName] = count - (lockedPets[petName] or 0)
	end
	store:dispatch(actions.deletePlayerPets(player.Name, ownedPets))

	store:dispatch(actions.rebirthPlayer(player.Name))
end)

Remotes.Server:Get("PurchaseRebirthUpgrade"):SetCallback(function(player, upgradeName)
	if not defaultStates.PurchaseData.RebirthUpgrades[upgradeName] then
		return
	end

	if
		#upgrades[upgradeName]:GetChildren()
		>= selectors.getRebirthUpgradeLevel(store:getState(), player.Name, upgradeName)
	then
		return
	end

	local cost =
		upgrades[upgradeName][selectors.getRebirthUpgradeLevel(store:getState(), player.Name, upgradeName) + 1].Value

	if selectors.getStat(store:getState(), player.Name, "RebirthTokens") < cost then
		return
	end

	store:dispatch(actions.incrementPlayerStat(player.Name, "RebirthTokens", -cost))
	store:dispatch(actions.incrementRebirthUpgradeLevel(player.Name, upgradeName))
end)
