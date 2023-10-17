local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local store = require(Client.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local playerStatePromise = require(Client.State.PlayerStatePromise)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local missionRequirements = ReplicatedStorage.Missions

local progressTextFormats = {
	Enemy = "Defeat {enemy} {progress}",
	Weapon = "Buy a Weapon",
	AnyPet = "Hatch Any Pet in {area} {progress}",
	PetRarity = "Hatch {rarity} Pet in {area} {progress}",
}

local function enteredRegion(regionName, progressUI)
	local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[regionName]
	local currentMissionRequirements =
		missionRequirements[regionName][tostring(currentMissionData.CurrentMissionNumber)]

	if currentMissionData.Active then
		local progressText
		for missionType, text in progressTextFormats do
			progressText = if currentMissionRequirements:FindFirstChild(missionType) then text else progressText
		end

		progressUI.Background.MissionName.Text = currentMissionRequirements.MissionName.Value

		if currentMissionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
			progressUI.Background.Progress.Visible = false
			progressUI.Background.Complete.Visible = true
			progressUI.Enabled = true
			return
		end

		progressUI.Background.Complete.Visible = false
		progressUI.Background.Progress.Visible = true

		if progressText == progressTextFormats.Enemy then
			progressText = progressText:gsub("{enemy}", currentMissionRequirements.Enemy.Value)
		elseif progressText == progressTextFormats.PetRarity then
			progressText = progressText:gsub("{rarity}", currentMissionRequirements.PetRarity.Value)
		end

		progressText = progressText:gsub("{area}", regionName)
		progressText = progressText:gsub(
			"{progress}",
			"("
				.. currentMissionData.CurrentMissionProgress
				.. "/"
				.. currentMissionRequirements.Requirements.Value
				.. ")"
		)

		progressUI.Background.Progress.Text = progressText
		progressUI.Enabled = true
	else
		progressUI.Enabled = false
	end
end

playerStatePromise:andThen(function()
	local progressUI = player.PlayerGui:WaitForChild "ProgressUI"
	for regionName, zone in regionUtils.getRegions() do
		if zone:findLocalPlayer() then
			enteredRegion(regionName, progressUI)
		end
		zone.localPlayerEntered:Connect(function()
			enteredRegion(regionName, progressUI)
		end)
	end
	store.changed:connect(function(newState, oldState)
		local newMissionData = selectors.getMissionData(newState, player.Name)
		local oldMissionData = selectors.getMissionData(oldState, player.Name)
		if newMissionData == oldMissionData then
			return
		end
		enteredRegion(regionUtils.getPlayerLocationName(player.Name), progressUI)
	end)
end)

return 0
