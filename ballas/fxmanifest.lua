-- Ballas Gang Resource Manifest
-- Framework: QBCore
-- FiveM resource definition

fx_version 'cerulean'
game 'gta5'

author 'OpenHands'
description 'Ballas Gang Job - garage, boss menu, territory blip (QBCore)'
version '1.0.0'

-- Shared config must load first so client/server can reference it.
shared_script 'config.lua'

-- Framework dependency. Uses QBCore export; the resource starts
-- whenever the core is ready (and ox_lib if present for UI).
client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

-- Ensure QBCore is loaded before this resource.
dependencies {
    'qb-core'
}

lua54 'yes'
