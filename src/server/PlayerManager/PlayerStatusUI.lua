local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local PlayerStatusUI = {}
PlayerStatusUI.__index = PlayerStatusUI

local store = require(ServerScriptService.Server.State.Store)
--local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)
local playerUITemplate = ReplicatedStorage.PlayerUI:Clone()
local selectors = require(ReplicatedStorage.Common.State.selectors)

function PlayerStatusUI.new(player: Player)
	local self = setmetatable({}, PlayerStatusUI)

	self._player = player
	self._playerUI = playerUITemplate:Clone()

	return setmetatable({
		_listener = nil,
		_healthBar = nil,
		_activePlayerUI = nil,
		_player = player,
		_playerUI = playerUITemplate:Clone(),
	}, PlayerStatusUI)
end

function PlayerStatusUI:_updateUIFields(state)
	if not selectors.isPlayerLoaded(state, self._player.Name) then
		return
	end
	local playerUIFrame = self._activePlayerUI.Frame

	playerUIFrame.PlayerName.Text = self._player.DisplayName
	playerUIFrame.Rank.Text = "Rank " .. selectors.getStat(state, self._player.Name, "Rank")
	playerUIFrame.Scared.Visible = selectors.getStat(state, self._player.Name, "CurrentFearMeter")
		== selectors.getStat(state, self._player.Name, "MaxFearMeter")

	if
		selectors.hasGamepass(state, self._player.Name, "VIP")
		and selectors.getSetting(state, self._player.Name, "VipNameTag")
	then
		playerUIFrame.PlayerName.TextColor3 = Color3.fromRGB(255, 193, 7)
	else
		playerUIFrame.PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	if
		selectors.hasGamepass(state, self._player.Name, "VIP")
		and selectors.getSetting(state, self._player.Name, "VipChatTag")
	then
		self._player:SetAttribute("isVIP", true)
	else
		self._player:SetAttribute("isVIP", false)
	end
end

function PlayerStatusUI:_applyUI(character: Model)
	if self._activePlayerUI then
		self._activePlayerUI:Destroy()
		self._listener:disconnect()
	end
	self._activePlayerUI = self._playerUI:Clone()

	self:_updateUIFields(store:getState())
	self._listener = store.changed:connect(function(newState)
		self:_updateUIFields(newState)
	end)

	self._activePlayerUI.Parent = character:WaitForChild "Head"
end

function PlayerStatusUI:enable()
	local character = self._player.Character
	if character then
		self:_applyUI(character)
	end
	self._player.CharacterAppearanceLoaded:Connect(function(newCharacter)
		self:_applyUI(newCharacter)
	end)
end

return PlayerStatusUI
