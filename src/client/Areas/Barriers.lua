local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local teleportPlayer = require(StarterPlayer.StarterPlayerScripts.Client.Areas.TeleportPlayer)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local debounce = false
local player = Players.LocalPlayer
local areaRequirements = ReplicatedStorage.Config.AreaRequirements

local teleporters = {}
local originalTransparencies = {}

local function unlockArea(areaName: string, lock: boolean?)
	for _, barrier in CollectionService:GetTagged(areaName .. "Barrier") do
		local barrierUI = barrier:FindFirstChild "BarrierLockDisplay"

		if not originalTransparencies[barrier] then
			originalTransparencies[barrier] = barrier.Transparency
		end

		barrier.CanCollide = if lock then true else false
		barrier.Transparency = if lock then originalTransparencies[barrier] else 1

		if barrierUI then
			barrierUI.Enabled = if lock then true else false
		end
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
		local target = teleporters[teleporter.Name:gsub("%d", opposite)]
		local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)

		if not hitPlayer or hitPlayer ~= player or not target then
			return
		end

		if selectors.getStat(store:getState(), player.Name, "Strength") < strengthRequirement then
			return
		end

		if debounce then
			return
		end
		debounce = true

		teleportPlayer(player, { target = target })

		petUtils.instantiatePets(player.Name, selectors.getEquippedPets(store:getState(), player.Name))

		task.wait(1)
		debounce = false
	end)
end

playerStatePromise:andThen(function()
	unlockAreas()
	store.changed:connect(function(newState, oldState)
		if
			selectors.isPlayerLoaded(oldState, player.Name)
			and selectors.getStat(newState, player.Name, "Strength")
				== selectors.getStat(oldState, player.Name, "Strength")
		then
			return
		end
		unlockAreas()
	end)
end)

CollectionService:GetInstanceAddedSignal("TP"):Connect(handleTeleporter)
for _, teleporter in CollectionService:GetTagged "TP" do
	handleTeleporter(teleporter)
end

return 0
