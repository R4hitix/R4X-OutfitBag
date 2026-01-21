-- R4X Outfit Bag | Server | by R4X Labs

local ESX = exports['es_extended']:getSharedObject()
local outfitCache = {}
local playersWithBagDown = {}

-- Create database table
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `r4x_outfit_bags` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `slot` INT NOT NULL,
            `outfits` LONGTEXT DEFAULT '[]',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_bag` (`identifier`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function GetBagOutfits(identifier, slot, cb)
    local cacheKey = identifier .. '_' .. slot
    
    if outfitCache[cacheKey] then
        cb(outfitCache[cacheKey])
        return
    end
    
    MySQL.query('SELECT outfits FROM r4x_outfit_bags WHERE identifier = ? AND slot = ?', {identifier, slot}, function(result)
        local outfits = {}
        if result and result[1] then
            outfits = json.decode(result[1].outfits) or {}
        end
        outfitCache[cacheKey] = outfits
        cb(outfits)
    end)
end

local function SaveBagOutfits(identifier, slot, outfits, cb)
    local cacheKey = identifier .. '_' .. slot
    outfitCache[cacheKey] = outfits
    
    MySQL.query([[
        INSERT INTO r4x_outfit_bags (identifier, slot, outfits) 
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE outfits = VALUES(outfits)
    ]], {identifier, slot, json.encode(outfits)}, function(result)
        if cb then cb(result) end
    end)
end

-- Item use
ESX.RegisterUsableItem(Config.ItemName, function(source, item, itemData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if playersWithBagDown[source] then
        TriggerClientEvent('r4x_outfitbag:notify', source, Config.GetLocale('bag_already_down'), 'error')
        return
    end
    
    local identifier = xPlayer.getIdentifier()
    local bagSlot = 1
    
    exports.ox_inventory:RemoveItem(source, Config.ItemName, 1)
    
    playersWithBagDown[source] = {
        identifier = identifier,
        slot = bagSlot
    }
    
    GetBagOutfits(identifier, bagSlot, function(outfits)
        TriggerClientEvent('r4x_outfitbag:openBag', source, bagSlot, outfits)
    end)
end)

-- Pickup bag
RegisterNetEvent('r4x_outfitbag:pickupBag', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if playersWithBagDown[source] then
        exports.ox_inventory:AddItem(source, Config.ItemName, 1)
        playersWithBagDown[source] = nil
    end
end)

-- Save outfit
RegisterNetEvent('r4x_outfitbag:saveOutfit', function(slot, name, outfitData)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local bagSlot = slot or 1
    
    GetBagOutfits(identifier, bagSlot, function(outfits)
        if #outfits >= Config.MaxOutfits then
            TriggerClientEvent('r4x_outfitbag:notify', source, string.format(Config.GetLocale('bag_full'), Config.MaxOutfits), 'error')
            return
        end
        
        table.insert(outfits, {
            name = name,
            data = outfitData,
            savedAt = os.date('%d/%m/%Y %H:%M')
        })
        
        SaveBagOutfits(identifier, bagSlot, outfits, function()
            TriggerClientEvent('r4x_outfitbag:notify', source, Config.GetLocale('outfit_saved'), 'success')
            TriggerClientEvent('r4x_outfitbag:updateOutfits', source, outfits)
        end)
    end)
end)

-- Delete outfit
RegisterNetEvent('r4x_outfitbag:deleteOutfit', function(slot, index)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local bagSlot = slot or 1
    
    GetBagOutfits(identifier, bagSlot, function(outfits)
        if outfits[index] then
            table.remove(outfits, index)
            
            SaveBagOutfits(identifier, bagSlot, outfits, function()
                TriggerClientEvent('r4x_outfitbag:notify', source, Config.GetLocale('outfit_deleted'), 'success')
                TriggerClientEvent('r4x_outfitbag:updateOutfits', source, outfits)
            end)
        end
    end)
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if playersWithBagDown[source] then
        if xPlayer then
            exports.ox_inventory:AddItem(source, Config.ItemName, 1)
        end
        playersWithBagDown[source] = nil
    end
    
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        for key in pairs(outfitCache) do
            if string.find(key, identifier) then
                outfitCache[key] = nil
            end
        end
    end
end)
