local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Enum = require(ReplicatedStorage.Common.Utils.Enum)

-- maybe just assume individual unless otherwise specified?

return {
	addPlayer = Enum.ReplicationRules.All,
	removePlayer = Enum.ReplicationRules.All,

	equipWeapon = Enum.ReplicationRules.Individual,
	givePlayerPets = Enum.ReplicationRules.Individual,
	resetPlayerData = Enum.ReplicationRules.Individual,
	setPlayerHealth = Enum.ReplicationRules.Individual,
	givePlayerWeapon = Enum.ReplicationRules.Individual,
	switchPlayerEnemy = Enum.ReplicationRules.Individual,
	setPlayerMaxHealth = Enum.ReplicationRules.Individual,
	removePlayerWeapon = Enum.ReplicationRules.Individual,
	incrementPlayerStat = Enum.ReplicationRules.Individual,
	setCurrentPunchingBag = Enum.ReplicationRules.Individual,
	updatePlayerWithProfile = Enum.ReplicationRules.Individual,
}
