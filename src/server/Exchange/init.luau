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

local function handlePunchingBag(bag: any)
	local prompt: ProximityPrompt = bag.HumanoidLockPart.Prompt
	local teleportPart: BasePart = bag.TPPart
	local inUse: boolean = false

	prompt.Triggered:Connect(function(player: Player)
		local cancelled: boolean = false

		if
			inUse
			or selectors.getCurrentTarget(store:getState(), player.Name)
			or selectors.getStat(store:getState(), player.Name, "Fear")
				< selectors.getStat(store:getState(), player.Name, "Strength") * 5
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

		local animationInstances: { Animation } = animations:FindFirstChild("Fists"):GetChildren()
		local currentAnimation: Animation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack: AnimationTrack = humanoid:LoadAnimation(currentAnimation)

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
			end
		end)

		task.spawn(function()
			repeat
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				task.wait(0.5)
			until cancelled
		end)

		while
			selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getStat(store:getState(), player.Name, "Fear") >= selectors.getStat(
				store:getState(),
				player.Name,
				"Strength"
			) * 5
			and not cancelled
		do
			store:dispatch(
				actions.incrementPlayerStat(
					player.Name,
					"Fear",
					-selectors.getStat(store:getState(), player.Name, "Strength") * 5
				)
			)
			store:dispatch(actions.incrementPlayerStat(player.Name, "Strength", 1))

			local maxFearMeter = selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			local currentFearMeter = selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
			local reductionAmount = -maxFearMeter / 10

			if (currentFearMeter + reductionAmount) < 0 then
				reductionAmount = -currentFearMeter
			end

			store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", -maxFearMeter / 10))

			task.wait(0.6)
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
