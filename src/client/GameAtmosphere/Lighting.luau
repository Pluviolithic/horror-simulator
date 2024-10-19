local Players = game:GetService "Players"
local Lighting = game:GetService "Lighting"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local playerName = Players.LocalPlayer.Name

local function updateLighting(setting)
	if Lighting.BrightMode.Enabled == setting then
		return
	end
	Lighting.BrightMode.Enabled = setting
end

playerStatePromise:andThen(function()
	updateLighting(selectors.getSetting(store:getState(), playerName, "BrightMode"))

	store.changed:connect(function(newState)
		updateLighting(selectors.getSetting(newState, playerName, "BrightMode"))
	end)
end)

return 0
