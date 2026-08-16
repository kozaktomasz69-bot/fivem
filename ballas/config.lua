-- ============================================================================
-- Ballas Gang Resource - Configuration (Shared)
-- Framework: QBCore
-- This file is shared (loaded on both client and server) so any value here is
-- available in both contexts without duplicating definitions.
-- ============================================================================

Config = {}

-- General resource flags -----------------------------------------------------
Config.Debug = false                 -- print extra diagnostics when true
Config.Framework = 'qbcore'          -- framework selector (kept for portability)

-- Job definition -------------------------------------------------------------
-- Mirrors what should be registered in qb-core/shared/jobs.lua (see SQL/README).
Config.JobName = 'ballas'

-- Ranks/grades from lowest to highest. The index == grade number in the DB.
Config.Ranks = {
    [0] = { name = 'thug',       label = 'Thug' },        -- Grade 0
    [1] = { name = 'hustler',    label = 'Hustler' },     -- Grade 1
    [2] = { name = 'shotcaller', label = 'Shot Caller' }, -- Grade 2
    [3] = { name = 'og',         label = 'O.G.' },        -- Grade 3 (boss)
}

Config.BossGrade = 3                 -- only this grade may open the boss menu
Config.MinGradeForGarage = 0         -- every member can use the garage (roster-limited)

-- Colors ---------------------------------------------------------------------
-- Vehicle paint colors. Purple is the Ballas signature.
Config.VehiclePrimaryColor = 27      -- Purple primary
Config.VehicleSecondaryColor = 27    -- Purple secondary

-- Blip color/sprite ----------------------------------------------------------
Config.Blip = {
    color  = 27,                     -- Purple
    sprite = 84,                     -- Gang/turf-style sprite (crown-ish)
    scale  = 1.0,
    label  = 'Ballas Territory',
    -- Grove Street / Davis area
    coords = vector3(117.32, -1944.66, 21.13),
}

-- Vehicle roster by minimum grade --------------------------------------------
-- A member of grade N may spawn ANY vehicle whose `grade` is <= N.
Config.Vehicles = {
    { model = 'bmx',            label = 'BMX',           grade = 0 }, -- Thug
    { model = 'voodoo',         label = 'Voodoo',        grade = 1 }, -- Hustler
    { model = 'buccaneer',      label = 'Buccaneer',     grade = 2 }, -- Shot Caller
    { model = 'schafter6',      label = 'Schafter V12',  grade = 3 }, -- O.G.
}

-- Interaction points ---------------------------------------------------------
Config.Locations = {
    -- Garage spawn point. Vehicle is placed at this coord facing `heading`.
    Garage = {
        marker  = vector3(110.52, -1948.91, 21.10),
        spawn   = vector4(110.52, -1948.91, 21.10, 70.0),
        drawDist = 20.0,  -- start drawing marker within this distance
        interactDist = 1.5,
    },
    -- Boss menu (society management) marker.
    BossMenu = {
        marker    = vector3(123.04, -1935.59, 21.13),
        drawDist  = 10.0,
        interactDist = 1.5,
    },
}

-- Marker visual --------------------------------------------------------------
Config.Marker = {
    type    = 2,                      -- upside-down cone
    scale   = vector3(0.3, 0.3, 0.3),
    color   = { r = 138, g = 43, b = 226, a = 200 }, -- purple
    bobUp   = false,
}

-- Keybind to open the nearest menu when standing on a marker.
-- Uses the standard FiveM keybind system so players can rebind it.
Config.OpenKey = 'E'                 -- maps to INPUT_CONTEXT by default
