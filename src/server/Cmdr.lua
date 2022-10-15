local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Cmdr = require(ServerScriptService.Server.lib.Cmdr)

Cmdr:RegisterCommandsIn(ServerScriptService.Server.Commands)
Cmdr:RegisterHooksIn(ReplicatedStorage.Common.CommandHooks)
Cmdr:RegisterDefaultCommands()

return 0
