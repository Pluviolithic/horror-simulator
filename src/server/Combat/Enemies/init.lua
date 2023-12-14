local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local TweenService = game:GetService "TweenService"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local applyDamageToEnemy = require(script.ApplyDamageToEnemy)
local store = require(ServerScriptService.Server.State.Store)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local actions = require(ServerScriptService.Server.State.Actions)
local applyDamageToPlayers = require(script.ApplyDamageToPlayers)
local applyEnemyAnimations = require(script.ApplyEnemyAnimations)
local applyPlayerAnimations = require(script.ApplyPlayerAnimations)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)

local gemVisualPart = ReplicatedStorage.GemVisualPart
local bossRespawnRate = ReplicatedStorage.Config.Combat.BossRespawnRate.Value
local enemyRespawnRate = ReplicatedStorage.Config.Combat.EnemyRespawnRate.Value
local maxFearFromBossPercentage = ReplicatedStorage.Config.Combat.BossFearPercentage.Value

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

local function handleEnemy(enemy)
	local info = {
		HealthValue = enemy.Configuration.FearHealth,
		MaxHealth = enemy.Configuration.FearHealth.Value,
		DamageDealtByPlayer = {},
		EngagedPlayers = {},
		Janitors = {},
	}

	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local fightRange = enemy.Configuration.FightRange.Value
	local respawnRate = if isBoss then bossRespawnRate else enemyRespawnRate
	local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"
	local idleAnimationInstance = if enemy.Configuration:FindFirstChild "IdleAnim"
		then enemy.Configuration.IdleAnim.Anim
		else nil

	local debounces = {}
	local lastInCombat = -1
	local enemyClone = enemy:Clone()
	local enemyJanitor = Janitor.new()
	local enemyAnimationJanitor = Janitor.new()

	if idleAnimationInstance then
		local idleTrack = enemy.Humanoid:LoadAnimation(idleAnimationInstance)
		idleTrack.Priority = Enum.AnimationPriority.Idle
		idleTrack:Play()
	end

	task.spawn(function()
		while enemy:IsDescendantOf(game) do
			if os.time() - lastInCombat < (if isBoss then 15 else 5) or #info.EngagedPlayers > 0 then
				task.wait(1)
				continue
			end
			local foundPlayerInRange = false
			for _, player in Players:GetPlayers() do
				if player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5 then
					foundPlayerInRange = true
					break
				end
			end
			if not foundPlayerInRange then
				info.HealthValue.Value = info.MaxHealth
				table.clear(info.DamageDealtByPlayer)
			end
			task.wait(5)
		end
	end)

	if isBoss then
		enemyJanitor:Add(function()
			enemy.Hitbox.DeathSFX:Play()
		end, true)
	end
	enemyJanitor:Add(enemyAnimationJanitor)
	enemyJanitor:Add(info.HealthValue:GetPropertyChangedSignal("Value"):Connect(function()
		if info.HealthValue.Value <= 0 then
			for player, damage in info.DamageDealtByPlayer do
				if Janitor.Is(info.Janitors[player]) then
					info.Janitors[player]:Destroy()
				end
				if not Players:FindFirstChild(player.Name) then
					continue
				end

				local fearToSend, gemsToSend = damage, enemy.Configuration.Gems.Value * damage / info.MaxHealth
				if isBoss then
					local fear = math.clamp(damage, 0, info.MaxHealth * maxFearFromBossPercentage / 100)
					fearToSend = fear
					store:dispatch(actions.incrementPlayerStat(player.Name, "Fear", fear, enemy.Name))
				else
					store:dispatch(actions.incrementPlayerStat(player.Name, "Fear", damage, enemy.Name))
				end

				store:dispatch(actions.incrementPlayerStat(player.Name, "Kills"))
				store:dispatch(actions.logKilledEnemyType(player.Name, enemy.Name))
				store:dispatch(actions.incrementPlayerStat(player.Name, "Gems", gemsToSend, enemy.Name))

				Remotes.Server:Get("SpawnRewardPart"):SendToPlayer(player, fearToSend, gemsToSend)
				Remotes.Server
					:Get("DropGems")
					:SendToPlayer(player, rootPart.CFrame, gemVisualPart, enemy.Configuration.GemVisualCount.Value)
			end
			enemyJanitor:Cleanup()
			enemyJanitor:Add(enemy)

			-- destroy npc ui
			-- fade out enemy

			enemy:FindFirstChild("NPCUI", true).Enabled = false
			for _, descendant in enemy:GetDescendants() do
				if
					not descendant:IsA "BasePart"
					or descendant.Name == "HumanoidRootPart"
					or descendant.Name == "Hitbox"
				then
					continue
				end

				local tween = TweenService:Create(descendant, TweenInfo.new(0.5), { Transparency = 1 })
				enemyJanitor:Add(tween)
				tween:Play()
			end

			if isBoss then
				task.spawn(function()
					if enemy.Hitbox.DeathSFX.IsPlaying then
						enemy.Hitbox.DeathSFX.Ended:Wait()
					else
						task.wait(1)
					end
					enemyJanitor:Destroy()
				end)
			else
				task.wait(1)
				enemyJanitor:Destroy()
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
		info.Janitors[player] = playerJanitor
		store:dispatch(actions.switchPlayerEnemy(player.Name, enemy))

		humanoid:MoveTo(enemy.Hitbox.Position + (humanoid.RootPart.Position - enemy.Hitbox.Position).Unit * fightRange)

		local oldEquippedWeaponModel = findFirstChildWithTag(player.Character, "WeaponModel")
		if oldEquippedWeaponModel then
			oldEquippedWeaponModel:Destroy()
		end

		playerJanitor:Add(
			store.changed:connect(function(newState)
				if
					(
						not selectors.isPlayerLoaded(newState, player.Name)
						or selectors.getCurrentTarget(newState, player.Name) ~= enemy
					) and Janitor.Is(playerJanitor)
				then
					playerJanitor:Destroy()
				end
			end),
			"disconnect"
		)
		playerJanitor:Add(humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			playerJanitor:Destroy()
		end))
		playerJanitor:Add(function()
			local playerIndex = table.find(info.EngagedPlayers, player)
			if
				selectors.isPlayerLoaded(store:getState(), player.Name)
				and selectors.getCurrentTarget(store:getState(), player.Name) == enemy
			then
				store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			end
			if playerIndex then
				table.remove(info.EngagedPlayers, playerIndex)
			end
			if #info.EngagedPlayers == 1 and not isBoss then
				orientEnemy(rootPart, info.EngagedPlayers[1].Character.HumanoidRootPart.Position)
			elseif #info.EngagedPlayers == 0 then
				lastInCombat = os.time()
				enemyAnimationJanitor:Cleanup()
			end
		end, true)

		local runServiceJanitor = Janitor.new()
		runServiceJanitor:Add(RunService.Stepped:Connect(function()
			local oldPosition = player.Character.Humanoid.RootPart.Position
			task.wait(0.05)
			if not Janitor.Is(playerJanitor) and Janitor.Is(runServiceJanitor) then
				runServiceJanitor:Destroy()
				return
			elseif not Janitor.Is(runServiceJanitor) then
				return
			end
			if
				player.Character.Humanoid.RootPart.Position == oldPosition
				and player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5
			then
				runServiceJanitor:Destroy()
				if not Janitor.Is(playerJanitor) then
					return
				end

				orientPlayer(player, rootPart)
				table.insert(info.EngagedPlayers, player)

				if #info.EngagedPlayers == 1 and not isBoss then
					orientEnemy(rootPart, player.Character.HumanoidRootPart.Position)
				end

				applyEnemyAnimations(enemy, info, enemyAnimationJanitor)
				applyPlayerAnimations(player, playerJanitor)
				applyDamageToPlayers(enemy, info, enemyAnimationJanitor)
				applyDamageToEnemy(player, enemy, info, playerJanitor)
			end
		end))
		playerJanitor:Add(runServiceJanitor)
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
