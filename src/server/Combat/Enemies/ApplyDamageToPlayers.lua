local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(enemy, info, janitor)
	if info.DamageActive then
		return
	end
	info.DamageActive = true

	local attackDelay = if CollectionService:HasTag(enemy, "Boss") then bossAttackSpeed else enemyAttackSpeed
	local damagePlayers = true

	task.spawn(function()
		while damagePlayers do
			for _, player in info.EngagedPlayers do
				if not selectors.isPlayerLoaded(store:getState(), player.Name) then
					continue
				end
				if selectors.getActiveBoosts(store:getState(), player.Name)["FearlessBoost"] then
					continue
				end
				local fearMeterGoal = math.min(
					selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
						+ enemy.Configuration.Damage.Value,
					selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
				)
				local fearMeterAddendum = fearMeterGoal
					- selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")

				if fearMeterAddendum ~= 0 then
					store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", fearMeterAddendum))
				end
			end
			task.wait(attackDelay)
		end
	end)

	if Janitor.Is(janitor) then
		janitor:Add(function()
			info.DamageActive = nil
			damagePlayers = false
		end, true)
	end
end
