local Players = game:GetService "Players"

local registeredListeners = {}

local function disableCharacterCollisions(character: Model)
	for _, part in character:GetDescendants() do
		if part:IsA "BasePart" then
			part.CollisionGroup = "PlayerCharacters"
		end
	end
end

local function disablePlayerCollisions(player: Player)
	if registeredListeners[player.UserId] then
		return
	end
	registeredListeners[player.UserId] = true
	if player.Character and player:HasAppearanceLoaded() then
		disableCharacterCollisions(player.Character)
	end
	player.CharacterAppearanceLoaded:Connect(disableCharacterCollisions)
end

Players.PlayerAdded:Connect(disablePlayerCollisions)
Players.PlayerRemoving:Connect(function(player)
	registeredListeners[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	disablePlayerCollisions(player)
end

return 0
