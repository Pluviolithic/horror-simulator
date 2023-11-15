local Players = game:GetService "Players"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)

local weapons = ReplicatedStorage.Weapons

local function findFirstChildWithTag(parent: Instance?, tag: string, recursive: boolean?): Instance?
	if not parent then
		return nil
	end
	for _, child in parent:GetChildren() do
		if CollectionService:HasTag(child, tag) then
			return child
		end
		if recursive then
			local result = findFirstChildWithTag(child, tag, recursive)
			if result then
				return result
			end
		end
	end
	return nil
end

return function(nextDispatch, store)
	return function(action)
		if
			not action.playerName
			or not Players:FindFirstChild(action.playerName)
			or (not selectors.isPlayerLoaded(store:getState(), action.playerName) and not action.profileData)
		then
			nextDispatch(action)
			return
		end

		local player = Players[action.playerName]
		local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
		local equippedWeapon = "Fists"

		if action.profileData then
			equippedWeapon = action.profileData.WeaponData.EquippedWeapon
		elseif action.weaponName then
			equippedWeapon = action.weaponName
		elseif selectors.getEquippedWeapon(store:getState(), player.Name) then
			equippedWeapon = selectors.getEquippedWeapon(store:getState(), player.Name)
		end

		local equippedWeaponAccessory = weapons.BodyAccessory:FindFirstChild(equippedWeapon)

		if not equippedWeaponAccessory then
			local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end
			nextDispatch(action)
			return
		end

		if action.type == "combatBegan" or action.type == "unequipWeapon" then
			local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end
		elseif action.type == "switchPlayerEnemy" then
			if not findFirstChildWithTag(player.Character, "WeaponAccessory") then
				humanoid:AddAccessory(equippedWeaponAccessory:Clone())
			end
		elseif action.type == "equipWeapon" then
			local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end
			if equippedWeaponAccessory then
				humanoid:AddAccessory(equippedWeaponAccessory:Clone())
			end
		elseif action.type == "addPlayer" then
			if action.profileData.WeaponData.EquippedWeapon ~= "Fists" then
				humanoid:AddAccessory(equippedWeaponAccessory:Clone())
			end
		end
		nextDispatch(action)
	end
end
