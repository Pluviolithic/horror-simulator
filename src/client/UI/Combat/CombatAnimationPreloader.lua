local ContentProvider = game:GetService "ContentProvider"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local animationsToPreload = {}
for _, animation in ReplicatedStorage.CombatAnimations:GetDescendants() do
	if animation:IsA "Animation" then
		table.insert(animationsToPreload, animation)
	end
end

task.spawn(ContentProvider.PreloadAsync, ContentProvider, animationsToPreload)

return 0
