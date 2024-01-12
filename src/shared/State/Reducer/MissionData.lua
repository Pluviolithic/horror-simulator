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
			draft[action.playerName] = table.clone(defaultStates.MissionData)
		end)
	end,
	startMission = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.areaName].Active = true
		end)
	end,
	disableMissionRewardPopup = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.areaName].ViewedRewardPopup = true
		end)
	end,
	completeMission = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.areaName].Active = false
			local nextMissionRequirements = missionRequirements[action.areaName]:FindFirstChild(
				tostring(state[action.playerName][action.areaName].CurrentMissionNumber + 1)
			)
			if nextMissionRequirements then
				draft[action.playerName][action.areaName].CurrentMissionProgress = 0
				draft[action.playerName][action.areaName].CurrentMissionNumber += 1
			elseif action.skipped then
				draft[action.playerName][action.areaName].CurrentMissionProgress =
					missionRequirements[action.areaName][tostring(
						state[action.playerName][action.areaName].CurrentMissionNumber
					)].Requirements.Value
			end
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
			if not playerRegion or not state[action.playerName][playerRegion].Active then
				return
			end
			local currentMissionRequirements =
				missionRequirements[playerRegion][tostring(state[action.playerName][playerRegion].CurrentMissionNumber)]
			if currentMissionRequirements:FindFirstChild "AnyPet" then
				if
					draft[action.playerName][playerRegion].CurrentMissionProgress
					~= currentMissionRequirements.Requirements.Value
				then
					draft[action.playerName][playerRegion].CurrentMissionProgress += #action.petRarities
				end

				draft[action.playerName][playerRegion].CurrentMissionProgress = math.min(
					draft[action.playerName][playerRegion].CurrentMissionProgress,
					currentMissionRequirements.Requirements.Value
				)
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
	rebirthPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.MissionData)
		end)
	end,
})
