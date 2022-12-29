local ReplicatedStorage = game:GetService "ReplicatedStorage"
local rarities: { [string]: { [string]: { [string]: number | string } | number } } = {}

for _, area in ReplicatedStorage.Pets:GetChildren() do
	rarities[area.Name] = {
		Sum = 0,
	}
	for _, pet in area:GetChildren() do
		rarities[area.Name][pet.Name] = {
			Rarity = pet.Rarity.Value,
			RarityName = pet.RarityName.Value,
		}
	end
end

return rarities
