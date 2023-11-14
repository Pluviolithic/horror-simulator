local Players = game:GetService "Players"

local function disableCharacterCollisions(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA "BasePart" then
			part.CollisionGroup = "PlayerCharacters"
		end
	end
end

local function disablePlayerCollisions(player: Player)
	player.CharacterAdded:Connect(disableCharacterCollisions)
	player.CharacterAppearanceLoaded:Wait()
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(disablePlayerCollisions)

for _, player in Players:GetPlayers() do
	disablePlayerCollisions(player)
	if player.Character then
		disableCharacterCollisions(player.Character)
	end
end

return 0
