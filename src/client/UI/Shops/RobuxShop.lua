local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

--local Remotes = require(ReplicatedStorage.Common.Remotes)
--local Table = require(ReplicatedStorage.Common.Utils.Table)
local Sift = require(ReplicatedStorage.Common.lib.Sift)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local RobuxShop = CentralUI.new(player.PlayerGui:WaitForChild "RobuxShop")
local mainUI = player.PlayerGui:WaitForChild "MainUI"

RobuxShop.Trigger = "RobuxShop"

local petProductIDs = ReplicatedStorage.Config.DevProductData.IDs
local packProductIDs = ReplicatedStorage.Config.DevProductData.Packs
local boostProductIDs = ReplicatedStorage.Config.DevProductData.Boosts

local function shouldRefresh(newState, oldState): boolean
	return not selectors.isPlayerLoaded(oldState, player.Name)
		or rankUtils.getBestUnlockedArea(selectors.getStat(newState, player.Name, "Strength")) ~= rankUtils.getBestUnlockedArea(
			selectors.getStat(oldState, player.Name, "Strength")
		)
		or not Sift.Dictionary.equalsDeep(
			selectors.getPurchasedBoosts(newState, player.Name),
			selectors.getPurchasedBoosts(oldState, player.Name)
		)
end

function RobuxShop:_closeFramesWithExclude(exclude)
	for _, frame in self._ui.Background:GetChildren() do
		if frame ~= exclude and self._ui:FindFirstChild(frame.Name:match "(%a+)Frame") then
			frame.Visible = false
		end
	end
end

function RobuxShop:Refresh()
	local bestAreaUnlocked = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
	for _, areaFrame in self._ui.Background.FearFrame:GetChildren() do
		if areaFrame.Name == bestAreaUnlocked then
			areaFrame.Visible = true
		elseif areaFrame.Name ~= "ShopText" then
			areaFrame.Visible = false
		end
	end
	for _, areaFrame in self._ui.Background.GemsFrame:GetChildren() do
		if areaFrame.Name == bestAreaUnlocked then
			areaFrame.Visible = true
		elseif areaFrame.Name ~= "ShopText" then
			areaFrame.Visible = false
		end
	end
	for _, buttonDisplay in self._ui.Background.BoostsFrame.ScrollingFrame:GetChildren() do
		for _, useButton in buttonDisplay:GetChildren() do
			if not useButton.Name:match "Use" then
				continue
			end
			local boostName = buttonDisplay.Name .. useButton.Name:match "(%d*%.?%d+)"
			useButton.Text = `Use ({selectors.getBoostCount(store:getState(), player.Name, boostName)})`
		end
	end
end

function RobuxShop:_countdownDescriptionDisplayTime()
	self._lastDescriptionTapped = os.time()
	if self._countdownActive then
		return
	end
	self._countdownActive = true
	self._ui.Background.GamepassesFrame.Description.Visible = true
	while self._lastDescriptionTapped + 10 > os.time() do
		task.wait(0.25)
	end
	self._ui.Background.GamepassesFrame.Description.Visible = false
	self._countdownActive = false
end

function RobuxShop:_initialize(): ()
	mainUI.RobuxShop.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Boosts.Activated:Connect(function()
		self._ui.Background.BoostsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.BoostsFrame)
	end)

	self._ui.Fear.Activated:Connect(function()
		self._ui.Background.FearFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.FearFrame)
	end)

	self._ui.Gamepasses.Activated:Connect(function()
		self._ui.Background.GamepassesFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GamepassesFrame)
	end)

	self._ui.Gems.Activated:Connect(function()
		self._ui.Background.GemsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GemsFrame)
	end)

	self._ui.Pets.Activated:Connect(function()
		self._ui.Background.PetsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.PetsFrame)
	end)

	for _, buttonDisplay in self._ui.Background.GamepassesFrame.ScrollingFrame:GetChildren() do
		local gamepassIDInstance = gamepassIDs:FindFirstChild(buttonDisplay.Name)
		if gamepassIDInstance then
			buttonDisplay.Purchase.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDInstance.Value)
			end)

			buttonDisplay.MouseEnter:Connect(function()
				if not UserInputService.MouseEnabled then
					return
				end
				self._ui.Background.GamepassesFrame.Description.TextLabel.Text = buttonDisplay.DescriptionText.Value
				self._ui.Background.GamepassesFrame.Description.Visible = true
			end)

			buttonDisplay.MouseLeave:Connect(function()
				if not UserInputService.MouseEnabled then
					return
				end
				self._ui.Background.GamepassesFrame.Description.Visible = false
			end)

			buttonDisplay.TouchTap:Connect(function()
				self._ui.Background.GamepassesFrame.Description.TextLabel.Text = buttonDisplay.DescriptionText.Value
				self:_countdownDescriptionDisplayTime()
			end)
		end
	end

	for _, buttonDisplay in self._ui.Background.PetsFrame.PetsFrame:GetChildren() do
		local productIDInstance = petProductIDs:FindFirstChild(buttonDisplay.Name)
		if productIDInstance then
			buttonDisplay.Purchase.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, productIDInstance.Value)
			end)
		end
	end

	for _, areaFrame in self._ui.Background.GemsFrame:GetChildren() do
		for _, buttonDisplay in areaFrame:GetChildren() do
			local packIDInstance = packProductIDs.Gems:FindFirstChild(buttonDisplay.Name)
			if packIDInstance then
				buttonDisplay.Purchase.Activated:Connect(function()
					MarketplaceService:PromptProductPurchase(player, packIDInstance.Value)
				end)
			end
		end
	end

	for _, areaFrame in self._ui.Background.FearFrame:GetChildren() do
		for _, buttonDisplay in areaFrame:GetChildren() do
			local packIDInstance = packProductIDs.Fear:FindFirstChild(buttonDisplay.Name)
			if packIDInstance then
				buttonDisplay.Purchase.Activated:Connect(function()
					MarketplaceService:PromptProductPurchase(player, packIDInstance.Value)
				end)
			end
		end
	end

	for _, buttonDisplay in self._ui.Background.BoostsFrame.ScrollingFrame:GetChildren() do
		for _, purchaseButton in buttonDisplay:GetChildren() do
			if not purchaseButton.Name:match "Purchase" then
				continue
			end
			local boostIDInstance =
				boostProductIDs:FindFirstChild(buttonDisplay.Name .. purchaseButton.Name:match "(%d*%.?%d+)")

			purchaseButton.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, boostIDInstance.Value)
			end)
		end
	end

	playerStatePromise:andThen(function()
		self:Refresh()

		store.changed:connect(function(newState, oldState)
			if not shouldRefresh(newState, oldState) then
				return
			end
			self:Refresh()
		end)
	end)
end

task.spawn(RobuxShop._initialize, RobuxShop)

return RobuxShop
