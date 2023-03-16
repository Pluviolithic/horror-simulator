local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local PlayerGui = Players.LocalPlayer:WaitForChild "PlayerGui"
local confirmationUI = PlayerGui:WaitForChild("Teleport").Confirmation
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

--TODO: Set up to be a promise so don't have to yield for player gui
--TODO: components to be loaded in.
return function(context, callback)
	local destructor = Janitor.new()
	confirmationUI.Visible = true
	confirmationUI.WarningText.Text =
		string.format("Unlock the %s teleport for %s Gems?", context.AreaName, context.Cost)

	destructor:Add(
		confirmationUI.GreenButton.Activated:Connect(function()
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

	return destructor
end
