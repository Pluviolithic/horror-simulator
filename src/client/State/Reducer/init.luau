local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)

local reducers = {
	Players = require(ReplicatedStorage.Common.State.Reducer.Players),
}

return Rodux.combineReducers(reducers)
