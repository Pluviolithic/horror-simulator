local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local random = Random.new()
local combatAnimations = ReplicatedStorage.CombatAnimations
local fistSound = ReplicatedStorage.Config.Audio.SoundEffects.Fists

return function(player, janitor)
	local runAnimations = true

	local currentIndex, animationTrack, animation = 0, nil, nil
	local idleAnimation = combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)].Idle
	local animationInstances = animationUtilities.filterAndSortAnimationInstances(
		combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)]:GetChildren()
	)

	local loadedIdleAnimation = player.Character.Humanoid:LoadAnimation(idleAnimation)
	loadedIdleAnimation.Priority = Enum.AnimationPriority.Idle

	task.spawn(function()
		while runAnimations do
			currentIndex, animation = animationUtilities.getNextIndexAndAnimationTrack(animationInstances, currentIndex)
			animationTrack = player.Character.Humanoid:LoadAnimation(animation)
			animationTrack.Priority = Enum.AnimationPriority.Action

			animationTrack:Play()

			task.spawn(function()
				local weapon = selectors.getEquippedWeapon(store:getState(), player.Name)
				if weapon == "Fists" then
					local sound = player.Character.HumanoidRootPart:FindFirstChild "Fists" or fistSound:Clone()
					sound.Parent = player.Character.HumanoidRootPart
					sound.PlaybackSpeed = random:NextNumber(0.9, 1.1)
					sound:Play()
					return
				end

				local playbackSpeed = random:NextNumber(0.9, 1.1)

				local sounds = player.Character[weapon]:FindFirstChild "Sounds"
				while not sounds do
					task.wait()
					local weaponObject = player.Character:FindFirstChild(weapon)
					if not weaponObject then
						return
					end
					sounds = weaponObject:FindFirstChild "Sounds"
				end
				for _, sound in sounds:GetChildren() do
					task.spawn(function()
						if sound:FindFirstChild "Delay" and sound.Delay.Value ~= 0 then
							task.wait(sound.Delay.Value)
						end
						sound.PlaybackSpeed = playbackSpeed
						sound:Play()
						if sound:FindFirstChild "Duration" then
							task.wait(sound.Duration.Value)
							sound:Stop()
						end
					end)
				end
			end)

			animationTrack.Stopped:Wait()
			animationTrack:Destroy()

			loadedIdleAnimation:Play()

			task.wait(animationUtilities.getPlayerAttackSpeed(player))

			loadedIdleAnimation:Stop()
		end
	end)

	if Janitor.Is(janitor) then
		janitor:Add(function()
			runAnimations = false
			if loadedIdleAnimation.IsPlaying then
				loadedIdleAnimation:Stop()
			end
			loadedIdleAnimation:Destroy()
			if animationTrack.IsPlaying then
				task.spawn(function()
					animationTrack.Stopped:Wait()
					animationTrack:Destroy()
				end)
			end
		end, true)
	end
end
