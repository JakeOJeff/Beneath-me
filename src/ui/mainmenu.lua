-- ui/mainmenu.lua
-- Animated main menu screen

local MainMenu = {}

-- ─────────────────────────────────────────────────────────────
--  State
-- ─────────────────────────────────────────────────────────────

MainMenu.active    = true
MainMenu.fadeOut   = 0       -- 0=visible  →  1=faded out (then switch state)
MainMenu.timer     = 0


-- Wave lines for water shimmer
local waves        = {}
local NUM_WAVES    = 7

-- Buttons
local buttons = {
    { id = "play",    label = "CAST OFF",    sub = "Begin your voyage" },
    { id = "credits", label = "THE LOGBOOK", sub = "View credits"       },
    { id = "quit",    label = "ABANDON SHIP",sub = "Quit game"          },
}

-- ─────────────────────────────────────────────────────────────
--  Init
-- ─────────────────────────────────────────────────────────────

function MainMenu.init(wW, wH)
    MainMenu.wW    = wW
    MainMenu.wH    = wH
    MainMenu.timer = 0
    MainMenu.fadeOut = 0
    MainMenu.active  = true
    MainMenu._callback = nil

    -- wave lines
    waves = {}
    for i = 1, NUM_WAVES do
        waves[i] = {
            y      = wH * 0.38 + (i - 1) * (wH * 0.12),
            phase  = math.random() * math.pi * 2,
            amp    = math.random(3, 10),
            freq   = math.random(2, 5) / wW * math.pi,
            speed  = (math.random(6, 16) / 10) * (math.random(2) == 1 and 1 or -1),
            alpha  = 0.04 + (i / NUM_WAVES) * 0.07,
        }
    end

    -- build button rects
    local btnW = 260
    local btnH = 60
    local gap  = 16
    local totalH = #buttons * btnH + (#buttons - 1) * gap
    local startY = wH * 0.55

    for i, b in ipairs(buttons) do
        b.x    = (wW - btnW) / 2
        b.y    = startY + (i - 1) * (btnH + gap)
        b.w    = btnW
        b.h    = btnH
        b.anim = 0   -- hover
    end
end

-- ─────────────────────────────────────────────────────────────
--  Update
-- ─────────────────────────────────────────────────────────────

function MainMenu.update(dt)
    MainMenu.timer = MainMenu.timer + dt

    -- wave phase
    for _, w in ipairs(waves) do
        w.phase = w.phase + w.speed * dt
    end

    -- button hover lerp
    local mx, my = love.mouse.getPosition()
    for _, b in ipairs(buttons) do
        local over = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
        local target = over and 1 or 0
        b.anim = b.anim + (target - b.anim) * math.min(1, dt * 10)
    end

    -- fade-out for state transition
    if MainMenu.fadeOut > 0 then
        MainMenu.fadeOut = MainMenu.fadeOut + dt * 2.2
        if MainMenu.fadeOut >= 1 and MainMenu._callback then
            MainMenu.active = false
            MainMenu._callback()
            MainMenu._callback = nil
        end
    end
end

-- ─────────────────────────────────────────────────────────────
--  Draw helpers
-- ─────────────────────────────────────────────────────────────

local function setC(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end
local function white(a)         love.graphics.setColor(1, 1, 1, a or 1) end

-- Ornamental horizontal rule
local function drawRule(cx, y, hw, a)
    setC(0.30, 0.70, 0.80, a)
    love.graphics.line(cx - hw, y, cx - 12, y)
    love.graphics.line(cx + 12, y, cx + hw, y)
    -- diamond in center
    love.graphics.polygon("fill",
        cx,      y - 4,
        cx + 5,  y,
        cx,      y + 4,
        cx - 5,  y)
end

-- Rope-corner border  (rounded rect with notched corners)
local function drawBorder(x, y, w, h, a)
    local nc = 10  -- notch size
    setC(0.25, 0.60, 0.75, a * 0.70)
    love.graphics.setLineWidth(1)
    love.graphics.polygon("line",
        x + nc, y,
        x + w - nc, y,
        x + w, y + nc,
        x + w, y + h - nc,
        x + w - nc, y + h,
        x + nc, y + h,
        x, y + h - nc,
        x, y + nc)
    love.graphics.setLineWidth(1)
end

-- ─────────────────────────────────────────────────────────────
--  Draw
-- ─────────────────────────────────────────────────────────────

function MainMenu.draw(font)
    if not MainMenu.active then return end
    local wW, wH = MainMenu.wW, MainMenu.wH
    local t      = MainMenu.timer
    local alpha  = 1 - math.max(0, MainMenu.fadeOut)

    -- ── Deep ocean gradient background ──────────────────────
    -- simulate with layered rects
    setC(0.00, 0.04, 0.12, alpha)
    love.graphics.rectangle("fill", 0, 0, wW, wH)
    setC(0.00, 0.06, 0.18, alpha * 0.7)
    love.graphics.rectangle("fill", 0, wH * 0.3, wW, wH * 0.7)
    setC(0.00, 0.02, 0.08, alpha * 0.5)
    love.graphics.rectangle("fill", 0, wH * 0.65, wW, wH * 0.35)


    -- ── Wave lines ───────────────────────────────────────────
    love.graphics.setLineWidth(1.5)
    for _, w in ipairs(waves) do
        setC(0.20, 0.65, 0.90, alpha * w.alpha)
        local pts = {}
        local steps = 60
        for s = 0, steps do
            local wx = wW * s / steps
            local wy = w.y + math.sin(wx * w.freq + w.phase) * w.amp
            pts[#pts + 1] = wx
            pts[#pts + 1] = wy
        end
        if #pts >= 4 then love.graphics.line(pts) end
    end
    love.graphics.setLineWidth(1)


    -- ── Glow behind title ─────────────────────────────────────
    local tcx = wW / 2
    local tcy = wH * 0.22
    for i = 3, 1, -1 do
        setC(0.10, 0.60, 0.85, alpha * 0.06 * i)
        love.graphics.circle("fill", tcx, tcy, 120 * i)
    end

    -- ── Title ─────────────────────────────────────────────────
    love.graphics.setFont(font.title or font.h)
    local title1 = "Beneath"
    local title2 = "Me"
    local tw1    = (font.title or font.h):getWidth(title1)
    local tw2    = (font.title or font.h):getWidth(title2)
    local th1    = (font.title or font.h):getWidth(title1)
    local th2    = (font.title or font.h):getWidth(title2)

    -- shadow layers
    for off = 4, 1, -1 do
        setC(0, 0.2, 0.4, alpha * 0.15 * off)
        love.graphics.print(title1, tcx - tw1 / 2 + off, tcy - 32 + off)
        love.graphics.print(title2, tcx - tw2 / 2 + off, tcy + off)
    end
    -- main text
    setC(0.55, 0.92, 1, alpha)
    love.graphics.print(title1, tcx - tw1 / 2, tcy - font.:getHeight())
    setC(0.90, 0.98, 1, alpha)
    love.graphics.print(title2, tcx - tw2 / 2, tcy)

    -- tagline
    love.graphics.setFont(font.sm)
    local tag = "dive deep  ·  catch rare  ·  grow wealthy"
    local tagW = font.sm:getWidth(tag)
    local tagPulse = 0.55 + math.sin(t * 1.8) * 0.15
    setC(0.45, 0.75, 0.90, alpha * tagPulse)
    love.graphics.print(tag, tcx - tagW / 2, tcy + (font.title or font.h):getHeight() + 6)

    -- ── Buttons ───────────────────────────────────────────────
    for i, b in ipairs(buttons) do
        local ha  = b.anim  -- hover 0→1
        local stagger = math.max(0, math.min(1, (t - i * 0.18) * 3))

        local bAlpha = alpha * stagger
        local slideX = (1 - stagger) * 40

        -- outer glow on hover
        if ha > 0.02 then
            setC(0.15, 0.60, 0.90, bAlpha * ha * 0.25)
            love.graphics.rectangle("fill",
                b.x - 6 + slideX, b.y - 4, b.w + 12, b.h + 8, 7, 7)
        end

        -- button bg
        local bgR = 0.04 + ha * 0.10
        local bgG = 0.10 + ha * 0.18
        local bgB = 0.22 + ha * 0.22
        setC(bgR, bgG, bgB, bAlpha * 0.92)
        love.graphics.rectangle("fill", b.x + slideX, b.y, b.w, b.h, 5, 5)

        -- border
        drawBorder(b.x + slideX, b.y, b.w, b.h, bAlpha)

        -- left accent strip
        setC(0.20 + ha * 0.30, 0.65 + ha * 0.20, 0.90, bAlpha)
        love.graphics.rectangle("fill", b.x + slideX, b.y, 4, b.h, 3, 3)

        -- label
        love.graphics.setFont(font.sm)
        local lw = font.sm:getWidth(b.label)
        setC(0.85 + ha * 0.15, 0.95 + ha * 0.05, 1, bAlpha)
        love.graphics.print(b.label,
            b.x + slideX + (b.w - lw) / 2,
            b.y + b.h / 2 - font.sm:getHeight() / 2 - 6)

        -- sub-label
        local sw = font.sm:getWidth(b.sub)
        setC(0.45 + ha * 0.20, 0.72 + ha * 0.15, 0.85, bAlpha * 0.75)
        love.graphics.print(b.sub,
            b.x + slideX + (b.w - sw) / 2,
            b.y + b.h / 2 + 2)
    end

    love.graphics.setFont(font.sm)
    setC(0.25, 0.45, 0.60, alpha * 0.55)
    love.graphics.print("v0.1.3 · early access", 10, wH - font.sm:getHeight() - 6)

    -- ── Fade overlay ──────────────────────────────────────────
    if MainMenu.fadeOut > 0 then
        setC(0, 0.03, 0.10, math.min(1, MainMenu.fadeOut))
        love.graphics.rectangle("fill", 0, 0, wW, wH)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- ─────────────────────────────────────────────────────────────
--  Input
-- ─────────────────────────────────────────────────────────────

function MainMenu.mousepressed(x, y, button, callback)
    if button ~= 1 then return end
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            if b.id == "play" then
                -- trigger fade-out, then call callback
                MainMenu.fadeOut   = 0.001
                MainMenu._callback = callback
            elseif b.id == "quit" then
                love.event.quit()
            end
            return
        end
    end
end

return MainMenu