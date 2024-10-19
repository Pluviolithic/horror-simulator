local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(Client.State.Store)

local MainUI = player.PlayerGui:WaitForChild "MainUI"

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		local newGems, oldGems =
			selectors.getStat(newState, player.Name, "Gems"), selectors.getStat(oldState, player.Name, "Gems") or 0
		local newFear, oldFear =
			selectors.getStat(newState, player.Name, "Fear"), selectors.getStat(oldState, player.Name, "Fear") or 0
		local newStrength, oldStrength =
			selectors.getStat(newState, player.Name, "Strength"),
			selectors.getStat(oldState, player.Name, "Strength") or 0

		if newGems ~= oldGems then
			formatter.tweenFormattedTextNumber(MainUI.Gems.Amount, { oldGems, newGems, 0.3 })
		elseif MainUI.Gems.Amount.Text ~= formatter.formatNumberWithSuffix(newGems) then
			MainUI.Gems.Amount.Text = formatter.formatNumberWithSuffix(newGems)
		end

		if newFear ~= oldFear then
			formatter.tweenFormattedTextNumber(MainUI.Fear.Amount, { oldFear, newFear, 0.3 })
		elseif MainUI.Fear.Amount.Text ~= formatter.formatNumberWithSuffix(newFear) then
			MainUI.Fear.Amount.Text = formatter.formatNumberWithSuffix(newFear)
		end

		if newStrength ~= oldStrength then
			formatter.tweenFormattedTextNumber(MainUI.Strength.Amount, { oldStrength, newStrength, 0.3 })
		elseif MainUI.Strength.Amount.Text ~= formatter.formatNumberWithSuffix(newStrength) then
			MainUI.Strength.Amount.Text = formatter.formatNumberWithSuffix(newStrength)
		end
	end)
end)

return 0
