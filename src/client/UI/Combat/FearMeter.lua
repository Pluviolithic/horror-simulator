local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local doubleFearMeterID = ReplicatedStorage.Config.GamepassData.IDs["2xFearMeter"].Value
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
	local fearMeterHidden = false

	local function hideFearMeter()
		fearMeterHidden = true
		fearMeter.Fear.Visible = false
		fearMeter.Icon.Visible = false
		fearMeter.Image.Visible = false
		fearMeter.Enable.Visible = true
		fearMeter.Disable.Visible = false
		fearMeter.Fearless.Visible = false
		fearMeter.Background.Visible = false
	end

	local function revealFearMeter()
		fearMeterHidden = false
		fearMeter.Icon.Visible = true
		fearMeter.Image.Visible = true
		fearMeter.Enable.Visible = false
		fearMeter.Disable.Visible = true
		fearMeter.Background.Visible = true

		if selectors.getActiveBoosts(currentState, player.Name)["FearlessBoost"] then
			fearMeter.Fear.Visible = false
			fearMeter.Fearless.Visible = true
		else
			fearMeter.Fear.Visible = true
			fearMeter.Fearless.Visible = false
		end
	end

	fearMeter.Background.Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, doubleFearMeterID)
	end)

	updateBarSize(store:getState(), bar)
	updateBarText(store:getState(), fearMeter.Fear)
	store.changed:connect(function(newState, oldState)
		currentState = newState
		updateBarSize(newState, bar)
		updateBarText(newState, fearMeter.Fear)

		if not selectors.isPlayerLoaded(oldState, player.Name) then
			return
		end

		local currentTarget = selectors.getCurrentTarget(newState, player.Name)
		local previousTarget = selectors.getCurrentTarget(oldState, player.Name)

		if not fearMeterHidden then
			if selectors.getActiveBoosts(newState, player.Name)["FearlessBoost"] then
				fearMeter.Fear.Visible = false
				fearMeter.Fearless.Visible = true
			else
				fearMeter.Fear.Visible = true
				fearMeter.Fearless.Visible = false
			end
		end

		if currentTarget ~= previousTarget and currentTarget then
			if
				selectors.getStat(newState, player.Name, "CurrentFearMeter")
					>= selectors.getStat(newState, player.Name, "MaxFearMeter") * 0.8
				and selectors.getStat(newState, player.Name, "CurrentFearMeter") ~= selectors.getStat(
					newState,
					player.Name,
					"MaxFearMeter"
				)
				and not CollectionService:HasTag(currentTarget, "PunchingBag")
			then
				hideFearMeter()
			end
		elseif previousTarget and not currentTarget then
			revealFearMeter()
		end
	end)

	fearMeter.Enable.Activated:Connect(revealFearMeter)
	fearMeter.Disable.Activated:Connect(hideFearMeter)

	RunService.RenderStepped:Connect(function()
		local secondsSinceLastScared = os.time() - selectors.getStat(currentState, player.Name, "LastScaredTimestamp")
		if secondsSinceLastScared < 120 then
			fearMeter.ScaredTextTimer.Text = string.format(
				"Lower your fear meter by working out or wait " .. "%02i:%02i" .. " minutes.",
				(120 - secondsSinceLastScared) / 60 % 60,
				(120 - secondsSinceLastScared) % 60
			)

			if not vignette.Enabled then
				fearMeter.ScaredText.Visible = true
				fearMeter.ScaredTextTimer.Visible = true
				vignette.Enabled = true
			end
		else
			if vignette.Enabled then
				fearMeter.ScaredText.Visible = false
				fearMeter.ScaredTextTimer.Visible = false
				vignette.Enabled = false
			end
		end
	end)
end)

return 0
