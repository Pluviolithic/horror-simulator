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

local function modifyAccessories(player, action, equippedWeaponAccessory, store)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild "Humanoid"
	if action.type == "unequipWeapon" then
		local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
		if oldEquippedWeaponAccessory then
			oldEquippedWeaponAccessory:Destroy()
		end
	elseif action.type == "equipWeapon" then
		local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
		if oldEquippedWeaponAccessory then
			oldEquippedWeaponAccessory:Destroy()
		end
		if equippedWeaponAccessory then
			humanoid:AddAccessory(equippedWeaponAccessory:Clone())
		end
	elseif action.type == "rebirthPlayer" then
		local bestWeaponName, bestWeaponDamage = "Fists", -1
		local ownedWeapons = selectors.getOwnedWeapons(store:getState(), player.Name)
		for weaponName in ownedWeapons do
			if weaponName == "Fists" then
				continue
			end
			if
				not weapons[weaponName]:FindFirstChild "Price"
				and weapons[weaponName].Damage.Value > bestWeaponDamage
			then
				bestWeaponName = weaponName
				bestWeaponDamage = weapons[weaponName].Damage.Value
			end
		end
		if bestWeaponName ~= "Fists" then
			local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end
			if weapons.BodyAccessory:FindFirstChild(bestWeaponName) then
				humanoid:AddAccessory(weapons.BodyAccessory[bestWeaponName]:Clone())
			end
		else
			local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end
		end
	elseif action.type == "addPlayer" then
		if action.profileData.WeaponData.EquippedWeapon ~= "Fists" then
			humanoid:AddAccessory(equippedWeaponAccessory:Clone())
		end
	end
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

		task.spawn(modifyAccessories, player, action, equippedWeaponAccessory, store)
		nextDispatch(action)
	end
end
