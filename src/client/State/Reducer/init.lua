local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)

local reducerModules = script:GetChildren()
local reducers = {}

for _, reducer in ipairs(reducerModules) do
	reducers[reducer.Name] = require(reducer)
end

return Rodux.combineReducers(reducers)
