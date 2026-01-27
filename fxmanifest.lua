fx_version 'cerulean'
game 'gta5'

name 'bs__coppertheft'
description 'Copper Theft Script for Qbox Framework'
author 'Custom'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core',
}
