local ReplicatedStorage = game:GetService "ReplicatedStorage"
local permissionList = require(ReplicatedStorage.Common.PermissionList)

return function(registry)
	registry:RegisterHook("BeforeRun", function(context): string?
		if
			(context.Group == "DefaultAdmin" or context.Group == "DefaultDebug" or context.Group == "DefaultUtil")
			and not permissionList.Admins[context.Executor.UserId]
		then
			return "You don't have permission to run this command"
		end
		return nil
	end)
end
