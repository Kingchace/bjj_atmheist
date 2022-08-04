local QBCore = exports['qb-core']:GetCoreObject()

local HIT_AREAS = {  }

local last_veh = nil
local rope
local atm_entity
local attached = false
local atm_pulled_out = false
local loose_atm
local hit_timer = 0

exports['qb-target']:AddTargetModel(Config.atm_props,{
        options = {
            {
                type = "client",
                event = "bjj_atmheist:client:attachcable",
                icon = "far fa-money-bill-alt ",
                label = "Attach Cable to ATM ",
                item = 'rope',
                canInteract = function(entity)
                    atm_entity = entity
			        return cableCanAttachCheck(entity)
		        end
            },
        },
        job = {"all"},
        distance = 1.8,
    })

function cableCanAttachCheck(entity)
    last_veh = GetLastDrivenVehicle()
    if last_veh ~= nil and attached == false and loose_atm == nil and hit_timer <= 0 then
        if Config.validvehs[GetDisplayNameFromVehicleModel(GetEntityModel(last_veh)):lower()]then
            local player = GetPlayerPed(-1)
            local coords = GetEntityCoords(player)
            if GetDistanceBetweenCoords(coords, GetEntityCoords(last_veh), true) < 5 then
                return true
            end
        end
    end
    if hit_timer > 0 then
        QBCore.Functions.Notify('ATMs are on lockdown for a while since last heist', 'error')
    end
end

function hit_timer_thread()
    CreateThread( function()
        while hit_timer > 0 do
            hit_timer = hit_timer - 10

            if Config.debug == true then
                hit_timer = 0
                print('DEBUG ACTIVE : HIT TIMER REMOVED')
            end

            Wait(10000)
        end
        if Config.debug == true then
            print('can hit another atm')
        end
    end)

end

RegisterNetEvent("bjj_atmheist:client:attachcable", function()
    QBCore.Functions.TriggerCallback('bjj_atmheist:server:copcount', function(cops)
        if cops >= Config.required_cop_count then
            local pos = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
            local Skillbar = exports['qb-skillbar']:GetSkillbarObject()
            local ped = PlayerPedId()
            TriggerEvent('animations:client:EmoteCommandStart', {"mechanic4"})
            FreezeEntityPosition(ped, true)
            Skillbar.Start({
                duration = math.random(7500, 8000),
                pos = math.random(10, 30),
                width = math.random(10, 20),
            }, function()
                print('sucess')
                TriggerServerEvent('bjj_atmheist:server:userope')
                FreezeEntityPosition(ped, false)
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})

                local ped = GetPlayerPed(PlayerId())
                local pedPos = GetEntityCoords(ped, false)

                local atm_entity_coords = GetEntityCoords(atm_entity)
                local veh_coords = GetEntityCoords(last_veh)
                local rope_length = GetDistanceBetweenCoords(atm_entity_coords, veh_coords, true)
                RopeLoadTextures()
                rope = AddRope(veh_coords.x, veh_coords.y, veh_coords.z, 0.0, 0.0, 0.0, 10.0, 2, rope_length+0.8, 1.0, 0, 0, 0, 0, 0, true, 0)
                ActivatePhysics(rope)
                AttachEntitiesToRope(rope, last_veh, atm_entity, veh_coords.x, veh_coords.y, veh_coords.z, atm_entity_coords.x, atm_entity_coords.y, atm_entity_coords.z, 10, false, false, nil, nil)
                --StartRopeWinding(rope)
                --RopeForceLength(rope, 10)

                attached = true
                location_check(veh_coords)

                pulling_timer(atm_entity_coords, rope_length)

                SetTimeout(7500, function()
                    exports['ps-dispatch']:ATMHeist()
                    TriggerServerEvent('hud:server:GainStress', math.random(2, 6))
                end)
            end, function()
                print('failure')
                FreezeEntityPosition(ped, false)
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                QBCore.Functions.Notify('You failed to attach the cable', 'error')
                --trigger cop call
                SetTimeout(9500, function()
                    exports['ps-dispatch']:ATMHeist(last_veh)
                end)
            end)
        else
            QBCore.Functions.Notify('You cannot do this right now.', 'error', 7500)
        end
    end)
end)

function location_check(veh_coords)
    CreateThread(function()
        while attached == true do
            local player = GetPlayerPed(-1)
            local coords = GetEntityCoords(player)
            if GetDistanceBetweenCoords(coords, veh_coords, true) > 10 and IsPedInAnyVehicle(PlayerPedId(), false) then
                print('left zone detaching and deleting rope')
                RopeUnloadTextures()
                DeleteRope(rope)
                attached = false
            end
            Wait(500)
        end
    end)
end

function pulling_timer(atm_entity_coords, rope_length)
    local counter
    if Config.debug == true then
        print('DEBUG ACTIVE : LOWER PULL')
        counter = 3
    else
        counter= 10
    end
    
    while attached == true do
        local player = GetPlayerPed(-1)
        local coords = GetEntityCoords(player)
        if GetDistanceBetweenCoords(coords, atm_entity_coords, true) > rope_length and IsPedInAnyVehicle(PlayerPedId(), false) then
            --THEY ARE PULLING
            print('pulling')
            print(counter)
            counter= counter-1
        end
        if counter<=0 then
            TriggerEvent("bjj_atmheist:client:atm_pulled_out")
            atm_pulled_out = true
            RopeUnloadTextures()
            DeleteRope(rope)
            attached = false
        end
        Wait(2000)
    end
end

RegisterNetEvent("bjj_atmheist:client:atm_pulled_out", function()
    
    if Config.debug == false then
        --TriggerServerEvent('bjj_atmheist:server:removeatm', atm_entity)
        SetEntityAsMissionEntity(atm_entity, true, true) -- Set as missionEntity so the object can be remove (Even map objects)
        NetworkRequestControlOfEntity(atm_entity) -- Request Network control so we own the object
        Wait(250) -- Safety Wait
        DeleteEntity(atm_entity) -- Delete the object
        DeleteObject(atm_entity) -- Delete the object (failsafe)
        SetEntityAsNoLongerNeeded(atm_entity) -- Tells the engine this prop isnt needed anymore
    else
        print('skipping atm delete')
    end
    local veh_coords = GetEntityCoords(last_veh)
    local forward_vector = GetEntityForwardVector(last_veh)
    loose_atm = CreateObject(Config.loose_atm, veh_coords.x  - (forward_vector.x * 4), veh_coords.y - (forward_vector.y * 3), veh_coords.z ,false,false,false)
    FreezeEntityPosition(loose_atm, false)
    ActivatePhysics(loose_atm)

    --attach rope for zone
    --[[
    local ped = GetPlayerPed(PlayerId())
	local pedPos = GetEntityCoords(ped, false)

    local atm_entity_coords = GetEntityCoords(loose_atm)
    local veh_coords = GetEntityCoords(last_veh)
    local rope_length = (GetDistanceBetweenCoords(loose_atm, veh_coords, true)+4)
	RopeLoadTextures()
	rope = AddRope(veh_coords.x, veh_coords.y, veh_coords.z, 0.0, 0.0, 0.0, 10.0, 2, rope_length+0.8, 1.0, 0, 0, 0, 0, 0, true, 0)
    ActivatePhysics(rope)
    AttachEntitiesToRope(rope, last_veh, loose_atm, veh_coords.x, veh_coords.y, veh_coords.z, loose_atm.x, loose_atm.y, loose_atm.z, 10, false, false, nil, nil)
        ]]


    Box_Zone()

end)

function Box_Zone()
    exports['qb-target']:AddTargetModel({Config.loose_atm},{
        options = {
            {
                type = "client",
                event = "bjj_atmheist:client:loose_atm_use",
                icon = "far fa-money-bill-alt",
                label = "Break Open ATM",
                item = Config.item_to_open_atm,
                canInteract = function(entity)
                    print(atm_pulled_out)
                    print(hit_timer)
                    if hit_timer <= 0 and atm_pulled_out == true then
                        return true
                    else
                        return false
                    end
		        end
            },
        },
        job = {"all"},
        distance = 1.5,
    })

end


RegisterNetEvent('bjj_atmheist:client:loose_atm_use', function()
    TriggerServerEvent('hud:server:GainStress', math.random(2, 6))
    if math.random(1, 100) <= 85 then
        local pos = GetEntityCoords(PlayerPedId())
        TriggerServerEvent("evidence:server:CreateFingerDrop", pos)
    end
    local Skillbar = exports['qb-skillbar']:GetSkillbarObject()
    local ped = PlayerPedId()
    TriggerEvent('animations:client:EmoteCommandStart', {"mechanic4"})
    FreezeEntityPosition(ped, true)
    Skillbar.Start({
        duration = math.random(7500, 15000),
        pos = math.random(10, 30),
        width = math.random(10, 20),
    }, function()
        print('sucess')
        atm_pulled_out = false
        FreezeEntityPosition(ped, false)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})


        print('set hit timer')
        hit_timer = Config.timeout
        hit_timer_thread()

        exports['qb-target']:RemoveTargetModel({Config.loose_atm})
        DeleteEntity(loose_atm)
        --Give Money
        TriggerServerEvent('bjj_atmheist:server:givereward')

    end, function()
        print('failure')
        FreezeEntityPosition(ped, false)
        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    end)
end)

-- HANDLE RESTART/CRASH
AddEventHandler('onResourceStop', function(resource)
    RopeUnloadTextures()
    DeleteRope(rope)
    DeleteEntity(loose_atm)
    exports['qb-target']:RemoveTargetModel(Config.loose_atm)
end)