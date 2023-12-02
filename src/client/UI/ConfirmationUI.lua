local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

return function(confirmationUI, message, callback)
	local destructor = Janitor.new()
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

	return destructor
end
