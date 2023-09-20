fx_version 'cerulean'
game 'gta5' 


author 'Tony'
description 'Tony Lockers'
version '1.0'
lua54 'yes'

shared_scripts{
	'@ox_lib/init.lua',
	'config.lua'
}
client_script {
	'client/main.lua'
}

server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

dependencies{
	'ox_lib'
}
