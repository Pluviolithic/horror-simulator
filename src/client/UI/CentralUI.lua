local CentralUI = {}
CentralUI.__index = CentralUI

function CentralUI.new(UI)
	local self = setmetatable({}, CentralUI)
	local exit = UI:FindFirstChild("Close", true)

	self._ui = UI
	self._visibilityProperty = if UI:IsA "ScreenGui" then "Enabled" else "Visible"

	if exit then
		exit.Activated:Connect(function()
			self:setEnabled(false)
		end)
	end

	return self
end

function CentralUI:setEnabled(enable)
	self._ui[self._visibilityProperty] = enable
end

return CentralUI
