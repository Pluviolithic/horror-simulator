local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server
local common = ReplicatedStorage.Common

local Rodux = require(common.lib.Rodux)
local reducer = require(common.State.Reducer)
local middleware = require(server.State.Middleware)
local defaultStates = require(common.State.DefaultStates)

return Rodux.Store.new(reducer, defaultStates.GameState, middleware)
