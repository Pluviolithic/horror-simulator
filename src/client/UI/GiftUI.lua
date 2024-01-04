local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer
local giftTimers = ReplicatedStorage.Config.Gifts.Timers
local packs = ReplicatedStorage.Config.DevProductData.Packs
local claimColors = ReplicatedStorage.Config.Gifts.ClaimColors
local skipAllID = ReplicatedStorage.Config.DevProductData.IDs.SkipAll.Value

local GiftUI = CentralUI.new(player.PlayerGui:WaitForChild "GiftUI")

function GiftUI:_initialize(): ()
	player.PlayerGui:WaitForChild("MainUI").Gifts.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(not self._isOpen)
	end)

	self._shakeTweenStart = TweenService:Create(
		player.PlayerGui.MainUI.Gifts.Icon,
		TweenInfo.new(0.5 / 3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Rotation = -10 }
	)
	self._shakeTweenEnd = TweenService:Create(
		player.PlayerGui.MainUI.Gifts.Icon,
		TweenInfo.new(0.5 / 3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Rotation = 12 }
	)
	self._shakeTweenReset = TweenService:Create(
		player.PlayerGui.MainUI.Gifts.Icon,
		TweenInfo.new(0.5 / 3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Rotation = -2 }
	)

	self._shakeTweenStart.Completed:Connect(function()
		self._shakeTweenEnd:Play()
	end)
	self._shakeTweenEnd.Completed:Connect(function()
		self._shakeTweenReset:Play()
	end)

	self._counter = 0

	for _, giftDisplay in self._ui.Background.Frame.ScrollingFrame:GetChildren() do
		if not giftDisplay:IsA "ImageButton" then
			continue
		end

		local debounce = false
		giftDisplay.Claim.Activated:Connect(function()
			if debounce then
				return
			end
			debounce = true
			if giftDisplay.Claim.Text.Text == "Claim" then
				Remotes.Client:Get("ClaimGift"):SendToServer(giftDisplay.Name)
			end
			task.wait(0.5)
			debounce = false
		end)
	end

	self._ui.Background.SkipAll.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, skipAllID)
	end)

	playerStatePromise:andThen(function()
		while true do
			self._counter = (self._counter + 1) % 2
			self:Refresh(true)
			task.wait(1)
		end
	end)
end

function GiftUI:OnOpen()
	self:Refresh()
end

function GiftUI:Refresh(fromLoop: boolean?)
	local firstTimerText = nil
	local claimExists = false
	for _, giftDisplay in self._ui.Background.Frame.ScrollingFrame:GetChildren() do
		if not giftDisplay:IsA "ImageButton" then
			continue
		end

		if giftDisplay.Name:match "Pack" then
			local statName = " STR"
			local pack = packs:FindFirstChild(giftDisplay.Name, true)
			local areaName = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
			areaName = areaName:gsub(" ", "_")

			if giftDisplay.Name:match "Gem" then
				statName = " GEMS"
			elseif giftDisplay.Name:match "Fear" then
				statName = " FEAR"
			end

			giftDisplay.Amount.Text = "+"
				.. formatter.formatNumberWithSuffix(pack:GetAttribute(areaName)):upper()
				.. statName
		elseif giftDisplay.Name:match "Pet" then
			local petValue = ReplicatedStorage.Config.Gifts[giftDisplay.Name]
			local areaName = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
			areaName = areaName:gsub(" ", "_")

			local pet = petUtils.getPet(petValue:GetAttribute(areaName))
			giftDisplay.PetImage.Image = pet.ImageID.Value
			giftDisplay.PetName.Text = pet.Name:upper()
		end

		if selectors.hasClaimedGift(store:getState(), player.Name, giftDisplay.Name) then
			giftDisplay.Claim.Text.Text = "Claimed"
			giftDisplay.Claim.ImageColor3 = claimColors.Claimed.Value
		elseif
			os.time() - selectors.getStat(store:getState(), player.Name, "GiftCycleBeganTimestamp")
				< giftTimers[giftDisplay.Name].Value * 60
			and not selectors.skippedGiftTimers(store:getState(), player.Name)
		then
			giftDisplay.Claim.Text.Text = clockUtils.getFormattedGiftTime(
				giftTimers[giftDisplay.Name].Value * 60
					- (os.time() - selectors.getStat(store:getState(), player.Name, "GiftCycleBeganTimestamp"))
			)
			giftDisplay.Claim.ImageColor3 = claimColors.Timer.Value

			if not firstTimerText then
				firstTimerText = giftDisplay.Claim.Text.Text
			end
		else
			claimExists = true
			giftDisplay.Claim.Text.Text = "Claim"
			giftDisplay.Claim.ImageColor3 = claimColors.Claim.Value
		end
	end

	if claimExists then
		player.PlayerGui.MainUI.Gifts.Timer.Text = "CLAIM GIFT"
		if self._counter == 0 and fromLoop then
			self._shakeTweenStart:Play()
		end
	elseif firstTimerText then
		player.PlayerGui.MainUI.Gifts.Timer.Text = "GIFT IN: " .. firstTimerText
		if not self._ui.Background.Frame.ScrollingFrame.Visible then
			self._ui.Background.Frame.ScrollingFrame.Visible = true
			self._ui.Background.Frame.CompletionText.Visible = false
			self._ui.Background.Frame.CompletionTimer.Visible = false
			self._ui.Background.SkipAll.Visible = true
		end
	else
		player.PlayerGui.MainUI.Gifts.Timer.Text = "COMPLETED"
		if self._ui.Background.Frame.ScrollingFrame.Visible then
			self._ui.Background.Frame.ScrollingFrame.Visible = false
			self._ui.Background.Frame.CompletionText.Visible = true
			self._ui.Background.Frame.CompletionTimer.Visible = true
			self._ui.Background.SkipAll.Visible = false
		end

		self._ui.Background.Frame.CompletionTimer.Text = "Next Gifts In: "
			.. clockUtils.getFormattedGiftTime(
				16 * 60 * 60
					- (os.time() - selectors.getStat(store:getState(), player.Name, "LastClaimedAGiftTimestamp"))
			)
	end
end

task.spawn(GiftUI._initialize, GiftUI)

interfaces[GiftUI] = true

return GiftUI
