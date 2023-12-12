local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local CentralUI = {}
CentralUI.__index = CentralUI

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)
local collidableInterfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

function CentralUI.new(UI: GuiObject)
	local self = setmetatable({}, CentralUI)
	local exit = UI:FindFirstChild("Close", true)

	self._ui = UI
	self._isOpen = false
	self._eventConnections = {}
	self._visibilityProperty = if UI:IsA "ScreenGui" then "Enabled" else "Visible"

	if exit then
		exit.Activated:Connect(function()
			playSoundEffect "UIButton"
			self:setEnabled(false)
		end)
	end

	return self
end

function CentralUI:setEnabled(enable: boolean?): ()
	self._ui[self._visibilityProperty] = enable
	self._isOpen = enable

	if not enable then
		if self.OnClose then
			self:OnClose()
		end
		return
	end

	-- may change the blanket closure to be more nuanced in future
	for interface in collidableInterfaces do
		if interface ~= self then
			if Janitor.Is(interface) then
				interface:Cleanup()
				continue
			end
			interface:setEnabled(false)
		end
	end

	if self.OnOpen then
		self:OnOpen()
	end
end

return CentralUI
