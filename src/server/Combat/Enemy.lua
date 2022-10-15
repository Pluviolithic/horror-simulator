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
	local fear = enemy.Configuration.Fear.Value

	clickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if not humanoid then
			return
		end

		if store:getState().Players[player.Name].CurrentEnemy == enemy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, enemy))
		end

		Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, enemy:FindFirstChild("NPCGUI", true), true)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)
		humanoid.MoveToFinished:Wait()

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

		while
			humanoid:IsDescendantOf(game)
			and store:getState().Players[player.Name]
			and store:getState().Players[player.Name].CurrentEnemy == enemy
			and player:DistanceFromCharacter(enemy.Hitbox.Position) < (fightRange + 2)
		do
			task.wait(1)
			store:dispatch(actions.incrementPlayerStat(humanoid.Parent.Name, "Fear", fear))
		end

		runAnimations = false

		if store:getState().Players[player.Name] and store:getState().Players[player.Name].CurrentEnemy == enemy then
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
		end
	end)
end

for _, dummy in ipairs(CollectionService:GetTagged "Enemy") do
	handleEnemy(dummy)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(handleEnemy)

return 0
