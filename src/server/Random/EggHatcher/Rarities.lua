local ReplicatedStorage = game:GetService "ReplicatedStorage"
local rarities: { [string]: { [string]: { [string]: number | string } } } = {}

for _, area in ReplicatedStorage.Pets:GetChildren() do
	rarities[area.Name] = {}
	for _, pet in area:GetChildren() do
		rarities[area.Name][pet.Name] = {
			Rarity = pet.Rarity.Value,
			RarityName = pet.RarityName.Value,
		}
	end
end

return rarities
