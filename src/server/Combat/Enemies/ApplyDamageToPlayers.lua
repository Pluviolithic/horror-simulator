local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

return function(enemy, engagedPlayers, janitor)
	local attackDelay = if CollectionService:HasTag(enemy, "Boss") then bossAttackSpeed else enemyAttackSpeed
	local damagePlayers = true

	task.spawn(function()
		while damagePlayers do
			for _, player in engagedPlayers do
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

	janitor:Add(function()
		damagePlayers = false
	end, true)
end
