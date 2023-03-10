local ReplicatedStorage = game:GetService "ReplicatedStorage"

local petUtils
petUtils = {
	getPet = function(petName: string): Instance?
		local pets = if petName:match "Evolved" then ReplicatedStorage.EvolvedPets else ReplicatedStorage.Pets
		for _, area in pets:GetChildren() do
			local pet = area:FindFirstChild(petName)
			if pet then
				return pet
			end
		end
		return nil
	end,
	getBestPetNames = function(ownedPets, n): { string }
		local sortedPets = {}
		local bestPets = {}

		for petName, quantity in ownedPets do
			local pet = petUtils.getPet(petName)
			for _ = 1, quantity do
				table.insert(sortedPets, pet)
			end
		end

		table.sort(sortedPets, function(a, b)
			return a.Multiplier.Value > b.Multiplier.Value
		end)

		for i = 1, n do
			table.insert(bestPets, sortedPets[i].Name)
		end

		return bestPets
	end,
}

return petUtils
