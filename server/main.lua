local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent("ts-lockers:server:CreateLocker", function(code, area)
    local xPlayer = ESX.GetPlayerFromId(source)
    local branch = area
    local passcode = code
    local allowed = true
    if code and xPlayer then
        exports.oxmysql:query('SELECT * FROM tslockers WHERE branch = ?', {branch}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    if v.owner == xPlayer.getIdentifier() then
                        allowed = false
                    end
                end
                if allowed then
                    exports.oxmysql:insert('INSERT INTO tslockers (owner, password, branch) VALUES (?, ?, ?)', {xPlayer.getIdentifier(), passcode, branch}, function(id)
                        print(xPlayer.getName()..' Created A Locker in '..branch)
                        exports.ox_inventory:RegisterStash(id, "Locker No: "..id, 50, 5000000)
                        TriggerClientEvent('esx:showNotification', xPlayer.source, 'You Created Locker with Locker ID: ~r~'..id..'~s~')
                    end)
                else
                    TriggerClientEvent('esx:showNotification', xPlayer.source, 'You can only create 1 locker in this area')
                end
            else
                exports.oxmysql:insert('INSERT INTO tslockers (owner, password, branch) VALUES (?, ?, ?)', {xPlayer.getIdentifier(), passcode, branch}, function(id)
                    print(xPlayer.getName()..' Created A Locker in '..branch)
                    exports.ox_inventory:RegisterStash(id, "Locker No: "..id, 50, 5000000)
                    TriggerClientEvent('esx:showNotification', xPlayer.source, 'You Created Locker with Locker ID: ~r~'..id..'~s~')
                end)
            end
        end)
       
        
    end
end)

RegisterNetEvent('ts-lockers:server:DeleteLocker', function(id)
    local lockerid = id.lockerid
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and lockerid then
        exports.oxmysql:query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
                    if tonumber(v.lockerid) == tonumber(lockerid) and v.owner == xPlayer.getIdentifier() then
                        MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { v.lockerid })
                        exports.oxmysql:query('DELETE FROM tslockers WHERE lockerid = ?', {v.lockerid}, function(result)
                            print(xPlayer.getName()..'Deleted Locker ID: '..v.lockerid)
                        end)
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent('ts-lockers:LoadStashes', function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(50) end
        exports.oxmysql:query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
			        exports.ox_inventory:RegisterStash(v.lockerid, "Locker No: "..v.lockerid, 50, 5000000)
                end
            end
        end)
end)

RegisterNetEvent('ts-lockers:server:ChangePass', function(lid, pass)
    local lockerid = lid
    local password = pass
    local xPlayer = ESX.GetPlayerFromId(source)
    print(lockerid)
    if xPlayer and lockerid then
        exports.oxmysql:query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
                    if tonumber(v.lockerid) == tonumber(lockerid) then
                        if v.owner == xPlayer.getIdentifier() then
                        exports.oxmysql:update('UPDATE tslockers SET password = ? WHERE lockerid = ? ', {password, lockerid}, function(affectedRows)
                            if affectedRows then
                                xPlayer.showNotification('Password Changed')
                            end
                        end)
                    else
                        xPlayer.showNotification("You are not Authorized to change the password!")
                    end
                    end
                end
            end
        end)
    end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ts-lockers' or resourceName == GetCurrentResourceName() then
        while GetResourceState('ox_inventory') ~= 'started' do Wait(50) end
        exports.oxmysql:query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
			        exports.ox_inventory:RegisterStash(v.lockerid, "Locker No: "..v.lockerid, 50, 5000000)
                end
            end
        end)
    end
end)


ESX.RegisterServerCallback("ts-lockers:getLockers", function(source, cb, area)
    local branch = area
    exports.oxmysql:query('SELECT * FROM tslockers WHERE branch = ?', {branch}, function(result)
        if result[1] then
            for k,v in pairs(result) do
                local xPlayer = ESX.GetPlayerFromIdentifier(v.owner)
                if xPlayer then
                v["playername"] = xPlayer.getName()
                else
                    v["playername"] = "Not Online"
                end
            end
            cb(result)
        else
            cb(nil)
        end
    end)
end)
