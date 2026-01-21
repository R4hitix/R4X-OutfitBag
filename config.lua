-- R4X Outfit Bag | Config | by R4X Labs

Config = {}

Config.MaxOutfits = 5
Config.ItemName = 'outfit_bag'
Config.UseTarget = true
Config.Locale = 'en' -- 'en' or 'it'

Config.Locales = {
    ['en'] = {
        outfit_saved = 'Outfit saved!',
        outfit_loaded = 'Outfit equipped!',
        outfit_deleted = 'Outfit deleted!',
        bag_full = 'Bag is full! Max %s outfits.',
        name_required = 'Enter a name!',
        bag_already_down = 'You already have a bag on the ground!'
    },
    ['it'] = {
        outfit_saved = 'Outfit salvato!',
        outfit_loaded = 'Outfit indossato!',
        outfit_deleted = 'Outfit eliminato!',
        bag_full = 'Borsa piena! Max %s outfit.',
        name_required = 'Inserisci un nome!',
        bag_already_down = 'Hai già una borsa a terra!'
    }
}

function Config.GetLocale(key)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    return locale[key] or key
end
