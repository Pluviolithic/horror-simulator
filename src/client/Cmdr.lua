local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Promise = require(ReplicatedStorage.Common.lib.Promise)

Promise.new(function(resolve)
	local Cmdr = require(ReplicatedStorage:WaitForChild "CmdrClient")
	resolve(Cmdr)
end):andThen(function(Cmdr)
	Cmdr:SetActivationKeys { Enum.KeyCode.F2 }
	--Cmdr:RegisterHooksIn(ReplicatedStorage.Common.CommandHooks)
end)

return 0
