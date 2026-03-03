

local fishDefs = {
    {
        name         = "Tuna",
        img          = nil,   -- loaded at runtime by assets.lua
        imgPath      = "assets/fishes/tuna.png",
        rarity       = "common",
        rarityWeight = 60,
        points       = 10,
        color        = { 0.6, 1, 0.6 },
    },
    {
        name         = "Golden Tuna",
        img          = nil,
        imgPath      = "assets/fishes/golden-tuna.png",
        rarity       = "rare",
        rarityWeight = 25,
        points       = 50,
        color        = { 1, 0.85, 0.2 },
    },
    {
        name         = "Slobbering Tuna",
        img          = nil,
        imgPath      = "assets/fishes/slobbering-tuna.png",
        rarity       = "legendary",
        rarityWeight = 15,
        points       = 150,
        color        = { 1, 0.4, 1 },
    },
}

return fishDefs