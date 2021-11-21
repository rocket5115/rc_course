local playervehs = {}
local localvehs = {}

local globalownedvehs = {}
local globallocalvehs = {}

RegisterServerEvent('rc_course:sendInfoToSyncOwned')
AddEventHandler('rc_course:sendInfoToSyncOwned', function(ownedplate, ownedamount)
    if ownedplate ~= nil then
        if playervehs[ownedplate] == nil then
            playervehs[ownedplate] = {
                plate = ownedplate,
                amount = tonumber(ownedamount)
            }
            table.insert(globalownedvehs, {
                plate = ownedplate,
                amount = tonumber(ownedamount)
            })
        end
    end
end)

RegisterServerEvent('rc_course:sendInfoToSyncLocal')
AddEventHandler('rc_course:sendInfoToSyncLocal', function(localplate, localamount)
    if localplate ~= nil then
        if localvehs[localplate] == nil then
            localvehs[localplate] = {
                plate = localplate,
                amount = tonumber(localamount)
            }
        end
    end
end)

RegisterServerEvent('rc_course:updateOwnedVeh')
AddEventHandler('rc_course:updateOwnedVeh', function(ownedplate, ownedamount)
    if ownedplate ~= nil then
        if playervehs[ownedplate] ~= nil then
            playervehs[ownedplate] = {
                plate = ownedplate,
                amount = tonumber(ownedamount)
            }
        end
    end
end)

RegisterServerEvent('rc_course:updateLocalVeh')
AddEventHandler('rc_course:updateLocalVeh', function(localplate, localamount)
    if localplate ~= nil then
        if localvehs[localplate] ~= nil then
            localvehs[localplate] = {
                plate = localplate,
                amount = tonumber(localamount)
            }
        end
    end
end)

RegisterServerEvent('rc_course:serverCallbackOwned')
AddEventHandler('rc_course:serverCallbackOwned', function(plate)
    if plate ~= nil then
        if playervehs[plate] ~= nil then
            TriggerClientEvent('rc_course:serverRespondOwned', source, playervehs[plate].plate, playervehs[plate].amount)
        end
    end
end)

RegisterServerEvent('rc_course:serverCallbackLocal')
AddEventHandler('rc_course:serverCallbackLocal', function(plate)
    if plate ~= nil then
        if localvehs[plate] ~= nil then
            TriggerClientEvent('rc_course:serverRespondLocal', source, localvehs[plate].plate, localvehs[plate].amount)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        for i=1, #globalownedvehs, 1 do
            if playervehs[globalownedvehs[i].plate] ~= nil then
                globalownedvehs[i] = {
                    plate = globalownedvehs[i].plate,
                    amount = playervehs[globalownedvehs[i].plate].amount
                } 
                MySQL.Async.fetchAll('SELECT * FROM rc_universal WHERE plate = @plate AND state = @state', {
                    ['@plate'] = globalownedvehs[i].plate, ['@state'] = 'course'
                }, function(result)
                    if result[1] then
                        MySQL.Async.execute('UPDATE rc_universal SET count=@count WHERE plate=@plate AND state = @state', {
                            ['@plate'] = globalownedvehs[i].plate, ['@state'] = 'course', ['@count'] = globalownedvehs[i].amount
                        })
                    else
                        MySQL.Async.execute('INSERT INTO rc_universal (plate, state, count) VALUES (@plate, @state, @count)', {
                            ['@plate'] = globalownedvehs[i].plate, ['@state'] = 'course', ['@count'] = globalownedvehs[i].amount
                        })
                    end
                end)
                Wait(100)
            end
        end
    end
end)

Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * from rc_universal WHERE state=@state', {
        ['@state'] = 'course'
    }, function(result)
        for i=1, #result, 1 do
            local p = result[i].plate
            globallocalvehs[p] = {
                plate = result[i].plate,
                amount = tonumber(result[i].count)
            }
        end
    end)
end)

RegisterServerEvent('rc_course:getCurrentCourses')
AddEventHandler('rc_course:getCurrentCourses', function()
    TriggerClientEvent('rc_course:sendCourses', source, globallocalvehs)
end)