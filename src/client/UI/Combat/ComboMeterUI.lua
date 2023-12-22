local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local setComboMeterLevel = Remotes.Client:Get "SetComboMeterLevel"

local enabled = false
local clickCount = 0
local lastClicked = -1
local decayActive = false
local decayCheckEnabled = false
local currentMultiplierLevel = 0
local multiplierLevelDetails = {}
local player = Players.LocalPlayer
local decayRate = ReplicatedStorage.Config.Combat.ComboLevels.DecayRate.Value

for _, multiplierLevel in ReplicatedStorage.Config.Combat.ComboLevels:GetChildren() do
	if multiplierLevel.Name == "DecayRate" then
		continue
	end
	multiplierLevelDetails[tonumber(multiplierLevel.Name)] = {
		Clicks = multiplierLevel.Clicks.Value,
		Multiplier = multiplierLevel.Multiplier.Value,
	}
end

local function decayComboMeter(comboMeterUI)
	if decayCheckEnabled then
		return
	end
	decayCheckEnabled = true
	while tick() - lastClicked < 3 and enabled do
		task.wait()
	end

	if not enabled then
		decayCheckEnabled = false
		return
	end

	decayActive = true

	if currentMultiplierLevel == 5 then
		currentMultiplierLevel -= 1
		comboMeterUI.Background.Multiplier.Text = "Combo Multiplier: "
			.. (multiplierLevelDetails[currentMultiplierLevel].Multiplier + 1)
			.. "x"
		setComboMeterLevel:SendToServer(currentMultiplierLevel)
	end

	while enabled and tick() - lastClicked >= 3 do
		local elapsedTime = tick() - lastClicked
		local newSizeX = comboMeterUI.Background.Frame.Bar.Size.X.Scale - (decayRate * (elapsedTime - 3))

		comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(newSizeX, 0.85)

		if newSizeX <= 0 then
			if currentMultiplierLevel == 0 then
				comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0, 0.85)
				clickCount = 0
				break
			end

			currentMultiplierLevel = math.max(currentMultiplierLevel - 1, 0)
			Remotes.Client:Get("SetComboMeterLevel"):SendToServer(currentMultiplierLevel)
			comboMeterUI.Background.Multiplier.Text = "Combo Multiplier: "
				.. (multiplierLevelDetails[currentMultiplierLevel].Multiplier + 1)
				.. "x"
			comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0.973, 0.85)
		end

		task.wait()
	end

	decayActive = false
	decayCheckEnabled = false
end

playerStatePromise:andThen(function()
	local comboMeterUI = player.PlayerGui:WaitForChild "ComboMeter"

	local debounce = false
	comboMeterUI.Click.Activated:Connect(function()
		if debounce then
			return
		end
		debounce = true
		task.delay(0.2, function()
			debounce = false
		end)

		if decayActive then
			decayActive = false
			decayCheckEnabled = false
			if currentMultiplierLevel > 0 then
				clickCount = 0
				for i = 1, currentMultiplierLevel - 1 do
					clickCount += multiplierLevelDetails[i].Clicks
				end
			end
			if multiplierLevelDetails[currentMultiplierLevel + 1] then
				clickCount = math.floor(
					comboMeterUI.Background.Frame.Bar.Size.X.Scale
						/ 0.973
						* multiplierLevelDetails[currentMultiplierLevel + 1].Clicks
				)
			else
				clickCount = math.floor(
					comboMeterUI.Background.Frame.Bar.Size.X.Scale
						/ 0.973
						* multiplierLevelDetails[currentMultiplierLevel].Clicks
				)
			end
		end

		clickCount += 1
		lastClicked = tick()

		task.spawn(decayComboMeter, comboMeterUI)

		if
			multiplierLevelDetails[currentMultiplierLevel + 1]
			and clickCount >= multiplierLevelDetails[currentMultiplierLevel + 1].Clicks
		then
			currentMultiplierLevel += 1
			clickCount = 0
			if multiplierLevelDetails[currentMultiplierLevel + 1] then
				comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0, 0.85)
			else
				comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0.973, 0.85)
			end
			comboMeterUI.Background.Multiplier.Text = "Combo Multiplier: "
				.. (multiplierLevelDetails[currentMultiplierLevel].Multiplier + 1)
				.. "x"
			setComboMeterLevel:SendToServer(currentMultiplierLevel)
			return
		end

		if not multiplierLevelDetails[currentMultiplierLevel + 1] then
			return
		end
		comboMeterUI.Background.Frame.Bar:TweenSize(
			UDim2.fromScale(clickCount / multiplierLevelDetails[currentMultiplierLevel + 1].Clicks * 0.973, 0.85),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.1,
			true
		)
	end)

	Remotes.Client:Get("CombatBegan"):Connect(function()
		enabled = true
		comboMeterUI.Enabled = true
	end)

	store.changed:connect(function(newState, oldState)
		if
			(
				not selectors.getCurrentTarget(newState, player.Name)
				and selectors.isPlayerLoaded(oldState, player.Name)
				and selectors.getCurrentTarget(oldState, player.Name)
			)
			or selectors.isPlayerLoaded(oldState, player.Name)
				and selectors.getCurrentTarget(newState, player.Name) ~= selectors.getCurrentTarget(
					oldState,
					player.Name
				)
		then
			enabled = false
			clickCount = 0
			decayCheckEnabled = false
			currentMultiplierLevel = 0
			comboMeterUI.Enabled = false
			comboMeterUI.Background.Multiplier.Text = "Combo Multiplier: 1x"
			comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0, 0.85)
			setComboMeterLevel:SendToServer(0)
		end
	end)
end)

return 0
