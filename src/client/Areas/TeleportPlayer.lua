local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local player = Players.LocalPlayer
local transitionsUI = player.PlayerGui:WaitForChild "Transitions"

local defaultTeleportData = {
	verticalOffset = 5,
	horizontalOffset = 5,
	target = workspace.Teleports["Clown TownTP"],
}

return function(teleportData)
	teleportData = Dict.merge(defaultTeleportData, teleportData)

	local locationName = regionUtils.getLocationNameForPoint(teleportData.target.Position)

	transitionsUI[locationName].Visible = true
	transitionsUI[locationName]:TweenPosition(
		UDim2.fromScale(0, 0),
		Enum.EasingDirection.In,
		Enum.EasingStyle.Sine,
		0.3,
		true,
		function()
			player.Character:PivotTo(
				CFrame.fromMatrix(
					teleportData.target.Position
						+ teleportData.target.CFrame.LookVector * teleportData.horizontalOffset
						+ teleportData.target.CFrame.UpVector * teleportData.verticalOffset,
					teleportData.target.CFrame.RightVector,
					teleportData.target.CFrame.UpVector
				)
			)
			task.wait(1)
			transitionsUI[locationName]:TweenPosition(
				UDim2.fromScale(1, 0),
				Enum.EasingDirection.In,
				Enum.EasingStyle.Sine,
				0.3,
				true,
				function()
					transitionsUI[locationName].Visible = false
					transitionsUI[locationName].Position = UDim2.fromScale(-1, 0)
				end
			)
		end
	)
end
