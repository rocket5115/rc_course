local ownedvehs = {}
local localvehs = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 then
            local plate = GetVehicleNumberPlateText(veh)
            local plt = string.gsub(plate, " ", "")
            local amt = string.len(plt)

            if amt == 6 then
                if ownedvehs[plt] == nil then
                    ownedvehs[plt] = {
                        plate = plt,
                        amount = 0
                    }
                    Wait(500)
                    TriggerServerEvent('rc_course:sendInfoToSyncOwned', plt, 0)
                    TriggerServerEvent('rc_course:serverCallbackOwned', plt)
                end
            elseif amt ~= 6 then
                if localvehs[plt] == nil then
                    local random = math.random(100, 1500)
                    localvehs[plt] = {
                        plate = plt,
                        amount = random
                    }
                    Wait(500)
                    TriggerServerEvent('rc_course:sendInfoToSyncLocal', plt, random)
                    TriggerServerEvent('rc_course:serverCallbackLocal', plt)
                end
            end
        end
    end
end)

local lastveh = 0
local totalspeed = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(veh) * 0.1
        
        if veh ~= 0 then
            if lastveh == 0 and veh ~= 0 then
                lastveh = veh
                totalspeed = totalspeed + speed
            elseif lastveh ~= 0 and lastveh == veh then
                lastveh = veh
                totalspeed = totalspeed + speed
            elseif lastveh ~= 0 and lastveh ~= veh then
                lastveh = veh
                totalspeed = 0
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)

        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, false)
        local speed = GetEntitySpeed(veh) * 0.1
        
        if veh ~= 0 then
            local plate = GetVehicleNumberPlateText(veh)
            local plt = string.gsub(plate, " ", "")
            local amt = string.len(plt)
            if lastveh ~= 0 and lastveh ~= veh then
                if amt == 6 then
                    TriggerServerEvent('rc_course:serverCallbackOwned', plt)
                    Wait(1000)
                elseif amt ~= 6 then
                    TriggerServerEvent('rc_course:serverCallbackLocal', plt)
                    Wait(1000)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 then
            local plate = GetVehicleNumberPlateText(veh)
            if totalspeed >= 900 then
                totalspeed = 0
                if GetPedInVehicleSeat(veh, -1) == ped then
                    AddCourseToVeh(plate)
                end
            end
        end
    end
end)

function AddCourseToVeh(plate)
    local ped = GetPlayerPed(-1)
    local _plate = plate
    if _plate ~= nil and _plate ~= 0 then
        local plt = string.gsub(plate, " ", "")
        local amt = string.len(plt)

        if amt == 6 then
            if ownedvehs[plt] ~= nil then
                local pl = ownedvehs[plt].plate
                local at = ownedvehs[plt].amount + 1
                
                ownedvehs[plt] = {
                    plate = pl,
                    amount = at
                }
                TriggerServerEvent('rc_course:updateOwnedVeh', pl, at)
            end
        elseif amt ~= 6 then
            if localvehs[plt] ~= nil then
                local pl = localvehs[plt].plate
                local at = localvehs[plt].amount + 1
                
                localvehs[plt] = {
                    plate = pl,
                    amount = at
                }
                TriggerServerEvent('rc_course:updateLocalVeh', pl, at)
            end
        end
    end
end

RegisterNetEvent('rc_course:syncInfo')
AddEventHandler('rc_course:syncInfo', function(ownvehs, lclvehs)
    if ownvehs ~= {} then
        ownedvehs = ownvehs
    end
    if lclvehs ~= {} then
        localvehs = lclvehs
    end
end)

RegisterNetEvent('rc_course:serverRespondOwned')
AddEventHandler('rc_course:serverRespondOwned', function(plt, amt)
    ownedvehs[plt] = {
        plate = plt,
        amount = amt
    }
end)

RegisterNetEvent('rc_course:serverRespondLocal')
AddEventHandler('rc_course:serverRespondLocal', function(plt, amt)
    localvehs[plt] = {
        plate = plt,
        amount = amt
    }
end)

local displayHud = false
local playerowned = false

local x = 0.01135
local y = 0.002

function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(sc, sc)
    N_0x4e096588b13ffeca(jus)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - 0.1+w, y - 0.02+h)
end

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, true)

        if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = string.gsub(GetVehicleNumberPlateText(veh), " ", "")
            displayHud = true
            if string.len(plate) == 6 then
                playerowned = true
            else
                playerowned = false
            end
        else
            displayHud = false
            Citizen.Wait(500)
        end

        Citizen.Wait(50)
    end
end)

Citizen.CreateThread(function()
    while true do
        local ped = GetPlayerPed(-1)
        local veh = GetVehiclePedIsIn(ped, true)

        if veh ~= 0 and veh ~= nil then
            local plate = string.gsub(GetVehicleNumberPlateText(veh), " ", "")

            if displayHud and veh ~= 0 and playerowned then
                if ownedvehs[plate] ~= nil then
                    DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, "course " .. ownedvehs[plate].amount, 255, 255, 255, 255, 6, 1)
                else
                    DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, "course " .. "N/I", 255, 255, 255, 255, 6, 1)
                end
            elseif displayHud and veh ~= 0 and playerowned == false then
                if localvehs[plate] ~= nil then
                    DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, "course " .. localvehs[plate].amount, 255, 255, 255, 255, 6, 1)
                else
                    DrawAdvancedText(0.130 - x, 0.77 - y, 0.005, 0.0028, 0.6, "course " .. "N/I", 255, 255, 255, 255, 6, 1)
                end
            else
                Citizen.Wait(750)
            end
        end
        Citizen.Wait(0)
    end
end)

local fs = true

AddEventHandler('playerSpawned', function()
    if fs then
        TriggerServerEvent('rc_course:getCurrentCourses')
        fs = false
    end
end)

RegisterNetEvent('rc_course:sendCourses')
AddEventHandler('rc_course:sendCourses', function(courses)
    ownedvehs = courses
end)
--[[
RegisterCommand('gg', function(source, args)
    local ped = GetPlayerPed(-1)
    local veh = GetVehiclePedIsIn(ped, false)
    local plate = GetVehicleNumberPlateText(veh)
    local plt = string.gsub(plate, " ", "")
    local amt = string.len(plt)

    if amt == 6 then
        print(ownedvehs[plt].plate .. " " .. ownedvehs[plt].amount)
    else
        print(localvehs[plt].plate .. " " .. localvehs[plt].amount)
    end
    print(totalspeed .. " " .. lastveh)

    SetVehicleNumberPlateText(veh, args[1] .. " " .. args[2])
end)
--]]