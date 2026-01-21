--[[
    ____  _  ___  __  _          _         
   |  _ \| || \ \/ / | |    __ _| |__  ___ 
   | |_) | || |_\  /  | |   / _` | '_ \/ __|
   |  _ <|__   _/  \  | |__| (_| | |_) \__ \
   |_| \_\  |_|/_/\_\ |_____\__,_|_.__/|___/
   
   Outfit Bag v1.0.0
   Save your favorite outfits
]]

fx_version 'cerulean'
game 'gta5'

author 'R4X Labs'
description 'Outfit Bag - Save and load your outfits'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'es_extended'
}
