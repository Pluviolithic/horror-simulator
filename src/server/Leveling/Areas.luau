local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)

local areaRequirements = ReplicatedStorage.Config.AreaRequirements

local teleporters = {}
local playerDebounces = {}

local function handleTeleporter(teleporter)
	teleporters[teleporter.Name] = teleporter
	local opposite = if teleporter.Name:match "1" then "2" else "1"
	local strengthRequirement = areaRequirements[teleporter.Name:sub(1, -4)].Value

	teleporter.Touched:Connect(function(hit)
		local goal = teleporters[teleporter.Name:gsub("%d", opposite)]
		local player = Players:GetPlayerFromCharacter(hit.Parent)

		if not player or playerDebounces[player] or not goal then
			return
		end

		playerDebounces[player] = true
		task.delay(1, function()
			playerDebounces[player] = nil
		end)

		if store:getState().Players[player.Name].Strength < strengthRequirement then
			return
		end

		player.Character:PivotTo(
			CFrame.fromMatrix(
				goal.Position + goal.CFrame.LookVector * 5 + goal.CFrame.UpVector * 5,
				goal.CFrame.RightVector,
				goal.CFrame.UpVector
			)
		)
	end)
end

CollectionService:GetInstanceAddedSignal("TP"):Connect(handleTeleporter)
for _, teleporter in pairs(CollectionService:GetTagged "TP") do
	handleTeleporter(teleporter)
end

return 0
