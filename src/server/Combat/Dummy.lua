local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations
local playerAttackSpeed = ReplicatedStorage.Config.Combat.PlayerAttackSpeed.Value

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

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
	return if selectors.hasGamepass(store:getState(), player.Name, "2xAttackSpeed")
		then playerAttackSpeed / 2
		else playerAttackSpeed
end

local function handleDummy(dummy)
	local clickDetector = dummy.Hitbox.ClickDetector
	local goalPosition = dummy.Hitbox.Position
	local fear = dummy.Configuration.Fear.Value
	local NPCUI = dummy:FindFirstChild("NPCUI", true)
	local fightRange = dummy.Configuration.FightRange.Value

	NPCUI:FindFirstChild("NPCName", true).Text = "Dummy"

	local debounceTable = {}

	clickDetector.MouseClick:Connect(function(player: Player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if debounceTable[player.UserId] or not humanoid then
			return
		end

		debounceTable[player.UserId] = true
		task.delay(1, function()
			debounceTable[player.UserId] = nil
		end)

		if selectors.getCurrentTarget(store:getState(), player.Name) == dummy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, dummy))
		end

		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		local failed = false
		local connection = nil
		connection = store.changed:connect(function(newState)
			if selectors.getCurrentTarget(newState, player.Name) ~= dummy then
				failed = true
			end
		end)

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			failed = true
		end)

		repeat
			task.wait(0.1)
		until player:DistanceFromCharacter(goalPosition) <= fightRange + 5
			or failed
			or not selectors.isPlayerLoaded(store:getState(), player.Name)

		connection:disconnect()
		if failed or (player:DistanceFromCharacter(goalPosition) > fightRange + 5) then
			return
		end

		local currentAnimation, currentTrack = nil, nil
		local animationInstances = getSortedAnimationInstances(animations.Fists:GetChildren())
		local runAnimations = true

		local currentIndex, maxIndex = 0, #animationInstances
		task.spawn(function()
			while
				runAnimations
				and humanoid:IsDescendantOf(game)
				and selectors.isPlayerLoaded(store:getState(), player.Name)
				and selectors.getCurrentTarget(store:getState(), player.Name) == dummy
				and player:DistanceFromCharacter(goalPosition) <= fightRange + 5
			do
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
			end
		end)

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			if failed then
				return
			end
			runAnimations = false
			currentTrack:Stop()
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
		end)

		task.wait(1)

		while
			runAnimations
			and humanoid:IsDescendantOf(game)
			and selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getCurrentTarget(store:getState(), player.Name) == dummy
			and player:DistanceFromCharacter(goalPosition) <= fightRange + 5
		do
			store:dispatch(actions.incrementPlayerStat(humanoid.Parent.Name, "Fear", fear, dummy.Name))
			if
				selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
				== selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			then
				task.wait(getPlayerAttackSpeed(player) * 2)
			else
				task.wait(getPlayerAttackSpeed(player))
			end
		end
	end)
end

for _, dummy in CollectionService:GetTagged "Dummy" do
	handleDummy(dummy)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(handleDummy)

return 0
