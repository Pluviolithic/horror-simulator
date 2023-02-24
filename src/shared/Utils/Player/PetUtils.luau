local ReplicatedStorage = game:GetService "ReplicatedStorage"

return {
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
}
