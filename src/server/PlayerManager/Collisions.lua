local Players = game:GetService "Players"
local PhysicsService = game:GetService "PhysicsService"

local function disableCharacterCollisions(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA "BasePart" then
			PhysicsService:SetPartCollisionGroup(part, "PlayerCharacters")
		end
	end
end

local function disablePlayerCollisions(player)
	player.CharacterAdded:Connect(disableCharacterCollisions)
end

Players.PlayerAdded:Connect(disablePlayerCollisions)

for _, player in ipairs(Players:GetPlayers()) do
	disablePlayerCollisions(player)
	if player.Character then
		disableCharacterCollisions(player.Character)
	end
end

return 0
