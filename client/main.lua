local ESX = exports['es_extended']:getSharedObject()


if Config.DrawText and not Config.Target then
Citizen.CreateThread(function()
    local sleep = 3000
    local inZone = false
    while true do
        local nearArea = false
        local coords = GetEntityCoords(PlayerPedId())
        for k, v in pairs(Config.LockerZone) do
            local dist = #(vec3(v.x,v.y,v.z)-coords)
            if dist < 5 then
                nearArea = true
                DisableControlAction(0, 47)
                if IsDisabledControlJustPressed(0, 47) then
                    ESX.TriggerServerCallback("ts-lockers:getLockers", function(data) 
                        TriggerServerEvent('ts-lockers:LoadStashes')
                        TriggerEvent("ts-lockers:OpenMenu", {locker = k, info = data})
                    end, k)
                    
                end
                DrawText3Ds(v.x,v.y,v.z+1.0, "Press ~r~[G]~s~ To Open ~y~Locker~s~")
            end
        end
        if nearArea and not inZone then
            inZone = true
            sleep = 0
        end
        if not nearArea and inZone then
            sleep = 3000
        end
        Citizen.Wait(sleep)
    end
end)
end

if Config.Target and not Config.DrawText then
onInteract = function(targetName,optionName,vars,entityHit)
    local tony = vars
    if optionName == "open_locker" then
        ESX.TriggerServerCallback("ts-lockers:getLockers", function(data) 
            TriggerServerEvent('ts-lockers:LoadStashes')
            TriggerEvent("ts-lockers:OpenMenu", {locker = tony.index, info = data})
        end, tony.index)
    end
end

Citizen.CreateThread(function()
    for k, v in pairs(Config.LockerZone) do
        exports["fivem-target"]:AddTargetPoint({
            name = k.."Target",
            label = "TKRP Lockers",
            icon = "fas fa-archive",
            point = vec3(v.x,v.y,v.z),
            interactDist = 2.5,
            onInteract = onInteract,
            options = {
              {
                name = "open_locker",
                label = "Open Locker Menu"
              },          
            },
            vars = {
              index = k
            }
          })
        exports["tony_peds"]:NewPed(`cs_casey`, k, {
            coords = vector3(v.x,v.y,v.z),
            radius = 50.0,
            heading = v.w,
            useZ = true,
            debug = false
        }, {
            invincible = true,
            canMove = true,
            ignorePlayer = true
        })
    end
end)

end

RegisterNetEvent("ts-lockers:OpenMenu", function(data)
    local myMenu = {
        {
            id = 1,
            header = data.locker..' Locker Menu',
            txt = ''
        },
        {
            id = 2,
            header = 'Create Locker',
            txt = 'Create A Locker',
            params = {
                event = 'ts-lockers:CreateLocker',
                isServer = false,
                args = {
                    branch = data.locker
                }
            }
        },
        {
            id = 3,
            header = 'Open Locker',
            txt = 'Open Existing Locker',
            params = {
                event = 'ts-lockers:LockerList',
                isServer = false,
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        },
        {
            id = 4,
            header = 'Delete Locker',
            txt = 'Delete Existing Locker',
            params = {
                event = 'ts-lockers:LockerListDelete',
                isServer = false,
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        },
        {
            id = 5,
            header = 'Change Locker Password',
            txt = 'Change Existing Locker Password',
            params = {
                event = 'ts-lockers:LockerChangePass',
                isServer = false,
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        },
    }
    exports['zf_context']:openMenu(myMenu)
end)

RegisterNetEvent('ts-lockers:LockerList', function(data)
    local arg = data.arg
    local myMenu = {
        {
            id = 1,
            header = data.branch..' Locker Menu',
            txt = ''
        },
        {
            id = 2,
            header = ' <- Go Back',
            txt = '',
            params = {
                event = 'ts-lockers:OpenMenu',
                isServer = false,
                args = {
                    locker = data.branch,
                    info = arg
                }
            }
        },
    }
    local idt = 2
    if arg then
    for k,v in pairs(arg) do
        idt = idt + 1
        table.insert(myMenu, {id = idt, header = "Locker ID: "..v.lockerid, txt = 'Owner: '..v.playername, params = {event = 'ts-lockers:client:OpenLocker', isServer = false, args = {data = v}}})
    end
    end
    exports['zf_context']:openMenu(myMenu)
end)

RegisterNetEvent('ts-lockers:LockerChangePass', function(data)
    local arg = data.arg
    local myMenu = {
        {
            id = 1,
            header = data.branch..' Change Password Menu',
            txt = ''
        },
        {
            id = 2,
            header = ' <- Go Back',
            txt = '',
            params = {
                event = 'ts-lockers:OpenMenu',
                isServer = false,
                args = {
                    locker = data.branch,
                    info = data.arg
                }
            }
        },
    }
    local idt = 2
    if arg then
    for k,v in pairs(arg) do
        if v.playername ~= 'Not Online' then
        idt = idt + 1
        table.insert(myMenu, {id = idt, header = "Locker ID: "..v.lockerid, txt = 'Owner: '..v.playername, params = {event = 'ts-lockers:client:ChangePassword', isServer = false, args = {data = v}}})
        end
    end
    end
    exports['zf_context']:openMenu(myMenu)
end)

RegisterNetEvent('ts-lockers:LockerListDelete', function(data)
    local PlayerData = ESX.GetPlayerData()
    local arg = data.arg
    local myMenu = {
        {
            id = 1,
            header = data.branch..' Delete Locker Menu',
            txt = ''
        },
        {
            id = 2,
            header = ' <- Go Back',
            txt = '',
            params = {
                event = 'ts-lockers:OpenMenu',
                isServer = false,
                args = {
                    locker = data.branch,
                    info = data.arg
                }
            }
        },
    }
    local idt = 2
    if arg then
    for k,v in pairs(arg) do
        if PlayerData.identifier == v.owner then
        idt = idt + 1
        table.insert(myMenu, {id = idt, header = "Locker ID: "..v.lockerid, txt = 'Owner: '..v.playername, params = {event = 'ts-lockers:client:DeleteLocker', isServer = false, args = {data = v, id = v.lockerid}}})
        end
    end
    end
    exports['zf_context']:openMenu(myMenu)
end)

RegisterNetEvent('ts-lockers:client:ChangePassword', function(info)
    local data = info.data
    local id = data.lockerid
    local keyboard = exports["nh-keyboard"]:KeyboardInput({
        header = "Input Password",
        rows = {
            {
                id = 0, 
                txt = "Password",
                ispassword = true
            }
        }
    })
    if keyboard then
        if keyboard[1].input == nil then return end
            TriggerServerEvent('ts-lockers:server:ChangePass', id, keyboard[1].input)
    end
end)

RegisterNetEvent('ts-lockers:client:DeleteLocker', function(info)
    local data = info.data
    local id = info.id
    local myMenu = {
        {
            id = 1,
            header = data.branch..' Delete Locker Menu',
            txt = ''
        },
        {
            id = 2,
            header = 'Confirm',
            txt = 'Confirm Deletion of Your Locker',
            params = {
                event = 'ts-lockers:server:DeleteLocker',
                isServer = true,
                args = {
                    lockerid = id
                }
            }
        },
        {
            id = 3,
            header = 'Cancel',
            txt = 'Cancel Deletion of Your Locker',
            params = {
                event = 'ts-lockers:OpenMenu',
                isServer = false,
                args = {
                    locker = data.branch,
                    info = data.arg
                }
            }
        },
    }
    exports['zf_context']:openMenu(myMenu)
end)

RegisterNetEvent('ts-lockers:client:OpenLocker', function(info)
    local data = info.data
    local keyboard = exports["nh-keyboard"]:KeyboardInput({
        header = "Input Password",
        rows = {
            {
                id = 0, 
                txt = "Password",
                ispassword = true
            }
        }
    })
    if keyboard then
        if keyboard[1].input == nil then return end
            if tostring(keyboard[1].input) == tostring(data.password) then  
                exports.ox_inventory:openInventory('stash', data.lockerid)
            else
                ESX.ShowNotification("Wrong Password")
            end
    end
    --[[exports['Boost-Numpad']:openNumpad(true,data.password,true,function(correct)
        if correct then
            print(data.lockerid)
            TriggerEvent('ox_inventory:openInventory', 'stash', {id = data.lockerid})
        end
      end)]]--
end)

RegisterNetEvent("ts-lockers:CreateLocker", function(data)
    local area = data.branch
    local keyboard = exports["nh-keyboard"]:KeyboardInput({
        header = "Create Password",
        rows = {
            {
                id = 0, 
                txt = "Password",
                ispassword = true
            }
        }
    })
    if keyboard then
        if keyboard[1].input == nil then return end
            TriggerServerEvent("ts-lockers:server:CreateLocker", keyboard[1].input, area)
    end
    --[[exports['Boost-Numpad']:openNumpad(false,1234,true,function(code)
        if code then
          TriggerServerEvent("ts-lockers:server:CreateLocker", code, area)
        end
      end)]]--
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

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
