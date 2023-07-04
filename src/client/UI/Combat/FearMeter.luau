local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Client = StarterPlayer.StarterPlayerScripts.Client
local player = Players.LocalPlayer

local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)

local minSize = UDim2.fromScale(0.878, 0.043)
local maxSize = UDim2.fromScale(0.878, 0.871)

local function updateBarSize(state, bar)
	local percentage = math.clamp(
		selectors.getStat(state, player.Name, "CurrentFearMeter")
			/ selectors.getStat(state, player.Name, "MaxFearMeter"),
		0,
		1
	)
	local relativeBarHeight = (maxSize.Y.Scale - minSize.Y.Scale) * percentage

	bar.Size = UDim2.fromScale(minSize.X.Scale, minSize.Y.Scale + relativeBarHeight)
end

local function updateBarText(state, textLabel)
	local currentFearMeter = selectors.getStat(state, player.Name, "CurrentFearMeter")
	local maxFearMeter = selectors.getStat(state, player.Name, "MaxFearMeter")
	local newText = currentFearMeter

	if currentFearMeter == maxFearMeter then
		newText = "Max"
	end

	textLabel.Text = newText
end

playerStatePromise:andThen(function()
	local fearMeter = player.PlayerGui:WaitForChild "FearMeter"
	local vignette = player.PlayerGui:WaitForChild "Vignette"

	local currentState = store:getState()
	local bar = fearMeter.Background.Bar

	updateBarSize(store:getState(), bar)
	updateBarText(store:getState(), fearMeter.Fear)
	store.changed:connect(function(newState)
		currentState = newState
		updateBarSize(newState, bar)
		updateBarText(newState, fearMeter.Fear)
	end)

	RunService.RenderStepped:Connect(function()
		local secondsSinceEpoch = workspace:GetServerTimeNow()
		local secondsSinceLastScared = secondsSinceEpoch
			- selectors.getStat(currentState, player.Name, "LastScaredTimestamp")
		if secondsSinceLastScared < 121 then
			fearMeter.ScaredTextTimer.Text = string.format(
				"Lower your fear meter by working out or wait " .. "%02i:%02i" .. " minutes.",
				(120 - secondsSinceLastScared) / 60 % 60,
				(120 - secondsSinceLastScared) % 60
			)

			if not vignette.Enabled then
				fearMeter.ScaredText.Visible = true
				fearMeter.ScaredTextTimer.Visible = true
				vignette.Enabled = true

				local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
				if humanoid then
					humanoid.WalkSpeed = 10
				end
			end
		else
			if vignette.Enabled then
				fearMeter.ScaredText.Visible = false
				fearMeter.ScaredTextTimer.Visible = false
				vignette.Enabled = false

				local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
				if humanoid then
					humanoid.WalkSpeed = 14
				end
			end
		end
	end)
end)

return 0
