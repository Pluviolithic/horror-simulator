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

	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth

	local function startEnemyAnimations()
		runEnemyAnimations = true
		repeat
			print("looping")
			attackTrack:Play()
			attackTrack.Stopped:Wait()
			attackTrack:Destroy()
			currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
			attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)
			task.wait(0.5)
		until not runEnemyAnimations
	end

	local function endEnemyAnimations()
		print("stopping enemy animations")
		runEnemyAnimations = false
		attackTrack:Stop()
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
					local humanoid = inflictingPlayer.Character:FindFirstChildOfClass "Humanoid"
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
			if not damageDealtByPlayer[player] then
				humanoid.Health = humanoid.MaxHealth
			end
		end

		local connections = {}
		local sentDisableUI = false
		local cleanedUp = false
		local runAnimations = true

		local animationInstances =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedTool):GetChildren()
		local currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack = humanoid:LoadAnimation(currentAnimation)

		local function cleanUpPlayer()
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
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			removePlayer(player)
		end

		table.insert(connections, humanoid.Died:Connect(cleanUpPlayer))

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, true, healthValue, maxHealth)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		table.insert(connections, store.changed:connect(function(newState)
			if newState.Players[player.Name].CurrentEnemy ~= enemy then
				cleanUpPlayer()
			end
		end))

		table.insert(connections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(cleanUpPlayer))

		--print("delay started")
		humanoid.MoveToFinished:Wait()
		--print("delay ended")

		if cleanedUp then
			return
		end

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
			-- rotate enemy to face player
			local lookAt = player.Character.HumanoidRootPart.Position * Vector3.new(1, 0, 1)
			enemyHumanoid.RootPart.CFrame = CFrame.lookAt(
				enemyHumanoid.RootPart.Position,
				lookAt + enemyHumanoid.RootPart.Position.Y * Vector3.new(0, 1, 0)
			)

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

			cleanUpPlayer()

			if resetBegan then
				return
			end

			for otherPlayer, damage in pairs(damageDealtByPlayer) do
				if not Players:FindFirstChild(otherPlayer.Name) then
					continue
				end
				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Fear", damage))
				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Kills"))

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

			task.delay(15, function()
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
	handleEnemy(enemy)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(handleEnemy)

return 0
