-- Ballas Gang Resource Manifest
-- Framework: ESX Legacy
-- FiveM resource definition

fx_version 'cerulean'
game 'gta5'

author 'OpenHands'
description 'Ballas Gang Job - garage, boss menu, territory blip (ESX Legacy)'
version '2.0.0'

-- Shared scripts: ESX imports MUST load first so the `ESX` shared object is
-- available to config.lua and the client/server files. Then our own config.
shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

-- ESX Legacy is the only hard dependency. esx_society / esx_menu_default are
-- required for the boss menu but are started in server.cfg ordering rather
-- than declared here (declaring optional addons can break servers without them).
dependencies {
    'es_extended'
}

lua54 'yes'
