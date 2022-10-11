local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local store = require(server.State.Store)
local actions = require(server.State.Actions)

local fightRange = 2

local function runFight(humanoid)
	while humanoid:IsDescendantOf(game) do
		task.wait(1)
		store:dispatch(actions.incrementPlayerStat(humanoid.Parent.Name, "Fear"))
	end
end

local function handleDummy(dummy)
	local clickDetector = dummy.Hitbox.ClickDetector
	local goalPosition = dummy.Hitbox.Position

	clickDetector.MouseClick:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass "Humanoid"
		if not humanoid then
			return
		end
		humanoid:MoveTo(goalPosition + (humanoid.RootPart.Position - goalPosition).Unit * fightRange)
		humanoid.MoveToFinished:Wait()
		runFight(humanoid)
	end)
end

for _, dummy in ipairs(CollectionService:GetTagged "Dummy") do
	handleDummy(dummy)
end

CollectionService:GetInstanceAddedSignal("Dummy"):Connect(handleDummy)

return 0
