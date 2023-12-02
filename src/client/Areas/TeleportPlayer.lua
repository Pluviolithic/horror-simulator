local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary

local defaultTeleportData = {
	verticalOffset = 5,
	horizontalOffset = 5,
}

return function(player, teleportData)
	teleportData = Dict.merge(defaultTeleportData, teleportData)
	player.Character:PivotTo(
		CFrame.fromMatrix(
			teleportData.target.Position
				+ teleportData.target.CFrame.LookVector * teleportData.horizontalOffset
				+ teleportData.target.CFrame.UpVector * teleportData.verticalOffset,
			teleportData.target.CFrame.RightVector,
			teleportData.target.CFrame.UpVector
		)
	)
end
