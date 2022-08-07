# bjj_atmheist by BigJohnJimmy for BJJ_FRAMEWORK
ATM Heist resource for FiveM, QBCore, BJJ Framework

- Removes ATM Prop
- Rope Physics
- Dynamic 3rd Eye
- Drops money bag prop
- Detailed Config.lua
- Balance payout easily
- Allow only certain vehicles
- etc... (check config for main stuff you can tweak)


Requires QB Core
Please credit me if you use this code. Don't claim this resource as your own. Thanks.

## For ps-dispatch to work
 
 
  - Put this in : `ps-dispatch/client/cl_extraalerts.lua`
 ```local function ATMHeist(veh)
    local vehdata = vehicleData(veh)
    local currentPos = GetEntityCoords(PlayerPedId())
    local locationInfo = getStreetandZone(currentPos)
    local heading = getCardinalDirectionFromHeading()
    TriggerServerEvent("dispatch:server:notify", {
        dispatchcodename = "atmheist", -- has to match the codes in sv_dispatchcodes.lua so that it generates the right blip
        dispatchCode = "10-90",
        firstStreet = locationInfo,
        model = vehdata.name, -- vehicle name
        plate = vehdata.plate, -- vehicle plate
        priority = 1,
        firstColor = vehdata.colour, -- vehicle color
        heading = heading,
        automaticGunfire = false,
        origin = {
            x = currentPos.x,
            y = currentPos.y,
            z = currentPos.z
        },
        dispatchMessage = 'ATM Tampering',
        job = { "police" }
    })
end exports('ATMHeist', ATMHeist)
```

  - Put this in : `ps-dispatch/server/sv_dispatchcodes.lua`
  ```
  	--BJJ
	["atmheist"] =  {displayCode = '10-90', description = "ATM Heist", radius = 20, recipientList = {'police'}, blipSprite = 500, blipColour = 60, blipScale = 1.5, blipLength = 2, sound = "Lose_1st", sound2 = "GTAO_FM_Events_Soundset", offset = "false", blipflash = "true"},
  ```
