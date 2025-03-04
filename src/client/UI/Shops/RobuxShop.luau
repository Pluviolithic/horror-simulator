local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer

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
		or selectors.getPurchaseData(newState, player.Name) ~= selectors.getPurchaseData(oldState, player.Name)
end

function RobuxShop:_closeFramesWithExclude(exclude)
	for _, frame in self._ui.Background:GetChildren() do
		if frame ~= exclude and self._ui:FindFirstChild(frame.Name:match "(%a+)Frame") then
			frame.Visible = false
		end
	end
end

function RobuxShop:OpenSubShop(subShopName: string)
	self:setEnabled(true)
	self._ui.Background[subShopName .. "Frame"].Visible = true
	self:_closeFramesWithExclude(self._ui.Background[subShopName .. "Frame"])
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
	for _, gamepassDisplay in self._ui.Background.GamepassesFrame.ScrollingFrame:GetChildren() do
		if gamepassDisplay:IsA "UIGridLayout" then
			continue
		end
		if selectors.hasGamepass(store:getState(), player.Name, gamepassDisplay.Name) then
			gamepassDisplay.BoughtImage.Visible = true
			gamepassDisplay.Purchase.BoughtText.Visible = true
			gamepassDisplay.Purchase.RobuxIcon.Visible = false
			gamepassDisplay.Purchase.RobuxPrice.Visible = false
		else
			gamepassDisplay.BoughtImage.Visible = false
			gamepassDisplay.Purchase.BoughtText.Visible = false
			gamepassDisplay.Purchase.RobuxIcon.Visible = true
			gamepassDisplay.Purchase.RobuxPrice.Visible = true
		end
	end
end

function RobuxShop:_initialize(): ()
	mainUI.RobuxShop.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(not self._isOpen)
	end)

	mainUI.Fear.Buy.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:OpenSubShop "Fear"
	end)

	mainUI.Gems.Buy.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:OpenSubShop "Gems"
	end)

	Remotes.Client:Get("OpenRobuxShopOnClient"):Connect(function(subShopName)
		self:OpenSubShop(subShopName)
	end)

	self._ui.Boosts.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.BoostsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.BoostsFrame)
	end)

	self._ui.Fear.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.FearFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.FearFrame)
	end)

	self._ui.Gamepasses.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.GamepassesFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GamepassesFrame)
	end)

	self._ui.Gems.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.GemsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GemsFrame)
	end)

	self._ui.Pets.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.PetsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.PetsFrame)
	end)

	for _, buttonDisplay in self._ui.Background.GamepassesFrame.ScrollingFrame:GetChildren() do
		local gamepassIDInstance = gamepassIDs:FindFirstChild(buttonDisplay.Name)
		if gamepassIDInstance then
			buttonDisplay.Purchase.Activated:Connect(function()
				playSoundEffect "UIButton"
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDInstance.Value)
			end)

			DescriptionUI(
				buttonDisplay,
				self._ui.Background.GamepassesFrame.Description,
				buttonDisplay.DescriptionText.Value
			)
		end
	end

	for _, buttonDisplay in self._ui.Background.PetsFrame.PetsFrame:GetChildren() do
		local productIDInstance = petProductIDs:FindFirstChild(buttonDisplay.Name)
		if productIDInstance then
			buttonDisplay.Purchase.Activated:Connect(function()
				playSoundEffect "UIButton"
				MarketplaceService:PromptProductPurchase(player, productIDInstance.Value)
			end)
		end
	end

	for _, areaFrame in self._ui.Background.GemsFrame:GetChildren() do
		for _, buttonDisplay in areaFrame:GetChildren() do
			local packIDInstance = packProductIDs.Gems:FindFirstChild(buttonDisplay.Name)
			if packIDInstance then
				buttonDisplay.Purchase.Activated:Connect(function()
					playSoundEffect "UIButton"
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
					playSoundEffect "UIButton"
					MarketplaceService:PromptProductPurchase(player, packIDInstance.Value)
				end)
			end
		end
	end

	for _, buttonDisplay in self._ui.Background.BoostsFrame.ScrollingFrame:GetChildren() do
		for _, purchaseButton in buttonDisplay:GetChildren() do
			if not purchaseButton.Name:match "Purchase" then
				if purchaseButton.Name:match "Use" then
					purchaseButton.Activated:Connect(function()
						playSoundEffect "UIButton"
						local boostDuration = purchaseButton.Name:match "(%d*%.?%d+)"
						if
							not selectors.getBoostCount(
								store:getState(),
								player.Name,
								buttonDisplay.Name .. boostDuration
							)
						then
							return
						end
						Remotes.Client:Get("UseBoost"):SendToServer(buttonDisplay.Name .. boostDuration)
					end)
				end
				continue
			end
			local boostIDInstance =
				boostProductIDs:FindFirstChild(buttonDisplay.Name .. purchaseButton.Name:match "(%d*%.?%d+)")

			purchaseButton.Activated:Connect(function()
				playSoundEffect "UIButton"
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

interfaces[RobuxShop] = true

return RobuxShop
