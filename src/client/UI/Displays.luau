local Players = game:GetService "Players"
local StarterGui = game:GetService "StarterGui"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

type pair<T, U> = {
	first: T,
	second: U,
}

local function updateDisplays(displays)
	for _, displayData in displays do
		local display = displayData.first
		local format = displayData.second
		if format then
			display.Text = format(display.Name)
		else
			display.Text =
				formatter.formatNumberWithSuffix(selectors.getStat(store:getState(), player.Name, display.Parent.Name))
		end
	end
end

Promise.new(function(resolve)
	local interfaces: { [string]: GuiObject } = {
		Rank = player.PlayerGui:WaitForChild "Rank",
		MainUI = player.PlayerGui:WaitForChild "MainUI",
		WeaponShop = player.PlayerGui:WaitForChild "WeaponShop",
		Jumpscares = player.PlayerGui:WaitForChild "Jumpscares",
		PetInventory = player.PlayerGui:WaitForChild "PetInventory",
		StrengthRanks = player.PlayerGui:WaitForChild "StrengthRanks",
	}
	resolve(interfaces)
end):andThen(function(interfaces)
	local displays = {
		{ first = interfaces.MainUI.Strength.Amount },
		{ first = interfaces.MainUI.Fear.Amount },
		{ first = interfaces.MainUI.Gems.Amount },
		{
			first = interfaces.WeaponShop.LeftBackground.Gems,
			second = function(displayName)
				return formatter.formatNumberWithSuffix(selectors.getStat(store:getState(), player.Name, displayName))
					.. " Gems"
			end,
		},
		{
			first = interfaces.PetInventory.Background.Storage.Amount,
			second = function()
				return selectors.getStat(store:getState(), player.Name, "CurrentPetCount")
					.. "/"
					.. selectors.getStat(store:getState(), player.Name, "MaxPetCount")
			end,
		},
		{
			first = interfaces.PetInventory.Background.Equipped.Amount,
			second = function()
				return selectors.getStat(store:getState(), player.Name, "CurrentPetEquipCount")
					.. "/"
					.. selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount")
			end,
		},
		{
			first = interfaces.PetInventory.Background.Multiplier.Amount,
			second = function()
				return "X"
					.. formatter.truncateMultiplier(
						selectors.getStat(store:getState(), player.Name, "PetFearMultiplier")
					)
			end,
		},
		{
			first = interfaces.Rank.Level.Text,
			second = function()
				return selectors.getStat(store:getState(), player.Name, "Rank")
			end,
		},
		{
			first = interfaces.StrengthRanks.Background.Background.MaxMeterText,
			second = function()
				return 'Max Meter: <font color="rgb(222, 124, 4)">'
					.. selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
					.. "</font>"
			end,
		},
	}

	playerStatePromise:andThen(function()
		StarterGui:SetCore("ResetButtonCallback", false)
		updateDisplays(displays)
		store.changed:connect(function()
			updateDisplays(displays)
		end)
	end)
end)

return 0
