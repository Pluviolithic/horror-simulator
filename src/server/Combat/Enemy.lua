local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations
local gemRewardPercentage = 0.3

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local bossRespawnRate = ServerStorage.Config.Combat.BossRespawnRate
local enemyRespawnRate = ServerStorage.Config.Combat.EnemyRespawnRate

local function handleEnemy(enemy)
	local clickDetector = enemy.Hitbox.ClickDetector
	local goalPosition = enemy.Hitbox.Position
	local enemyHumanoid = enemy.Humanoid
	local maxHealth = enemyHumanoid.MaxHealth

	local NPCUI = enemy:FindFirstChild("NPCUI", true)
	local healthValue = enemy.Configuration.Health
	local damageValue = enemy.Configuration.Damage
	local fightRange = enemy.Configuration.FightRange.Value
	local gemAmountToDrop = enemy.Configuration.Gems.Value
	local idleAnimationInstance = enemy.Configuration:FindFirstChild "IdleAnim" and enemy.Configuration.IdleAnim.Anim

	local runEnemyAnimations = false
	local attackAnimations = enemy.Configuration.AttackAnims:GetChildren()
	local currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
	local attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)

	local debounceTable = {}
	local engagedPlayers = {}
	local damageDealtByPlayer = {}

	local targetPlayer
	local resetBegan = false
	local totalDamageDealt = 0
	local enemyClone = enemy:Clone()
	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local respawnRate = if isBoss then bossRespawnRate else enemyRespawnRate
	local rootPart = enemyHumanoid.RootPart or enemy:FindFirstChild "RootPart"

	if not rootPart then
		error "Failed to find a root part for the provided enemy."
		return
	end

	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth

	local function startEnemyAnimations()
		--[[
		for _, animation in ipairs(enemyHumanoid:GetPlayingAnimationTracks()) do
			animation:Stop()
		end
		--]]

		runEnemyAnimations = true
		repeat
			attackTrack.Priority = Enum.AnimationPriority.Action
			attackTrack:Play()
			attackTrack.Stopped:Wait()
			attackTrack:Destroy()
			currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
			attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)
			task.wait(0.5)
		until not runEnemyAnimations
	end

	local function endEnemyAnimations()
		runEnemyAnimations = false
		attackTrack:Stop()
		--[[
		if idleAnimationInstance then
			local idleTrack = enemyHumanoid:LoadAnimation(idleAnimationInstance)
			idleTrack.Priority = Enum.AnimationPriority.Action
			idleTrack:Play()
		end
		--]]
	end

	local function removePlayer(player)
		local playerIndex = table.find(engagedPlayers, player)
		if not playerIndex then
			return
		end

		table.remove(engagedPlayers, playerIndex)

		if #engagedPlayers == 0 then
			local playersState = store:getState().Players
			for inflictingPlayer in pairs(damageDealtByPlayer) do
				if not playersState[inflictingPlayer.Name].CurrentEnemy then
					local humanoid = inflictingPlayer.Character
						and inflictingPlayer.Character:FindFirstChildOfClass "Humanoid"
					if humanoid then
						humanoid.Health = humanoid.MaxHealth
					end
				end
			end

			totalDamageDealt = 0
			damageDealtByPlayer = {}
			healthValue.Value = maxHealth
			enemyHumanoid.Health = maxHealth

			endEnemyAnimations()
		elseif engagedPlayers[1] ~= targetPlayer then
			if not isBoss then
				local lookAt = engagedPlayers[1].Character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)
				rootPart.CFrame = CFrame.lookAt(rootPart.Position, lookAt + rootPart.Position.Y * Vector3.new(0, 1, 0))
			end
			targetPlayer = engagedPlayers[1]
		end
	end

	-- set up idle animations
	if idleAnimationInstance then
		local idleTrack = enemyHumanoid:LoadAnimation(idleAnimationInstance)
		idleTrack.Priority = Enum.AnimationPriority.Idle
		idleTrack:Play()
	end

	clickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if debounceTable[player.UserId] or not humanoid then
			return
		end

		debounceTable[player.UserId] = true
		task.delay(1, function()
			debounceTable[player.UserId] = nil
		end)

		if store:getState().Players[player.Name].CurrentEnemy == enemy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, enemy))
			if not damageDealtByPlayer[player] then
				humanoid.Health = humanoid.MaxHealth
			end
		end

		local connections = {}
		local cleanedUp = false
		local runAnimations = true

		local animationInstances =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedTool):GetChildren()
		local currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack = humanoid:LoadAnimation(currentAnimation)

		local function cleanUpPlayer(skipPlayerRemoval)
			if cleanedUp then
				return
			end
			cleanedUp = true

			for _, connection in ipairs(connections) do
				connection:disconnect()
			end

			runAnimations = false
			currentTrack:Stop()

			Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			if store:getState().Players[player.Name].CurrentEnemy == enemy then
				store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			end
			if not skipPlayerRemoval then
				removePlayer(player)
			end
		end

		table.insert(connections, humanoid.Died:Connect(cleanUpPlayer))

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, true, enemy)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		table.insert(connections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(cleanUpPlayer))

		table.insert(
			connections,
			store.changed:connect(function(newState)
				if newState.Players[player.Name].CurrentEnemy ~= enemy then
					cleanUpPlayer()
				end
			end)
		)

		task.wait(player:DistanceFromCharacter(rootPart.Position) / humanoid.WalkSpeed)

		if cleanedUp then
			return
		end

		-- rotate the player to face the enemy
		local enemyDirection = rootPart.Position * Vector3.new(1, 0, 1)
		local playerPosition = player.Character.HumanoidRootPart.Position
		player.Character:PivotTo(
			CFrame.lookAt(playerPosition, enemyDirection + playerPosition.Y * Vector3.new(0, 1, 0))
		)

		task.spawn(function()
			repeat
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				task.wait(0.5)
			until not runAnimations
		end)

		table.insert(engagedPlayers, player)
		if #engagedPlayers == 1 then
			-- rotate enemy to face player if not boss and it is not already facing a player
			if not isBoss then
				local playerDirection = playerPosition * Vector3.new(1, 0, 1)
				rootPart.CFrame =
					CFrame.lookAt(rootPart.Position, playerDirection + rootPart.Position.Y * Vector3.new(0, 1, 0))
			end

			targetPlayer = player

			task.spawn(startEnemyAnimations)
		end

		task.wait(0.5)

		while
			runAnimations
			and humanoid.Health > 0
			and totalDamageDealt < maxHealth
			and humanoid:IsDescendantOf(game)
			and store:getState().Players[player.Name]
			and store:getState().Players[player.Name].CurrentEnemy == enemy
		do
			local damageToDeal =
				math.clamp(store:getState().Players[player.Name].Strength, 0, maxHealth - totalDamageDealt)
			totalDamageDealt += damageToDeal
			damageDealtByPlayer[player] = (damageDealtByPlayer[player] or 0) + damageToDeal
			healthValue.Value = maxHealth - totalDamageDealt

			-- now receive damage from enemy

			humanoid.Health -= damageValue.Value

			-- need to quick exit for this one
			if totalDamageDealt >= maxHealth then
				break
			end

			task.wait(1)
		end

		if totalDamageDealt >= maxHealth then
			cleanUpPlayer(true)

			if resetBegan then
				return
			end
			resetBegan = true

			for otherPlayer, damage in pairs(damageDealtByPlayer) do
				if not Players:FindFirstChild(otherPlayer.Name) then
					continue
				end
				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Fear", damage))
				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Kills"))

				if damage >= maxHealth * gemRewardPercentage then
					store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Gems", gemAmountToDrop))
				end

				if not store:getState().Players[otherPlayer.Name].CurrentEnemy then
					local otherHumanoid = otherPlayer.Character
						and otherPlayer.Character:FindFirstChildOfClass "Humanoid"
					if not otherHumanoid then
						continue
					end
					otherHumanoid.Health = otherHumanoid.MaxHealth
				end
			end

			enemy:Destroy()

			task.delay(respawnRate, function()
				enemyClone.Parent = workspace
				handleEnemy(enemyClone)
			end)

			return
		else
			cleanUpPlayer()
		end
	end)
end

for _, enemy in ipairs(CollectionService:GetTagged "Enemy") do
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
