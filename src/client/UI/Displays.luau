local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local playerStatePromise = require(Client.State.PlayerStatePromise)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

type pair<T, U> = {
	first: T,
	second: U,
}

local function updateDisplays(state, displays)
	local playerState = state.Players[player.Name]
	for _, displayData in displays do
		local display = displayData.first
		local format = displayData.second
		if format then
			display.Text = format(playerState[display.Name])
		else
			display.Text = formatter.formatNumberWithSuffix(playerState[display.Parent.Name])
		end
	end
end

Promise.new(function(resolve)
	local interfaces: { [string]: GuiObject } = {
		Rank = player.PlayerGui:WaitForChild "Rank",
		MainUI = player.PlayerGui:WaitForChild "MainUI",
		Pets = player.PlayerGui:WaitForChild "PetInventory",
		WeaponShop = player.PlayerGui:WaitForChild "WeaponShop",
		Jumpscares = player.PlayerGui:WaitForChild "Jumpscares",
	}
	resolve(interfaces)
end):andThen(function(interfaces)
	local displays: { pair<GuiObject, (((...any) -> any)?)> } = {
		{ first = interfaces.MainUI.Strength.Amount },
		{ first = interfaces.MainUI.Fear.Amount },
		{ first = interfaces.MainUI.Gems.Amount },
		{
			first = interfaces.WeaponShop.LeftBackground.Gems,
			second = function(gems)
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
