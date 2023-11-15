local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local applyDamageToEnemy = require(script.ApplyDamageToEnemy)
local store = require(ServerScriptService.Server.State.Store)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local actions = require(ServerScriptService.Server.State.Actions)
local applyDamageToPlayers = require(script.ApplyDamageToPlayers)
local applyEnemyAnimations = require(script.ApplyEnemyAnimations)
local applyPlayerAnimations = require(script.ApplyPlayerAnimations)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local function handleEnemy(enemy)
	local info = {
		HealthValue = enemy.Configuration.FearHealth,
		MaxHealth = enemy.Configuration.FearHealth.Value,
		DamageDealtByPlayer = {},
	}
	local debounces = {}
	local enemyJanitor = Janitor.new()

	enemyJanitor:Add(enemy)

	enemy.Hitbox.ClickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
		if debounces[player] or not humanoid then
			return
		end

		debounces[player] = true
		task.delay(1, function()
			debounces[player] = nil
		end)

		if
			selectors.getCurrentTarget(store:getState(), player.Name) == enemy
			or CollectionService:HasTag(selectors.getCurrentTarget(store:getState(), player.Name), "PunchingBag")
		then
			return
		end

		local playerJanitor = Janitor.new()
		store:dispatch(actions.switchPlayerEnemy(player.Name, enemy))

		playerJanitor:Add(store.changed:connect(function(newState)
			if selectors.getCurrentTarget(newState, player.Name) ~= enemy then
				playerJanitor:Destroy()
			end
		end, "disconnect"))
	end)
end

for _, enemy in CollectionService:GetTagged "Enemy" do
	local success, error = pcall(handleEnemy, enemy)
	if not success then
		warn(error)
	end
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(function(enemy)
	local success, error = pcall(handleEnemy, enemy)
	if not success then
		warn(error)
	end
end)

return 0
