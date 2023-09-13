local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local animations = ReplicatedStorage.CombatAnimations

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local function handleDummy(dummy)
	local clickDetector: ClickDetector = dummy.Hitbox.ClickDetector
	local goalPosition: Vector3 = dummy.Hitbox.Position
	local fear: number = dummy.Configuration.Fear.Value
	local NPCUI = dummy:FindFirstChild("NPCUI", true)
	local fightRange: number = dummy.Configuration.FightRange.Value

	NPCUI:FindFirstChild("NPCName", true).Text = "Dummy"

	local debounceTable: { boolean } = {}

	clickDetector.MouseClick:Connect(function(player: Player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if debounceTable[player.UserId] or not humanoid then
			return
		end

		debounceTable[player.UserId] = true
		task.delay(1, function()
			debounceTable[player.UserId] = nil
		end)

		if selectors.getCurrentTarget(store:getState(), player.Name) == dummy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, dummy))
		end

		--Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, true)
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)

		local failed: boolean = false
		local connection = nil
		connection = store.changed:connect(function(newState)
			if selectors.getCurrentTarget(newState, player.Name) ~= dummy then
				failed = true
				--Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			end
		end)

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			--Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
			failed = true
		end)

		humanoid.MoveToFinished:Wait()
		connection:disconnect()
		if failed then
			return
		end

		local animationInstances: { Animation } = animations.Fists:GetChildren() :: { Animation }
		local currentAnimation: Animation = animationInstances[math.random(#animationInstances)]:Clone()
		local currentTrack: AnimationTrack = humanoid:LoadAnimation(currentAnimation)
		local runAnimations: boolean = true

		task.spawn(function()
			while runAnimations do
				currentTrack:Play()
				currentTrack.Stopped:Wait()
				currentTrack:Destroy()
				currentAnimation = animationInstances[math.random(#animationInstances)]:Clone()
				currentTrack = humanoid:LoadAnimation(currentAnimation)
				task.wait(0.5)
			end
		end)

		task.spawn(function()
			humanoid:GetPropertyChangedSignal("MoveDirection"):Wait()
			if failed then
				return
			end
			runAnimations = false
			currentTrack:Stop()
			--Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
			store:dispatch(actions.switchPlayerEnemy(player.Name, nil))
		end)

		task.wait(1)

		while
			runAnimations
			and humanoid:IsDescendantOf(game)
			and selectors.isPlayerLoaded(store:getState(), player.Name)
			and selectors.getCurrentTarget(store:getState(), player.Name) == dummy
		do
			store:dispatch(
				actions.incrementPlayerStat(
					humanoid.Parent.Name,
					"Fear",
					fear * selectors.getStat(store:getState(), player.Name, "PetFearMultiplier")
				)
			)
			task.wait(1)
		end

		--Remotes.Server:Get("SendNPCHealthBar"):SendToPlayer(player, NPCUI, false)
	end)
end

for _, dummy in CollectionService:GetTagged "Dummy" do
	handleDummy(dummy)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(handleDummy)

return 0
