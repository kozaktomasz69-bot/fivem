-- ============================================================================
-- Ballas Gang Resource - Server
-- Framework: ESX Legacy
-- Responsibilities:
--   * Authorize vehicle spawn requests (job + grade checks).
--   * Spawn the vehicle at the garage spawn point with purple paint + plate.
--   * Register the society so esx_society manages the gang's bank account.
--   * Provide society deposit/withdraw that talks to esx_addon_account.
-- All privilege checks happen server-side; the client is never trusted.
-- ============================================================================

ESX = exports['es_extended']:getSharedObject()
local JobName = Config.JobName
local SocietyAccount = Config.SocietyAccount

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
-- Register the society on resource start.
-- esx_society uses the account name `society_<job>` for both money and data.
-- ----------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end

    if GetResourceState('esx_society') == 'started' then
        TriggerEvent('esx_society:registerSociety',
            JobName,           -- name
            'Ballas',          -- label
            SocietyAccount,    -- account (addon_account name)
            SocietyAccount,    -- datastore
            SocietyAccount,    -- inventory
            { type = 'private' })
    end

    print(('^5[Ballas]^7 Resource started. Job: %s, Boss grade name: %s'):format(
        JobName, Config.BossGradeName))
end)

-- ----------------------------------------------------------------------------
-- Vehicle spawn handler
-- ----------------------------------------------------------------------------
RegisterNetEvent('ballas:server:SpawnVehicle', function(model)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Job + grade check (server-authoritative).
    local job = xPlayer.getJob()
    if job.name ~= JobName then
        DropPlayer(src, 'Ballas: attempted spawn without the gang job')
        return
    end

    local playerGrade = job.grade or 0
    local required = MinGradeForModel(model)
    if not required then
        TriggerClientEvent('esx:showNotification', src, 'Unknown vehicle model.')
        return
    end
    if playerGrade < required then
        TriggerClientEvent('esx:showNotification', src,
            ('Your rank is too low for the %s.'):format(model))
        return
    end

    -- NOTE: model validation via IsModelInCdimage/IsModelAVehicle is NOT done
    -- here - those are CLIENT-ONLY natives and would error on the server. The
    -- roster check above (MinGradeForModel) already guarantees `model` is one
    -- of our whitelisted Config.Vehicles entries, which is sufficient.

    local plate = MakePlate()
    local spawn = Config.Locations.Garage.spawn

    -- Server-side vehicle creation via ESX OneSync. This is server-safe and
    -- returns the network id directly in the callback. We do NOT call any
    -- vehicle visual natives here (SetVehicleColours, SetVehicleFuelLevel,
    -- etc. are client-only) - the client applies paint/plate/fuel/dirt in the
    -- 'ballas:client:VehicleSpawned' handler.
    ESX.OneSync.SpawnVehicle(model, vector3(spawn.x, spawn.y, spawn.z), spawn.w,
        { plate = plate }, function(networkId)
            -- networkId is enough; verify the entity exists (shared native).
            local veh = NetworkGetEntityFromNetworkId(networkId)
            if not veh or not DoesEntityExist(veh) then
                TriggerClientEvent('esx:showNotification', src, 'Failed to spawn vehicle.')
                return
            end

            -- Optional: hand keys via a vehicle-keys resource if present.
            if GetResourceState('esx_vehiclekey') == 'started' then
                TriggerEvent('esx_vehiclekey:giveKeys', plate, src)
            end

            -- Hand off to the client for seat placement + visual config.
            TriggerClientEvent('ballas:client:VehicleSpawned', src, networkId, plate)
        end, 'automobile')
end)

-- ----------------------------------------------------------------------------
-- Society money: deposit / withdraw.
-- These talk directly to esx_addon_account so the gang's bank balance stays
-- correct even if a UI resource is swapped out. esx_society's boss menu uses
-- the same account, so the two never desync.
-- ----------------------------------------------------------------------------
local function GetSocietyAccount(cb)
    if GetResourceState('esx_addonaccount') ~= 'started' then
        cb(nil)
        return
    end
    TriggerEvent('esx_addonaccount:getSharedAccount', SocietyAccount, cb)
end

RegisterNetEvent('ballas:server:DepositMoney', function(amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    if job.name ~= JobName or job.grade_name ~= Config.BossGradeName then
        TriggerClientEvent('esx:showNotification', src, 'Only the O.G. can deposit.')
        return
    end

    amount = ESX.Math.Round(tonumber(amount) or 0)
    if amount <= 0 then return end

    if xPlayer.getAccount('money').money < amount then
        TriggerClientEvent('esx:showNotification', src, 'You do not have that much cash.')
        return
    end

    xPlayer.removeAccountMoney('money', amount)
    GetSocietyAccount(function(account)
        if not account then
            -- Addon account missing: refund the player.
            xPlayer.addAccountMoney('money', amount)
            TriggerClientEvent('esx:showNotification', src,
                'Society account is not configured.')
            return
        end
        account.addMoney(amount)
        TriggerClientEvent('esx:showNotification', src,
            ('Deposited $%s to the society.'):format(amount))
    end)
end)

RegisterNetEvent('ballas:server:WithdrawMoney', function(amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job = xPlayer.getJob()
    if job.name ~= JobName or job.grade_name ~= Config.BossGradeName then
        TriggerClientEvent('esx:showNotification', src, 'Only the O.G. can withdraw.')
        return
    end

    amount = ESX.Math.Round(tonumber(amount) or 0)
    if amount <= 0 then return end

    GetSocietyAccount(function(account)
        if not account then
            TriggerClientEvent('esx:showNotification', src,
                'Society account is not configured.')
            return
        end
        if account.money < amount then
            TriggerClientEvent('esx:showNotification', src,
                'The society does not have that much money.')
            return
        end
        account.removeMoney(amount)
        xPlayer.addAccountMoney('money', amount)
        TriggerClientEvent('esx:showNotification', src,
            ('Withdrew $%s from the society.'):format(amount))
    end)
end)
