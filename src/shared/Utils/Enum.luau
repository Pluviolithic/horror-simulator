local CustomEnum = setmetatable({}, {
	__index = Enum,
})

CustomEnum.ReplicationRules = {
	All = 5000,
	None = 5001,
	Individual = 5002,
}

return CustomEnum
