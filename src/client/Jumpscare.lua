local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local jumpscares = workspace:WaitForChild "Jumpscares"
local playerStatePromise = require(Client.State.PlayerStatePromise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)
local camera = workspace.CurrentCamera

local jumpscareGap = 5
local lastJumpscared = -1

local function isScared(playerName, state)
	return selectors.getStat(state, playerName, "CurrentFearMeter")
			== selectors.getStat(state, playerName, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, playerName, "LastScaredTimestamp")) < 121
end

local function jumpscarePlayer(enemyName)
	local jumpscare = jumpscares[enemyName]
	local animation = jumpscare.Enemy.Configuration.Anim

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
	end)
end

playerStatePromise:andThen(function()
	local lastEnemyFought = selectors.getCurrentTarget(store:getState(), player.Name)
	store.changed:connect(function(newState, oldState)
		if selectors.getCurrentTarget(newState, player.Name) then
			lastEnemyFought = selectors.getCurrentTarget(newState, player.Name)
		end
		if
			isScared(player.Name, newState)
			and not isScared(player.Name, oldState)
			and (os.time() - lastJumpscared) > jumpscareGap
		then
			jumpscarePlayer(lastEnemyFought.Name)
		end
	end)
end)

return 0
