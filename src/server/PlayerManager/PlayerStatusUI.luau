local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local PlayerStatusUI = {}
PlayerStatusUI.__index = PlayerStatusUI

local store = require(ServerScriptService.Server.State.Store)
local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local playerUITemplate = ReplicatedStorage.PlayerUI:Clone()

type PlayerStatusUI = typeof(setmetatable(
	{} :: {
		_player: Player,
		_playerUI: GuiObject,
		_activePlayerUI: GuiObject,
		_listener: RBXScriptConnection,
		_healthBar: HealthBar.HealthBar,
	},
	PlayerStatusUI
))

function PlayerStatusUI.new(player: Player): PlayerStatusUI
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
	local playerState = state.Players[self._player.Name]
	if not playerState or not next(playerState) then
		return
	end
	local playerUIFrame = self._activePlayerUI.Frame

	playerUIFrame.PlayerName.Text = self._player.Name
	playerUIFrame.Rank.Text = "Rank " .. playerState.Rank

	local humanoid: Humanoid = self._player.Character and self._player.Character:FindFirstChildWhichIsA "Humanoid"

	if not humanoid then
		return
	end

	local healthDisplay = self._activePlayerUI.Health
	if playerState.CurrentEnemy then
		healthDisplay.Visible = true
	else
		healthDisplay.Visible = false
	end
end

function PlayerStatusUI:_applyUI(character: Model)
	if self._activePlayerUI then
		self._activePlayerUI:Destroy()
		self._listener:disconnect()
	end
	self._activePlayerUI = self._playerUI:Clone()
	self._healthBar = HealthBar.new(self._activePlayerUI.Health.Frame)

	task.spawn(function()
		self._healthBar:connect(character:WaitForChild "Humanoid")
	end)

	self:_updateUIFields(store:getState())
	self._listener = store.changed:connect(function(newState)
		self:_updateUIFields(newState)
	end)

	self._activePlayerUI.Parent = character:WaitForChild "Head"
end

function PlayerStatusUI:enable()
	local character: Model = self._player.Character
	if character then
		self:_applyUI(character)
	end
	self._player.CharacterAppearanceLoaded:Connect(function(newCharacter)
		self:_applyUI(newCharacter)
	end)
end

return PlayerStatusUI
