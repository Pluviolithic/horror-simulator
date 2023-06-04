local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)

local player = Players.LocalPlayer
local areaRequirements = ReplicatedStorage.Config.AreaRequirements

local teleporters = {}
local debounce = false

local function unlockArea(areaName: string, lock: boolean?)
	for _, barrier in CollectionService:GetTagged(areaName .. "Barrier") do
		barrier.CanCollide = if lock then true else false
	end
end

local function unlockAreas()
	for _, requirement in areaRequirements:GetChildren() do
		if requirement.Value > selectors.getStat(store:getState(), player.Name, "Strength") then
			unlockArea(requirement.Name, true)
		else
			unlockArea(requirement.Name)
		end
	end
end

local function handleTeleporter(teleporter)
	teleporters[teleporter.Name] = teleporter
	local opposite = if teleporter.Name:match "1" then "2" else "1"
	local strengthRequirement = areaRequirements[teleporter.Name:sub(1, -4)].Value

	teleporter.Touched:Connect(function(hit)
		local goal = teleporters[teleporter.Name:gsub("%d", opposite)]
		local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)

		if not hitPlayer or hitPlayer ~= player or not goal then
			return
		end

		if selectors.getStat(store:getState(), player.Name, "Strength") < strengthRequirement then
			return
		end

		if debounce then
			return
		end
		debounce = true

		player.Character:PivotTo(
			CFrame.fromMatrix(
				goal.Position + goal.CFrame.LookVector * 5 + goal.CFrame.UpVector * 5,
				goal.CFrame.RightVector,
				goal.CFrame.UpVector
			)
		)

		petUtils.instantiatePets(player.Name, selectors.getEquippedPets(store:getState(), player.Name))

		task.wait(1)
		debounce = false
	end)
end

playerStatePromise:andThen(function()
	unlockAreas()
	store.changed:connect(function(newState, oldState)
		if
			selectors.getStat(newState, player.Name, "Strength") == selectors.getStat(oldState, player.Name, "Strength")
		then
			return
		end
		unlockAreas()
	end)
end)

CollectionService:GetInstanceAddedSignal("TP"):Connect(handleTeleporter)
for _, teleporter in pairs(CollectionService:GetTagged "TP") do
	handleTeleporter(teleporter)
end

return 0
