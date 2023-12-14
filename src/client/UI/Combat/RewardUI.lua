local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local currencyDroppingUtils = require(ReplicatedStorage.Common.Utils.Player.CurrencyDroppingUtils)
local getMultiplierAdjustedStat =
	require(ReplicatedStorage.Common.Utils.Player.MultiplierUtils).getMultiplierAdjustedStat

local player = Players.LocalPlayer
local baseRewardPart = ReplicatedStorage.KillRewardPart

Remotes.Client:Get("SpawnRewardPart"):Connect(function(fear, gems)
	local rewardPart = baseRewardPart:Clone()
	local obliterator = Janitor.new()

	rewardPart.Position = player.Character.HumanoidRootPart.Position
	rewardPart.Parent = workspace
	obliterator:LinkToInstance(rewardPart)

	formatter.tweenFormattedTextNumber(rewardPart.KillRewardUI.Frame.FearFrame.Amount, {
		0,
		getMultiplierAdjustedStat(player, "Fear", fear),
		0.3,
	})
	formatter.tweenFormattedTextNumber(rewardPart.KillRewardUI.Frame.GemsFrame.Amount, {
		0,
		getMultiplierAdjustedStat(player, "Gems", gems),
		0.3,
	})

	task.wait(0.5)
	rewardPart.KillRewardUI.Frame:TweenPosition(
		UDim2.fromScale(0, -0.3),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		1,
		true,
		function()
			for _, descendant in rewardPart:GetDescendants() do
				local propertyToChange
				if descendant:IsA "ImageLabel" then
					propertyToChange = "ImageTransparency"
				elseif descendant:IsA "TextLabel" then
					propertyToChange = "TextTransparency"
				else
					continue
				end
				local tween = TweenService:Create(descendant, TweenInfo.new(0.5), { [propertyToChange] = 1 })
				obliterator:Add(tween)
				tween:Play()
			end

			task.wait(1)
			rewardPart:Destroy()
		end
	)
end)

Remotes.Client:Get("DropGems"):Connect(currencyDroppingUtils.dropCurrency)

return 0
