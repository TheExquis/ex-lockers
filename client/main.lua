local ESX,QBCore = nil,nil
local PlayerData = {}
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    PlayerData = QBCore.Functions.GetPlayerData()
end)
RegisterNetEvent('esx:playerLoaded', function ()
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
    end
    PlayerData = ESX.GetPlayerData()
end)

CreateThread(function()
    for k, v in pairs(Config.LockerZone) do
        v.point = lib.points.new(v.coords, 5)
        function v.point:nearby()
            DrawText3Ds(v.coords.x, v.coords.y, v.coords.z + 1.0, "Press ~r~[G]~s~ To Open ~y~Locker~s~")
            DisableControlAction(0, 47)
            if IsDisabledControlJustPressed(0, 47) then
                lib.callback('ts-lockers:getLockers', false, function(data)
                    TriggerEvent("ts-lockers:OpenMenu", { locker = k, info = data })
                end, k)
            end
        end
    end
end)


RegisterNetEvent("ts-lockers:OpenMenu", function(data)
    lib.registerContext({
        id = 'locker_menu',
        title = 'EX Lockers',
        options = {
            ['Create Locker'] = {
                description = 'Create A Locker',
                arrow = true,
                event = 'ts-lockers:CreateLocker',
                args = {
                    branch = data.locker
                }
            },
            ['Open Locker'] = {
                description = 'Open Existing Locker',
                arrow = true,
                event = 'ts-lockers:LockerList',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
            ['Open Your Locker'] = {
                description = 'Open Self Locker',
                arrow = true,
                event = 'ts-lockers:OpenSelfLocker',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
            ['Delete Locker'] = {
                description = 'Delete Existing Locker',
                arrow = true,
                event = 'ts-lockers:LockerListDelete',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
            ['Change Locker Password'] = {
                description = 'Change Existing Locker Password',
                arrow = true,
                event = 'ts-lockers:LockerChangePass',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        }
    })
    lib.showContext('locker_menu')
end)

RegisterNetEvent('ts-lockers:LockerList', function(data)
    local optionTable = {}
    local arg = data.arg
    local idt = 2
    if arg then
        for k, v in pairs(arg) do
            idt = idt + 1
            optionTable["Locker ID: " .. v.dbid] = {
                description = 'Owner: ' .. v.playername,
                arrow = true,
                event = 'ts-lockers:client:OpenLocker',
                args = v
            }
        end
    end
    lib.registerContext({
        id = 'locker_list',
        title = data.branch .. ' Locker Menu',
        menu = "locker_menu",
        options = optionTable
    })
    lib.showContext('locker_list')
end)

RegisterNetEvent('ts-lockers:LockerChangePass', function(data)
    local plyIdentifier = PlayerData.identifier or PlayerData.citizenid
    if not plyIdentifier then
        plyIdentifier = (ESX and ESX.GetPlayerData().identifier) or (QBCore and QBCore.Functions.GetPlayerData())
    end
    local lockers = data.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                TriggerEvent('ts-lockers:client:ChangePassword', { data = v })
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent('ts-lockers:LockerListDelete', function(data)
    local plyIdentifier = PlayerData.identifier or PlayerData.citizenid
    local lockers = data.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                TriggerEvent('ts-lockers:client:DeleteLocker', { data = v, id = v.lockerid })
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent('ts-lockers:client:ChangePassword', function(info)
    local data = info.data
    local id = data.lockerid
    local input = lib.inputDialog('TS Lockers',
        { { type = "input", label = "Locker Password", password = true, icon = 'lock' } })
    if input and input[1] then
        TriggerServerEvent('ts-lockers:server:ChangePass', id, input[1])
    end
end)

RegisterNetEvent('ts-lockers:client:DeleteLocker', function(info)
    local id = info.id
    lib.registerContext({
        id = 'delete_locker_confirmation',
        title = 'Delete Locker',
        menu = 'locker_menu',
        options = {
            ['Confirm'] = {
                description = 'Confirm Deletion of Your Locker',
                arrow = true,
                serverEvent = 'ts-lockers:server:DeleteLocker',
                args = id
            },
            ['Cancel'] = {
                description = 'Cancel Deletion of Your Locker',
                arrow = true,
                menu = 'locker_menu'
            }

        }
    })
    lib.showContext('delete_locker_confirmation')
end)

function OpenTSLocker(lid)
    if Config.OXInventory then
        exports.ox_inventory:openInventory('stash', lid)
    elseif Config.QBInventory then
        TriggerEvent("inventory:client:SetCurrentStash", lid)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", lid, {
            maxweight = Config.MaxWeight,
            slots = Config.MaxSlots,
        })
    elseif Config.ChezzaInv then
        TriggerEvent('inventory:openInventory', {
            type = "stash",
            id = lid,
            title = "Locker",
            weight = Config.MaxWeight,
            delay = 200,
            save = true
        })
    end
end


RegisterNetEvent('ts-lockers:OpenSelfLocker', function(info)
    local plyIdentifier = PlayerData.identifier or PlayerData.citizenid
    local lockers = info.arg
    if lockers then
        local exist = false
        for k, v in pairs(lockers) do
            if plyIdentifier == v.owner then
                exist = true
                OpenTSLocker(v.lockerid) 
            end
        end
        if not exist then
            lib.defaultNotify({
                title = 'Lockers',
                description = 'You don\'t have a locker',
                status = 'error'
            })
        end
    else
        lib.defaultNotify({
            title = 'Lockers',
            description = 'You don\'t have a locker',
            status = 'error'
        })
    end
end)

RegisterNetEvent('ts-lockers:client:OpenLocker', function(info)
    local data = info
    local input = lib.inputDialog('TS Lockers',
        { { type = "input", label = "Locker Password", password = true, icon = 'lock' } })
    if input and input[1] then
        if tostring(input[1]) == tostring(data.password) then
            OpenTSLocker(data.lockerid)
        else
            lib.defaultNotify({
                title = 'Lockers',
                description = 'Wrong Password',
                status = 'error'
            })
        end
    end
end)

RegisterNetEvent("ts-lockers:CreateLocker", function(data)
    local area = data.branch
    local input = lib.inputDialog('TS Lockers - Create Password',
        { { type = "input", label = "Locker Password", password = true, icon = 'lock' } })
    if input and input[1] then
        TriggerServerEvent("ts-lockers:server:CreateLocker", input[1], area)
    end
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 500
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 80)
end
