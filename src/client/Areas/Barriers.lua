local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local teleportPlayer = require(StarterPlayer.StarterPlayerScripts.Client.Areas.TeleportPlayer)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local debounce = false
local player = Players.LocalPlayer
local AFKUnlockUI = player.PlayerGui:WaitForChild("ScreenEffects").Unlocks.AFK
local areaRequirements = ReplicatedStorage.Config.AreaRequirements

local teleporters = {}
local unlockedAreas = {}
local originalTransparencies = {}

local AFKUnlockUIOnTween = TweenService:Create(
	AFKUnlockUI,
	TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{ TextTransparency = 0 }
)
local AFKUnlockUIOffTween = TweenService:Create(
	AFKUnlockUI,
	TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{ TextTransparency = 1 }
)

AFKUnlockUIOnTween.Completed:Connect(function()
	task.wait(6)
	AFKUnlockUIOffTween:Play()
end)

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

local function unlockAreas(oldWasLoaded)
	for _, requirement in areaRequirements:GetChildren() do
		if requirement.Value > selectors.getStat(store:getState(), player.Name, "Strength") then
			unlockArea(requirement.Name, true)
		else
			unlockArea(requirement.Name)
			if not unlockedAreas[requirement.Name] then
				unlockedAreas[requirement.Name] = true

				if oldWasLoaded then
					PopupUI("New Area Unlocked!", Color3.fromRGB(250, 250, 250))
				end

				if workspace.Beams:FindFirstChild(requirement.Name) and oldWasLoaded then
					workspace.Beams[requirement.Name].Beam.Attachment1 =
						player.Character.HumanoidRootPart.RootAttachment
				end

				if requirement.Name == "Howling Woods" and oldWasLoaded then
					AFKUnlockUIOnTween:Play()
				end
			end
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

		teleportPlayer { target = target }

		for _, beam in workspace.Beams:GetChildren() do
			if beam.Name == teleporter.Name:sub(1, -4) and beam.Beam.Attachment1 then
				beam.Beam.Attachment1 = nil
			end
		end

		petUtils.instantiatePets(player.Name, selectors.getEquippedPets(store:getState(), player.Name))

		task.wait(1)
		debounce = false
	end)
end

playerStatePromise:andThen(function()
	unlockAreas(false)
	store.changed:connect(function(newState, oldState)
		if
			selectors.isPlayerLoaded(oldState, player.Name)
			and selectors.getStat(newState, player.Name, "Strength")
				== selectors.getStat(oldState, player.Name, "Strength")
		then
			return
		end
		unlockAreas(selectors.isPlayerLoaded(oldState, player.Name))
	end)
end)

CollectionService:GetInstanceAddedSignal("TP"):Connect(handleTeleporter)
for _, teleporter in CollectionService:GetTagged "TP" do
	handleTeleporter(teleporter)
end

return 0
