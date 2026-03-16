
local FishManager = {}

local spawnTimer = 0

function FishManager.init()
    FishManager.fish = {}
    FishManager.inventory = {}
    spawnTimer = 0
end


local function pickFishDef()
    local df = Camera.depthFraction()
    local weights, total = {}, 0

    for i, fd in ipairs(fishDefs) do
        local w = fd.rarityWeight

        if fd.rarity == "common" then
            w = w * (1 - df * 0.7)

        elseif fd.rarity == "uncommon" then
            w = w * (0.8 + df * 0.6)

        elseif fd.rarity == "rare" then
            w = w * (0.6 + df * 0.7)

        elseif fd.rarity == "legendary" then
            w = w * (0.1 + df * df)
        end

        w = math.max(w, 0.5)
        weights[i] = w
        total = total + w
    end

    local r = math.random() * total
    for i, fd in ipairs(fishDefs) do
        r = r - weights[i]
        if r <= 0 then return fd end
    end

    return fishDefs[1]
end

local function spawnOne(layers, depths, mH)
    local def    = pickFishDef()
    local img    = def.img
    local iw, ih = img:getDimensions()
    local dir    = (math.random(2) == 1) and 1 or -1
    local speed  = math.random(12, 28) / 10


    local topY   = mH - layers[#layers]:getHeight() + 10 - Camera.offsetY
    local botY   = mH + depths[1]:getHeight() - 10 - Camera.offsetY
    local spawnY = math.random(math.floor(topY + ih), math.floor(botY - ih))
    local spawnX = (dir == 1) and (-iw - 2) or (Settings.MAP_W + 2)

    table.insert(FishManager.fish, Fish.new(def, spawnX, spawnY, dir, speed))
end

function FishManager.update(dt, layers, depths, mH, mW)
    if Camera.isInDepthZone() then
        spawnTimer = spawnTimer + dt
        local interval = Settings.FISH_SPAWN_INTERVAL * (0.4 + (1 - Camera.depthFraction()) * 0.6)
        if spawnTimer >= interval then
            spawnTimer = 0
            if #FishManager.fish < Settings.MAX_FISH then
                spawnOne(layers, depths, mH)
            end
        end
    else
        FishManager.fish = {}
        spawnTimer = 0
    end


    for i = #FishManager.fish, 1, -1 do
        local f = FishManager.fish[i]
        f:update(dt, love.timer and love.timer.getTime() or 0)
        if f:isOffScreen(mW) then
            table.remove(FishManager.fish, i)
        end
    end
end

function FishManager.draw(timer)
    for _, f in ipairs(FishManager.fish) do
        f:draw(timer)
    end
end


function FishManager.hitTest(screenX, screenY)
    local gx       = screenX / Settings.SCALE
    local gy       = screenY / Settings.SCALE
    local canvasGY = gy - Camera.offsetY

    for i = #FishManager.fish, 1, -1 do
        if FishManager.fish[i]:containsPoint(gx, canvasGY) then
            return i
        end
    end
    return nil
end


function FishManager.remove(idx)
    return table.remove(FishManager.fish, idx)
end

function FishManager.clear()
    FishManager.fish = {}
end

return FishManager
