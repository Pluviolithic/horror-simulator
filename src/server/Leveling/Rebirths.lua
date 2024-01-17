local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local upgrades = ReplicatedStorage.Config.Rebirth.Upgrades
local exchangeAmount = ReplicatedStorage.Config.Rebirth.Exchange.Value

Remotes.Server:Get("Rebirth"):Connect(function(player)
	if selectors.getStat(store:getState(), player.Name, "Strength") < exchangeAmount then
		return
	end

	local rebirthIncrement = math.floor(selectors.getStat(store:getState(), player.Name, "Strength") / exchangeAmount)

	store:dispatch(actions.incrementPlayerStat(player.Name, "Rebirths", rebirthIncrement))
	store:dispatch(actions.incrementPlayerStat(player.Name, "RebirthTokens", rebirthIncrement))

	store:dispatch(actions.unlockPlayerPets(player.Name, selectors.getLockedPets(store:getState(), player.Name)))
	store:dispatch(actions.unequipPlayerPets(player.Name, selectors.getEquippedPets(store:getState(), player.Name)))

	local ownedPets = table.clone(selectors.getOwnedPets(store:getState(), player.Name))
	local lockedPets = table.clone(selectors.getLockedPets(store:getState(), player.Name))

	local bestPets = petUtils.getBestPetNames(ownedPets, math.huge)
	local legendaryKeepLimit = selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "KeepLegendaries")

	for _, petName in bestPets do
		if legendaryKeepLimit < 1 then
			break
		end
		local pet = petUtils.getPet(petName)
		if pet.RarityName.Value == "Legendary" and not pet:FindFirstChild "PermaLock" then
			legendaryKeepLimit -= 1
			lockedPets[petName] = (lockedPets[petName] or 0) + 1
		end
	end

	for petName, count in ownedPets do
		ownedPets[petName] = count - (lockedPets[petName] or 0)
	end
	store:dispatch(actions.deletePlayerPets(player.Name, ownedPets))

	store:dispatch(actions.rebirthPlayer(player.Name))
end)

Remotes.Server:Get("PurchaseRebirthUpgrade"):Connect(function(player, upgradeName)
	if not defaultStates.PurchaseData.RebirthUpgrades[upgradeName] then
		return
	end

	if
		#upgrades[upgradeName]:GetChildren()
		<= selectors.getRebirthUpgradeLevel(store:getState(), player.Name, upgradeName)
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

	if upgradeName == "ExtraPetStorage" then
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetCount", 5))
	elseif upgradeName == "EquipMorePets" then
		store:dispatch(actions.incrementPlayerStat(player.Name, "MaxPetEquipCount"))
	end
end)

return 0
