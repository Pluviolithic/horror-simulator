local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local TeleportService = game:GetService "TeleportService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)

game:BindToClose(function()
	if RunService:IsStudio() then
		return
	end

	Remotes.Server:Get("NotifyOfShutdown"):SendToAllPlayers()

	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		local waitTime = 5
		Players.PlayerAdded:Connect(function(player)
			task.wait(waitTime)
			waitTime /= 2
			TeleportService:Teleport(game.PlaceId, player)
		end)
		for _, player in Players:GetPlayers() do
			TeleportService:Teleport(game.PlaceId, player)
			task.wait(waitTime)
			waitTime /= 2
		end
		return
	end

	local reservedServer = TeleportService:ReserveServer(game.PlaceId)
	Players.PlayerAdded:Connect(function(player)
		TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServer, { player })
	end)

	TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServer, Players:GetPlayers())

	while next(Players:GetPlayers()) do
		task.wait(1)
	end
end)

return 0
