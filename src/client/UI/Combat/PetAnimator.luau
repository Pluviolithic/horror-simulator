local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local player = Players.LocalPlayer

Promise.new(function(resolve)
	local petsFolder = workspace:WaitForChild "PetModels"
	resolve(petsFolder:WaitForChild(player.Name))
end):andThen(function(petsModel)
	RunService.RenderStepped:Connect(function()
		local rootPart = player.Character and player.Character:FindFirstChild "HumanoidRootPart"
		if not rootPart then
			return
		end

		local numPets = #petsModel:GetChildren()
		for i, petModel in ipairs(petsModel:GetChildren()) do
			local position, look = petUtils.calculatePosition(rootPart, numPets, i)

			petModel.PrimaryPart.BodyPosition.Position = position
			petModel.PrimaryPart.BodyGyro.CFrame = CFrame.lookAt(Vector3.new(), look * Vector3.new(1, 0, 1))
		end
	end)
	player.CharacterAdded:Connect(function()
		if not selectors.isPlayerLoaded(store:getState(), player.Name) then
			return
		end
		petUtils.instantiatePets(player, selectors.getEquippedPets(store:getState(), player.Name))
	end)
end)

return 0
