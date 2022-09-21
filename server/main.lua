local ESX,QBCore = nil,nil
CreateThread(function ()
    if GetResourceState('es_extended') ~= 'missing' and GetResourceState('es_extended') ~= 'unknown' then
        while GetResourceState('es_extended') ~= 'started' do Wait(0) end
        ESX = exports['es_extended']:getSharedObject()
    end
    if GetResourceState('qb-core') ~= 'missing' and GetResourceState('qb-core') ~= 'unknown' then
        while GetResourceState('qb-core') ~= 'started' do Wait(0) end
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

local GetPlayer = function(id)
    if ESX then
        return ESX.GetPlayerFromId(id)
    elseif QBCore then
        return QBCore.Functions.GetPlayer(id)
    end
end
local GetPlayerCID = function (id)
    if ESX then
        return ESX.GetPlayerFromIdentifier(id)
    elseif QBCore then
        return QBCore.Functions.GetPlayerByCitizenId(id)
    end
end

local GetName = function (id)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(id)
        return xPlayer.getName()
    elseif QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(id)
        local name = xPlayer.PlayerData.charinfo.firstname .. ' '.. xPlayer.PlayerData.charinfo.lastname
        return name
    end
end

local RegisterStash = function (lockerid,label)
    if Config.OXInventory then
        exports.ox_inventory:RegisterStash(lockerid, label, Config.MaxSlots, Config.MaxWeight) 
    end
end

RegisterNetEvent("ts-lockers:server:CreateLocker", function(code, area)
    local src = source
    local xPlayer = GetPlayer(src)
    local branch = area
    local passcode = code
    local allowed = true
    if code and xPlayer then
        local plyIdentifier = xPlayer.identifier or xPlayer.PlayerData.citizenid
        MySQL.query('SELECT * FROM tslockers WHERE branch = ?', {branch}, function(result)
            if result[1] then
                for k,v in pairs(result) do
                    if v.owner == plyIdentifier  then
                        allowed = false
                    end
                end
                if allowed then
		            local lockerid = plyIdentifier..branch
                    MySQL.insert('INSERT INTO tslockers (lockerid, owner, password, branch) VALUES (?, ?, ?, ?)', {lockerid, plyIdentifier, passcode, branch}, function(id)
                        RegisterStash(lockerid,"Locker No:"..id)
                        TriggerClientEvent('ox_lib:defaultNotify', src, {
                            title = 'Locker',
                            description = 'You Created Locker with Locker ID: '..id,
                            status = 'success'
                        })
                    end)
                else
                    TriggerClientEvent('ox_lib:defaultNotify', src, {
                        title = 'Locker',
                        description = 'You can only create 1 locker in this area',
                        status = 'error'
                    })
                end
            else
		local lockerid = plyIdentifier..branch
                MySQL.insert('INSERT INTO tslockers (lockerid,owner, password, branch) VALUES (?, ?, ?, ?)', {lockerid,plyIdentifier, passcode, branch}, function(id)
                    RegisterStash(lockerid,"Locker No:"..id)
                    TriggerClientEvent('ox_lib:defaultNotify', src, {
                        title = 'Locker',
                        description = 'You Created Locker with Locker ID: '..id,
                        status = 'success'
                    })
                end)
            end
        end)
       
        
    end
end)

RegisterNetEvent('ts-lockers:server:DeleteLocker', function(id)
    local lockerid = id
    local src = source
    local xPlayer = GetPlayer(src)
    if xPlayer and lockerid then
        local plyIdentifier = xPlayer.identifier or xPlayer.PlayerData.citizenid
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
                    if tostring(v.lockerid) == tostring(lockerid) and v.owner == plyIdentifier then
                        if Config.OXInventory then
                            MySQL.query('DELETE FROM ox_inventory WHERE name = ?', { v.lockerid })
                        elseif Config.QBInventory then
                            MySQL.query('DELETE FROM stashitems WHERE stash = ?', { v.lockerid })
                        elseif Config.ChezzaInv then
                            MySQL.query('DELETE FROM inventories WHERE identifier = ?', { v.lockerid })
                        end
                        MySQL.query('DELETE FROM tslockers WHERE lockerid = ?', {v.lockerid}, function(result)
                            TriggerClientEvent('ox_lib:defaultNotify', src, {
                                title = 'Locker',
                                description = 'You Deleted the Locker with Locker ID: '..id,
                                status = 'success'
                            })
                        end)
                    end
                end
            end
        end)
    end
end)


RegisterNetEvent('ts-lockers:server:ChangePass', function(lid, pass)
    local src = source
    local lockerid = lid
    local password = pass
    local xPlayer = GetPlayer(src)
    if xPlayer and lockerid then
        local plyIdentifier = xPlayer.identifier or xPlayer.PlayerData.citizenid
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
                    if tostring(v.lockerid) == tostring(lockerid) then
                        if v.owner == plyIdentifier then
                        MySQL.update('UPDATE tslockers SET password = ? WHERE lockerid = ? ', {password, lockerid}, function(affectedRows)
                            if affectedRows then
                                TriggerClientEvent('ox_lib:defaultNotify', src, {
                                    title = 'Locker',
                                    description = 'Password Changed',
                                    status = 'success'
                                })
                            end
                        end)
                    else
                        TriggerClientEvent('ox_lib:defaultNotify', src, {
                            title = 'Locker',
                            description = "You are not Authorized to change the password!",
                            status = 'error'
                        })
                    end
                    end
                end
            end
        end)
    end
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'ts-lockers' or resourceName == GetCurrentResourceName() then
        if Config.OXInventory then
            while GetResourceState('ox_inventory') ~= 'started' do Wait(50) end
        elseif Config.QBInventory then
            while GetResourceState('qb-inventory') ~= 'started' do Wait(50) end
        elseif Config.ChezzaInv then
            while GetResourceState('inventory') ~= 'started' do Wait(50) end
        end
        MySQL.query('SELECT * FROM tslockers', {}, function(result)
            if result[1] then
	  	        for k,v in pairs(result) do
                    RegisterStash(v.lockerid,"Locker No:"..v.dbid)
                end
            end
        end)
    end
end)


lib.callback.register('ts-lockers:getLockers', function(source, area)
    local result = MySQL.query.await('SELECT * FROM tslockers WHERE branch = ?', {area})
    if result[1] then
        for k,v in pairs(result) do
            local xPlayer = GetPlayerCID(v.owner)
            if xPlayer then
                v["playername"] = GetName(xPlayer.source or xPlayer.PlayerData.source)
            else
                v["playername"] = "Not Online"
            end
        end
        return result
    else
        return nil
    end
end)
