local TweenService = game:GetService "TweenService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local random = Random.new()
local weapons = ReplicatedStorage.Weapons
local combatAnimations = ReplicatedStorage.CombatAnimations
local damageIndicatorTemplate = ReplicatedStorage.DamageTemplate
local fistSound = ReplicatedStorage.Config.Audio.SoundEffects.Fists

local function findFirstChildWithTag(parent: Instance?, tag: string, recursive: boolean?): Instance?
	if not parent then
		return nil
	end
	for _, child in parent:GetChildren() do
		if CollectionService:HasTag(child, tag) then
			return child
		end
		if recursive then
			local result = findFirstChildWithTag(child, tag, recursive)
			if result then
				return result
			end
		end
	end
	return nil
end

local function dealDamageToEnemy(player, enemy, info)
	Remotes.Server:Get("SendFightInfo"):SendToPlayer(player, {
		IsBoss = CollectionService:HasTag(enemy, "Boss"),
		Gems = enemy.Configuration.Gems.Value,
		Health = info.HealthValue.Value,
		MaxHealth = info.MaxHealth,
		DamageDealtByPlayer = info.DamageDealtByPlayer[player],
	})
end

local function createDamageIndicator(enemy, damageToDeal)
	local damageIndicator = damageIndicatorTemplate:Clone()
	local tween = TweenService:Create(damageIndicator.Amount, TweenInfo.new(0.5), { TextTransparency = 1 })

	damageIndicator.Position = UDim2.fromScale(random:NextNumber(0, 0.7), random:NextNumber(0.01, 0.85))
	damageIndicator.Rotation = random:NextNumber(-7, 7)
	damageIndicator.Amount.Text = "-" .. formatter.formatNumberWithSuffix(damageToDeal)
	damageIndicator.Parent = enemy.Hitbox.DamageIndicators.Frame

	damageIndicator.Amount:TweenPosition(UDim2.fromScale(0.05, -1), "Out", "Quad", 1, true)
	task.wait(0.5)

	tween:Play()
	tween.Completed:Wait()
	tween:Destroy()
	damageIndicator:Destroy()
end

local function canAttack(player, enemy, info)
	if not enemy:IsDescendantOf(game) then
		return false
	end

	local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"
	local fightRange = enemy.Configuration.FightRange.Value

	return info.HealthValue.Value > 0
		and selectors.isPlayerLoaded(store:getState(), player.Name)
		and selectors.getCurrentTarget(store:getState(), player.Name) == enemy
		and player:DistanceFromCharacter(rootPart.Position) <= fightRange + 5
end

return function(player, enemy, info, janitor)
	local enabled = true
	local weaponName = selectors.getEquippedWeapon(store:getState(), player.Name)
	local damageMultiplier = if weaponName == "Fists" then 1 else weapons[weaponName].Damage.Value

	local currentIndex, animationTrack, animation = 0, nil, nil
	local idleAnimation = combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)].Idle
	local animationInstances = animationUtilities.filterAndSortAnimationInstances(
		combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)]:GetChildren()
	)

	local loadedIdleAnimation = player.Character.Humanoid:LoadAnimation(idleAnimation)
	loadedIdleAnimation.Priority = Enum.AnimationPriority.Idle

	local oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
	if oldEquippedWeaponAccessory then
		oldEquippedWeaponAccessory:Destroy()
	end

	if weaponName ~= "Fists" then
		local weaponAccessory = weapons[weaponName]:Clone()
		player.Character.Humanoid:AddAccessory(weaponAccessory)
		janitor:Add(function()
			local equippedWeaponAccessory = weapons.BodyAccessory:FindFirstChild(weaponName)
			if info.HealthValue.Value > 0 then
				weaponAccessory:Destroy()
				if player.Character and not findFirstChildWithTag(player.Character, "WeaponAccessory") then
					player.Character.Humanoid:AddAccessory(equippedWeaponAccessory:Clone())
				end
				return
			end
			task.delay(1, function()
				weaponAccessory:Destroy()
				if not findFirstChildWithTag(player.Character, "WeaponAccessory") then
					player.Character.Humanoid:AddAccessory(equippedWeaponAccessory:Clone())
				end
			end)
		end, true)
	end

	task.spawn(function()
		while canAttack(player, enemy, info) and enabled do
			local damageToDeal = math.clamp(
				selectors.getStat(store:getState(), player.Name, "Strength") * damageMultiplier,
				0,
				info.HealthValue.Value
			)
			info.DamageDealtByPlayer[player] = (info.DamageDealtByPlayer[player] or 0) + damageToDeal
			info.HealthValue.Value -= damageToDeal

			if enemy.Parent == nil then
				break
			end

			oldEquippedWeaponAccessory = findFirstChildWithTag(player.Character, "WeaponAccessory")
			if oldEquippedWeaponAccessory then
				oldEquippedWeaponAccessory:Destroy()
			end

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

					task.delay(0.1, function()
						dealDamageToEnemy(player, enemy, info)
						createDamageIndicator(enemy, damageToDeal)
					end)

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
					if not sound:IsA "Sound" then
						continue
					end
					if sound.Name == "Impact" then
						task.delay(sound.Delay.Value - 0.1, function()
							dealDamageToEnemy(player, enemy, info)
							createDamageIndicator(enemy, damageToDeal)
						end)
					end
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

			if not enemy:FindFirstChild "Humanoid" then
				return
			end
			local rootPart = if enemy.Humanoid.RootPart
				then enemy.Humanoid.RootPart
				else enemy:FindFirstChild "RootPart"
			local fightRange = enemy.Configuration.FightRange.Value
			if player:DistanceFromCharacter(rootPart.Position) > fightRange + 10 and Janitor.Is(janitor) then
				janitor:Destroy()
			end
		end
	end)

	if Janitor.Is(janitor) then
		janitor:Add(function()
			enabled = false
		end, true)
		janitor:Add(function()
			if loadedIdleAnimation.IsPlaying then
				loadedIdleAnimation:Stop()
			end
			loadedIdleAnimation:Destroy()
			if animationTrack and animationTrack.IsPlaying then
				task.spawn(function()
					animationTrack.Stopped:Wait()
					animationTrack:Destroy()
				end)
			end
		end, true)
	else
		enabled = false
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
	end
end
