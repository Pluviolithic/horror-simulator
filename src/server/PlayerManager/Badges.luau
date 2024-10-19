local Players = game:GetService "Players"
local BadgeService = game:GetService "BadgeService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local badgeIDs = ReplicatedStorage.Config.Badges

local function awardJoinBadge(player)
	if not BadgeService:UserHasBadgeAsync(player.UserId, badgeIDs.Welcome.Value) then
		BadgeService:AwardBadge(player.UserId, badgeIDs.Welcome.Value)
	end
end

Players.PlayerAdded:Connect(awardJoinBadge)
for _, player in Players:GetPlayers() do
	task.spawn(awardJoinBadge, player)
end

for areaName, areaZone in regionUtils.getRegions() do
	if not badgeIDs:FindFirstChild(areaName) then
		continue
	end
	areaZone.playerEntered:Connect(function(player)
		if not BadgeService:UserHasBadgeAsync(player.UserId, badgeIDs[areaName].Value) then
			BadgeService:AwardBadge(player.UserId, badgeIDs[areaName].Value)
		end
	end)
end

return 0
