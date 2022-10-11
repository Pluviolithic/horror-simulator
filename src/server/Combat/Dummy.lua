local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)

local fightRange = 2

local function handleDummy(dummy)
	local clickDetector = dummy.Hitbox.ClickDetector
	local goalPosition = dummy.Hitbox.Position

	clickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if not humanoid then
			return
		end

		if store:getState().Players[player.Name].CurrentEnemy == dummy then
			return
		else
			store:dispatch(actions.switchPlayerEnemy(player.Name, dummy))
		end

		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)
		humanoid.MoveToFinished:Wait()

		while
			humanoid:IsDescendantOf(game)
			and store:getState().Players[player.Name]
			and store:getState().Players[player.Name].CurrentEnemy == dummy
		do
			task.wait(1)
			store:dispatch(actions.incrementPlayerStat(humanoid.Parent.Name, "Fear"))
		end
	end)
end

for _, dummy in ipairs(CollectionService:GetTagged "Dummy") do
	handleDummy(dummy)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(handleDummy)

return 0
