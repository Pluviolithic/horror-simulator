local Players = game:GetService "Players"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations
local gemRewardPercentage = 0.3

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local bossRespawnRate = ReplicatedStorage.Config.Combat.BossRespawnRate.Value
local enemyRespawnRate = ReplicatedStorage.Config.Combat.EnemyRespawnRate.Value
local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value
local playerAttackSpeed = ReplicatedStorage.Config.Combat.PlayerAttackSpeed.Value
local doubleAttackSpeedID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xAttackSpeed"].Value)

local weapons = ReplicatedStorage.Weapons

local function getSortedAnimationInstances(animationInstances)
	for i, animationInstance in animationInstances do
		if animationInstance.Name == "Idle" then
			table.remove(animationInstances, i)
			break
		end
	end
	table.sort(animationInstances, function(a, b)
		return tonumber(a.Name:match "%d+") < tonumber(b.Name:match "%d+")
	end)
	return animationInstances
end

local function getPlayerAttackSpeed(player)
	return if selectors.hasGamepass(store:getState(), player.Name, doubleAttackSpeedID)
		then playerAttackSpeed / 2
		else playerAttackSpeed
end

local function handleEnemy(enemy)
	local clickDetector = enemy.Hitbox.ClickDetector
	local goalPosition = enemy.Hitbox.Position
	local enemyHumanoid = enemy.Humanoid
	local maxHealth = enemy.Configuration.FearHealth.Value

	local NPCUI = enemy:FindFirstChild("NPCUI", true)
	local healthValue = enemy.Configuration.FearHealth
	local damageValue = enemy.Configuration.Damage
	local fightRange = enemy.Configuration.FightRange.Value
	local gemAmountToDrop = enemy.Configuration.Gems.Value
	local idleAnimationInstance = if enemy.Configuration:FindFirstChild "IdleAnim"
		then enemy.Configuration.IdleAnim.Anim
		else nil

	local runEnemyAnimations = false
	local attackAnimations = getSortedAnimationInstances(enemy.Configuration.AttackAnims:GetChildren())
	local currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
	local attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)

	local debounceTable = {}
	local engagedPlayers = {}
	local damageDealtByPlayer = {}

	local targetPlayer = nil
	local resetBegan = false
	local totalDamageDealt = 0
	local enemyClone = enemy:Clone()
	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local respawnRate = if isBoss then bossRespawnRate else enemyRespawnRate
	local rootPart = if enemyHumanoid.RootPart then enemyHumanoid.RootPart else enemy:FindFirstChild "RootPart"

	if not rootPart then
		error "Failed to find a root part for the provided enemy."
		return
	end

	HealthBar.new(NPCUI.Frame.Background.Frame):connect(enemy)
	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth
	NPCUI.Enabled = true

	local function startEnemyAnimations(): ()
		local t = if isBoss then bossAttackSpeed else enemyAttackSpeed
		runEnemyAnimations = true
		repeat
			task.wait(t)

			attackTrack.Priority = Enum.AnimationPriority.Action
			attackTrack:Play()
			attackTrack.Stopped:Wait()
			attackTrack:Destroy()
			currentAttackAnimation = attackAnimations[math.random(#attackAnimations)]:Clone()
			attackTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)

			for _, player in engagedPlayers do
				local fearMeterGoal = math.min(
					selectors.getStat(store:getState(), player.Name, "CurrentFearMeter") + damageValue.Value,
					selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
				)
				local fearMeterAddendum = fearMeterGoal
					- selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")

				if fearMeterAddendum ~= 0 then
					store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", fearMeterAddendum))
				end
			end
		until not runEnemyAnimations
	end

	local function endEnemyAnimations(): ()
		runEnemyAnimations = false
		attackTrack:Stop()
	end

	local function removePlayer(player: Player): ()
		local playerIndex = table.find(engagedPlayers, player)
		if not playerIndex then
			return
		end

		table.remove(engagedPlayers, playerIndex)

		if #engagedPlayers == 0 then
			totalDamageDealt = 0
			healthValue.Value = maxHealth
			table.clear(damageDealtByPlayer)
			endEnemyAnimations()
		elseif targetPlayer == player then
			if not isBoss then
				for _, engagedPlayer in engagedPlayers do
					if not engagedPlayer.Character or not engagedPlayer.Character:FindFirstChildOfClass "Humanoid" then
						continue
					end
					local humanoidRootPart = engagedPlayer.Character.HumanoidRootPart
					local lookAt = humanoidRootPart.Position * Vector3.new(1, 0, 1)
					rootPart.CFrame =
						CFrame.lookAt(rootPart.Position, lookAt + rootPart.Position.Y * Vector3.new(0, 1, 0))
					targetPlayer = engagedPlayer
					break
				end
			end
		end
	end

	-- set up idle animations
	if idleAnimationInstance then
		local idleTrack = enemyHumanoid:LoadAnimation(idleAnimationInstance)
		idleTrack.Priority = Enum.AnimationPriority.Idle
		idleTrack:Play()
	end

	clickDetector.MouseClick:Connect(function(player: Player)
		local humanoid = if player.Character then player.Character:FindFirstChildOfClass "Humanoid" else nil
		if debounceTable[player.UserId] or not humanoid then
			return
		end

		debounceTable[player.UserId] = true
		task.delay(1, function()
			debounceTable[player.UserId] = nil
		end)

		if
			selectors.getCurrentTarget(store:getState(), player.Name) == enemy
			or CollectionService:HasTag(selectors.getCurrentTarget(store:getState(), player.Name), "PunchingBag")
		then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, enemy))
		end

		local connections = {}
		local cleanedUp = false
		local runAnimations = true

		local currentAnimation, currentTrack = nil, nil
		local animationInstances = getSortedAnimationInstances(
			animations[selectors.getEquippedWeapon(store:getState(), player.Name)]:GetChildren()
		)

		local function cleanUpPlayer(skipPlayerRemoval: boolean?): ()
			if cleanedUp then
				return
			end
			cleanedUp = true

			for _, connection in connections do
				if typeof(connection) == "RBXScriptSignal" then
					connection:Disconnect()
				else
					connection:disconnect()
				end
			end

			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				return
			end

			local weaponName = selectors.getEquippedWeapon(store:getState(), player.Name)
			local wepaon = if player.Character then player.Character:FindFirstChild(weaponName) :: Accessory else nil
			if wepaon then
				wepaon:Destroy()
			end

			runAnimations = false
			if currentTrack then
				currentTrack:Stop()
			end

			if selectors.getCurrentTarget(store:getState(), player.Name) == enemy then
				store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			end
			if not skipPlayerRemoval then
				removePlayer(player)
			end
		end

		table.insert(connections, humanoid.Died:Connect(cleanUpPlayer))

		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		table.insert(connections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(cleanUpPlayer))

		table.insert(
			connections,
			store.changed:connect(function(newState)
				if selectors.getCurrentTarget(newState, player.Name) ~= enemy then
					cleanUpPlayer()
				end
			end)
		)

		repeat
			task.wait(0.1)
		until player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5
			or cleanedUp
			or not selectors.isPlayerLoaded(store:getState(), player.Name)

		if cleanedUp or (player:DistanceFromCharacter(rootPart.Position) > fightRange + 5) then
			return
		end

		-- rotate the player to face the enemy
		local enemyDirection = rootPart.Position * Vector3.new(1, 0, 1)
		local playerRootPart = player.Character and player.Character:FindFirstChild(rootPart)
		local playerPosition = if playerRootPart then playerRootPart.Position else Vector3.new(0, 0, 0)

		if player.Character then
			player.Character:PivotTo(
				CFrame.lookAt(playerPosition, enemyDirection + playerPosition.Y * Vector3.new(0, 1, 0))
			)
		end

		-- attach currently equipped weapon to player's hand
		local weaponName = selectors.getEquippedWeapon(store:getState(), player.Name)
		if weaponName ~= "Fists" then
			local weaponAccessory = weapons[weaponName]:Clone()
			humanoid:AddAccessory(weaponAccessory)
		end

		local currentIndex, maxIndex = 0, #animationInstances
		task.spawn(function()
			repeat
				currentIndex = (currentIndex % maxIndex) + 1
				currentAnimation = animationInstances[currentIndex]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				if
					selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
					== selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
				then
					task.wait(getPlayerAttackSpeed(player) * 2)
				else
					task.wait(getPlayerAttackSpeed(player))
				end
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

		local damageMultiplier = if weaponName == "Fists" then 1 else weapons[weaponName].Damage.Value
		local counter = 0

		while
			runAnimations
			--and humanoid.Health > 0
			and totalDamageDealt < maxHealth
			and humanoid:IsDescendantOf(game)
			and selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getCurrentTarget(store:getState(), player.Name) == enemy
		do
			if
				selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
					~= selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
				or counter % 2 == 0
			then
				local damageToDeal = math.clamp(
					selectors.getStat(store:getState(), player.Name, "Strength") * damageMultiplier,
					0,
					maxHealth - totalDamageDealt
				)
				totalDamageDealt += damageToDeal
				damageDealtByPlayer[player] = (damageDealtByPlayer[player] or 0) + damageToDeal
				healthValue.Value = maxHealth - totalDamageDealt
			end

			-- need to quick exit for this one
			if totalDamageDealt >= maxHealth then
				break
			end

			counter += 1
			if
				selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
				== selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			then
				task.wait(getPlayerAttackSpeed(player) * 2)
			else
				task.wait(getPlayerAttackSpeed(player))
			end
		end

		if totalDamageDealt >= maxHealth then
			cleanUpPlayer(true)

			if resetBegan then
				return
			end
			resetBegan = true

			for otherPlayer, damage in damageDealtByPlayer do
				if not Players:FindFirstChild(otherPlayer.Name) then
					continue
				end

				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Fear", damage, enemy.Name))
				store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Kills"))
				store:dispatch(actions.logKilledEnemyType(otherPlayer.Name, enemy.Name))

				if damage >= maxHealth * gemRewardPercentage then
					store:dispatch(actions.incrementPlayerStat(otherPlayer.Name, "Gems", gemAmountToDrop, enemy.Name))
				end
			end

			enemy:Destroy()

			task.delay(respawnRate, function()
				enemyClone.Parent = workspace
				--I think instanceadded handles this?
				--handleEnemy(enemyClone)
			end)

			return
		else
			cleanUpPlayer()
		end
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
