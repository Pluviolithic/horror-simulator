local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local weapons = ReplicatedStorage.Weapons

local function canAttack(player, enemy, info)
	if not enemy:IsDescendantOf(game) then
		return false
	end

	local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"
	local fightRange = enemy.Configuration.FightRange.Value

	return info.HealthValue.Value > 0
		and selectors.isPlayerLoaded(store:getState(), player.Name)
		and selectors.getCurrentTarget(store:getState(), player.Name) == enemy
		and player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5
end

return function(player, enemy, info, janitor)
	local enabled = true
	local weaponName = selectors.getEquippedWeapon(store:getState(), player.Name)
	local damageMultiplier = if weaponName == "Fists" then 1 else weapons[weaponName].Damage.Value

	janitor:Add(function()
		enabled = false
	end, true)

	store:dispatch(actions.combatBegan(player.Name))

	if weaponName ~= "Fists" then
		local weaponAccessory = weapons[weaponName]:Clone()
		player.Character.Humanoid:AddAccessory(weaponAccessory)
		janitor:Add(weaponAccessory)
	end

	task.spawn(function()
		while canAttack(player, enemy, info) and enabled do
			local damageToDeal = math.clamp(
				selectors.getStat(store:getState(), player.Name, "Strength") * damageMultiplier,
				0,
				info.HealthValue.Value
			)
			info.DamageDealtByPlayer[player] = (info.DamageDealtByPlayer[player] or 0) + damageToDeal
			info.HealthValue.Value -= damageToDeal
			Remotes.Server:Get("SendFightInfo"):SendToPlayer(player, {
				Gems = enemy.Configuration.Gems.Value,
				Health = info.HealthValue.Value,
				MaxHealth = info.MaxHealth,
				DamageDealtByPlayer = info.DamageDealtByPlayer[player],
			})
			task.wait(animationUtilities.getPlayerAttackSpeed(player))
		end
		if not enemy:FindFirstChild "Humanoid" then
			return
		end
		local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"
		local fightRange = enemy.Configuration.FightRange.Value
		if player:DistanceFromCharacter(rootPart.Position) > fightRange + 10 and Janitor.Is(janitor) then
			janitor:Destroy()
		end
	end)
end
