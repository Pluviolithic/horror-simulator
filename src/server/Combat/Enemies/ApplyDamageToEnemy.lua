local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local weapons = ReplicatedStorage.Weapons

local function canAttack(player, enemy, info)
	local fightRange = enemy.Configuration.FightRange.Value
	local enemyRootPosition = enemy.RootPart.Position

	return info.HealthValue.Value > 0
		and selectors.isPlayerLoaded(store:getState(), player.Name)
		and selectors.getCurrentTarget(store:getState(), player.Name) == enemy
		and player:DistanceFromCharacter(enemyRootPosition) <= fightRange + 10
end

return function(player, enemy, info, janitor)
	local weaponName = selectors.getEquippedWeapon(store:getState(), player.Name)
	local damageMultiplier = if weaponName == "Fists" then 1 else weapons[weaponName].Damage.Value
	task.spawn(function()
		while canAttack(player, enemy, info) do
			local damageToDeal = math.clamp(
				selectors.getStat(store:getState(), player.Name, "Strength") * damageMultiplier,
				0,
				info.HealthValue.Value
			)
			info.DamageDealtByPlayer[player] = (info.DamageDealtByPlayer[player] or 0) + damageToDeal
			info.HealthValue.Value -= damageToDeal
			task.wait(animationUtilities.getPlayerAttackSpeed(player))
		end
	end)
	janitor:Add(function() end, true)
end
