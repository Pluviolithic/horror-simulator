local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Enum = require(ReplicatedStorage.Common.Utils.Enum)

-- assumes individual unless otherwise specified
return {
	addPlayer = Enum.ReplicationRules.All,
	removePlayer = Enum.ReplicationRules.All,
}
