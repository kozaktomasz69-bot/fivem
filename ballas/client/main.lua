-- ============================================================================
-- Ballas Gang Resource - Client
-- Framework: QBCore
-- Responsibilities:
--   * Create the territory blip.
--   * Draw markers for the garage and boss menu.
--   * Open the garage menu (vehicle spawn, roster-limited by grade).
--   * Open the boss menu (society management) for O.G. only.
-- Performance: a single 0-wait loop checks player distance against the
-- handful of fixed markers, so no heavy threads are created.
-- ============================================================================

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob, PlayerGrade

-- Cached references (populated in LoadPlayer) to avoid per-frame calls.
local function RefreshPlayer()
    local Player = QBCore.Functions.GetPlayerData()
    PlayerJob  = Player and Player.job and Player.job.name or nil
    PlayerGrade = Player and Player.job and Player.job.grade and Player.job.grade.level or nil
end

-- Listen for job changes so cached grade stays accurate.
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if job then
        PlayerJob = job.name
        PlayerGrade = (job.grade and job.grade.level) or 0
    end
end)

RegisterNetEvent('QBCore:Client:SetPlayerData', function(data)
    if data and data.job then RefreshPlayer() end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', RefreshPlayer)
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
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
    return PlayerJob == Config.JobName
end

-- Returns true if the local player is the boss (O.G.).
local function IsBoss()
    return PlayerJob == Config.JobName and PlayerGrade == Config.BossGrade
end

-- Draws a single marker. Cheap helper so the main loop stays readable.
local function DrawMarkerAt(pos)
    local m = Config.Marker
    DrawMarker(m.type, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
        m.scale.x, m.scale.y, m.scale.z, m.color.r, m.color.g, m.color.b, m.color.a,
        m.bobUp, true, 2, false)
end

-- Builds the garage vehicle menu based on the player's current grade.
local function GetGarageOptions()
    local opts = {}
    for _, v in ipairs(Config.Vehicles) do
        if (PlayerGrade or -1) >= v.grade then
            opts[#opts + 1] = {
                title = v.label,
                description = ('Grade %d+'):format(v.grade),
                icon = 'fa-solid fa-car',
                -- Capture model in closure; called when selected.
                onSelect = function()
                    TriggerServerEvent('ballas:server:SpawnVehicle', v.model)
                end,
            }
        end
    end
    return opts
end

-- Opens the garage menu (uses ox_lib context menu if available, else a simple
-- registered NUI command. ox_lib is optional and gracefully degraded.)
local function OpenGarageMenu()
    if not IsBallas() then
        QBCore.Functions.Notify('You are not a Ballas member.', 'error')
        return
    end

    local options = GetGarageOptions()
    if #options == 0 then
        QBCore.Functions.Notify('No vehicles available at your rank.', 'error')
        return
    end

    -- Use ox_lib context menu if present; otherwise fall back to a basic list.
    if GetResourceState('ox_lib') == 'started' then
        exports['ox_lib']:registerContext({
            id = 'ballas_garage',
            title = 'Ballas Garage',
            options = options,
        })
        exports['ox_lib']:showContext('ballas_garage')
    else
        -- Minimal fallback: spawn the highest-tier vehicle the player owns.
        -- (Real servers should add ox_lib or implement a custom NUI list.)
        local top = options[#options]
        if top.onSelect then top.onSelect() end
    end
end

-- Opens the boss menu via qb-bossmenu (standard society management UI).
-- qb-bossmenu already handles deposit/withdraw/hire/fire/promote/demote; we
-- simply tell it to open for the 'ballas' job.
local function OpenBossMenu()
    if not IsBoss() then
        QBCore.Functions.Notify('Only the O.G. can access this.', 'error')
        return
    end

    -- qb-bossmenu exposes an export to open the menu for a given job.
    if GetResourceState('qb-bossmenu') == 'started' then
        TriggerEvent('qb-bossmenu:client:OpenMenu')
    else
        QBCore.Functions.Notify('qb-bossmenu resource is not running.', 'error')
    end
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
                QBCore.Functions.DrawText(g.marker.x, g.marker.y, g.marker.z + 0.5,
                    '[E] Open Garage')
                if IsControlJustReleased(0, 38) then -- E
                    OpenGarageMenu()
                end
            end
        end

        if dgBoss <= b.interactDist then
            if IsBoss() then
                QBCore.Functions.DrawText(b.marker.x, b.marker.y, b.marker.z + 0.5,
                    '[E] Boss Menu')
                if IsControlJustReleased(0, 38) then -- E
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

    -- Apply purple primary + secondary paint.
    SetVehicleColours(veh, Config.VehiclePrimaryColor, Config.VehicleSecondaryColor)
    SetVehicleExtraColours(veh, Config.VehiclePrimaryColor, 0)

    -- Plate is set server-side; ensure visible.
    SetVehicleNumberPlateText(veh, plate)

    -- Put the player in the driver seat.
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleEngineOn(veh, true, true, false)

    QBCore.Functions.Notify(('Vehicle spawned: %s'):format(plate), 'success')
end)
