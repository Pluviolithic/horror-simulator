local ReplicatedStorage = game:GetService "ReplicatedStorage"
local permissionList = require(ReplicatedStorage.Common.PermissionList)

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == "DefaultAdmin" and not permissionList.Admins[context.Executor.UserId] then
			return "You don't have permission to run this command"
		end
	end)
end
