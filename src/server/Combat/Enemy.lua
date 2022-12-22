local Players = game:GetService "Players"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server: ModuleScript = ServerScriptService.Server
local animations: Folder = ReplicatedStorage.CombatAnimations
local gemRewardPercentage: number = 0.3

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local bossRespawnRate: number = ReplicatedStorage.Config.Combat.BossRespawnRate.Value
local enemyRespawnRate: number = ReplicatedStorage.Config.Combat.EnemyRespawnRate.Value

local weapons: Folder = ReplicatedStorage.Weapons

local function handleEnemy(enemy: Model)
	local clickDetector: ClickDetector = enemy.Hitbox.ClickDetector
	local goalPosition: Vector3 = enemy.Hitbox.Position
	local enemyHumanoid: Humanoid = enemy.Humanoid
	local maxHealth: number = enemyHumanoid.MaxHealth

	local NPCUI: GuiObject = enemy:FindFirstChild("NPCUI", true)
	local healthValue: NumberValue | IntValue = enemy.Configuration.Health
	local damageValue: NumberValue | IntValue = enemy.Configuration.Damage
	local fightRange: number = enemy.Configuration.FightRange.Value
	local gemAmountToDrop: number = enemy.Configuration.Gems.Value
	local idleAnimationInstance: Animation = if enemy.Configuration:FindFirstChild "IdleAnim"
		then enemy.Configuration.IdleAnim.Anim
		else nil

	local runEnemyAnimations: boolean = false
	local attackAnimations: { Animation } = enemy.Configuration.AttackAnims:GetChildren()
	local currentAttackAnimation: Animation = attackAnimations[math.random(#attackAnimations)]:Clone()
	local attackTrack: AnimationTrack = enemyHumanoid:LoadAnimation(currentAttackAnimation)

	local debounceTable: { boolean } = {}
	local engagedPlayers: { Player } = {}
	local damageDealtByPlayer: { [Player]: number } = {}

	local targetPlayer: Player = nil
	local resetBegan: boolean = false
	local totalDamageDealt: number = 0
	local enemyClone: Model = enemy:Clone()
	local isBoss: boolean = CollectionService:HasTag(enemy, "Boss")
	local respawnRate: number = if isBoss then bossRespawnRate else enemyRespawnRate
	local rootPart: BasePart = if enemyHumanoid.RootPart then enemy:FindFirstChild "RootPart" else nil

	if not rootPart then
		error "Failed to find a root part for the provided enemy."
		return
	end

	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth

	local function startEnemyAnimations(): ()
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

	local function endEnemyAnimations(): ()
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

	local function removePlayer(player: Player): ()
		local playerIndex = table.find(engagedPlayers, player)
		if not playerIndex then
			return
		end

		table.remove(engagedPlayers, playerIndex)

		if #engagedPlayers == 0 then
			local playersState = store:getState().Players
			for inflictingPlayer in pairs(damageDealtByPlayer) do
				if not playersState[inflictingPlayer.Name].CurrentEnemy then
					local humanoid = if inflictingPlayer.Character
						then inflictingPlayer.Character:FindFirstChildOfClass "Humanoid"
						else nil
					if humanoid then
						humanoid.Health = humanoid.MaxHealth
					end
				end
			end

			totalDamageDealt = 0
			healthValue.Value = maxHealth
			enemyHumanoid.Health = maxHealth
			table.clear(damageDealtByPlayer)

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
		local idleTrack: AnimationTrack = enemyHumanoid:LoadAnimation(idleAnimationInstance)
		idleTrack.Priority = Enum.AnimationPriority.Idle
		idleTrack:Play()
	end

	clickDetector.MouseClick:Connect(function(player: Player)
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

		local connections: { RBXScriptConnection | typeof(store.changed:connect(function() end)) } = {}
		local cleanedUp: boolean = false
		local runAnimations: boolean = true

		local animationInstances: { Animation } =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedWeapon):GetChildren()
		local currentAnimation: Animation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack: AnimationTrack = humanoid:LoadAnimation(currentAnimation)

		local function cleanUpPlayer(skipPlayerRemoval: boolean)
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

			local weaponName: string = store:getState().Players[player.Name].EquippedWeapon
			local wepaon: Model = player.Character:FindFirstChild(weaponName)
			if wepaon then
				wepaon:Destroy()
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
		local enemyDirection: Vector3 = rootPart.Position * Vector3.new(1, 0, 1)
		local playerPosition: Vector3 = player.Character.HumanoidRootPart.Position
		player.Character:PivotTo(
			CFrame.lookAt(playerPosition, enemyDirection + playerPosition.Y * Vector3.new(0, 1, 0))
		)

		-- attach currently equipped weapon to player's hand
		local weaponName: string = store:getState().Players[player.Name].EquippedWeapon
		if weaponName ~= "Fists" then
			local weaponAccessory: Accessory = weapons[weaponName]:Clone()
			player.Character.Humanoid:AddAccessory(weaponAccessory)
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
			-- rotate enemy to face player if not boss and it is not already facing a player
			if not isBoss then
				local playerDirection: Vector3 = playerPosition * Vector3.new(1, 0, 1)
				rootPart.CFrame =
					CFrame.lookAt(rootPart.Position, playerDirection + rootPart.Position.Y * Vector3.new(0, 1, 0))
			end

			targetPlayer = player

			task.spawn(startEnemyAnimations)
		end

		task.wait(0.5)

		local damageMultiplier = weapons[weaponName].Damage.Value

		while
			runAnimations
			and humanoid.Health > 0
			and totalDamageDealt < maxHealth
			and humanoid:IsDescendantOf(game)
			and store:getState().Players[player.Name]
			and store:getState().Players[player.Name].CurrentEnemy == enemy
		do
			local damageToDeal: number = math.clamp(
				store:getState().Players[player.Name].Strength * damageMultiplier,
				0,
				maxHealth - totalDamageDealt
			)
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

			for otherPlayer, damage in damageDealtByPlayer do
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
