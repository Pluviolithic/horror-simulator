local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ContentProvider = game:GetService "ContentProvider"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local jumpscares = workspace:WaitForChild "Jumpscares"
local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)
local camera = workspace.CurrentCamera

local jumpscareGap = ReplicatedStorage.Config.Combat.JumpscareCooldown.Value
local lastJumpscared = -1

local function isScared(state)
	if selectors.getActiveBoosts(state, player.Name)["FearlessBoost"] then
		return false
	end
	return selectors.getStat(state, player.Name, "CurrentFearMeter")
			== selectors.getStat(state, player.Name, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, player.Name, "LastScaredTimestamp")) < 121
end

local function jumpscarePlayer(enemyName)
	local preservedUIState = {}
	local jumpscare = jumpscares[enemyName]
	local animation = jumpscare.Enemy.Configuration.Anim

	for _, gui in player.PlayerGui:GetChildren() do
		if gui:IsA "ScreenGui" then
			preservedUIState[gui] = gui.Enabled
			gui.Enabled = false
		end
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = jumpscare.Camera.CFrame
	lastJumpscared = os.time()

	for _, sound in jumpscare.Enemy.Configuration.Sounds:GetChildren() do
		task.delay(sound.Delay.Value, function()
			local timePosition = sound.TimePosition
			sound:Play()
			if sound:FindFirstChild "Duration" then
				task.wait(sound.Duration.Value)
				sound:Stop()
			end
			if sound.IsPlaying then
				sound.Ended:Wait()
			end
			sound.TimePosition = timePosition
		end)
	end

	local animationTrack = jumpscare.Enemy.AnimationController:LoadAnimation(animation)
	animationTrack:Play()

	task.spawn(function()
		if jumpscare.Enemy.Configuration:FindFirstChild "ScareDuration" then
			task.wait(jumpscare.Enemy.Configuration.ScareDuration.Value)
		else
			animationTrack.Ended:Wait()
		end

		camera.CameraSubject = player.Character
		camera.CameraType = Enum.CameraType.Custom

		for gui, enabled in pairs(preservedUIState) do
			gui.Enabled = enabled
		end
	end)
end

playerStatePromise:andThen(function()
	local lastEnemyFought = selectors.getCurrentTarget(store:getState(), player.Name)
	store.changed:connect(function(newState, oldState)
		if selectors.getCurrentTarget(newState, player.Name) then
			lastEnemyFought = selectors.getCurrentTarget(newState, player.Name)
		end
		if
			isScared(newState)
			and not isScared(oldState)
			and ((os.time() - lastJumpscared) > jumpscareGap or not selectors.getSetting(
				newState,
				player.Name,
				"JumpscareCooldown"
			))
			and selectors.getSetting(newState, player.Name, "Jumpscares")
		then
			jumpscarePlayer(if lastEnemyFought then lastEnemyFought.Name else "Evil Clown")
		end
	end)
end)

local jumpscareAnimations = {}
for _, jumpscare in jumpscares:GetChildren() do
	table.insert(jumpscareAnimations, jumpscare.Enemy.Configuration.Anim)
end

task.spawn(ContentProvider.PreloadAsync, ContentProvider, jumpscareAnimations)

return 0
