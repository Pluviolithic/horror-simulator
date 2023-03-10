local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local PlayerGui = Players.LocalPlayer:WaitForChild "PlayerGui"
local confirmationUI = PlayerGui:WaitForChild("PetInventory").Confirmation
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

local contextMessages = {
	UnequipAll = "Are you sure you want to Unequip All Pets?",
	EquipBest = "Are you sure you want to Equip Your Best Pet?",
	EvolveAll = "Are you sure you want to Evolve All Pets?",
	DeleteAll = "Delete All Pets? Make sure all the pets you want to keep are Locked",
}

--TODO: Set up to be a promise so don't have to yield for player gui
--TODO: components to be loaded in.
return function(context, callback)
	local destructor = Janitor.new()
	confirmationUI.Visible = true
	confirmationUI.WarningText.Text = contextMessages[context]

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
