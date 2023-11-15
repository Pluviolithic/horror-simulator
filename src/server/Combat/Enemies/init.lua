local Players = game:GetService "Players"
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
local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)

local bossRespawnRate = ReplicatedStorage.Config.Combat.BossRespawnRate.Value
local enemyRespawnRate = ReplicatedStorage.Config.Combat.EnemyRespawnRate.Value

local function addHealthBar(enemy, info)
	local NPCUI = enemy:FindFirstChild("NPCUI", true)
	HealthBar.new(NPCUI.Frame.Background.Frame):connect(enemy)
	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	info.HealthValue.Value = info.MaxHealth
	NPCUI.Enabled = true
end

local function orientPlayer(player, rootPart)
	local enemyDirection = rootPart.Position * Vector3.new(1, 0, 1)
	local playerRootPart = player.Character and player.Character:FindFirstChild "HumanoidRootPart"
	local playerPosition = if playerRootPart then playerRootPart.Position else Vector3.new(0, 0, 0)

	if player.Character then
		player.Character:PivotTo(
			CFrame.lookAt(playerPosition, enemyDirection + playerPosition.Y * Vector3.new(0, 1, 0))
		)
	end
end

local function orientEnemy(rootPart, playerPosition)
	rootPart.CFrame = CFrame.lookAt(
		rootPart.Position,
		playerPosition * Vector3.new(1, 0, 1) + rootPart.Position.Y * Vector3.new(0, 1, 0)
	)
end

local function handleEnemy(enemy)
	local info = {
		Active = false,
		HealthValue = enemy.Configuration.FearHealth,
		MaxHealth = enemy.Configuration.FearHealth.Value,
		DamageDealtByPlayer = {},
		EngagedPlayers = {},
	}

	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local fightRange = enemy.Configuration.FightRange.Value
	local respawnRate = if isBoss then bossRespawnRate else enemyRespawnRate
	local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"

	local debounces = {}
	local enemyClone = enemy:Clone()
	local enemyJanitor = Janitor.new()

	enemyJanitor:Add(enemy)
	enemyJanitor:Add(info.HealthValue.Value:GetPropertyChangedSignal("Value"):Connect(function()
		if info.HealthValue <= 0 then
			enemyJanitor:Destroy()
			for player, damage in info.DamageDealtByPlayer do
				if not Players:FindFirstChild(player.Name) then
					continue
				end

				store:dispatch(actions.incrementPlayerStat(player.Name, "Fear", damage, enemy.Name))
				store:dispatch(actions.incrementPlayerStat(player.Name, "Kills"))
				store:dispatch(actions.logKilledEnemyType(player.Name, enemy.Name))

				if damage >= info.MaxHealth * 0.3 then
					store:dispatch(
						actions.incrementPlayerStat(player.Name, "Gems", enemy.Configuration.Gems.Value, enemy.Name)
					)
				end
			end
			task.wait(respawnRate)
			enemyClone.Parent = workspace
		end
	end))
	addHealthBar(enemy, info)

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

		repeat
			task.wait(0.1)
		until player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5
			or not Janitor.Is(playerJanitor)
			or not selectors.isPlayerLoaded(store:getState(), player.Name)

		if
			not Janitor.Is(playerJanitor)
			or (player:DistanceFromCharacter(rootPart.Position) > fightRange + 10)
			or not selectors.isPlayerLoaded(store:getState(), player.Name)
		then
			return
		end

		orientPlayer(player, rootPart)
		table.insert(info.EngagedPlayers, player)

		if #info.EngagedPlayers == 1 and not isBoss then
			orientEnemy(rootPart, player.Character.HumanoidRootPart.Position)
		end

		playerJanitor:Add(function()
			table.remove(info.EngagedPlayers, table.find(info.EngagedPlayers, player))
			if #info.EngagedPlayers == 1 and not isBoss then
				orientEnemy(rootPart, player.Character.HumanoidRootPart.Position)
			end
		end, true)

		applyEnemyAnimations(enemy, info, enemyJanitor)
		applyPlayerAnimations(player, playerJanitor)
		applyDamageToPlayers(enemy, info, enemyJanitor)
		applyDamageToEnemy(player, enemy, info, playerJanitor)
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
