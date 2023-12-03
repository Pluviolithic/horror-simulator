local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local destructor = Janitor.new()
local currentConfirmationUI

return function(confirmationUI, message, callback, interfaceToSkip)
	for interface in interfaces do
		if interface == interfaceToSkip then
			continue
		end
		if Janitor.Is(interface) then
			interface:Cleanup()
			continue
		end
		interface:setEnabled(false)
	end

	if currentConfirmationUI == confirmationUI then
		currentConfirmationUI = nil
		return
	end

	interfaces[destructor] = true
	confirmationUI.Visible = true
	currentConfirmationUI = confirmationUI

	if #message > 0 then
		confirmationUI.WarningText.Text = message
	end

	destructor:Add(
		confirmationUI.Confirm.Activated:Connect(function()
			confirmationUI.Visible = false
			destructor:Cleanup()
			callback()
		end),
		"Disconnect"
	)

	destructor:Add(
		confirmationUI.Close.Activated:Connect(function()
			confirmationUI.Visible = false
			destructor:Cleanup()
		end),
		"Disconnect"
	)

	local cancel = confirmationUI:FindFirstChild "Cancel"
	if cancel then
		destructor:Add(
			confirmationUI.Cancel.Activated:Connect(function()
				confirmationUI.Visible = false
				destructor:Cleanup()
			end),
			"Disconnect"
		)
	end

	destructor:Add(function()
		confirmationUI.Visible = false
	end, true)

	return destructor
end
