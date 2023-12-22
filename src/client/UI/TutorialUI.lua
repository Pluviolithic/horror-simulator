local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local permissionList = require(ReplicatedStorage.Common.PermissionList)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local fearMeter = require(StarterPlayer.StarterPlayerScripts.Client.UI.Combat.FearMeter)
local strengthMeters = require(StarterPlayer.StarterPlayerScripts.Client.UI.Combat.StrengthMeters)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local step = 1
local connection
local deletedEnemyBeam = false
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TutorialUI = player.PlayerGui:WaitForChild "Tutorial"
local starterStrength = ReplicatedStorage.Config.Workout.Strength.Value
local rolloutSpeed = ReplicatedStorage.Config.Text.MissionTextRolloutSpeed.Value

if permissionList.TutorialExempt[player.UserId] and not ReplicatedStorage.Config.Misc.TutorialTesting.Value then
	return 0
end

local rolloutFinished = false
local function rolloutTutorialText(text)
	if TutorialUI.TutorialText.Visible then
		if rolloutFinished then
			TutorialUI.TutorialText.Text = text
		end
		return
	end
	rolloutFinished = false
	TutorialUI.TutorialText.Visible = true
	for i = 1, #text do
		TutorialUI.TutorialText.Text = text:sub(1, i)
		task.wait(rolloutSpeed)
	end
	rolloutFinished = true
end

local subStep = 1
local stepLocked = false
local tutorialFunctions
tutorialFunctions = {
	function() -- step 1
		local kills = selectors.getStat(store:getState(), player.Name, "Kills")
		if kills < 2 then
			rolloutTutorialText(`Defeat enemies to gain Fear! ({kills}/2)`)

			if not workspace.Beams.TutorialEnemy.Beam.Attachment1 and not deletedEnemyBeam then
				local rootPart = if player.Character then player.Character:FindFirstChild "HumanoidRootPart" else nil
				if rootPart then
					workspace.Beams.TutorialEnemy.Beam.Attachment1 = rootPart.RootAttachment
				end
			end
		else
			step = 2
			Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
			tutorialFunctions[step]()
		end
	end,
	function() -- step 2
		local strength = selectors.getStat(store:getState(), player.Name, "Strength")
		if strength - starterStrength < 10 then
			if not workspace.Beams.TutorialWorkout.Beam.Attachment1 then
				workspace.Beams.TutorialWorkout.Beam.Attachment1 = player.Character.HumanoidRootPart.RootAttachment
			end
			rolloutTutorialText(`Turn your Fear into Strength by Working Out! ({strength - starterStrength}/10)`)
		else
			step = 3
			Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
			tutorialFunctions[step]()
		end
	end,
	function() -- step 3
		if subStep == 1 then
			rolloutTutorialText "You are now stronger! Try defeating an enemy!"
			subStep += 1
			Remotes.Client:Get("SetTutorialFearMeterPercent"):SendToServer(0.95)
			return
		end

		if stepLocked then
			return
		end

		if
			selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
			>= selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
		then
			local meterDisplayText = "This is your Fear Meter. When it is maxed you get scared!"
			stepLocked = true
			rolloutTutorialText "You got scared by an enemy!"

			task.wait(4)

			Remotes.Client:Get("SetTutorialFearMeterPercent"):SendToServer(0)
			fearMeter(true)

			TutorialUI.DarkScreen.Visible = true
			TutorialUI.DisplayOrder = 1
			TutorialUI.TutorialText.Visible = false
			TutorialUI.MeterText.Visible = true
			TutorialUI.MeterArrow.Visible = true

			for i = 1, #meterDisplayText do
				TutorialUI.MeterText.Text = meterDisplayText:sub(1, i)
				task.wait(rolloutSpeed)
			end

			task.wait(5)

			TutorialUI.DarkScreen.Visible = false
			TutorialUI.MeterText.Visible = false
			TutorialUI.MeterArrow.Visible = false

			step = 4
			subStep = 1
			stepLocked = false
			Remotes.Client:Get("IncrementTutorialStep"):SendToServer()

			tutorialFunctions[step]()
		end
	end,
	function() -- step 4
		rolloutTutorialText "When you are scared you attack and move slower!"
		step = 5
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 5
		local rankText = "Click Strength Rank to see all the ranks!"
		if stepLocked then
			return
		end
		stepLocked = true

		task.wait(5)

		TutorialUI.DarkScreen.Visible = true
		TutorialUI.DisplayOrder = 3
		TutorialUI.TutorialText.Visible = false
		TutorialUI.RankText.Visible = true
		TutorialUI.RankArrow.Visible = true

		task.spawn(function()
			repeat
				TutorialUI.RankArrow:TweenPosition(
					UDim2.fromScale(0.157, 0.879),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Linear,
					0.5,
					true
				)
				task.wait(0.6)
				TutorialUI.RankArrow:TweenPosition(
					UDim2.fromScale(0.163, 0.879),
					Enum.EasingDirection.In,
					Enum.EasingStyle.Linear,
					0.5,
					true
				)
				task.wait(0.6)
			until step ~= 5
		end)

		for i = 1, #rankText do
			TutorialUI.RankText.Text = rankText:sub(1, i)
			task.wait(rolloutSpeed)
		end

		player.PlayerGui.Rank.Open.Activated:Wait()

		step = 6
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 6
		local strengthText = "Increase your rank by working out to get more fear meter!"
		if stepLocked then
			return
		end
		stepLocked = true

		TutorialUI.RankText.Visible = false
		TutorialUI.RankArrow.Visible = false
		TutorialUI.StrengthText.Visible = true

		for i = 1, #strengthText do
			TutorialUI.StrengthText.Text = strengthText:sub(1, i)
			task.wait(rolloutSpeed)
		end

		task.wait(5)

		TutorialUI.DarkScreen.Visible = false
		TutorialUI.StrengthText.Visible = false
		strengthMeters:setEnabled(false)

		step = 7
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 7
		if stepLocked then
			return
		end
		stepLocked = true

		rolloutTutorialText "Use the AFK area to gain fear while you're away!"

		camera.CameraType = Enum.CameraType.Scriptable
		local tween =
			TweenService:Create(camera, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
				CFrame = workspace.Cutscenes.AFKCutscene.CFrame,
			})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		step = 8
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 8
		local bossText1 = "Defeating bosses gives you lots of gems!"
		local bossText2 = "They are strong, so fight them with other players!"
		if stepLocked then
			return
		end
		stepLocked = true

		task.wait(4)

		TutorialUI.TutorialText.Visible = false

		local tween =
			TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
				CFrame = workspace.Cutscenes.Boss1Cutscene.CFrame,
			})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		tween = TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
			CFrame = workspace.Cutscenes.Boss2Cutscene.CFrame,
		})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		TutorialUI.BossText1.Visible = true
		for i = 1, #bossText1 do
			TutorialUI.BossText1.Text = bossText1:sub(1, i)
			task.wait(rolloutSpeed)
		end

		task.wait(1)

		TutorialUI.BossText2.Visible = true
		for i = 1, #bossText2 do
			TutorialUI.BossText2.Text = bossText2:sub(1, i)
			task.wait(rolloutSpeed)
		end

		step = 9
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 9
		local portalText1 = "Once you are strong enough you"
		local portalText2 = "can advance to the next area!"
		if stepLocked then
			return
		end
		stepLocked = true

		task.wait(4)

		TutorialUI.BossText1.Visible = false
		TutorialUI.BossText2.Visible = false

		local tween = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
			CFrame = workspace.Cutscenes.PortalCutscene.CFrame,
		})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		TutorialUI.PortalText1.Visible = true
		for i = 1, #portalText1 do
			TutorialUI.PortalText1.Text = portalText1:sub(1, i)
			task.wait(rolloutSpeed)
		end

		TutorialUI.PortalText2.Visible = true
		for i = 1, #portalText2 do
			TutorialUI.PortalText2.Text = portalText2:sub(1, i)
			task.wait(rolloutSpeed)
		end

		step = 10
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
		tutorialFunctions[step]()
	end,
	function() -- step 10
		local missionText1 = "Talk to the Police Officer for missions that give gems!"
		local missionText2 = "Gems can buy Pets & Weapons!"
		if stepLocked then
			return
		end
		stepLocked = true

		task.wait(4)

		TutorialUI.PortalText1.Visible = false
		TutorialUI.PortalText2.Visible = false

		local tween =
			TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
				CFrame = workspace.Cutscenes.Boss1Cutscene.CFrame,
			})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		tween = TweenService:Create(camera, TweenInfo.new(1.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
			CFrame = workspace.Cutscenes.MissionCutscene.CFrame,
		})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()

		TutorialUI.MissionText1.Visible = true
		for i = 1, #missionText1 do
			TutorialUI.MissionText1.Text = missionText1:sub(1, i)
			task.wait(rolloutSpeed)
		end

		TutorialUI.MissionText2.Visible = true
		for i = 1, #missionText2 do
			TutorialUI.MissionText2.Text = missionText2:sub(1, i)
			task.wait(rolloutSpeed)
		end

		task.wait(2)

		camera.CameraSubject = player.Character.Humanoid
		camera.CameraType = Enum.CameraType.Custom

		workspace.Beams.TutorialMission.Beam.Attachment1 = player.Character.HumanoidRootPart.RootAttachment

		step = 11
		stepLocked = false
		Remotes.Client:Get("IncrementTutorialStep"):SendToServer()
	end,
}

playerStatePromise:andThen(function()
	step = selectors.getTutorialStep(store:getState(), player.Name)
	if step > 10 then
		return
	end
	task.spawn(tutorialFunctions[step])
	connection = store.changed:connect(function(newState)
		local currentTarget = selectors.getCurrentTarget(newState, player.Name)
		if currentTarget and CollectionService:HasTag(currentTarget, "PunchingBag") and step == 2 then
			TutorialUI.TutorialText.Visible = false
			if workspace.Beams.TutorialWorkout.Beam.Attachment1 then
				workspace.Beams.TutorialWorkout.Beam.Attachment1 = nil
			end
			return
		end

		if tutorialFunctions[step] then
			task.spawn(tutorialFunctions[step])
		end
	end)

	local connections = {}
	for _, missionPrompt in CollectionService:GetTagged "MissionPrompt" do
		table.insert(
			connections,
			missionPrompt.Triggered:Connect(function(source)
				if source == player and step == 11 then
					for _, missionConnection in connections do
						missionConnection:Disconnect()
					end
					connection:disconnect()
					TutorialUI.Enabled = false
					workspace.Beams.TutorialMission.Beam.Attachment1 = nil
				end
			end)
		)
	end

	table.insert(
		connections,
		Remotes.Client:Get("CombatBegan"):Connect(function()
			if workspace.Beams.TutorialEnemy.Beam.Attachment1 then
				deletedEnemyBeam = true
				workspace.Beams.TutorialEnemy.Beam.Attachment1 = nil
			end
		end)
	)
end)

return 0
