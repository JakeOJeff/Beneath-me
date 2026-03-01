-- ============================================================
--  DEEP DIVE  –  depth-based fishing exploration
-- ============================================================

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    -- ── window / world ──────────────────────────────────────
    mW, mH   = 140, 88
    scale    = 10
    wW, wH   = mW * scale, mH * scale
    love.window.setMode(wW, wH)

    -- ── assets ──────────────────────────────────────────────
    layers = {}
    stableSky  = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy   = love.graphics.newImage("assets/watertop/buoy.png")
    depths = {
        love.graphics.newImage("assets/depths/1.png"),
        love.graphics.newImage("assets/depths/2.png"),
    }
    ruler   = love.graphics.newImage("assets/depth-bar.png")
    pointer = love.graphics.newImage("assets/pointer.png")

    -- fonts in screen-space pixels
    font = {
        h  = love.graphics.newFont("fonts/jersey.ttf", 36),
        sm = love.graphics.newFont("fonts/jersey.ttf", 28),
    }

    fishDefs = {
        { name = "Tuna",           img = love.graphics.newImage("assets/fishes/tuna.png"),           rarity = "common",    rarityWeight = 60, points = 10,  color = {0.6,1,0.6}  },
        { name = "Golden Tuna",    img = love.graphics.newImage("assets/fishes/golden-tuna.png"),    rarity = "rare",      rarityWeight = 25, points = 50,  color = {1,0.85,0.2} },
        { name = "Slobbering Tuna",img = love.graphics.newImage("assets/fishes/slobbering-tuna.png"),rarity = "legendary", rarityWeight = 15, points = 150, color = {1,0.4,1}   },
    }

    -- ── state ───────────────────────────────────────────────
    timer         = 0
    player        = { x = 0, y = 0 }
    baseY         = player.y
    ox, oy        = 0, 0

    canvasOffsetY = -10          -- negative = scrolled down
    dragActive    = false
    dragLastY     = 0
    dragVelocityY = 0
    friction      = 0.98

    score         = 0
    catchFeedback = nil

    DEPTH_ZONE_THRESHOLD = -70  
    MAX_DEPTH = -(depths[1]:getHeight() * 2 - mH + 10)

    activeFishes  = {}
    fishSpawnTimer = 0
    FISH_SPAWN_INTERVAL = 2.5

    -- surface button in screen-space pixels
    surfaceBtn = {
        x = 14, y = 14,
        w = 120, h = 34,
        label = "▲ Surface"
    }

    particles = {}
end


function distFromCenter(x, y)
    return (mW / 2) - x, (mH / 2) - y
end

function isInDepthZone()
    return canvasOffsetY < DEPTH_ZONE_THRESHOLD
end

-- depth 0-1 (0 = threshold, 1 = max depth)
function depthFraction()
    local range = MAX_DEPTH - DEPTH_ZONE_THRESHOLD
    return math.min(1, math.max(0, (canvasOffsetY - DEPTH_ZONE_THRESHOLD) / range))
end

-- weighted random pick
function pickFishByDepth()
    local df = depthFraction()  

    local weights = {}
    local total   = 0
    for i, fd in ipairs(fishDefs) do
        local w = fd.rarityWeight
        if fd.rarity == "common"    then w = w * (1 - df * 0.7) end
        if fd.rarity == "rare"      then w = w * (0.3 + df * 0.7) end
        if fd.rarity == "legendary" then w = w * (df * df) end
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

function spawnFish()
    local def   = pickFishByDepth()
    local img   = def.img
    local iw, ih = img:getDimensions()
    local dir   = (math.random(2) == 1) and 1 or -1
    local speed = math.random(12, 28) / 10

    local topY  = mH - layers[#layers]:getHeight() + 10 - canvasOffsetY
    local botY  = mH + depths[1]:getHeight() - 10 - canvasOffsetY
    local spawnY = math.random(math.floor(topY + ih), math.floor(botY - ih))
    local spawnX = (dir == 1) and (-iw - 2) or (mW + 2)

    local bobPhase = math.random() * math.pi * 2

    table.insert(activeFishes, {
        def      = def,
        x        = spawnX,
        y        = spawnY,
        dir      = dir,
        speed    = speed,
        bobPhase = bobPhase,
        alive    = true,
        flashTimer = 0,
    })
end

function returnToSurface()
    dragVelocityY = 0
    local dist = math.abs(canvasOffsetY - (-10))
    dragVelocityY = dist * 0.12
    activeFishes  = {}
end



function love.update(dt)
    timer = timer + dt
    ox, oy = distFromCenter(player.x, player.y)

    local amplitude = (canvasOffsetY < -90) and 1 or 12
    player.y       = baseY + math.sin(timer * 3) * amplitude
    player.rotation = math.sin(timer * 3) * 0.02

    -- momentum
    if not dragActive then
        canvasOffsetY = math.min(canvasOffsetY + dragVelocityY, -10)
        canvasOffsetY = math.max(canvasOffsetY, MAX_DEPTH)
        dragVelocityY = dragVelocityY * friction
        if math.abs(dragVelocityY) < 0.01 then dragVelocityY = 0 end
    end

    -- fish spawning
    if isInDepthZone() then
        fishSpawnTimer = fishSpawnTimer + dt
        local interval = FISH_SPAWN_INTERVAL * (0.4 + (1 - depthFraction()) * 0.6)
        if fishSpawnTimer >= interval then
            fishSpawnTimer = 0
            if #activeFishes < 6 then spawnFish() end
        end
    else
        if #activeFishes > 0 then activeFishes = {} end
        fishSpawnTimer = 0
    end

    -- update fish
    for i = #activeFishes, 1, -1 do
        local f = activeFishes[i]
        f.x = f.x + f.dir * f.speed * dt
        f.y = f.y + math.sin(timer * 2 + f.bobPhase) * 0.08
        f.flashTimer = math.max(0, f.flashTimer - dt)

        local iw = f.def.img:getWidth()
        if (f.dir == 1 and f.x > mW + iw + 5) or
           (f.dir == -1 and f.x < -iw - 5) then
            table.remove(activeFishes, i)
        end
    end

    -- catch feedback timer
    if catchFeedback then
        catchFeedback.timer = catchFeedback.timer - dt
        if catchFeedback.timer <= 0 then catchFeedback = nil end
    end

    -- particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 30 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end


function love.mousepressed(x, y, button)
    if button == 1 then
        -- surface button in screen-space pixels
        if x >= surfaceBtn.x and x <= surfaceBtn.x + surfaceBtn.w and
           y >= surfaceBtn.y and y <= surfaceBtn.y + surfaceBtn.h then
            returnToSurface()
            return
        end

        -- fish click — convert screen px → game units → canvas space
        local gx = x / scale
        local gy = y / scale
        local canvasGY = gy - canvasOffsetY
        for i = #activeFishes, 1, -1 do
            local f  = activeFishes[i]
            local img = f.def.img
            local iw, ih = img:getDimensions()
            if gx >= f.x and gx <= f.x + iw and
               canvasGY >= f.y and canvasGY <= f.y + ih then
                catchFish(i)
                return
            end
        end

        dragActive    = true
        dragLastY     = y / scale
        dragVelocityY = 0
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then dragActive = false end
end

function love.mousemoved(x, y, dx, dy)
    if dragActive then
        local gy = y / scale
        dragVelocityY = gy - dragLastY
        dragLastY     = gy
        canvasOffsetY = math.min(canvasOffsetY + dragVelocityY, -10)
        canvasOffsetY = math.max(canvasOffsetY, MAX_DEPTH)
    end
end

function catchFish(idx)
    local f   = activeFishes[idx]
    local def = f.def
    score = score + def.points

    local img = def.img
    local cx  = (f.x + img:getWidth()/2) * scale
    local cy  = (f.y + canvasOffsetY + img:getHeight()/2) * scale
    for _ = 1, 20 do
        table.insert(particles, {
            x = cx, y = cy,
            vx = math.random(-80, 80),
            vy = math.random(-120, -20),
            life = math.random(5, 12) / 10,
            r = def.color[1], g = def.color[2], b = def.color[3],
        })
    end

    catchFeedback = {
        text  = "+" .. def.points .. "  " .. def.name .. "!",
        timer = 2.5,
        color = def.color,
    }

    table.remove(activeFishes, idx)
    returnToSurface()
end



function love.draw()
    love.graphics.push()
    love.graphics.scale(scale, scale)

        -- ── world rotation (buoy bob) ──
        love.graphics.push()
        love.graphics.translate(mW/2, mH/2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)
        love.graphics.translate(-mW/2, -mH/2)

            -- ── vertical scroll ──
            love.graphics.push()
            love.graphics.translate(0, canvasOffsetY)

                -- backgrounds
                local depthBgY = (mH - layers[#layers]:getHeight()) + 35
                love.graphics.draw(depths[2], 0, depthBgY + depths[1]:getHeight())
                love.graphics.draw(depths[1], 0, depthBgY)

                -- sky
                love.graphics.draw(stableSky, 0, -44 + oy/10)

                -- water layers
                for i = 1, #layers do
                    love.graphics.draw(layers[i], 0,
                        (mH - layers[i]:getHeight()) + oy/10 * i)
                end

                -- buoy
                love.graphics.draw(buoy, 0,
                    (mH - layers[#layers]:getHeight()) +
                    oy/10 * #layers - buoy:getHeight())

                -- ── depth zone overlay (subtle dark tint) ──
                if isInDepthZone() then
                    local df = depthFraction()
                    love.graphics.setColor(0, 0.05, 0.2, df * 0.45)
                    love.graphics.rectangle("fill", 0, 0, mW, mH * 4)
                    love.graphics.setColor(1,1,1,1)
                end

                -- ── fish ──
                for _, f in ipairs(activeFishes) do
                    local img = f.def.img
                    local iw, ih = img:getDimensions()

                    if f.flashTimer > 0 then
                        love.graphics.setColor(1, 1, 1, 0.5 + math.sin(f.flashTimer*40)*0.5)
                    end

                    if f.dir == -1 then
                        love.graphics.draw(img, f.x + iw, f.y, 0, -1, 1)
                    else
                        love.graphics.draw(img, f.x, f.y)
                    end
                    love.graphics.setColor(1,1,1,1)

                    -- rarity glow dot above fish
                    local gc = f.def.color
                    love.graphics.setColor(gc[1], gc[2], gc[3], 0.85)
                    love.graphics.circle("fill", f.x + iw/2, f.y - 2, 1)
                    love.graphics.setColor(1,1,1,1)
                end

            love.graphics.pop()  -- scroll

        love.graphics.pop()  -- rotation

        -- ── ruler & pointer (fixed, screen space) ──
        local rulerX = mW - ruler:getWidth() - 5
        local rulerY = mH/2 - ruler:getHeight()/2
        love.graphics.draw(ruler, rulerX, rulerY)

        local pY = rulerY - 1 +
            ((-canvasOffsetY) / (depths[1]:getHeight() * 2)) * ruler:getHeight()
        love.graphics.draw(pointer, rulerX - 4, pY)

        -- depth zone indicator on ruler
        local zoneY = rulerY + ((-DEPTH_ZONE_THRESHOLD) / (depths[1]:getHeight() * 2)) * ruler:getHeight()
        love.graphics.setColor(0.3, 0.8, 1, 0.9)
        love.graphics.line(rulerX - 3, zoneY, rulerX + ruler:getWidth() + 1, zoneY)
        love.graphics.setColor(1,1,1,1)

    love.graphics.pop()  -- scale

    -- ══════════════════════════════════════════════════════
    --  ALL HUD below this line is in true screen-space pixels
    -- ══════════════════════════════════════════════════════

    -- ── surface button ──
    local sb = surfaceBtn
    local btnAlpha = isInDepthZone() and 1 or 0.35
    love.graphics.setColor(0.1, 0.2, 0.4, 0.85 * btnAlpha)
    love.graphics.rectangle("fill", sb.x, sb.y, sb.w, sb.h, 4, 4)
    love.graphics.setColor(0.5, 0.85, 1, btnAlpha)
    love.graphics.rectangle("line", sb.x, sb.y, sb.w, sb.h, 4, 4)
    love.graphics.setColor(1, 1, 1, btnAlpha)
    love.graphics.setFont(font.sm)
    local lblW = font.sm:getWidth(sb.label)
    love.graphics.print(sb.label, sb.x + (sb.w - lblW) / 2, sb.y + (sb.h - font.sm:getHeight()) / 2)
    love.graphics.setColor(1,1,1,1)

    -- ── score (top-right) ──
    love.graphics.setFont(font.h)
    local scoreText = "Score: " .. score
    local scoreW = font.h:getWidth(scoreText)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.print(scoreText, wW - scoreW - 14 + 1, 16 + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(scoreText, wW - scoreW - 14, 16)

    -- ── "drag down" hint ──
    if not isInDepthZone() then
        local hintText = "Drag down to fish"
        local alpha = math.abs(math.sin(timer * 1.5)) * 0.7 + 0.2
        love.graphics.setFont(font.sm)
        local hintW = font.sm:getWidth(hintText)
        love.graphics.setColor(0.6, 0.9, 1, alpha)
        love.graphics.print(hintText, (wW - hintW) / 2, wH - 30)
        love.graphics.setColor(1,1,1,1)
    end

    -- ── "DEPTH ZONE" banner ──
    if isInDepthZone() and depthFraction() < 0.05 then
        local bannerText = "~ DEPTH ZONE ~"
        love.graphics.setFont(font.h)
        local bw = font.h:getWidth(bannerText)
        love.graphics.setColor(0.3, 0.8, 1, 0.9)
        love.graphics.print(bannerText, (wW - bw) / 2, wH / 2 - 13)
        love.graphics.setColor(1,1,1,1)
    end

    -- ── catch feedback ──
    if catchFeedback then
        local cf = catchFeedback
        local fade = math.min(1, cf.timer / 0.5)
        love.graphics.setFont(font.h)
        local tw = font.h:getWidth(cf.text)
        -- drop shadow
        love.graphics.setColor(0, 0, 0, fade * 0.5)
        love.graphics.print(cf.text, (wW - tw) / 2 + 1, wH / 2 - 13 + 1)
        love.graphics.setColor(cf.color[1], cf.color[2], cf.color[3], fade)
        love.graphics.print(cf.text, (wW - tw) / 2, wH / 2 - 13)
        love.graphics.setColor(1,1,1,1)
    end

    -- ── particles (true screen space) ──
    for _, p in ipairs(particles) do
        local a = math.min(1, p.life * 2)
        love.graphics.setColor(p.r, p.g, p.b, a)
        love.graphics.rectangle("fill", p.x, p.y, 4, 4)
    end
    love.graphics.setColor(1,1,1,1)
end