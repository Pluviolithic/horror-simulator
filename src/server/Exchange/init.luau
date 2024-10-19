local Players = game:GetService "Players"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local random = Random.new()
local animations = ReplicatedStorage.CombatAnimations
local disableSwitch = Instance.new "BindableEvent"

local strengthRanks = ReplicatedStorage.Config.StrengthRanks
local fistSound = ReplicatedStorage.Config.Audio.SoundEffects.Fists
local requiredFear = ReplicatedStorage.Config.Workout.RequiredFear.Value
local workoutSpeed = ReplicatedStorage.Config.Workout.WorkoutSpeed.Value
local tripleWorkoutSpeedPassID = ReplicatedStorage.Config.GamepassData.IDs["3xWorkoutSpeed"].Value

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
	local prompt = bag.HumanoidLockPart.Prompt
	local colorParts = bag:FindFirstChild("Color"):GetChildren()
	local teleportPart = bag.TPPart
	local multiplier = bag.Multiplier.Value
	local inUse = false

	prompt.Triggered:Connect(function(player)
		local cancelled = false

		if
			selectors.getStat(store:getState(), player.Name, "Fear")
			< selectors.getStat(store:getState(), player.Name, "RequiredFear")
		then
			Remotes.Server:Get("SendPopupMessage"):SendToPlayer(player, "Not enough fear!")
			Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Fear")
			return
		end

		local startStrength = selectors.getStat(store:getState(), player.Name, "Strength")

		if inUse or selectors.getCurrentTarget(store:getState(), player.Name) then
			if selectors.getCurrentTarget(store:getState(), player.Name) == bag and not cancelled then
				disableSwitch:Fire(player, startStrength)
			end
			return
		end

		local humanoid = if player.Character then player.Character:FindFirstChildOfClass "Humanoid" else nil
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
		local currentIndex, maxIndex = 0, #animationInstances
		local idleAnimation = ReplicatedStorage.CombatAnimations.Fists.Idle
		local loadedIdleAnimation = humanoid:LoadAnimation(idleAnimation)
		loadedIdleAnimation.Priority = Enum.AnimationPriority.Idle

		local connection
		connection = disableSwitch.Event:Connect(function(disablingPlayer: Player, initialStrength: number)
			if disablingPlayer == player then
				cancelled = true
				connection:Disconnect()
				currentTrack:Stop()
				loadedIdleAnimation:Stop()

				prompt.ActionText = "Start Training"
				inUse = false

				if
					selectors.isPlayerLoaded(store:getState(), player.Name)
					and selectors.getStat(store:getState(), player.Name, "Strength") >= initialStrength
				then
					humanoid.RootPart.CFrame = teleportPart.CFrame
						+ Vector3.new(0, 1, 0) * (humanoid.RootPart.Size.Y + 3)
				end

				if Players:FindFirstChild(player.Name) then
					store:dispatch(actions.setCurrentPunchingBag(player.Name, nil))
					Remotes.Server:Get("SetControlsEnabled"):SendToPlayer(player, true)
				end

				for _, part in colorParts do
					part.Color = Color3.fromRGB(231, 0, 0)
				end
			end
		end)

		task.spawn(function()
			repeat
				currentIndex = (currentIndex % maxIndex) + 1
				currentAnimation = animationInstances[currentIndex]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				currentTrack:Play()

				local sound = player.Character.HumanoidRootPart:FindFirstChild "Fists" or fistSound:Clone()
				sound.Parent = player.Character.HumanoidRootPart
				sound.PlaybackSpeed = random:NextNumber(0.9, 1.1)
				sound:Play()

				currentTrack.Stopped:Wait()
				currentTrack:Destroy()

				loadedIdleAnimation:Play()

				local newWorkoutSpeed = workoutSpeed

				if selectors.isPlayerLoaded(store:getState(), player.Name) then
					local rebirthBuff = selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "WorkoutSpeed")
						* 0.05

					newWorkoutSpeed *= (1 - rebirthBuff)

					if selectors.hasGamepass(store:getState(), player.Name, tripleWorkoutSpeedPassID) then
						newWorkoutSpeed /= 3
					end

					if selectors.getActiveBoosts(store:getState(), player.Name)["WorkoutBoost"] then
						newWorkoutSpeed /= 3
					end
				end

				task.wait(newWorkoutSpeed)

				loadedIdleAnimation:Stop()
			until cancelled

			loadedIdleAnimation:Destroy()
		end)

		while
			selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getStat(store:getState(), player.Name, "Fear") >= selectors.getStat(
				store:getState(),
				player.Name,
				"RequiredFear"
			)
			and not cancelled
			and player:DistanceFromCharacter(bag.HumanoidLockPart.Position) <= 10
		do
			store:dispatch(
				actions.incrementPlayerStat(
					player.Name,
					"Fear",
					-selectors.getStat(store:getState(), player.Name, "RequiredFear")
				)
			)
			store:dispatch(actions.incrementPlayerStat(player.Name, "Strength", requiredFear * multiplier, bag.Name))

			local maxFearMeter = selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			local currentFearMeter = selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
			local reductionAmount = -maxFearMeter
				* strengthRanks["Rank" .. selectors.getStat(store:getState(), player.Name, "Rank")].FearDecrease.Value
				/ 100

			if (currentFearMeter + reductionAmount) < 0 then
				reductionAmount = -currentFearMeter
			end

			if reductionAmount < 0 then
				store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", reductionAmount))
			end

			local newWorkoutSpeed = workoutSpeed
			local rebirthBuff = selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "WorkoutSpeed") * 0.05

			newWorkoutSpeed *= (1 - rebirthBuff)

			if selectors.hasGamepass(store:getState(), player.Name, tripleWorkoutSpeedPassID) then
				newWorkoutSpeed /= 3
			end

			if selectors.getActiveBoosts(store:getState(), player.Name)["WorkoutBoost"] then
				newWorkoutSpeed /= 3
			end

			task.wait(newWorkoutSpeed)
		end

		if connection.Connected then
			disableSwitch:Fire(player, startStrength)
		end
	end)
end

for _, punchingBag in CollectionService:GetTagged "PunchingBag" do
	handlePunchingBag(punchingBag)
end

CollectionService:GetInstanceAddedSignal("PunchingBag"):Connect(handlePunchingBag)

return 0
