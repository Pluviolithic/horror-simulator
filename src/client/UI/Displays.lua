local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
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
	local interfaces = {
		Rank = player.PlayerGui:WaitForChild "Rank",
		MainUI = player.PlayerGui:WaitForChild "MainUI",
		WeaponShop = player.PlayerGui:WaitForChild "WeaponShop",
		PetInventory = player.PlayerGui:WaitForChild "PetInventory",
		StrengthRanks = player.PlayerGui:WaitForChild "StrengthRanks",
	}
	resolve(interfaces)
end):andThen(function(interfaces)
	local displays = {
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
				local multiplierData = selectors.getMultiplierData(store:getState(), player.Name)
				local multiplier = multiplierData.FearMultiplier or 0
				if (multiplierData.FearMultiplierCount or 0) < 1 then
					multiplier += 1
				end
				return "X" .. formatter.truncateMultiplier(multiplier)
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
		updateDisplays(displays)
		store.changed:connect(function()
			updateDisplays(displays)
		end)

		-- implementation taken from https://devforum.roblox.com/t/resetbuttoncallback-has-not-been-registered-by-the-corescripts/78470/6
		local coreCall
		do
			local MAX_RETRIES = 8

			function coreCall(method, ...)
				local result = {}
				for _ = 1, MAX_RETRIES do
					result = { pcall(StarterGui[method], StarterGui, ...) }
					if result[1] then
						break
					end
					RunService.Stepped:Wait()
				end
				return unpack(result)
			end
		end

		coreCall("SetCore", "ResetButtonCallback", false)
	end)
end)

return 0
