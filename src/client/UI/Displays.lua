local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local playerStatePromise = require(Client.State.PlayerStatePromise)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

local function updateDisplays(state, displays)
	local playerState = state.GameState.Players[player.Name]
	for _, displayData in ipairs(displays) do
		local display = displayData[1]
		local format = displayData[2]
		if format then
			display.Text = format(playerState[display.Name])
		else
			display.Text = formatter.formatNumberWithSuffix(playerState[display.Parent.Name])
		end
	end
end

Promise.new(function(resolve)
	local interfaces = {
		Jumpscares = player.PlayerGui:WaitForChild "Jumpscares",
		MainUI = player.PlayerGui:WaitForChild "MainUI",
		Pets = player.PlayerGui:WaitForChild "Pets",
		Rank = player.PlayerGui:WaitForChild "Rank",
		WeaponShop = player.PlayerGui:WaitForChild "WeaponShop",
	}
	resolve(interfaces)
end):andThen(function(interfaces)
	local displays = {
		{ interfaces.MainUI.Strength.Amount },
		{ interfaces.MainUI.Fear.Amount },
		{ interfaces.MainUI.Gems.Amount },
		{
			interfaces.WeaponShop.LeftBackground.Gems,
			function(gems)
				return formatter.formatNumberWithSuffix(gems) .. " Gems"
			end,
		},
	}

	playerStatePromise:andThen(function()
		updateDisplays(store:getState(), displays)
		store.changed:connect(function(newState)
			updateDisplays(newState, displays)
		end)
	end)
end)

return 0
