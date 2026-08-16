-- ============================================================================
-- Ballas Gang Resource - Client
-- Framework: ESX Legacy
-- Responsibilities:
--   * Create the territory blip.
--   * Draw markers for the garage and boss menu.
--   * Open the garage menu (vehicle spawn, roster-limited by grade).
--   * Open the boss menu (esx_society) for the O.G. (boss grade) only.
-- Performance: a single 0-wait loop checks player distance against the
-- handful of fixed markers, so no heavy threads are created.
-- ============================================================================

-- ESX shared object. With @es_extended/imports.lua in shared_scripts this is
-- already defined as a global; the line below is a safe fallback for servers
-- that only use the legacy export.
ESX = exports['es_extended']:getSharedObject()

-- Cached copies of the player's job so we don't call into ESX every frame.
local PlayerJobName   = nil
local PlayerGrade     = nil
local PlayerGradeName = nil

-- Refresh the cached job fields from ESX.PlayerData.
local function RefreshPlayer()
    local job = ESX.PlayerData and ESX.PlayerData.job or nil
    if job then
        PlayerJobName   = job.name
        PlayerGrade     = job.grade
        PlayerGradeName = job.grade_name
    end
end

-- ESX fires these events when the player loads or their job changes.
RegisterNetEvent('esx:playerLoaded', RefreshPlayer)
RegisterNetEvent('esx:setJob', function(job)
    if job then
        PlayerJobName   = job.name
        PlayerGrade     = job.grade
        PlayerGradeName = job.grade_name
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        -- PlayerData may already be populated if the player was already in.
        RefreshPlayer()
    end
end)

-- ----------------------------------------------------------------------------
-- Blip creation (run once).
-- ----------------------------------------------------------------------------
CreateThread(function()
    local b = Config.Blip
    local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
    SetBlipSprite(blip, b.sprite)
    SetBlipColour(blip, b.color)
    SetBlipScale(blip, b.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.label)
    EndTextCommandSetBlipName(blip)
end)

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

-- Returns true if the local player is a Ballas member.
local function IsBallas()
    return PlayerJobName == Config.JobName
end

-- Returns true if the local player is the boss (O.G.).
-- ESX exposes both the numeric grade (job.grade) and the grade name
-- (job.grade_name). We check the name because esx_society authorizes on it.
local function IsBoss()
    return PlayerJobName == Config.JobName
        and PlayerGradeName == Config.BossGradeName
        and (PlayerGrade or -1) >= Config.BossGrade
end

-- Draws a single marker. Cheap helper so the main loop stays readable.
local function DrawMarkerAt(pos)
    local m = Config.Marker
    DrawMarker(m.type, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
        m.scale.x, m.scale.y, m.scale.z, m.color.r, m.color.g, m.color.b, m.color.a,
        m.bobUp, true, 2, false)
end

-- Floating help text shown when standing on a marker.
local function DrawHelpText(pos, text)
    ESX.Game.Utils.DrawText3D(vector3(pos.x, pos.y, pos.z), text, 0.7)
end

-- Builds the garage vehicle elements for the ESX menu based on grade.
local function GetGarageElements()
    local elements = {}
    for _, v in ipairs(Config.Vehicles) do
        if (PlayerGrade or -1) >= v.grade then
            elements[#elements + 1] = {
                label = ('%s  (Grade %d+)'):format(v.label, v.grade),
                value = v.model,
            }
        end
    end
    return elements
end

-- Opens the garage menu using ESX's built-in UI (no extra dependencies).
local function OpenGarageMenu()
    if not IsBallas() then
        ESX.ShowNotification('You are not a Ballas member.')
        return
    end

    local elements = GetGarageElements()
    if #elements == 0 then
        ESX.ShowNotification('No vehicles available at your rank.')
        return
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ballas_garage', {
        title    = 'Ballas Garage',
        align    = 'top-left',
        elements = elements,
    }, function(data, menu)
        local model = data.current.value
        menu.close()
        TriggerServerEvent('ballas:server:SpawnVehicle', model)
    end, function(data, menu)
        menu.close()
    end)
end

-- Opens the boss menu via esx_society (deposit/withdraw/hire/fire/promote/demote).
-- esx_society itself re-checks that the player's grade_name is in BossGrades,
-- so this is safe even if our client check is somehow bypassed.
local function OpenBossMenu()
    if not IsBoss() then
        ESX.ShowNotification('Only the O.G. can access this.')
        return
    end

    if GetResourceState('esx_society') ~= 'started' then
        ESX.ShowNotification('esx_society is not running.')
        return
    end

    TriggerEvent('esx_society:openBossMenu', Config.JobName, function(menu)
        ESX.UI.Menu.CloseAll()
    end, { wash = false })
end

-- ----------------------------------------------------------------------------
-- Main interaction loop
-- A single thread with Wait(0) only when very close to a marker; otherwise it
-- yields to keep CPU usage low.
-- ----------------------------------------------------------------------------
CreateThread(function()
    local g = Config.Locations.Garage
    local b = Config.Locations.BossMenu
    local ped = PlayerPedId()

    while true do
        -- Refresh ped cache each iteration (cheap), coords only when needed.
        local pos = GetEntityCoords(ped)

        local dgGarage = #(pos - g.marker)
        local dgBoss   = #(pos - b.marker)

        -- If far from both points, sleep longer to save CPU.
        if dgGarage > g.drawDist and dgBoss > b.drawDist then
            Wait(800)
            ped = PlayerPedId() -- refresh ped in case of respawn/swap
            goto continue
        end

        -- Draw whichever markers are in range.
        if dgGarage <= g.drawDist then DrawMarkerAt(g.marker) end
        if dgBoss   <= b.drawDist then DrawMarkerAt(b.marker)   end

        -- Interaction prompts.
        if dgGarage <= g.interactDist then
            if IsBallas() then
                DrawHelpText(g.marker, '[E] Open Garage')
                if IsControlJustReleased(0, 38) then -- E / INPUT_CONTEXT
                    OpenGarageMenu()
                end
            end
        end

        if dgBoss <= b.interactDist then
            if IsBoss() then
                DrawHelpText(b.marker, '[E] Boss Menu')
                if IsControlJustReleased(0, 38) then -- E / INPUT_CONTEXT
                    OpenBossMenu()
                end
            end
        end

        Wait(0) -- tight loop only while near a marker
        ::continue::
    end
end)

-- ----------------------------------------------------------------------------
-- Receive spawned vehicle from server and finalize on client
-- (paint, plate, hand to player).
-- ----------------------------------------------------------------------------
RegisterNetEvent('ballas:client:VehicleSpawned', function(netId, plate)
    local veh = NetworkGetEntityFromNetworkId(netId)
    -- Wait for the entity to exist on this client.
    local tries = 0
    while not DoesEntityExist(veh) and tries < 100 do
        Wait(10)
        veh = NetworkGetEntityFromNetworkId(netId)
        tries = tries + 1
    end
    if not DoesEntityExist(veh) then return end

    -- Apply purple primary + secondary paint (client-side natives; the server
    -- cannot use these).
    SetVehicleColours(veh, Config.VehiclePrimaryColor, Config.VehicleSecondaryColor)
    SetVehicleExtraColours(veh, Config.VehiclePrimaryColor, 0)

    -- Plate + clean + full fuel, all applied here (server can't touch visuals).
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleFuelLevel(veh, 100.0)

    -- Put the player in the driver seat.
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleEngineOn(veh, true, true, false)

    ESX.ShowNotification(('Vehicle spawned: %s'):format(plate))
end)
