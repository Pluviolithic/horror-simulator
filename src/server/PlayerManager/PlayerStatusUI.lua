local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local PlayerStatusUI = {}
PlayerStatusUI.__index = PlayerStatusUI

local store = require(ServerScriptService.Server.State.Store)
local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)
local playerUITemplate = ReplicatedStorage.PlayerUI:Clone()

function PlayerStatusUI.new(player)
	local self = setmetatable({}, PlayerStatusUI)

	self._player = player
	self._playerUI = playerUITemplate:Clone()

	return self
end

function PlayerStatusUI:_updateUIFields(state)
	local playerState = state.Players[self._player.Name]
	local playerUIFrame = self._activePlayerUI.Frame

	playerUIFrame.PlayerName.Text = self._player.Name
	playerUIFrame.Rank.Text = "Rank " .. playerState.Rank

	local humanoid = self._player.Character and self._player.Character:FindFirstChildWhichIsA "Humanoid"

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

function PlayerStatusUI:_applyUI(character)
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
	local character = self._player.Character
	if character then
		self:_applyUI(character)
	end
	self._player.CharacterAppearanceLoaded:Connect(function(newCharacter)
		self:_applyUI(newCharacter)
	end)
end

return PlayerStatusUI
