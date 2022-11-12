local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local playerStatePromise = require(Client.State.PlayerStatePromise)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

local function updateDisplays(state, displays)
	local playerState = state.GameState.Players[player.Name]
	for _, display in ipairs(displays) do
		display.Text = playerState[display.Parent.Name]
	end
end

Promise.new(function(resolve)
	resolve(player.PlayerGui:WaitForChild "MainUI")
end):andThen(function(MainUI)
	local displays = {
		MainUI.Strength.Amount,
		MainUI.Fear.Amount,
		MainUI.Gems.Amount,
	}

	playerStatePromise:andThen(function()
		updateDisplays(store:getState(), displays)
		store.changed:connect(function(newState)
			updateDisplays(newState, displays)
		end)
	end)
end)

return 0
