local Players = game:GetService "Players"
local BadgeService = game:GetService "BadgeService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

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

return 0
