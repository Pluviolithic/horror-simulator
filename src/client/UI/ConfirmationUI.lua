local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local destructor = Janitor.new()

return function(confirmationUI, message, callback)
	interfaces[destructor] = true
	destructor:Cleanup()
	confirmationUI.Visible = true

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
