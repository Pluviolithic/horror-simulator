local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Client = StarterPlayer.StarterPlayerScripts.Client
local player = Players.LocalPlayer

local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)

local minSize = UDim2.fromScale(0.053, 0.88)
local maxSize = UDim2.fromScale(0.981, 0.88)

local function updateBarSize(state, bar)
	local percentage = selectors.getStat(state, player.Name, "CurrentFearMeter")
		/ selectors.getStat(state, player.Name, "MaxFearMeter")
	local relativeBarHeight = (maxSize.X.Scale - minSize.X.Scale) * percentage

	bar.Size = UDim2.fromScale(minSize.X.Scale + relativeBarHeight, minSize.Y.Scale)
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
	local bar = fearMeter.Background.Bar

	updateBarSize(store:getState(), bar)
	updateBarText(store:getState(), fearMeter.Fear)
	store.changed:connect(function(newState)
		updateBarSize(newState, bar)
		updateBarText(newState, fearMeter.Fear)
	end)
end)

return 0
