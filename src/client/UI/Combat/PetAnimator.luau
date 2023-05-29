local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)

local player = Players.LocalPlayer

Promise.new(function(resolve)
	local petsFolder = workspace:WaitForChild "PetModels"
	if petsFolder:FindFirstChild(player.Name) then
		resolve(petsFolder[player.Name])
	else
		local connection
		connection = petsFolder.ChildAdded:Connect(function(newChild)
			if newChild.Name == player.Name then
				connection:Disconnect()
				resolve(newChild)
			end
		end)
	end
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
end)

return 0
