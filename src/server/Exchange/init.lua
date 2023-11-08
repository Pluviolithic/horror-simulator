local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local animations = ReplicatedStorage.CombatAnimations
local disableSwitch = Instance.new "BindableEvent"

local workoutSpeed = ReplicatedStorage.Config.Workout.WorkoutSpeed.Value
local baseStrength = ReplicatedStorage.Config.Workout.Strength.Value
local tripleWorkoutSpeedPassID = tostring(ReplicatedStorage.Config.GamepassData.IDs["3xWorkoutSpeed"].Value)

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

local function handlePunchingBag(bag: any)
	local prompt: ProximityPrompt = bag.HumanoidLockPart.Prompt
	local colorParts = bag:FindFirstChild("Color"):GetChildren()
	local teleportPart: BasePart = bag.TPPart
	local multiplier = bag.Multiplier.Value
	local inUse: boolean = false

	prompt.Triggered:Connect(function(player: Player)
		local cancelled: boolean = false

		if
			inUse
			or selectors.getCurrentTarget(store:getState(), player.Name)
			or selectors.getStat(store:getState(), player.Name, "Fear")
				< selectors.getStat(store:getState(), player.Name, "RequiredFear")
		then
			if selectors.getCurrentTarget(store:getState(), player.Name) == bag and not cancelled then
				disableSwitch:Fire(player)
			end
			return
		end

		local humanoid: any = if player.Character then player.Character:FindFirstChildOfClass "Humanoid" else nil
		if not humanoid then
			return
		end

		inUse = true
		store:dispatch(actions.setCurrentPunchingBag(player.Name, bag))
		Remotes.Server:Get("SetControlsEnabled"):SendToPlayer(player, false)
		humanoid.RootPart.CFrame = bag.HumanoidLockPart.CFrame + Vector3.new(0, 1, 0) * (humanoid.RootPart.Size.Y + 3)
		prompt.ActionText = "Stop Training"

		for _, part in colorParts do
			part.Color = Color3.fromRGB(0, 255, 0)
		end

		local currentAnimation, currentTrack = nil, nil
		local animationInstances = getSortedAnimationInstances(animations:FindFirstChild("Fists"):GetChildren())

		local connection
		connection = disableSwitch.Event:Connect(function(disablingPlayer: Player)
			if disablingPlayer == player then
				cancelled = true
				connection:Disconnect()
				currentTrack:Stop()
				store:dispatch(actions.setCurrentPunchingBag(player.Name, nil))
				prompt.ActionText = "Start Training"
				inUse = false
				humanoid.RootPart.CFrame = teleportPart.CFrame + Vector3.new(0, 1, 0) * (humanoid.RootPart.Size.Y + 3)
				Remotes.Server:Get("SetControlsEnabled"):SendToPlayer(player, true)

				for _, part in colorParts do
					part.Color = Color3.fromRGB(231, 0, 0)
				end
			end
		end)

		local currentIndex, maxIndex = 0, #animationInstances
		task.spawn(function()
			repeat
				currentIndex = (currentIndex % maxIndex) + 1
				currentAnimation = animationInstances[currentIndex]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				task.wait(workoutSpeed)
			until cancelled
		end)

		while
			selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getStat(store:getState(), player.Name, "Fear") >= selectors.getStat(
				store:getState(),
				player.Name,
				"RequiredFear"
			)
			and not cancelled
		do
			store:dispatch(
				actions.incrementPlayerStat(
					player.Name,
					"Fear",
					-selectors.getStat(store:getState(), player.Name, "RequiredFear")
				)
			)
			store:dispatch(actions.incrementPlayerStat(player.Name, "Strength", baseStrength * multiplier, bag.Name))

			local maxFearMeter = selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			local currentFearMeter = selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
			local reductionAmount = -maxFearMeter / 10

			if (currentFearMeter + reductionAmount) < 0 then
				reductionAmount = -currentFearMeter
			end

			store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", reductionAmount))

			if selectors.hasGamepass(store:getState(), player.Name, tripleWorkoutSpeedPassID) then
				task.wait(workoutSpeed / 3)
			else
				task.wait(workoutSpeed)
			end
		end

		if connection.Connected then
			disableSwitch:Fire(player)
		end
	end)
end

for _, punchingBag in CollectionService:GetTagged "PunchingBag" do
	handlePunchingBag(punchingBag)
end

CollectionService:GetInstanceAddedSignal("PunchingBag"):Connect(handlePunchingBag)

return 0
