-- ui/hud.lua
-- Draws all screen-space HUD elements

local Settings = require("src.conf.settings")
local Camera   = require("src.systems.camera")

local HUD = {}

-- ─────────────────────────────────────────────────────────────
--  Button geometry (screen-space pixels)
-- ─────────────────────────────────────────────────────────────

HUD.surfaceBtn   = { x = 14, y = 14,                      w = 120, h = 34, label = "Surface"   }
HUD.inventoryBtn = { x = 14, y = 14 + 34 + 5,             w = 120, h = 34, label = "Inventory" }
HUD.marketBtn    = { x = 14, y = 14 + 34 + 5 + 34 + 5,    w = 120, h = 34, label = "⚓ Market"  }

-- ─────────────────────────────────────────────────────────────
--  Inventory panel state
-- ─────────────────────────────────────────────────────────────

HUD.inventoryOpen   = false
HUD.invScroll       = 0
HUD.invScrollTarget = 0
HUD.invAnim         = 0

local INV_W       = 320
local INV_PAD     = 12
local CARD_H      = 64
local CARD_GAP    = 6
local HEADER_H    = 40
local CLOSE_SIZE  = 24
local PANEL_MAX_H = 480
local SCROLL_SPEED = 60

-- ─────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────

function HUD.hitBtn(button, sx, sy)
    local b = button
    return sx >= b.x and sx <= b.x + b.w
       and sy >= b.y and sy <= b.y + b.h
end

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
    if HUD.inventoryOpen then HUD.invScrollTarget = 0 end
end

function HUD.update(dt)
    local target = HUD.inventoryOpen and 1 or 0
    HUD.invAnim  = HUD.invAnim + (target - HUD.invAnim) * math.min(1, dt * 12)
    HUD.invScroll = HUD.invScroll + (HUD.invScrollTarget - HUD.invScroll) * math.min(1, dt * 14)
end

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

    local a  = HUD.invAnim
    local ph = math.min(PANEL_MAX_H, wH - 60)
    local pw = INV_W
    local px = (wW - pw) / 2
    local py = (wH - ph) / 2
    local slideY = (1 - a) * (ph * 0.35)

    love.graphics.push()
    love.graphics.translate(0, slideY)

    -- shadow
    love.graphics.setColor(0, 0, 0, 0.55 * a)
    love.graphics.rectangle("fill", px + 5, py + 8, pw, ph, 8, 8)
    -- bg
    love.graphics.setColor(0.04, 0.09, 0.20, 0.96 * a)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    -- border
    love.graphics.setColor(0.25, 0.55, 0.90, 0.70 * a)
    love.graphics.rectangle("line", px, py, pw, ph, 8, 8)
    -- header
    love.graphics.setColor(0.08, 0.18, 0.38, 0.95 * a)
    love.graphics.rectangle("fill", px, py, pw, HEADER_H, 8, 8)
    love.graphics.rectangle("fill", px, py + HEADER_H - 8, pw, 8)

    love.graphics.setFont(font.h)
    love.graphics.setColor(0.55, 0.85, 1, a)
    love.graphics.print("Inventory  (" .. #inventory .. " caught)",
        px + INV_PAD, py + (HEADER_H - font.h:getHeight()) / 2)

    -- close btn
    local cx = px + pw - CLOSE_SIZE - 8
    local cy = py + (HEADER_H - CLOSE_SIZE) / 2
    love.graphics.setColor(0.20, 0.45, 0.75, 0.80 * a)
    love.graphics.rectangle("fill", cx, cy, CLOSE_SIZE, CLOSE_SIZE, 4, 4)
    love.graphics.setColor(0.70, 0.90, 1, a)
    love.graphics.rectangle("line", cx, cy, CLOSE_SIZE, CLOSE_SIZE, 4, 4)
    love.graphics.setFont(font.sm)
    love.graphics.setColor(1, 1, 1, a)
    local xLW = font.sm:getWidth("X")
    love.graphics.print("X", cx + (CLOSE_SIZE - xLW) / 2, cy + (CLOSE_SIZE - font.sm:getHeight()) / 2)
    HUD._closeBtn = { x = cx, y = cy + slideY, w = CLOSE_SIZE, h = CLOSE_SIZE }

    -- content
    local contentH  = ph - HEADER_H
    local listH     = #inventory * (CARD_H + CARD_GAP) - CARD_GAP
    local maxScroll = math.max(0, listH - contentH + INV_PAD * 2)
    HUD.invScrollTarget = math.max(0, math.min(HUD.invScrollTarget, maxScroll))

    love.graphics.setScissor(px, py + HEADER_H, pw, contentH)

    if #inventory == 0 then
        love.graphics.setFont(font.sm)
        local empty = "No fish caught yet. Dive in!"
        local ew    = font.sm:getWidth(empty)
        love.graphics.setColor(0.40, 0.60, 0.80, 0.65 * a)
        love.graphics.print(empty, px + (pw - ew) / 2,
            py + HEADER_H + contentH / 2 - font.sm:getHeight() / 2)
    else
        for i, f in ipairs(inventory) do
            local iy     = py + HEADER_H + INV_PAD + (i - 1) * (CARD_H + CARD_GAP) - HUD.invScroll
            local ix     = px + INV_PAD
            local iw     = pw - INV_PAD * 2
            local rarity = f.def and f.def.rarity or "common"
            local rc     = rarityColors[rarity] or rarityColors.common
            local rg     = rarityGlow[rarity]   or rarityGlow.common

            love.graphics.setColor(0.07, 0.15, 0.30, 0.92 * a)
            love.graphics.rectangle("fill", ix, iy, iw, CARD_H, 5, 5)
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.90 * a)
            love.graphics.rectangle("fill", ix, iy, 4, CARD_H, 3, 3)
            love.graphics.setColor(rg[1], rg[2], rg[3], rg[4] * a)
            love.graphics.rectangle("line", ix, iy, iw, CARD_H, 5, 5)

            if f.def and f.def.img then
                local img    = f.def.img
                local iSW, iSH = img:getDimensions()
                local drawH  = CARD_H - 12
                local scl    = drawH / iSH
                local drawW  = iSW * scl
                local sx2    = ix + 10
                local sy2    = iy + (CARD_H - drawH) / 2
                love.graphics.setColor(1, 1, 1, a)
                love.graphics.draw(img, sx2 + (f.dir == -1 and drawW or 0), sy2,
                    0, (f.dir == -1 and -1 or 1) * scl, scl)
                local textX = sx2 + drawW + 10
                love.graphics.setFont(font.sm)
                love.graphics.setColor(1, 1, 1, a)
                love.graphics.print(f.def.name or "Unknown", textX, iy + 10)
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.85 * a)
                love.graphics.print("[" .. rarity:upper() .. "]", textX, iy + 10 + font.sm:getHeight() + 2)
                love.graphics.setColor(0.80, 1, 0.70, a)
                local pts = "+" .. (f.def.points or 0) .. " pts"
                local ptW = font.sm:getWidth(pts)
                love.graphics.print(pts, ix + iw - ptW - 8, iy + (CARD_H - font.sm:getHeight()) / 2)
            end
        end
    end

    love.graphics.setScissor()

    -- scrollbar
    if #inventory > 0 then
        local visible = contentH - INV_PAD * 2
        if #inventory * (CARD_H + CARD_GAP) > visible then
            local sbH = math.max(30, visible * (visible / (#inventory * (CARD_H + CARD_GAP))))
            local sbY = py + HEADER_H + 4 + (maxScroll > 0 and (HUD.invScroll / maxScroll) or 0) * (contentH - 8 - sbH)
            love.graphics.setColor(0.25, 0.55, 0.90, 0.55 * a)
            love.graphics.rectangle("fill", px + pw - 6, sbY, 3, sbH, 2, 2)
        end
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

-- ─────────────────────────────────────────────────────────────
--  Scroll / click handlers
-- ─────────────────────────────────────────────────────────────

function HUD.onWheel(x, y, dx, dy, wW, wH)
    if HUD.inventoryOpen and HUD.hitInventoryPanel(x, y, wW, wH) then
        HUD.invScrollTarget = HUD.invScrollTarget - dy * SCROLL_SPEED
    end
end

function HUD.handleInventoryClick(sx, sy, wW, wH)
    if HUD.invAnim < 0.1 then return false end
    if HUD._closeBtn then
        local b = HUD._closeBtn
        if sx >= b.x and sx <= b.x + b.w and sy >= b.y and sy <= b.y + b.h then
            HUD.inventoryOpen = false
            return true
        end
    end
    return HUD.hitInventoryPanel(sx, sy, wW, wH)
end

-- ─────────────────────────────────────────────────────────────
--  Standard HUD elements
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