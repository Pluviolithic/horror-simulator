local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local actions = require(StarterPlayer.StarterPlayerScripts.Client.State.Actions)

local player = Players.LocalPlayer
local regionPriorities = ReplicatedStorage.Config.Audio.SoundRegionPriorities
local regionsAndPriorities = {}

-- initialize priority values for comparison later
for _, regionPriority in regionPriorities:GetChildren() do
	regionsAndPriorities[regionPriority.Name] = regionPriority.Value
end

-- listen for changes to the player's region list
store.changed:connect(function(newState, oldState)
	local oldSoundRegions = selectors.getAudioData(oldState, player.Name)
	local newSoundRegions = selectors.getAudioData(newState, player.Name)
	local highestPriority, associatedSoundRegion = -1, nil

	-- verify whether this actually does anything
	if
		Sift.Array.equals(
			Sift.Dictionary.keys(oldSoundRegions.OccupiedSoundRegions),
			Sift.Dictionary.keys(newSoundRegions.OccupiedSoundRegions)
		)
	then
		return
	end

	for region, priority in regionsAndPriorities do
		if not newSoundRegions.OccupiedSoundRegions[region] then
			continue
		end
		-- compare other regions to the current highest priority
		if priority > highestPriority then
			highestPriority = priority
			associatedSoundRegion = region
		end
	end

	if highestPriority == -1 and newSoundRegions.PrimarySoundRegion then
		-- the player is not in a sound region, so set the primary sound region to nil
		store:dispatch(actions.setPrimarySoundRegion(player.Name, nil))
	elseif newSoundRegions.PrimarySoundRegion ~= associatedSoundRegion then
		-- the player is in a sound region with a higher priority than the current primary sound region
		store:dispatch(actions.setPrimarySoundRegion(player.Name, associatedSoundRegion))
	end
end)

return 0
