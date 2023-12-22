local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local tutorialActive = require(StarterPlayer.StarterPlayerScripts.Client.UI.TutorialUI)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local multiplierLevelDetails = {}
local obliterator = Janitor.new()
local clickCleaner = Janitor.new()

local setComboMeterLevel = Remotes.Client:Get "SetComboMeterLevel"
local decayRate = ReplicatedStorage.Config.Combat.ComboLevels.DecayRate.Value
local autoClickPassID = ReplicatedStorage.Config.GamepassData.IDs.AutoClicker.Value
local enabled, clickCount, lastClicked, decayActive, decayCheckEnabled, currentMultiplierLevel

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

	while tick() - lastClicked < 3 and enabled and decayCheckEnabled do
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

	while enabled and tick() - lastClicked >= 3 and decayActive do
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

	local function mainCleanup()
		clickCount = 0
		lastClicked = -1
		currentMultiplierLevel = 0

		enabled = false
		decayActive = false
		decayCheckEnabled = false

		comboMeterUI.Enabled = false
		comboMeterUI.Background.Multiplier.Text = "Combo Multiplier: 1x"
		comboMeterUI.Background.Frame.Bar.Size = UDim2.fromScale(0, 0.85)

		setComboMeterLevel:SendToServer(0)
	end

	obliterator:Add(mainCleanup, true)
	obliterator:Cleanup()

	local function handleClick()
		if decayActive then
			decayActive = false
			decayCheckEnabled = false
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
	end

	DescriptionUI(comboMeterUI.Passes.AutoClicker, comboMeterUI.Passes.AutoClicker.Frame)
	comboMeterUI.Passes.AutoClicker.Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, autoClickPassID)
	end)

	Remotes.Client:Get("CombatBegan"):Connect(function()
		if enabled or tutorialActive() then
			return
		end

		obliterator:Add(mainCleanup, true)

		enabled = true
		comboMeterUI.Enabled = true

		obliterator:Add(function()
			clickCleaner:Cleanup()
		end, true)

		if
			selectors.hasGamepass(store:getState(), player.Name, "AutoClicker")
			and selectors.getSetting(store:getState(), player.Name, "AutoClicker")
		then
			while enabled do
				handleClick()
				task.wait(0.1)
			end
		else
			local debounce = false
			clickCleaner:Add(comboMeterUI.ClickBackground.Click.Activated:Connect(function()
				if debounce then
					return
				end
				debounce = true
				task.delay(0.2, function()
					debounce = false
				end)
				handleClick()
			end))
		end
	end)

	if selectors.hasGamepass(store:getState(), player.Name, "AutoClicker") then
		comboMeterUI.Passes.AutoClicker.Visible = false
		comboMeterUI.Background.Position = UDim2.fromScale(0.405, 0.8)
		comboMeterUI.ClickBackground.Position = UDim2.fromScale(0.552, 0.811)
	end

	store.changed:connect(function(newState, oldState)
		if
			selectors.hasGamepass(newState, player.Name, "AutoClicker")
			and selectors.isPlayerLoaded(oldState, player.Name)
			and not selectors.hasGamepass(oldState, player.Name, "AutoClicker")
		then
			comboMeterUI.Passes.AutoClicker.Visible = false
			comboMeterUI.Background.Position = UDim2.fromScale(0.405, 0.8)
			comboMeterUI.ClickBackground.Position = UDim2.fromScale(0.552, 0.811)
			clickCleaner:Cleanup()
			task.spawn(function()
				while enabled do
					handleClick()
					task.wait(0.1)
				end
			end)
		end

		if
			selectors.getSetting(newState, player.Name, "AutoClicker")
			~= selectors.getSetting(oldState, player.Name, "AutoClicker")
		then
			if selectors.getSetting(newState, player.Name, "AutoClicker") then
				clickCleaner:Cleanup()
				task.spawn(function()
					while enabled do
						handleClick()
						task.wait(0.1)
					end
				end)
			else
				local debounce = false
				clickCleaner:Add(comboMeterUI.ClickBackground.Click.Activated:Connect(function()
					if debounce then
						return
					end
					debounce = true
					task.delay(0.2, function()
						debounce = false
					end)
					handleClick()
				end))
			end
		end

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
			obliterator:Cleanup()
		end
	end)
end)

return 0
