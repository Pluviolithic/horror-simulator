local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.ConfirmationUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer
local mainUI = player.PlayerGui:WaitForChild "MainUI"
local exchangeRate = ReplicatedStorage.Config.Rebirth.Exchange.Value
local RebirthUI = CentralUI.new(player.PlayerGui:WaitForChild "Rebirth")
local doubleTokensID = ReplicatedStorage.Config.GamepassData.IDs["2xTokens"].Value

local function shouldRefresh(newState, oldState)
	return selectors.getPurchaseData(newState, player.Name) ~= selectors.getPurchaseData(oldState, player.Name)
		or selectors.getStat(newState, player.Name, "Strength")
			~= selectors.getStat(oldState, player.Name, "Strength")
end

function RebirthUI:_initialize()
	mainUI.Rebirth.Activated:Connect(function()
		playSoundEffect "UIButton"
		if not rankUtils.hasBestAreaUnlocked(selectors.getStat(store:getState(), player.Name, "Strength")) then
			PopupUI(`Unlock {rankUtils.getBestAreaName()} First To Rebirth!`)
			return
		end
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Background.Passes["2xTokens"].Activated:Connect(function()
		playSoundEffect "UIButton"
		MarketplaceService:PromptGamePassPurchase(player, doubleTokensID)
	end)

	DescriptionUI(self._ui.Background.Passes["2xTokens"], self._ui.Background.Passes["2xTokens"].Frame)

	self._ui.Background.Confirm.Activated:Connect(function()
		playSoundEffect "UIButton"
		self._ui.Background.Visible = false
		self._ui.Close.Visible = false
		confirmationUI(self._ui.Confirmation, "", function()
			Remotes.Client:Get("Rebirth"):SendToServer()
			self:setEnabled(false)
			self._ui.Background.Visible = true
			self._ui.Close.Visible = true
		end, self):Add(self._ui.Confirmation.Close.Activated:Connect(function()
			self._ui.Background.Visible = true
			self._ui.Close.Visible = true
		end))
	end)

	playerStatePromise:andThen(function()
		self:Refresh()
		store.changed:connect(function(newState, oldState)
			if shouldRefresh(newState, oldState) then
				self:Refresh()
			end
		end)
	end)
end

function RebirthUI:OnClose()
	self._ui.Background.Visible = true
	self._ui.Close.Visible = true
end

function RebirthUI:Refresh()
	local tokenMultiplier = 1
	local rebirths = math.floor(selectors.getStat(store:getState(), player.Name, "Strength") / exchangeRate)
	if selectors.hasGamepass(store:getState(), player.Name, "2xTokens") then
		tokenMultiplier = 2
		self._ui.Background.Passes["2xTokens"].Visible = false
	else
		self._ui.Background.Passes["2xTokens"].Visible = true
	end
	self._ui.Background.Tokens.Text = `{formatter.formatNumberWithSuffix(rebirths * tokenMultiplier)} Rebirth Tokens`
	self._ui.Background.Strength.Text = `{formatter.formatNumberWithCommas(1 + 0.1 * rebirths)}x Strength`
end

task.spawn(RebirthUI._initialize, RebirthUI)

interfaces[RebirthUI] = true

return RebirthUI
