local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)

local petConfig = ReplicatedStorage.Config.Pets
local modelYOffset = petConfig.VerticalOffset.Value
local leaderboardPetName = ReplicatedStorage.Config.Misc.LeaderboardPet.Value

local baseBodyPosition = Instance.new "BodyPosition"
local baseBodyGyro = Instance.new "BodyGyro"

baseBodyPosition.D = petConfig.Dampening.Value
baseBodyPosition.P = petConfig.Aggressiveness.Value
baseBodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

baseBodyGyro.D = petConfig.Dampening.Value
baseBodyGyro.P = petConfig.Aggressiveness.Value
baseBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

local function calculatePosition(rootPart, numPets, i)
	local petAngle = math.rad(180 / (numPets + 1))
	local petRadius = 4

	local bobOffset = Vector3.new(0, math.sin(tick() * 5) * 0.3, 0)
	local petOffset = Vector3.new(math.cos(petAngle * i) * petRadius, modelYOffset, math.sin(petAngle * i) * petRadius)
	local petCFrame = rootPart.CFrame * CFrame.new(petOffset + bobOffset)
	local lookVector = (rootPart.Position - petCFrame.Position).Unit

	return petCFrame.Position, lookVector
end

local petUtils
petUtils = {
	getPet = function(petName: string): Instance?
		local pets
		if petName:match "Evolved" then
			pets = ReplicatedStorage.EvolvedPets
		elseif petName:match "Shiny" or petName == leaderboardPetName then
			pets = ReplicatedStorage.ShinyPets
		else
			pets = ReplicatedStorage.Pets
		end
		for _, area in pets:GetChildren() do
			local pet = area:FindFirstChild(petName)
			if pet then
				return pet
			end
		end
		return nil
	end,
	getEquippedPetsMultiplier = function(equippedPets): (number, number)
		local multiplier = 0
		local multiplierWholePartCount = 0
		for petName, quantity in equippedPets do
			local pet = petUtils.getPet(petName)
			multiplier += pet.Multiplier.Value * quantity
			if pet.Multiplier.Value > 1 then
				multiplierWholePartCount += quantity
			end
		end
		return multiplier, multiplierWholePartCount
	end,
	countPetsInDict = function(dict): number
		local counter = 0
		for _, quantity in dict do
			counter += quantity
		end
		return counter
	end,
	getPetRarities = function(petNames: { string }): { string }
		local rarities = {}
		for _, petName in petNames do
			table.insert(rarities, ReplicatedStorage.Pets:FindFirstChild(petName, true).RarityName.Value)
		end
		return rarities
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

		for i = 1, math.min(n, #sortedPets) do
			table.insert(bestPets, sortedPets[i].Name)
		end

		return bestPets
	end,
	instantiatePets = function(playerName, equippedPets)
		local isServer = RunService:IsServer()
		local petsModel = workspace.PetModels:FindFirstChild(playerName)
		if not petsModel then
			if not isServer then
				return
			end
			petsModel = Instance.new "Model"
			petsModel.Name = playerName
			petsModel.Parent = workspace.PetModels

			local janitor = Janitor.new()
			janitor:Add(petsModel, "Destroy")
			janitor:LinkToInstance(Players[playerName])
		end

		task.spawn(function()
			local character = Players[playerName].Character or Players[playerName].CharacterAdded:Wait()
			local rootPart = character:WaitForChild "HumanoidRootPart"
			local equippedPetModels = petsModel:GetChildren()
			for petName, quantity in equippedPets do
				for i = 1, quantity do
					local position, look = calculatePosition(rootPart, quantity, i)
					local newPetIndex = nil
					local newPet = nil

					for index, pet in equippedPetModels do
						if pet.Name == petName then
							newPetIndex = index
						end
					end

					if newPetIndex then
						newPet = table.remove(equippedPetModels, newPetIndex)
					elseif isServer then
						newPet = petUtils.getPet(petName):Clone()
						baseBodyGyro:Clone().Parent = newPet.PrimaryPart
						baseBodyPosition:Clone().Parent = newPet.PrimaryPart
					else
						continue
					end
					newPet.PrimaryPart.BodyGyro.CFrame = CFrame.lookAt(position, look * Vector3.new(1, 0, 1))
					newPet.PrimaryPart.BodyPosition.Position = position
					newPet:SetPrimaryPartCFrame(CFrame.lookAt(position, look * Vector3.new(1, 0, 1)))
					newPet.Parent = petsModel

					if isServer then
						newPet:FindFirstChildWhichIsA("BasePart"):SetNetworkOwner(Players[playerName])
					end
				end
			end
			for _, petModel in equippedPetModels do
				petModel:Destroy()
			end
		end)
	end,
	calculatePosition = calculatePosition,
}

return petUtils
