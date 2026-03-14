-- ui/hud.lua
-- Draws all screen-space HUD elements

local Settings = require("src.conf.settings")
local Camera   = require("src.systems.camera")

local HUD = {}

-- ─────────────────────────────────────────────────────────────
--  Button geometry (screen-space pixels)
-- ─────────────────────────────────────────────────────────────

HUD.surfaceBtn   = { x = 14, y = 14,          w = 120, h = 34, label = "Surface"   }
HUD.inventoryBtn = { x = 14, y = 14 + 34 + 5, w = 120, h = 34, label = "Inventory" }

-- ─────────────────────────────────────────────────────────────
--  Inventory panel state
-- ─────────────────────────────────────────────────────────────

HUD.inventoryOpen   = false
HUD.invScroll       = 0          -- vertical scroll offset (pixels)
HUD.invScrollTarget = 0          -- for smooth scrolling
HUD.invAnim         = 0          -- 0 = fully closed, 1 = fully open  (lerped)

-- Layout constants
local INV_W        = 320         -- panel width  (screen px)
local INV_PAD      = 12          -- inner padding
local CARD_H       = 64          -- height of each fish card
local CARD_GAP     = 6           -- gap between cards
local HEADER_H     = 40          -- panel title bar
local CLOSE_SIZE   = 24          -- close button square
local PANEL_MAX_H  = 480         -- max visible panel height
local SCROLL_SPEED = 60          -- pixels per scroll event

-- ─────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────

function HUD.hitBtn(button, sx, sy)
    local b = button
    return sx >= b.x and sx <= b.x + b.w
       and sy >= b.y and sy <= b.y + b.h
end

-- Returns true if (sx,sy) is inside the inventory panel (when open).
function HUD.hitInventoryPanel(sx, sy, wW, wH)
    if HUD.invAnim < 0.01 then return false end
    local pw = INV_W
    local ph = math.min(PANEL_MAX_H, wH - 60)
    local px = (wW - pw) / 2
    local py = (wH - ph) / 2
    return sx >= px and sx <= px + pw and sy >= py and sy <= py + ph
end


function HUD.toggleInventory()
    HUD.inventoryOpen = not HUD.inventoryOpen
    -- reset scroll when reopening
    if HUD.inventoryOpen then
        HUD.invScrollTarget = 0
    end
end

-- Call every frame from love.update
function HUD.update(dt)
    local target = HUD.inventoryOpen and 1 or 0
    HUD.invAnim  = HUD.invAnim + (target - HUD.invAnim) * math.min(1, dt * 12)

    -- smooth scroll
    HUD.invScroll = HUD.invScroll + (HUD.invScrollTarget - HUD.invScroll) * math.min(1, dt * 14)
end

-- Rarity color table
local rarityColors = {
    common    = { 0.75, 0.85, 0.95 },
    rare      = { 0.35, 0.65, 1.00 },
    legendary = { 1.00, 0.80, 0.20 },
}

local rarityGlow = {
    common    = { 0.55, 0.75, 0.95, 0.18 },
    rare      = { 0.20, 0.50, 1.00, 0.30 },
    legendary = { 1.00, 0.75, 0.10, 0.40 },
}

-- ─────────────────────────────────────────────────────────────
--  Inventory panel draw
-- ─────────────────────────────────────────────────────────────

function HUD.drawInventory(font, inventory, wW, wH)
    if HUD.invAnim < 0.005 then return end

    local a  = HUD.invAnim  -- alpha / scale factor
    local ph = math.min(PANEL_MAX_H, wH - 60)
    local pw = INV_W
    local px = (wW - pw) / 2
    local py = (wH - ph) / 2

    -- ── slide-in from bottom ────────────────────────────────
    local slideY = (1 - a) * (ph * 0.35)
    love.graphics.push()
    love.graphics.translate(0, slideY)

    -- ── panel shadow ────────────────────────────────────────
    love.graphics.setColor(0, 0, 0, 0.55 * a)
    love.graphics.rectangle("fill", px + 5, py + 8, pw, ph, 8, 8)

    -- ── panel background ────────────────────────────────────
    love.graphics.setColor(0.04, 0.09, 0.20, 0.96 * a)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)

    -- ── border ──────────────────────────────────────────────
    love.graphics.setColor(0.25, 0.55, 0.90, 0.70 * a)
    love.graphics.rectangle("line", px, py, pw, ph, 8, 8)

    -- ── header bar ──────────────────────────────────────────
    love.graphics.setColor(0.08, 0.18, 0.38, 0.95 * a)
    love.graphics.rectangle("fill", px, py, pw, HEADER_H, 8, 8)
    love.graphics.rectangle("fill", px, py + HEADER_H - 8, pw, 8)

    -- header title
    love.graphics.setFont(font.h)
    local title    = "Inventory  (" .. #inventory .. " caught)"
    local titleW   = font.h:getWidth(title)
    love.graphics.setColor(0.55, 0.85, 1, a)
    love.graphics.print(title, px + INV_PAD, py + (HEADER_H - font.h:getHeight()) / 2)

    -- close button  [X]
    local cx = px + pw - CLOSE_SIZE - 8
    local cy = py + (HEADER_H - CLOSE_SIZE) / 2
    love.graphics.setColor(0.20, 0.45, 0.75, 0.80 * a)
    love.graphics.rectangle("fill", cx, cy, CLOSE_SIZE, CLOSE_SIZE, 4, 4)
    love.graphics.setColor(0.70, 0.90, 1, a)
    love.graphics.rectangle("line", cx, cy, CLOSE_SIZE, CLOSE_SIZE, 4, 4)
    love.graphics.setFont(font.sm)
    local xLabel = "X"
    local xLW    = font.sm:getWidth(xLabel)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.print(xLabel, cx + (CLOSE_SIZE - xLW) / 2, cy + (CLOSE_SIZE - font.sm:getHeight()) / 2)

    -- store close-btn rect for hit testing
    HUD._closeBtn = { x = cx, y = cy + slideY, w = CLOSE_SIZE, h = CLOSE_SIZE }

    -- ── scrollable content area ──────────────────────────────
    local contentH = ph - HEADER_H
    local listH    = #inventory * (CARD_H + CARD_GAP) - CARD_GAP
    local maxScroll = math.max(0, listH - contentH + INV_PAD * 2)
    HUD.invScrollTarget = math.max(0, math.min(HUD.invScrollTarget, maxScroll))

    -- scissor clip  (love.graphics.setScissor uses window pixels)
    love.graphics.setScissor(px, py + HEADER_H, pw, contentH)

    -- ── fish cards ──────────────────────────────────────────
    if #inventory == 0 then
        love.graphics.setFont(font.sm)
        local empty = "No fish caught yet. Dive in!"
        local ew    = font.sm:getWidth(empty)
        love.graphics.setColor(0.40, 0.60, 0.80, 0.65 * a)
        love.graphics.print(empty,
            px + (pw - ew) / 2,
            py + HEADER_H + contentH / 2 - font.sm:getHeight() / 2)
    else
        for i, f in ipairs(inventory) do
            local iy   = py + HEADER_H + INV_PAD
                       + (i - 1) * (CARD_H + CARD_GAP)
                       - HUD.invScroll
            local ix   = px + INV_PAD
            local iw   = pw - INV_PAD * 2
            local rarity = f.def and f.def.rarity or "common"
            local rc   = rarityColors[rarity] or rarityColors.common
            local rg   = rarityGlow[rarity]   or rarityGlow.common

            -- card bg
            love.graphics.setColor(0.07, 0.15, 0.30, 0.92 * a)
            love.graphics.rectangle("fill", ix, iy, iw, CARD_H, 5, 5)

            -- rarity glow left strip
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.90 * a)
            love.graphics.rectangle("fill", ix, iy, 4, CARD_H, 3, 3)

            -- rarity border
            love.graphics.setColor(rg[1], rg[2], rg[3], rg[4] * a)
            love.graphics.rectangle("line", ix, iy, iw, CARD_H, 5, 5)

            -- fish sprite  (draw at 2× inside card, centered vertically)
            if f.def and f.def.img then
                local img   = f.def.img
                local iSW, iSH = img:getDimensions()
                local drawH = CARD_H - 12
                local scl   = drawH / iSH
                local drawW = iSW * scl
                local sx2   = ix + 10
                local sy2   = iy + (CARD_H - drawH) / 2

                -- flip so fish faces right regardless of direction
                love.graphics.setColor(1, 1, 1, a)
                love.graphics.draw(img, sx2 + (f.dir == -1 and drawW or 0), sy2,
                    0,
                    (f.dir == -1 and -1 or 1) * scl,
                    scl)

                -- text block starts after sprite
                local textX = sx2 + drawW + 10

                -- name
                love.graphics.setFont(font.sm)
                love.graphics.setColor(1, 1, 1, a)
                local fname = (f.def.name or "Unknown Fish")
                love.graphics.print(fname, textX, iy + 10)

                -- rarity badge
                love.graphics.setFont(font.sm)
                local badge  = "[" .. rarity:upper() .. "]"
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.85 * a)
                love.graphics.print(badge, textX, iy + 10 + font.sm:getHeight() + 2)

                -- points
                love.graphics.setColor(0.80, 1, 0.70, a)
                local pts = "+" .. (f.def.points or 0) .. " pts"
                local ptW = font.sm:getWidth(pts)
                love.graphics.print(pts, ix + iw - ptW - 8, iy + (CARD_H - font.sm:getHeight()) / 2)
            end
        end
    end

    love.graphics.setScissor()

    -- ── scrollbar ───────────────────────────────────────────
    if #inventory > 0 then
        local listTotal = #inventory * (CARD_H + CARD_GAP)
        local visible   = contentH - INV_PAD * 2
        if listTotal > visible then
            local sbH   = math.max(30, visible * (visible / listTotal))
            local sbTrackH = contentH - 8
            local sbY   = py + HEADER_H + 4 + (HUD.invScroll / maxScroll) * (sbTrackH - sbH)
            love.graphics.setColor(0.25, 0.55, 0.90, 0.55 * a)
            love.graphics.rectangle("fill", px + pw - 6, sbY, 3, sbH, 2, 2)
        end
    end

    love.graphics.pop()  -- translate

    love.graphics.setColor(1, 1, 1, 1)
end

-- ─────────────────────────────────────────────────────────────
--  Scroll wheel support  (call from love.wheelmoved)
-- ─────────────────────────────────────────────────────────────

function HUD.onWheel(x, y, dx, dy, wW, wH)
    if HUD.inventoryOpen and HUD.hitInventoryPanel(x, y, wW, wH) then
        HUD.invScrollTarget = HUD.invScrollTarget - dy * SCROLL_SPEED
    end
end

-- ─────────────────────────────────────────────────────────────
--  Click handler for inventory panel internals
--  Returns true if the click was consumed by the panel.
-- ─────────────────────────────────────────────────────────────

function HUD.handleInventoryClick(sx, sy, wW, wH)
    if HUD.invAnim < 0.1 then return false end
    -- close button
    if HUD._closeBtn then
        local b = HUD._closeBtn
        if sx >= b.x and sx <= b.x + b.w and sy >= b.y and sy <= b.y + b.h then
            HUD.inventoryOpen = false
            return true
        end
    end
    -- consume any click inside the panel so it doesn't drag the camera
    if HUD.hitInventoryPanel(sx, sy, wW, wH) then
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────────────────
--  Existing HUD elements (unchanged)
-- ─────────────────────────────────────────────────────────────

function HUD.drawButton(font, inDepth, button)
    local b     = button
    local alpha = inDepth and 1 or 0.35
    if b then
        love.graphics.setColor(0.1, 0.2, 0.4, 0.85 * alpha)
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4, 4)
        love.graphics.setColor(0.5, 0.85, 1, alpha)
        love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4, 4)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setFont(font.sm)
        local lw = font.sm:getWidth(b.label)
        love.graphics.print(b.label,
            b.x + (b.w - lw) / 2,
            b.y + (b.h - font.sm:getHeight()) / 2)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function HUD.drawScore(font, score, wW)
    love.graphics.setFont(font.h)
    local text = "Score: " .. score
    local tw   = font.h:getWidth(text)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.print(text, wW - tw - 14 + 1, 17)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, wW - tw - 14, 16)
end

function HUD.drawDragHint(font, timer, wW, wH)
    local text  = "Drag down to fish"
    local alpha = math.abs(math.sin(timer * 1.5)) * 0.7 + 0.2
    love.graphics.setFont(font.sm)
    local tw = font.sm:getWidth(text)
    love.graphics.setColor(0.6, 0.9, 1, alpha)
    love.graphics.print(text, (wW - tw) / 2, wH - 30)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawDepthZoneBanner(font, wW, wH)
    local text = "~ DEPTH ZONE ~"
    love.graphics.setFont(font.h)
    local tw = font.h:getWidth(text)
    love.graphics.setColor(0.3, 0.8, 1, 0.9)
    love.graphics.print(text, (wW - tw) / 2, wH / 2 - 13)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawCatchFeedback(font, catchFeedback, wW, wH)
    if not catchFeedback then return end
    local cf   = catchFeedback
    local fade = math.min(1, cf.timer / 0.5)
    love.graphics.setFont(font.h)
    local tw = font.h:getWidth(cf.text)
    love.graphics.setColor(0, 0, 0, fade * 0.5)
    love.graphics.print(cf.text, (wW - tw) / 2 + 1, wH / 2 - 13 + 1)
    love.graphics.setColor(cf.color[1], cf.color[2], cf.color[3], fade)
    love.graphics.print(cf.text, (wW - tw) / 2, wH / 2 - 13)
    love.graphics.setColor(1, 1, 1, 1)
end

function HUD.drawRuler(ruler, pointer, depths, mW, mH, offsetY, threshold)
    local rulerX = mW - ruler:getWidth() - 5
    local rulerY = mH / 2 - ruler:getHeight() / 2
    love.graphics.draw(ruler, rulerX, rulerY)

    local pY = rulerY - 1 +
        ((-offsetY + 20) / (depths[1]:getHeight() * #depths)) * ruler:getHeight()
    love.graphics.draw(pointer, rulerX - 4, pY)

    local zoneY = rulerY +
        ((-threshold) / (depths[1]:getHeight() * 3)) * ruler:getHeight()
    love.graphics.setColor(0.3, 0.8, 1, 0.9)
    love.graphics.line(rulerX - 3, zoneY, rulerX + ruler:getWidth() + 1, zoneY)
    love.graphics.setColor(1, 1, 1, 1)
end

return HUD