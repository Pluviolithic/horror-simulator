local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local weapons = ReplicatedStorage.Weapons

Remotes.Server:Get("PurchaseWeapon"):SetCallback(function(player: Player, weaponName: string)
	if typeof(weaponName) ~= "string" then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if playerState.OwnedWeapons[weaponName] then
		return 1
	end

	local price = if weapons:FindFirstChild(weaponName) then weapons[weaponName]:FindFirstChild "Price" else nil

	if not price then
		warn("Weapon model or price configured incorrectly for " .. weaponName)
		return 1
	end

	if playerState.Gems >= price.Value then
		store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", -price.Value))
		store:dispatch(actions.givePlayerWeapon(player.Name, weaponName))
		store:dispatch(actions.equipWeapon(player.Name, weaponName))
		return 0
	end

	return 1
end)

Remotes.Server:Get("EquipWeapon"):SetCallback(function(player: Player, weaponName: string)
	if typeof(weaponName) ~= "string" or not weapons:FindFirstChild(weaponName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.OwnedWeapons[weaponName] or playerState.EquippedWeapon == weaponName then
		return 1
	end

	store:dispatch(actions.equipWeapon(player.Name, weaponName))

	return 0
end)

return 0
