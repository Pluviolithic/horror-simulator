local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local fightRange = 2

local function handleDummy(dummy)
	local clickDetector = dummy.Hitbox.ClickDetector
	local goalPosition = dummy.Hitbox.Position
	local fear = dummy.Configuration.Fear.Value
	local NPCUI = dummy:FindFirstChild("NPCUI", true)

	NPCUI:FindFirstChild("NPCName", true).Text = "Dummy"

	local debounceTable = {}

	clickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if debounceTable[player.UserId] or not humanoid then
			return
		end

		debounceTable[player.UserId] = true
		task.delay(1, function()
			debounceTable[player.UserId] = nil
		end)

		if store:getState().Players[player.Name].CurrentEnemy == dummy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, dummy))
		end

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, true)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		local failed = false
		local connection
		connection = store.changed:connect(function(newState)
			if newState.Players[player.Name].CurrentEnemy ~= dummy then
				failed = true
				Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			end
		end)

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			failed = true
		end)

		humanoid.MoveToFinished:Wait()
		connection:disconnect()
		if failed then
			return
		end

		local animationInstances =
			animations:FindFirstChild(store:getState().Players[player.Name].EquippedWeapon):GetChildren()
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
			and humanoid:IsDescendantOf(game)
			and store:getState().Players[player.Name]
			and store:getState().Players[player.Name].CurrentEnemy == dummy
		do
			store:dispatch(actions.incrementPlayerStat(humanoid.Parent.Name, "Fear", fear))
			task.wait(1)
		end

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
	end)
end

for _, dummy in ipairs(CollectionService:GetTagged "Dummy") do
	handleDummy(dummy)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(handleDummy)

return 0
