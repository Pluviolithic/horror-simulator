local CollectionService = game:GetService "CollectionService"
local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local function handleEnemy(enemy)
	local clickDetector = enemy.Hitbox.ClickDetector
	local goalPosition = enemy.Hitbox.Position
	local enemyHumanoid = enemy.Humanoid
	local maxHealth = enemyHumanoid.MaxHealth

	local NPCUI = enemy:FindFirstChild("NPCUI", true)
	local healthValue = enemy.Configuration.Health
	local damageValue = enemy.Configuration.Damage
	local fightRange = enemy.Configuration.FightRange.Value

	local attackAnimations = enemy.Configuration.AttackAnims:GetChildren()
	local currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
	local attackTrack

	local debounceTable = {}
	local engagedPlayers = {}
	local damageDealtByPlayer = {}

	local targetPlayer
	local resetBegan = false
	local totalDamageDealt = 0
	local enemyClone = enemy:Clone()

	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth

	local function removePlayer(player)
		local playerIndex = table.find(engagedPlayers, player)
		if not playerIndex then
			return
		end
		table.remove(engagedPlayers, playerIndex)
		if #engagedPlayers == 0 then
			totalDamageDealt = 0
			damageDealtByPlayer = {}
			healthValue.Value = maxHealth
			enemyHumanoid.Health = maxHealth
		elseif engagedPlayers[1] ~= targetPlayer then
			local lookAt = engagedPlayers[1].Character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)
			enemyHumanoid.RootPart.CFrame = CFrame.lookAt(
				enemyHumanoid.RootPart.Position,
				lookAt + enemyHumanoid.RootPart.Position.Y * Vector3.new(0, 1, 0)
			)
			targetPlayer = engagedPlayers[1]
		end
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
		end

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, true, healthValue, maxHealth)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		local quit = false
		local connection
		connection = store.changed:connect(function(newState)
			if newState.Players[player.Name].CurrentEnemy ~= enemy then
				quit = true
				Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			end
		end)

		local animationInstances =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedTool):GetChildren()
		local currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack = humanoid:LoadAnimation(currentAnimation)
		local runAnimations = true

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			if quit then
				return
			end
			runAnimations = false
			currentTrack:Stop()
			Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			removePlayer(player)
		end)

		humanoid.MoveToFinished:Wait()
		connection:disconnect()
		if quit then
			return
		end

		task.spawn(function()
			while runAnimations do
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				task.wait(0.5)
			end
		end)

		table.insert(engagedPlayers, player)
		if #engagedPlayers == 1 then
			-- rotate enemy to face player
			local lookAt = player.Character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)
			enemyHumanoid.RootPart.CFrame = CFrame.lookAt(
				enemyHumanoid.RootPart.Position,
				lookAt + enemyHumanoid.RootPart.Position.Y * Vector3.new(0, 1, 0)
			)

			targetPlayer = player

			task.spawn(function()
				while #engagedPlayers > 0 and enemyHumanoid:IsDescendantOf(game) do
					attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)
					attackTrack:Play()
					attackTrack.Stopped:Wait()
					attackTrack:Destroy()
					currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
					task.wait(0.5)
				end
			end)
		end

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

			task.wait(1)
		end

		if totalDamageDealt >= maxHealth then
			quit = true
			currentTrack:Stop()
			runAnimations = false

			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))

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
			end

			enemy:Destroy()

			task.delay(15, function()
				handleEnemy(enemyClone)
				enemyClone.Parent = workspace
			end)

			return
		end

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)

		removePlayer(player)
	end)
end

for _, enemy in ipairs(CollectionService:GetTagged "Enemy") do
	handleEnemy(enemy)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(handleEnemy)

return 0
