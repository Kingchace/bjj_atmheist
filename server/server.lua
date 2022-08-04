local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('bjj_atmheist:server:removeatm', function(atm)
    SetEntityAsMissionEntity(atm, true, true) -- Set as missionEntity so the object can be remove (Even map objects)
    NetworkRequestControlOfEntity(atm) -- Request Network control so we own the object
    Wait(250) -- Safety Wait
    DeleteEntity(atm) -- Delete the object
    DeleteObject(atm) -- Delete the object (failsafe)
    SetEntityAsNoLongerNeeded(atm) -- Tells the engine this prop isnt needed anymore
end)

RegisterNetEvent('bjj_atmheist:server:userope', function()
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem('rope', 1)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['rope'], 'remove', 1)
end)

RegisterNetEvent('bjj_atmheist:server:givereward', function()
    local Player = QBCore.Functions.GetPlayer(source)
    local info = {
        worth = Config.reward
    }
    if Player.Functions.AddItem('markedbills', 1, nil, info) then
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], 'add', 1)
    end
end)

QBCore.Functions.CreateCallback('bjj_atmheist:server:copcount', function(source, cb)
	local amount = 0
    for k, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    cb(amount)
end)