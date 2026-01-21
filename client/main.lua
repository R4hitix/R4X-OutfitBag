-- R4X Outfit Bag | Client | by R4X Labs

local ESX = exports['es_extended']:getSharedObject()
local isNuiOpen = false
local currentBagSlot = nil
local bagProp = nil
local isAnimating = false
local currentOutfits = {}
local originalOutfit = nil
local previewCam = nil

local PlayPickupBagAnimation, DeleteBagProp, GetCurrentOutfit, ApplyOutfit, CreatePreviewCam, DestroyPreviewCam, SaveOutfitToSkin

-- Component mapping for esx_skin
local ComponentMap = {
    [1] = {"mask_1", "mask_2"},
    [3] = {"arms", "arms_2"},
    [4] = {"pants_1", "pants_2"},
    [5] = {"bags_1", "bags_2"},
    [6] = {"shoes_1", "shoes_2"},
    [7] = {"chain_1", "chain_2"},
    [8] = {"tshirt_1", "tshirt_2"},
    [9] = {"bproof_1", "bproof_2"},
    [10] = {"decals_1", "decals_2"},
    [11] = {"torso_1", "torso_2"}
}

local PropMap = {
    [0] = {"helmet_1", "helmet_2"},
    [1] = {"glasses_1", "glasses_2"},
    [2] = {"ears_1", "ears_2"},
    [6] = {"watches_1", "watches_2"},
    [7] = {"bracelets_1", "bracelets_2"}
}

-- Save outfit to esx_skin for persistence
SaveOutfitToSkin = function(outfit)
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        if not skin then return end
        
        for compId, names in pairs(ComponentMap) do
            local comp = outfit['component_' .. compId]
            if comp then
                skin[names[1]] = comp.drawable
                skin[names[2]] = comp.texture
            end
        end
        
        for propId, names in pairs(PropMap) do
            local prop = outfit['prop_' .. propId]
            if prop then
                skin[names[1]] = prop.drawable
                skin[names[2]] = prop.texture
            end
        end
        
        if outfit.hair_color then
            skin.hair_color_1 = outfit.hair_color.color
            skin.hair_color_2 = outfit.hair_color.highlight
        end
        
        TriggerServerEvent('esx_skin:save', skin)
    end)
end

CreatePreviewCam = function()
    if previewCam then return end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local angle = math.rad(heading)
    
    local camX = coords.x - (math.sin(angle) * 1.8)
    local camY = coords.y + (math.cos(angle) * 1.8)
    local camZ = coords.z + 0.5
    
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camX, camY, camZ)
    PointCamAtEntity(previewCam, playerPed, 0.0, 0.0, 0.0, true)
    SetCamFov(previewCam, 50.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 500, true, false)
end

DestroyPreviewCam = function()
    if previewCam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end

local BagConfig = {
    model = "prop_big_bag_01",
    bagAnimation = {
        dict = "amb@medic@standing@tendtodead@idle_a",
        anim = "idle_a"
    },
    pickUp = {
        dict = "amb@medic@standing@tendtodead@idle_a",
        anim = "idle_a",
        duration = 1500
    }
}

local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

local function CreateBagProp()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local modelHash = GetHashKey(BagConfig.model)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then return nil end
    end
    
    local forwardX = -math.sin(math.rad(heading)) * 0.8
    local forwardY = math.cos(math.rad(heading)) * 0.8
    local bagX = coords.x + forwardX
    local bagY = coords.y + forwardY
    local bagZ = coords.z
    
    local foundGround, groundZ = GetGroundZFor_3dCoord(bagX, bagY, bagZ + 3.0, false)
    if foundGround then
        bagZ = groundZ
    else
        bagZ = coords.z - 0.98
    end
    
    bagProp = CreateObjectNoOffset(modelHash, bagX, bagY, bagZ, true, false, false)
    
    if not DoesEntityExist(bagProp) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    SetEntityHeading(bagProp, heading)
    PlaceObjectOnGroundProperly(bagProp)
    FreezeEntityPosition(bagProp, true)
    SetEntityCollision(bagProp, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    
    if Config.UseTarget then
        exports.ox_target:addLocalEntity(bagProp, {
            {
                name = 'outfitbag_open',
                icon = 'fas fa-tshirt',
                label = 'Open Outfit Bag',
                onSelect = function()
                    if not isNuiOpen then
                        isNuiOpen = true
                        originalOutfit = GetCurrentOutfit()
                        CreatePreviewCam()
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            action = 'open',
                            outfits = currentOutfits or {},
                            maxOutfits = Config.MaxOutfits
                        })
                    end
                end
            },
            {
                name = 'outfitbag_pickup',
                icon = 'fas fa-hand',
                label = 'Pickup Bag',
                onSelect = function()
                    PlayPickupBagAnimation()
                end
            }
        })
    end
    
    return bagProp
end

DeleteBagProp = function()
    if bagProp and DoesEntityExist(bagProp) then
        if Config.UseTarget then
            exports.ox_target:removeLocalEntity(bagProp, {'outfitbag_open', 'outfitbag_pickup'})
        end
        DeleteEntity(bagProp)
        bagProp = nil
    end
end

PlayPickupBagAnimation = function()
    if isAnimating then return end
    isAnimating = true
    
    local playerPed = PlayerPedId()
    
    if isNuiOpen then
        isNuiOpen = false
        DestroyPreviewCam()
        if originalOutfit then
            ApplyOutfit(originalOutfit)
            originalOutfit = nil
        end
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end
    
    LoadAnimDict(BagConfig.pickUp.dict)
    TaskPlayAnim(playerPed, BagConfig.pickUp.dict, BagConfig.pickUp.anim, 8.0, -8.0, BagConfig.pickUp.duration, 0, 0, false, false, false)
    
    Wait(600)
    DeleteBagProp()
    Wait(BagConfig.pickUp.duration - 600)
    
    ClearPedTasks(playerPed)
    isAnimating = false
    TriggerServerEvent('r4x_outfitbag:pickupBag')
end

local function PlayPutDownBagAnimation(callback)
    if isAnimating then 
        if callback then callback() end
        return 
    end
    isAnimating = true
    
    local playerPed = PlayerPedId()
    LoadAnimDict(BagConfig.bagAnimation.dict)
    TaskPlayAnim(playerPed, BagConfig.bagAnimation.dict, BagConfig.bagAnimation.anim, 4.0, 8.0, 1500, 1, 1, false, false, false)
    
    Wait(500)
    CreateBagProp()
    Wait(1000)
    
    ClearPedTasks(playerPed)
    isAnimating = false
    
    if callback then callback() end
end

local function PlayCloseBagAnimation()
    local playerPed = PlayerPedId()
    LoadAnimDict(BagConfig.bagAnimation.dict)
    TaskPlayAnim(playerPed, BagConfig.bagAnimation.dict, BagConfig.bagAnimation.anim, 4.0, 8.0, 1500, 1, 1, false, false, false)
    
    Wait(700)
    DeleteBagProp()
    Wait(800)
    ClearPedTasks(playerPed)
end

GetCurrentOutfit = function()
    local playerPed = PlayerPedId()
    local outfit = {}
    
    for i = 0, 11 do
        outfit['component_' .. i] = {
            drawable = GetPedDrawableVariation(playerPed, i),
            texture = GetPedTextureVariation(playerPed, i),
            palette = GetPedPaletteVariation(playerPed, i)
        }
    end
    
    for i = 0, 9 do
        outfit['prop_' .. i] = {
            drawable = GetPedPropIndex(playerPed, i),
            texture = GetPedPropTextureIndex(playerPed, i)
        }
    end
    
    outfit.hair_color = {
        color = GetPedHairColor(playerPed),
        highlight = GetPedHairHighlightColor(playerPed)
    }
    
    return outfit
end

ApplyOutfit = function(outfit)
    local playerPed = PlayerPedId()
    
    for i = 0, 11 do
        local comp = outfit['component_' .. i]
        if comp then
            SetPedComponentVariation(playerPed, i, comp.drawable, comp.texture, comp.palette or 0)
        end
    end
    
    for i = 0, 9 do
        local prop = outfit['prop_' .. i]
        if prop then
            if prop.drawable == -1 then
                ClearPedProp(playerPed, i)
            else
                SetPedPropIndex(playerPed, i, prop.drawable, prop.texture, true)
            end
        end
    end
    
    if outfit.hair_color then
        SetPedHairColor(playerPed, outfit.hair_color.color, outfit.hair_color.highlight)
    end
end

local function OpenOutfitBag(slot, outfits)
    if isNuiOpen or isAnimating then return end
    
    currentBagSlot = slot
    currentOutfits = outfits or {}
    originalOutfit = GetCurrentOutfit()
    
    if Config.UseTarget then
        PlayPutDownBagAnimation()
    else
        PlayPutDownBagAnimation(function()
            isNuiOpen = true
            CreatePreviewCam()
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'open',
                outfits = outfits or {},
                maxOutfits = Config.MaxOutfits
            })
        end)
    end
end

local function CloseOutfitBag()
    if not isNuiOpen then return end
    
    isNuiOpen = false
    DestroyPreviewCam()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    
    if not Config.UseTarget then
        currentBagSlot = nil
        PlayCloseBagAnimation()
    end
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    if originalOutfit then
        ApplyOutfit(originalOutfit)
        originalOutfit = nil
    end
    CloseOutfitBag()
    cb('ok')
end)

RegisterNUICallback('previewOutfit', function(data, cb)
    if data.outfit then
        if not originalOutfit then
            originalOutfit = GetCurrentOutfit()
        end
        ApplyOutfit(data.outfit)
    end
    cb('ok')
end)

RegisterNUICallback('resetPreview', function(data, cb)
    if originalOutfit then
        ApplyOutfit(originalOutfit)
    end
    cb('ok')
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    if not data.name or data.name == '' then
        SendNUIMessage({
            action = 'notify',
            message = Config.GetLocale('name_required'),
            type = 'error'
        })
        cb({ success = false })
        return
    end
    
    local outfit = GetCurrentOutfit()
    local slot = currentBagSlot or 1
    TriggerServerEvent('r4x_outfitbag:saveOutfit', slot, data.name, outfit)
    cb({ success = true })
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    if data.outfit then
        ApplyOutfit(data.outfit)
        SaveOutfitToSkin(data.outfit)
        originalOutfit = nil
        SendNUIMessage({
            action = 'notify',
            message = Config.GetLocale('outfit_loaded'),
            type = 'success'
        })
    end
    cb('ok')
end)

RegisterNUICallback('deleteOutfit', function(data, cb)
    local slot = currentBagSlot or 1
    TriggerServerEvent('r4x_outfitbag:deleteOutfit', slot, data.index)
    cb('ok')
end)

-- Events
RegisterNetEvent('r4x_outfitbag:openBag', function(slot, outfits)
    OpenOutfitBag(slot, outfits)
end)

RegisterNetEvent('r4x_outfitbag:updateOutfits', function(outfits)
    SendNUIMessage({
        action = 'updateOutfits',
        outfits = outfits or {},
        maxOutfits = Config.MaxOutfits
    })
end)

RegisterNetEvent('r4x_outfitbag:notify', function(message, notifyType)
    SendNUIMessage({
        action = 'notify',
        message = message,
        type = notifyType or 'info'
    })
end)

-- Control thread
CreateThread(function()
    while true do
        Wait(0)
        if isNuiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            
            if IsDisabledControlJustReleased(0, 322) then
                CloseOutfitBag()
            end
        else
            Wait(500)
        end
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    DestroyPreviewCam()
    DeleteBagProp()
    
    if isNuiOpen then
        SetNuiFocus(false, false)
        isNuiOpen = false
    end
    isAnimating = false
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Wait(500)
    local playerPed = PlayerPedId()
    if playerPed and playerPed ~= 0 then
        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)
    end
    
    DeleteBagProp()
    isNuiOpen = false
    isAnimating = false
    SetNuiFocus(false, false)
end)

-- Emergency fix command
RegisterCommand('fixbag', function()
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    DeleteBagProp()
    isNuiOpen = false
    isAnimating = false
    SetNuiFocus(false, false)
end, false)

exports('OpenOutfitBag', function(slot, outfits)
    OpenOutfitBag(slot, outfits)
end)
