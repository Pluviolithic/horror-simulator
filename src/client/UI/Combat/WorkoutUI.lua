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
local length = 0
local looping = false
local defaultLength = workoutSpeed * 100
local WorkoutUI = player.PlayerGui:WaitForChild "WorkoutUI"
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

--local buffer = {}

local function countdownTimer()
	length = defaultLength
	if looping then
		return
	end
	looping = true
	--length = defaultLength
	--WorkoutUI.Background.Frame.Bar.Size = UDim2.fromScale(1.013, 1.104)
	--WorkoutUI.Background.Frame.Bar:TweenSize(UDim2.fromScale(0, 1.104), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, (length + 30) / 100, true)
	WorkoutUI.Background.Frame.Timer.Text = length
	repeat
		task.wait(0.01)
		length -= 1
		-- one decimal of precision
		WorkoutUI.Background.Frame.Timer.Text = string.format("%.1fs", length / 100)
		WorkoutUI.Background.Frame.Bar.Size = UDim2.fromScale(1.013 * length / defaultLength, 1.104)
	until length <= 0 or not looping
	looping = false
	--if #buffer > 0 then
	--  table.remove(buffer)
	--  countdownTimer()
	--end
end

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		local currentTarget = selectors.getCurrentTarget(newState, player.Name)
		local previousTarget = selectors.getCurrentTarget(oldState, player.Name)
		local requiredFearChanged = selectors.getStat(newState, player.Name, "RequiredFear")
			~= selectors.getStat(oldState, player.Name, "RequiredFear")

		if requiredFearChanged then
			WorkoutUI.Background.FearCost.Text =
				`Required Fear: <font color= "rgb(255, 207, 56)">{formatter.formatNumberWithSuffix(
					selectors.getStat(newState, player.Name, "RequiredFear")
				)}</font>`
		end

		if not currentTarget and WorkoutUI.Enabled then
			--table.clear(buffer)
			looping = false
			WorkoutUI.Enabled = false
			return
		elseif not currentTarget then
			local hasTripleSpeed = selectors.hasGamepass(newState, player.Name, "3xWorkoutSpeed")
			if hasTripleSpeed then
				defaultLength = workoutSpeed / 3 * 100
			else
				defaultLength = workoutSpeed * 100
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
			--table.insert(buffer, true)
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
