AyseCore = exports["Ayse_Core"]:GetCoreObject()

local alreadyShot = false
local setRoute = false
local route = false

local suppresors = {
    "0x65EA7EBB", -- Pistol.
    "0x837445AA", -- Carbine Rifle, Advanced Rifle, Bullpup Rifle, Assault Shotgun, Marksman Rifle.
    "0xA73D4664", -- .50 Pistol, Micro SMG, Assault SMG, Assault Rifle, Special Carbine, Bullpup Shotgun, Heavy Shotgun, Sniper Rifle.
    "0xC304849A", -- Combat Pistol, AP Pistol, Heavy Pistol, Vintage Pistol, SMG.
    "0xE608B35E" -- Pump Shotgun.
}

function isInShotSpotterLocation(pedCoords)
    for _, location in pairs(config.realisticShotSpotterLocations) do
        if #(pedCoords - vector3(location.x, location.y, location.z)) < 450.0 then
            return true
        end
    end
    return false
end

function isCop()
    local job = AyseCore.Functions.GetSelectedCharacter().job
    for _, department in pairs(config.receiveAlerts) do
        if department == job then
            return true
        end
    end
    return false
end

function triggerShotSpotter(ped)
    local pedCoords = GetEntityCoords(ped)
    if config.shotSpotterUsePostal then
        postal = exports[config.postalResourceName]:getPostal()
    else
        postal = false
    end

    if config.useRealisticShotSpotter and not isInShotSpotterLocation(pedCoords) then
        return
    end

    local selectedWeapon = GetSelectedPedWeapon(ped)
    for _, weapon in pairs(config.weaponBlackList) do
        if GetHashKey(weapon) == selectedWeapon then
            return
        end
    end

    for _, suppresor in pairs(suppresors) do
        if HasPedGotWeaponComponent(ped, selectedWeapon, tonumber(suppresor)) then
            return
        end
    end

    if isCop() then
        return
    end

    if alreadyShot then return end
    alreadyShot = true
    Citizen.Wait(config.shotSpotterDelay * 1000)
    local zoneName = GetLabelText(GetNameOfZone(pedCoords.x, pedCoords.y, pedCoords.z))
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(pedCoords.x, pedCoords.y, pedCoords.z))
    TriggerServerEvent("Ayse_ShotSpotter:Trigger", street, pedCoords, postal, zoneName)
    Citizen.Wait(config.shotSpotterCooldown * 1000)
    alreadyShot = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            triggerShotSpotter(ped)
        end
    end
end)

RegisterNetEvent("Ayse_ShotSpotter:Report", function(street, pedCoords, postal)
    if not isCop() then
        return
    end

    if #(GetEntityCoords(PlayerPedId()) - pedCoords) < 50.0 then
        return
    end

    blip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
    setRoute = true
    route = false
    TriggerEvent("Ayse_shotSpotter:setRoute")
    notify("~w~Press ~g~G ~w~to respond to the latest shot spotter.")
    SetBlipSprite(blip, 161)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    SetBlipColour(blip, 1)
    if not postal then
        msg = "Shotspotter detected in " .. street .. "."
        AddTextComponentString("Shot Spotter: " .. street)
    else
        msg = "Shotspotter detected in " .. street .. ", postal: " .. postal .. "."
        AddTextComponentString("Shot Spotter: " .. street .. ", postal: " .. postal)
    end
    TriggerEvent("chat:addMessage", {
        color = {255, 0, 0},
        args = {"^*Dispatch ", msg}
    })
    EndTextCommandSetBlipName(blip)
    Citizen.Wait(config.shotSpotterTimer * 1000)
    RemoveBlip(blip)
    setRoute = false
    route = false
end)

RegisterNetEvent("Ayse_shotSpotter:setRoute", function()
    while setRoute do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 113) then
            if route then
                route = false
                SetBlipRoute(blip, route)
            else
                route = true
                SetBlipRoute(blip, route)
                SetBlipRouteColour(blip, 1)
            end
        end
    end
end)

if config.testing then
    Citizen.CreateThread(function()
        Citizen.Wait(0)
        for k, v in pairs(config.realisticShotSpotterLocations) do
            k = AddBlipForRadius(v.x, v.y, v.z, 450.0)
            SetBlipAlpha(k, 100)
        end
    end)
end