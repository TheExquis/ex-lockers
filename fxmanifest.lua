fx_version 'cerulean'
game 'gta5' 


author 'Tony'
description 'Tony Lockers'
version '1.0'


shared_scripts{
	'config.lua'
}
client_script {
	'client/main.lua'
}

server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}
