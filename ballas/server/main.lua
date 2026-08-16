-- ============================================================================
-- Ballas Gang Resource - Server
-- Framework: QBCore
-- Responsibilities:
--   * Authorize vehicle spawn requests (job + grade checks).
--   * Spawn the vehicle at the garage spawn point with purple paint + plate.
--   * Expose a debug-grade lookup if needed.
-- All privilege checks happen server-side; the client is never trusted.
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local JobName = Config.JobName

-- Returns the minimum grade required to spawn `model`, or nil if unknown.
local function MinGradeForModel(model)
    for _, v in ipairs(Config.Vehicles) do
        if v.model == model then
            return v.grade
        end
    end
    return nil
end

-- Generates a unique-ish purple-themed plate for the vehicle.
local function MakePlate()
    local base = 'BLLS' .. math.random(1000, 9999)
    return string.sub(base, 1, 8)
end

-- ----------------------------------------------------------------------------
-- Vehicle spawn handler
-- ----------------------------------------------------------------------------
RegisterNetEvent('ballas:server:SpawnVehicle', function(model)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Job check.
    if Player.PlayerData.job.name ~= JobName then
        DropPlayer(src, 'Ballas: attempted spawn without job') -- or just Notify
        return
    end

    -- Grade check: player grade must be >= the model's required grade.
    local playerGrade = Player.PlayerData.job.grade.level or 0
    local required = MinGradeForModel(model)
    if not required then
        return
    end
    if playerGrade < required then
        TriggerClientEvent('QBCore:Notify', src,
            ('Your rank is too low for the %s.'):format(model), 'error')
        return
    end

    -- Hash the model (client hashes are unreliable, do it here).
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid vehicle model.', 'error')
        return
    end

    local plate = MakePlate()
    local spawn = Config.Locations.Garage.spawn

    -- Create the vehicle server-side via QBCore's vehicle spawn helper.
    -- This ensures the entity is networked and owned by the server, then
    -- transferred to the player once created.
    QBCore.Functions.SpawnVehicle(model, function(veh)
        if not veh or not DoesEntityExist(veh) then
            TriggerClientEvent('QBCore:Notify', src, 'Failed to spawn vehicle.', 'error')
            return
        end

        -- Apply paint server-side so it is authoritative.
        SetVehicleColours(veh, Config.VehiclePrimaryColor, Config.VehicleSecondaryColor)
        SetVehicleExtraColours(veh, Config.VehiclePrimaryColor, 0)

        -- Plate + properties.
        SetVehicleNumberPlateText(veh, plate)
        SetEntityHeading(veh, spawn.w)
        SetVehicleFuelLevel(veh, 100.0)
        SetVehicleDirtLevel(veh, 0.0)

        -- Lock & keys via QBCore vehicle keys (optional integration).
        TriggerEvent('vehiclekeys:server:SetVehicleOwner', plate)

        -- Hand off to the client for seat placement / final polish.
        local netId = NetworkGetNetworkIdFromEntity(veh)
        TriggerClientEvent('ballas:client:VehicleSpawned', src, netId, plate)
    end, spawn, true)
end)

-- ----------------------------------------------------------------------------
-- Boss-menu authorization guard
-- If qb-bossmenu is not enforcing job grade, we re-assert here.
-- ----------------------------------------------------------------------------
RegisterNetEvent('ballas:server:CheckBoss', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local ok = Player.PlayerData.job.name == JobName
        and (Player.PlayerData.job.grade.level or 0) == Config.BossGrade
    TriggerClientEvent('ballas:client:BossResult', src, ok)
end)

-- Quick log on resource start.
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        print(('^5[Ballas]^7 Resource started. Job: %s, Boss grade: %d'):format(
            JobName, Config.BossGrade))
    end
end)
