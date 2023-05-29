local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce, None = Immut.produce, Immut.None

return Rodux.createReducer({}, {
    addPlayer = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = Dict.mergeDeep(defaultStates.Pets, action.profileData.Pets)
        end)
    end,
    removePlayer = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = None
        end)
    end,
    resetPlayerData = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = defaultStates.Pets
        end)
    end,
    givePlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = {
                OwnedPets = Dict.map(action.petsToGive, function(value, key)
                    return value + (state[action.playerName].OwnedPets[key] or 0), key
                end),
                FoundPets = Dict.map(action.petsToGive, function(_, key)
                    return true, key
                end),
            }
        end)
    end,
    deletePlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName].OwnedPets = Dict.map(action.petsToDelete, function(value, key)
                local newOwnedAmount = (state[action.playerName].OwnedPets[key] or 0) - value
                if newOwnedAmount < 1 then
                    newOwnedAmount = None
                end
                return newOwnedAmount, key
            end)
        end)
    end,
    equipPlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName].EquippedPets = Dict.map(action.petsToEquip, function(value, key)
                return value + (state[action.playerName].EquippedPets[key] or 0), key
            end)
        end)
    end,
    unequipPlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName].EquippedPets = Dict.map(action.petsToUnequip, function(value, key)
                local newEquipAmount = (state[action.playerName].EquippedPets[key] or 0) - value
                if newEquipAmount < 1 then
                    newEquipAmount = None
                end
                return newEquipAmount, key
            end)
        end)
    end,
    lockPlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName].LockedPets = Dict.map(action.petsToLock, function(value, key)
                return value + (state[action.playerName].LockedPets[key] or 0), key
            end)
        end)
    end,
    unlockPlayerPets = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = Dict.map(action.petsToUnlock, function(value, key)
                local newLockAmount = (state[action.playerName].LockedPets[key] or 0) - value
                if newLockAmount < 1 then
                    newLockAmount = None
                end
                return newLockAmount, key
            end)
        end)
    end,
})
