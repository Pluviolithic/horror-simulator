local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local PlayerGui = Players.LocalPlayer:WaitForChild "PlayerGui"
local confirmationUI = PlayerGui.PetInventory.Confirmation
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

local contextMessages = {
	EquipBest = "Are you sure you want to Equip Your Best Pet?",
	EvolveAll = "Are you sure you want to Evolve All Pets?",
	DeleteAll = "Delete All Pets? Make sure all the pets you want to keep are Locked",
}

return function(context, callback)
	local destructor = Janitor.new()
	confirmationUI.Visible = true
	confirmationUI.WarningText.Text = contextMessages[context]

	destructor:Add(
		confirmationUI.Green.Activated:Connect(function()
			confirmationUI.Visible = false
			destructor:Cleanup()
			callback()
		end),
		"Disconnect"
	)

	return destructor
end
