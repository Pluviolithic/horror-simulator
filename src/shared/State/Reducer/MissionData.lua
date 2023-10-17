local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local regionUtils = require(ReplicatedStorage.Common.Utils.Player.RegionUtils)

local produce = Immut.produce
local missionRequirements = ReplicatedStorage.Missions

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.MissionData, action.profileData.MissionData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = defaultStates.MissionData
		end)
	end,
	startMission = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.areaName].Active = true
		end)
	end,
	completeMission = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.areaName].Active = false
			draft[action.playerName][action.areaName].CurrentMissionNumber += 1
			draft[action.playerName][action.areaName].CurrentMissionProgress = 0
		end)
	end,
	logKilledEnemyType = function(state, action)
		return produce(state, function(draft)
			local playerRegion = regionUtils.getPlayerLocationName(action.playerName)
			if not playerRegion or not state[action.playerName][playerRegion].Active then
				return
			end
			local currentMissionRequirements =
				missionRequirements[playerRegion][tostring(state[action.playerName][playerRegion].CurrentMissionNumber)]

			if not currentMissionRequirements:FindFirstChild "Enemy" then
				return
			end

			if
				currentMissionRequirements.Enemy.Value == action.enemyType
				and draft[action.playerName][playerRegion].CurrentMissionProgress
					~= currentMissionRequirements.Requirements.Value
			then
				draft[action.playerName][playerRegion].CurrentMissionProgress += 1
			end
		end)
	end,
	logPurchasedWeaponType = function(state, action)
		return produce(state, function(draft)
			local playerRegion = regionUtils.getPlayerLocationName(action.playerName)
			if not playerRegion or not state[action.playerName][playerRegion].Active then
				return
			end
			local currentMissionRequirements =
				missionRequirements[playerRegion][tostring(state[action.playerName][playerRegion].CurrentMissionNumber)]

			if not currentMissionRequirements:FindFirstChild "Weapon" then
				return
			end

			if
				draft[action.playerName][playerRegion].CurrentMissionProgress
				~= currentMissionRequirements.Requirements.Value
			then
				draft[action.playerName][playerRegion].CurrentMissionProgress += 1
			end
		end)
	end,
	logHatchedPetRarities = function(state, action)
		return produce(state, function(draft)
			local playerRegion = regionUtils.getPlayerLocationName(action.playerName)
			print("logging a pet hatching event from the " .. playerRegion .. " area")
			if not playerRegion or not state[action.playerName][playerRegion].Active then
				return
			end
			local currentMissionRequirements =
				missionRequirements[playerRegion][tostring(state[action.playerName][playerRegion].CurrentMissionNumber)]
			print "checking current mission type"
			if currentMissionRequirements:FindFirstChild "AnyPet" then
				print "mission is anypet type"
				if
					draft[action.playerName][playerRegion].CurrentMissionProgress
					~= currentMissionRequirements.Requirements.Value
				then
					print "updating progress"
					draft[action.playerName][playerRegion].CurrentMissionProgress += 1
				end
			elseif currentMissionRequirements:FindFirstChild "PetRarity" then
				for _, rarity in action.petRarities do
					if rarity ~= currentMissionRequirements.PetRarity.Value then
						continue
					end

					if
						draft[action.playerName][playerRegion].CurrentMissionProgress
						~= currentMissionRequirements.Requirements.Value
					then
						draft[action.playerName][playerRegion].CurrentMissionProgress += 1
					end
				end
			end
		end)
	end,
})
