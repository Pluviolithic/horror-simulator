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
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local missionRequirements = ReplicatedStorage.Missions
local missionSkipProductID = ReplicatedStorage.Config.DevProductData.IDs.MissionSkip.Value
local rolloutSpeed = ReplicatedStorage.Config.Text.MissionTextRolloutSpeed.Value
local MissionsUI = CentralUI.new(player.PlayerGui:WaitForChild "MissionsUI")
local MissionFearRewardUI = require(script.MissionFearRewardUI)

function MissionsUI:_initialize(): ()
	self._janitor = Janitor.new()
	interfaces[self] = true

	self._ui.Dialogue.Cancel.Activated:Connect(function()
		self:setEnabled(false)
	end)

	self._ui.Dialogue.Skip.MouseEnter:Connect(function()
		self._ui.Dialogue.Skip.ScrollText.Visible = true
	end)

	self._ui.Dialogue.Skip.MouseLeave:Connect(function()
		self._ui.Dialogue.Skip.ScrollText.Visible = false
	end)

	self._ui.Dialogue.Skip.Visible = false
	self._ui.Dialogue.Skip.Activated:Connect(function()
		local playerRegion = regionUtils.getPlayerLocationName(player.Name)
		local currentMissionData = selectors.getMissionData(store:getState(), player.Name)[playerRegion]
		local currentMissionRequirements =
			missionRequirements[playerRegion][tostring(currentMissionData.CurrentMissionNumber)]

		if currentMissionData.CurrentMissionProgress == currentMissionRequirements.Requirements.Value then
			return
		end

		MarketplaceService:PromptProductPurchase(player, missionSkipProductID)
		self:setEnabled(false)
	end)

	for _, hitbox in CollectionService:GetTagged "NPCHitbox" do
		Zone.new(hitbox).localPlayerExited:Connect(function()
			self:setEnabled(false)
		end)
	end
end

function MissionsUI:RolloutDialogue(dialogueSegment, gemRewardValue)
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
					print(text)
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
			self._ui.Dialogue.Skip.Visible = false

			local pending = true
			task.spawn(function()
				self:RolloutDialogue("Good job for completing the quest!", currentMissionRequirements.Gems.Value)
				pending = false
			end)
			self._janitor:Add(self._ui.Dialogue.Confirm.Activated:Connect(function()
				if pending then
					self._confirmPressed = true
					return
				end
				self._janitor:Cleanup()
				Remotes.Client:Get("CompleteMission"):CallServerAsync():andThen(function()
					if self._ui.Enabled then
						self:OnOpen()
					end
				end)
			end))
		else
			self._ui.Dialogue.Skip.Visible = true

			local pending = true
			task.spawn(function()
				self:RolloutDialogue(
					"Finish your current quest before starting the next one.",
					currentMissionRequirements.Gems.Value
				)
				pending = false
			end)
			self._janitor:Add(self._ui.Dialogue.Confirm.Activated:Connect(function()
				if pending then
					self._confirmPressed = true
					return
				end
				self._janitor:Cleanup()
				self:setEnabled(false)
			end))
		end
	elseif currentMissionData.CurrentMissionProgress ~= currentMissionRequirements.Requirements.Value then
		self._ui.Dialogue.Skip.Visible = true

		local i = 1
		local pending = true
		local dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))

		task.spawn(function()
			self:RolloutDialogue(dialogueSegment, currentMissionRequirements.Gems.Value)
			pending = false
		end)

		self._janitor:Add(self._ui.Dialogue.Confirm.Activated:Connect(function()
			if pending then
				self._confirmPressed = true
				return
			end
			i += 1
			if i > dialogueSegmentCount then
				Remotes.Client:Get("StartMission"):SendToServer()
				self:setEnabled(false)
			else
				pending = true
				dialogueSegment = currentMissionRequirements.Dialogue:FindFirstChild(tostring(i))
				self:RolloutDialogue(dialogueSegment, currentMissionRequirements.Gems.Value)
				pending = false
			end
		end))
	else
		self._ui.Dialogue.Skip.Visible = false
		local pending = true

		if not currentMissionData.ViewedRewardPopup then
			Remotes.Client:Get("DisableMissionRewardPopup"):SendToServer()
			MissionFearRewardUI._ui.Enabled = true
		end

		task.spawn(function()
			self:RolloutDialogue(
				'You have completed all the missions in Clown Town! You have received a Permanent <font color= "rgb(255, 207, 56)">+10% Fear Boost</font>!',
				currentMissionRequirements.Gems.Value
			)
			pending = false
		end)

		self._janitor:Add(self._ui.Dialogue.Confirm.Activated:Connect(function()
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
	missionPrompt.Triggered:Connect(function(source)
		if source ~= player or debounce then
			return
		end
		debounce = true
		MissionsUI:setEnabled(not MissionsUI._isOpen)
		task.wait(0.5)
		debounce = false
	end)
end

task.spawn(MissionsUI._initialize, MissionsUI)
require(script.ProgressUI)

return 0
