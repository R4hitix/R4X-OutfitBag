# R4X Outfit Bag

A bag to save your favorite outfits. Simple, works well.

[preview.png](https://cdn.discordapp.com/attachments/1335760717110054914/1463350866089214045/Screenshot_2026-01-21_015114.png?ex=69718332&is=697031b2&hm=391e6b2a2a6574ffb1713f8dfce1fb59823fc780baf35a138d8cf4f14fde3907&)

## What it does

- Save up to 5 outfits
- Live preview when you hover over them
- Outfits persist after relog
- Nice leather bag UI
- ox_target support

## Dependencies

- es_extended
- ox_lib
- ox_inventory
- ox_target (optional but recommended)
- oxmysql

## Installation

1. Put `r4x_outfitbag` folder in your resources

2. Add the item to `ox_inventory/data/items.lua`:
```lua
['outfit_bag'] = {
    label = 'Outfit Bag',
    weight = 500,
    stack = false,
    close = true,
    description = 'Save your outfits',
},
```

3. Copy `outfit_bag.png` to `ox_inventory/web/images/`

4. Start the resource in server.cfg or put it in an already started folder

5. Give yourself the item: `/giveitem [id] outfit_bag 1`

## Configuration

Open `config.lua`:
- `Config.Locale` - Change language ('it' or 'en')
- `Config.MaxOutfits` - How many outfits per bag
- `Config.UseTarget` - Use ox_target or not

## How to use

1. Use the item from inventory
2. Bag gets placed on the ground
3. With ox_target you can open or pick it up
4. In the interface: hover to preview, click to wear/delete
5. ESC to close

## Commands

`/fixbag` - If you get stuck for some reason

---

by R4X Labs
