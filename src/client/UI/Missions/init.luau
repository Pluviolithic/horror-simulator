local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local store = require(Client.State.Store)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local missionRequirements = ReplicatedStorage.Missions
local rolloutSpeed = ReplicatedStorage.Config.Text.MissionTextRolloutSpeed.Value
local MissionsUI = CentralUI.new(player.PlayerGui:WaitForChild "MissionsUI")

function MissionsUI:_initialize(): ()
	self._confirmPressed = false
	interfaces[self] = true

	self._ui.Dialogue.Cancel.Activated:Connect(function()
		self:setEnabled(false)
	end)
end

function MissionsUI:RolloutDialogue(dialogueSegment)
	local text = if typeof(dialogueSegment) == "string" then dialogueSegment else dialogueSegment.Value
	for j = 1, #text do
		self._ui.Dialogue.Background.Dialogue.Text = text:sub(1, j)
		task.wait(rolloutSpeed)
		if self._confirmPressed then
			self._confirmPressed = false
			break
		end
	end

	if typeof(dialogueSegment) ~= "string" then
		for _, colorValue in dialogueSegment:GetChildren() do
			for _, attributeValue in colorValue:GetAttributes() do
				local rgb = {
					math.round(colorValue.Value.R * 255),
					math.round(colorValue.Value.G * 255),
					math.round(colorValue.Value.B * 255),
				}
				text = text:gsub(
					attributeValue,
					'<font color="rgb(' .. table.concat(rgb, ",") .. ')">' .. attributeValue .. "</font>"
				)
			end
		end
	end

	self._ui.Dialogue.Background.Dialogue.Text = text
end

function MissionsUI:OnOpen()
	local playerRegion = regionUtils.getPlayerLocationName(player.Name)
	local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[playerRegion]
	local currentMissionRequirements =
		missionRequirements[playerRegion][tostring(currentMissionData.CurrentMissionNumber)]
	local dialogueSegmentCount = #currentMissionRequirements.Dialogue:GetChildren()
	local completedMissionsNumber = if currentMissionData.CurrentMissionProgress
				== currentMissionRequirements.Requirements.Value
			and not currentMissionData.Active
		then currentMissionData.CurrentMissionNumber
		else currentMissionData.CurrentMissionNumber - 1

	self._ui.Dialogue.Area.Text = playerRegion .. " Missions"
	self._ui.Dialogue.MissionsCompleted.Text = "("
		.. completedMissionsNumber
		.. "/"
		.. #missionRequirements[playerRegion]:GetChildren()
		.. ")"

	if currentMissionData.Active then
		if currentMissionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
			self:RolloutDialogue "Good job for completing the quest!"
			self._confirmConnection = self._ui.Dialogue.Confirm.Activated:Connect(function()
				self._confirmConnection:Disconnect()
				Remotes.Client:Get("CompleteMission"):CallServerAsync():andThen(function()
					if self._ui.Enabled then
						self:OnOpen()
					end
				end)
			end)
		else
			self:RolloutDialogue "Finish your current quest before starting the next one."
			self._confirmConnection = self._ui.Dialogue.Confirm.Activated:Connect(function()
				self._confirmConnection:Disconnect()
				self:setEnabled(false)
			end)
		end
	else
		local i = 1
		local pending = false
		local dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))
		self:RolloutDialogue(dialogueSegment)

		self._ui.Dialogue.Confirm.Activated:Connect(function()
			if pending then
				self._confirmPressed = true
			end
			i += 1
			if i > dialogueSegmentCount then
				Remotes.Client:Get("StartMission"):SendToServer()
				self:setEnabled(false)
			else
				pending = true
				dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))
				self:RolloutDialogue(dialogueSegment)
				pending = false
			end
		end)
	end
end

function MissionsUI:OnClose()
	if self._confirmConnection and self._confirmConnection.Connected then
		self._confirmConnection:Disconnect()
	end
	self._confirmConnection = nil
end

for _, missionPrompt in CollectionService:GetTagged "MissionPrompt" do
	missionPrompt.Triggered:Connect(function(source)
		if source ~= player then
			return
		end
		MissionsUI:setEnabled(not MissionsUI._isOpen)
	end)
end

task.spawn(MissionsUI._initialize, MissionsUI)
require(script.ProgressUI)

return 0
