fx_version 'cerulean'
game 'gta5'

author 'Xoxo Pistols'
description 'Advanced Kill Ranking System with Discord Integration'
version '1.0.0'

shared_scripts {
    'config.lua',
    'bridge.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'

dependencies {
    'oxmysql'
}
