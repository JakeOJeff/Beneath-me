

local fishDefs = {
    {
        name         = "Tuna",
        img          = nil,
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
        rarity       = "uncommon",
        rarityWeight = 40,
        points       = 50,
        color        = { 1, 0.85, 0.2 },
    },
    {
        name         = "Slobbering Tuna",
        img          = nil,
        imgPath      = "assets/fishes/slobbering-tuna.png",
        rarity       = "rare",
        rarityWeight = 20,
        points       = 150,
        color        = { 1, 0.4, 1 },
    },
        {
        name         = "Shark",
        img          = nil,
        imgPath      = "assets/fishes/shark.png",
        rarity       = "legendary",
        rarityWeight = 100,
        points       = 400,
        color        = { 0.5, 0.4, 1 },
    },
}

return fishDefs
