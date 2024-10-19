local Players = game:GetService "Players"
local UserInputService = game:GetService "UserInputService"

if not UserInputService.TouchEnabled then
	return 0
end

task.spawn(function()
	local player = Players.LocalPlayer
	local mainUI = player.PlayerGui:WaitForChild "MainUI"

	mainUI.Gifts.Size = UDim2.fromScale(0.112, 0.059)
	mainUI.Gifts.Position = UDim2.fromScale(0.888, 0.391)
	mainUI.Invite.Position = UDim2.fromScale(0.905, 0.46)
	mainUI.Codes.Position = UDim2.fromScale(0.952, 0.459)
	mainUI.Rebirth.Position = UDim2.fromScale(0.905, 0.548)
	mainUI.Settings.Position = UDim2.fromScale(0.952, 0.549)
	mainUI.AFK.Position = UDim2.fromScale(0.006, 0.699)
	mainUI.Teleport.Position = UDim2.fromScale(0.052, 0.698)

	player.PlayerGui:WaitForChild("ScreenEffects").Unlocks.AFK.Position = UDim2.fromScale(0.348, 0.339)
end)

return 0
