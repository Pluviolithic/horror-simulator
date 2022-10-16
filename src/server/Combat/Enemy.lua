local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local fightRange = 2

local function handleEnemy(enemy)
	local clickDetector = enemy.Hitbox.ClickDetector
	local goalPosition = enemy.Hitbox.Position
	local maxHealth = enemy.Humanoid.MaxHealth

	local NPCUI = enemy:FindFirstChild("NPCUI", true)
	local healthValue = enemy.Configuration.Health

	local debounceTable = {}
	local damageDealtByPlayer = {}

	local totalDamageDealt = 0

	NPCUI:FindFirstChild("NPCName", true).Text = enemy.Name
	healthValue.Value = maxHealth

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

		local failed = false
		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			failed = true
		end)

		humanoid.MoveToFinished:Wait()
		if failed then
			return
		end

		local animationInstances =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedTool):GetChildren()
		local currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack = humanoid:LoadAnimation(currentAnimation)
		local runAnimations = true

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

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			if failed then
				return
			end
			runAnimations = false
			currentTrack:Stop()
			Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
		end)

		task.wait(1)

		while
			runAnimations
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
			task.wait(1)
		end

		-- clean up

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
	end)
end

for _, enemy in ipairs(CollectionService:GetTagged "Enemy") do
	handleEnemy(enemy)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(handleEnemy)

return 0
