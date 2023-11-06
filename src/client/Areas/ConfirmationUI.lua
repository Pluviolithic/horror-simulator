local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local PlayerGui = Players.LocalPlayer:WaitForChild "PlayerGui"
local confirmationUI = PlayerGui:WaitForChild("Teleport").Confirmation
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

--TODO: Set up to be a promise so don't have to yield for player gui
--TODO: components to be loaded in.
return function(context, callback)
	local destructor = Janitor.new()
	confirmationUI.Visible = true
	confirmationUI.WarningText.Text = string.format(
		'Unlock the %s teleport for <font color= "rgb(224, 18, 231)">%s Gems</font>?',
		context.AreaName,
		formatter.formatNumberWithSuffix(context.Cost)
	)

	destructor:Add(
		confirmationUI.Purchase.Activated:Connect(function()
			confirmationUI.Visible = false
			destructor:Destroy()
			callback()
		end),
		"Disconnect"
	)

	destructor:Add(
		confirmationUI.Close.Activated:Connect(function()
			confirmationUI.Visible = false
			destructor:Destroy()
		end),
		"Disconnect"
	)

	return destructor
end
