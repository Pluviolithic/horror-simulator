local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local store = require(Client.State.Store)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local playerStatePromise = require(Client.State.PlayerStatePromise)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local statusUIListeners = {}
local missionRequirements = ReplicatedStorage.Missions
local missionSkipProductID = ReplicatedStorage.Config.DevProductData.IDs.MissionSkip.Value
local doubleGemsGamepassID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xGems"].Value)
local rolloutSpeed = ReplicatedStorage.Config.Text.MissionTextRolloutSpeed.Value
local MissionsUI = CentralUI.new(player.PlayerGui:WaitForChild "MissionsUI")
local MissionFearRewardUI = require(script.MissionFearRewardUI)

local startMission, completeMission, disableMissionRewardPopup =
	Remotes.Client:Get "StartMission",
	Remotes.Client:Get "CompleteMission",
	Remotes.Client:Get "DisableMissionRewardPopup"

local function handleMissionStatusUI(statusUI, areaName)
	local frame = statusUI.MissionUI.Frame
	statusUIListeners[areaName] = function(missionData)
		local currentMissionRequirements = missionRequirements[areaName][tostring(missionData.CurrentMissionNumber)]
		if missionData.Active then
			if missionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
				frame.Mission.Visible = false
				frame.Completed.Visible = true
			end
		elseif missionData.CurrentMissionProgress ~= currentMissionRequirements.Requirements.Value then
			frame.Completed.Visible = false
			frame.Mission.Visible = true
		else
			frame.Completed.Visible = false
			frame.Mission.Visible = false
		end
	end
end

function MissionsUI:_initialize(): ()
	self._janitor = Janitor.new()
	interfaces[self] = true

	self._ui.Dialogue.Frame.Cancel.Activated:Connect(function()
		self:setEnabled(false)
	end)

	self._ui.Dialogue.Frame.Skip.MouseEnter:Connect(function()
		self._ui.Dialogue.Frame.Skip.ScrollText.Visible = true
	end)

	self._ui.Dialogue.Frame.Skip.MouseLeave:Connect(function()
		self._ui.Dialogue.Frame.Skip.ScrollText.Visible = false
	end)

	self._ui.Dialogue.Frame.Skip.Visible = false
	self._ui.Dialogue.Frame.Skip.Activated:Connect(function()
		local playerRegion = regionUtils.getPlayerLocationName(player.Name)
		local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[playerRegion]
		local currentMissionRequirements =
			missionRequirements[playerRegion][tostring(currentMissionData.CurrentMissionNumber)]

		if currentMissionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
			return
		end

		MarketplaceService:PromptProductPurchase(player, missionSkipProductID)
	end)

	for _, hitbox in CollectionService:GetTagged "NPCHitbox" do
		Zone.new(hitbox).localPlayerExited:Connect(function()
			self:setEnabled(false)
		end)
	end
end

function MissionsUI:RolloutDialogue(dialogueSegment, gemRewardValue)
	if selectors.hasGamepass(store:getState(), player.Name, doubleGemsGamepassID) then
		gemRewardValue *= 2
	end

	local splitText = {}
	local text = if typeof(dialogueSegment) == "string" then dialogueSegment else dialogueSegment.Value
	local gemRewardText = formatter.formatNumberWithSuffix(gemRewardValue) .. " Gems"

	if typeof(dialogueSegment) ~= "string" then
		for _, colorValue in dialogueSegment:GetChildren() do
			for _, attributeValue in colorValue:GetAttributes() do
				local rgb = {
					math.round(colorValue.Value.R * 255),
					math.round(colorValue.Value.G * 255),
					math.round(colorValue.Value.B * 255),
				}

				if attributeValue == "{gems}" then
					text = text:gsub(
						attributeValue,
						'<font color="rgb(' .. table.concat(rgb, ",") .. ')">' .. gemRewardText .. "</font>"
					)
					continue
				end

				text = text:gsub(
					attributeValue,
					'<font color="rgb(' .. table.concat(rgb, ",") .. ')">' .. attributeValue .. "</font>"
				)
			end
		end
	end

	local bracketStart = nil
	for i = 1, #text do
		local c = text:sub(i, i)
		if c == "<" then
			bracketStart = i
		elseif c == ">" then
			table.insert(splitText, text:sub(bracketStart, i))
			bracketStart = nil
		elseif not bracketStart then
			table.insert(splitText, c)
		end
	end

	local runningTotal = ""
	local richtextActive = false
	for i = 1, #splitText do
		local currentSegment = splitText[i]

		if currentSegment:match "color=" then
			richtextActive = true
			runningTotal = runningTotal .. currentSegment
			continue
		elseif currentSegment == "</font>" then
			richtextActive = false
		end

		runningTotal = runningTotal .. currentSegment

		if richtextActive then
			self._ui.Dialogue.Background.Dialogue.Text = runningTotal .. "</font>"
		else
			self._ui.Dialogue.Background.Dialogue.Text = runningTotal
		end

		task.wait(rolloutSpeed)
		if self._confirmPressed then
			self._confirmPressed = false
			break
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

	self._confirmPressed = false
	self._janitor:Cleanup()

	if currentMissionData.Active then
		if currentMissionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
			self._ui.Dialogue.Frame.Skip.Visible = false

			local pending = true
			task.spawn(function()
				self:RolloutDialogue("Good job for completing the quest!", currentMissionRequirements.Gems.Value)
				pending = false
			end)
			self._janitor:Add(self._ui.Dialogue.Frame.Confirm.Activated:Connect(function()
				if pending then
					self._confirmPressed = true
					return
				end
				self._janitor:Cleanup()
				completeMission:CallServerAsync():andThen(function()
					if self._ui.Enabled then
						self:OnOpen()
					end
				end)
			end))
		else
			self._ui.Dialogue.Frame.Skip.Visible = true

			local pending = true
			task.spawn(function()
				self:RolloutDialogue(
					"Finish your current quest before starting the next one.",
					currentMissionRequirements.Gems.Value
				)
				pending = false
			end)
			self._janitor:Add(self._ui.Dialogue.Frame.Confirm.Activated:Connect(function()
				if pending then
					self._confirmPressed = true
					return
				end
				self._janitor:Cleanup()
				self:setEnabled(false)
			end))
		end
	elseif currentMissionData.CurrentMissionProgress ~= currentMissionRequirements.Requirements.Value then
		self._ui.Dialogue.Frame.Skip.Visible = true

		local i = 1
		local pending = true
		local dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))

		task.spawn(function()
			self:RolloutDialogue(dialogueSegment, currentMissionRequirements.Gems.Value)
			pending = false
		end)

		self._janitor:Add(self._ui.Dialogue.Frame.Confirm.Activated:Connect(function()
			if pending then
				self._confirmPressed = true
				return
			end
			i += 1
			if i > dialogueSegmentCount then
				startMission:SendToServer()
				self:setEnabled(false)
			else
				pending = true
				dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))
				self:RolloutDialogue(dialogueSegment, currentMissionRequirements.Gems.Value)
				pending = false
			end
		end))
	else
		self._ui.Dialogue.Frame.Skip.Visible = false
		local pending = true

		if not currentMissionData.ViewedRewardPopup then
			disableMissionRewardPopup:SendToServer()
			MissionFearRewardUI._ui.Enabled = true
		end

		task.spawn(function()
			self:RolloutDialogue(
				'You have completed all the missions in Clown Town! You have received a Permanent <font color= "rgb(255, 207, 56)">+10% Fear Boost</font>!',
				currentMissionRequirements.Gems.Value
			)
			pending = false
		end)

		self._janitor:Add(self._ui.Dialogue.Frame.Confirm.Activated:Connect(function()
			if pending then
				self._confirmPressed = true
				return
			end
			self:setEnabled(false)
		end))
	end
end

for _, missionPrompt in CollectionService:GetTagged "MissionPrompt" do
	local debounce = false
	local areaName = missionPrompt.Parent.Parent.Name:sub(1, -12)
	missionPrompt.Triggered:Connect(function(source)
		if source ~= player or debounce then
			return
		end
		debounce = true
		MissionsUI:setEnabled(not MissionsUI._isOpen)
		task.wait(0.5)
		debounce = false
	end)
	handleMissionStatusUI(missionPrompt.Parent.Parent.MissionStatus, areaName)
end

task.spawn(MissionsUI._initialize, MissionsUI)
playerStatePromise:andThen(function()
	for areaName, listener in statusUIListeners do
		listener(selectors.getMissionData(store:getState(), player.Name)[areaName])
	end
	store.changed:connect(function(newState, oldState)
		local newMissionData = selectors.getMissionData(newState, player.Name)
		local oldMissionData = selectors.getMissionData(oldState, player.Name)
		if newMissionData == oldMissionData then
			return
		end
		MissionsUI:OnOpen()
		for areaName, listener in statusUIListeners do
			listener(newMissionData[areaName])
		end
	end)
end)

require(script.ProgressUI)

return 0
