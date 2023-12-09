local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer
local workoutSpeed = ReplicatedStorage.Config.Workout.WorkoutSpeed.Value
local playerWorkoutSpeed = workoutSpeed
local looping = false
local WorkoutUI = player.PlayerGui:WaitForChild "WorkoutUI"
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

local startTime

local function countdownTimer()
	startTime = os.clock()
	if looping then
		return
	end
	looping = true
	WorkoutUI.Background.Frame.Timer.Text = playerWorkoutSpeed .. "s"
	repeat
		task.wait()
		local length = os.clock() - startTime
		WorkoutUI.Background.Frame.Timer.Text =
			string.format("%.1fs", math.clamp(playerWorkoutSpeed - length, 0, playerWorkoutSpeed))
		WorkoutUI.Background.Frame.Bar.Size =
			UDim2.fromScale(1.013 * (playerWorkoutSpeed - length) / playerWorkoutSpeed, 1.104)
	until length >= playerWorkoutSpeed or not looping
	looping = false
end

playerStatePromise:andThen(function()
	local previousRequiredFear = selectors.getStat(store:getState(), player.Name, "RequiredFear")
	store.changed:connect(function(newState, oldState)
		local currentTarget = selectors.getCurrentTarget(newState, player.Name)
		local previousTarget = selectors.getCurrentTarget(oldState, player.Name)
		local currentRequiredFear = selectors.getStat(newState, player.Name, "RequiredFear")
		local requiredFearChanged = currentRequiredFear ~= selectors.getStat(oldState, player.Name, "RequiredFear")

		if requiredFearChanged then
			formatter.tweenFormattedTextNumber(WorkoutUI.Background.FearCost, {
				previousRequiredFear,
				currentRequiredFear,
				0.5,
				function(n)
					return `Required Fear: <font color= "rgb(255, 207, 56)">{formatter.formatNumberWithSuffix(n)}</font>`
				end,
			})
			previousRequiredFear = currentRequiredFear
		end

		if not currentTarget and WorkoutUI.Enabled then
			looping = false
			WorkoutUI.Enabled = false
			return
		elseif not currentTarget then
			local hasTripleSpeed = selectors.hasGamepass(newState, player.Name, "3xWorkoutSpeed")
			if hasTripleSpeed then
				playerWorkoutSpeed = workoutSpeed / 3
			else
				playerWorkoutSpeed = workoutSpeed
			end
			return
		end

		if not CollectionService:HasTag(currentTarget, "PunchingBag") then
			return
		end

		if currentTarget ~= previousTarget and not WorkoutUI.Enabled then
			WorkoutUI.Enabled = true
		end

		if requiredFearChanged then
			task.spawn(countdownTimer)
		end
	end)
end)

WorkoutUI.Passes["2xStrength"].Activated:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xStrength"].Value)
end)

WorkoutUI.Passes["3xWorkoutSpeed"].Activated:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["3xWorkoutSpeed"].Value)
end)

return 0
