-- ui/hud.lua
-- Draws all screen-space HUD elements

local Settings = require("src.conf.settings")
local Camera   = require("src.systems.camera")

local HUD = {}

-- Surface button geometry (screen-space pixels)
HUD.surfaceBtn = { x = 14, y = 14, w = 120, h = 34, label = "Surface" }

---Returns true if the given screen-space point is inside the surface button.
function HUD.hitsSurfaceBtn(sx, sy)
    local b = HUD.surfaceBtn
    return sx >= b.x and sx <= b.x + b.w
       and sy >= b.y and sy <= b.y + b.h
end

function HUD.drawSurfaceButton(font, inDepth)
    local b        = HUD.surfaceBtn
    local alpha    = inDepth and 1 or 0.35

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

function HUD.drawScore(font, score, wW)
    love.graphics.setFont(font.h)
    local text = "Score: " .. score
    local tw   = font.h:getWidth(text)
    -- drop shadow
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
    -- shadow
    love.graphics.setColor(0, 0, 0, fade * 0.5)
    love.graphics.print(cf.text, (wW - tw) / 2 + 1, wH / 2 - 13 + 1)
    love.graphics.setColor(cf.color[1], cf.color[2], cf.color[3], fade)
    love.graphics.print(cf.text, (wW - tw) / 2, wH / 2 - 13)
    love.graphics.setColor(1, 1, 1, 1)
end

---Draw the depth ruler and pointer (in game-unit space, called inside scale push).
function HUD.drawRuler(ruler, pointer, depths, mW, mH, offsetY, threshold)
    local rulerX = mW - ruler:getWidth() - 5
    local rulerY = mH / 2 - ruler:getHeight() / 2
    love.graphics.draw(ruler, rulerX, rulerY)

    -- pointer position
    local pY = rulerY - 1 +
        ((-offsetY + 20) / (depths[1]:getHeight() * 4)) * ruler:getHeight()
    love.graphics.draw(pointer, rulerX - 4, pY)

    -- depth-zone line
    local zoneY = rulerY +
        ((-threshold) / (depths[1]:getHeight() * 3)) * ruler:getHeight()
    love.graphics.setColor(0.3, 0.8, 1, 0.9)
    love.graphics.line(rulerX - 3, zoneY, rulerX + ruler:getWidth() + 1, zoneY)
    love.graphics.setColor(1, 1, 1, 1)
end

return HUD