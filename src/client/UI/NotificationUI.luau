local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local achievedMilestone = Remotes.Client:Get "AchievedMilestone"
local NotificationUI = CentralUI.new(player.PlayerGui:WaitForChild "GameCompleted")

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		if
			not selectors.isPlayerLoaded(newState, player.Name) or not selectors.isPlayerLoaded(oldState, player.Name)
		then
			return
		end

		if
			selectors.getStat(newState, player.Name, "Strength") >= 10 ^ 8
			and (selectors.getStat(oldState, player.Name, "Strength") < 10 ^ 8 or not selectors.achievedMilestone(
				newState,
				player.Name,
				"100MStrength"
			))
			and not selectors.achievedMilestone(newState, player.Name, "100MStrength")
		then
			NotificationUI:setEnabled(true)
			achievedMilestone:SendToServer "100MStrength"
		end
	end)
end)

return NotificationUI
