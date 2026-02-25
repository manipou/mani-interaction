fx_version 'cerulean'
game 'gta5'

lua54 'yes'
author 'Jungurum Team - Mani'

-- ui_page 'http://localhost:5173/' -- Uncomment this if you are using Vite (live preview when developing)
ui_page 'web/build/index.html'

client_scripts {
    'client/**/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@jCore/imports.lua',
}

files {
    'config.lua',
    'web/build/index.html',
    'web/build/**/*'
}