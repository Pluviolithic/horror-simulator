local Players = game:GetService "Players"

local function fixNoob(player)
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end

	local torso = player.Character:FindFirstChild "Torso"
	if torso and torso.Color3 == Color3.fromRGB(13, 105, 172) then
		player.Character.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(player.UserId))
	end
end

Players.PlayerAdded:Connect(fixNoob)
for _, player in Players:GetPlayers() do
	fixNoob(player)
end

return 0
