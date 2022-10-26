local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local function handlePunchingBag(bag)
	local prompt = bag.HumanoidLockPart.Prompt
	local inUse = false

	prompt.PromptTriggered:Connect(function(_, player)
		local playerState = store:getState().Players[player.Name]
		local cancelled = false
		if inUse or playerState.CurrentPunchingBag or playerState.Fear < playerState.RequiredFear then
			return
		end
		store:dispatch(actions.setCurrentPunchingBag(player.Name, bag))
		Remotes.Server:Get("SetControlsEnabled"):SendToPlayer(player, false)

		local connection
		connection = Remotes:Get("CancelExchange"):Connect(function(cancellingPlayer)
			if cancellingPlayer == player then
				cancelled = true
				connection:Disconnect()
			end
		end)

		while
			store:getState().Players[player.Name].Fear >= store:getState().Players[player.Name].RequiredFear
			and not cancelled
		do
			-- change "magic number 5" to be based on gamepasses
			store:dispatch(actions.incrementPlayerStat(player.Name, "Strength", 1))
			store:dispatch(actions.incrementPlayerStat(player.Name, "Fear", -5))
			store:dispatch(actions.updateRequiredFear(player.Name, 5))
			task.wait(0.6)
		end

		connection:Disconnect()
		--kick player
	end)
end

for _, punchingBag in ipairs(CollectionService:GetTagged "PunchingBag") do
	handlePunchingBag(punchingBag)
end

CollectionService:GetInstanceAddedSignal("PunchingBag"):Connect(handlePunchingBag)
