


local Market = {}





local PW         = 480
local PH         = 520
local PAD        = 14
local HEADER_H   = 44
local TAB_H      = 36
local CARD_H     = 68
local CARD_GAP   = 8
local CLOSE_SZ   = 26
local SCROLL_SPD = 55


local shopItems = {

    { tab = "shop", category = "luck",  name = "Lucky Charm I",   desc = "Common fish +15% spawn rate",  cost = 80,   color = {0.40, 0.75, 0.40} },
    { tab = "shop", category = "luck",  name = "Lucky Charm II",  desc = "Rare fish +20% spawn rate",    cost = 200,  color = {0.35, 0.65, 1.00} },
    { tab = "shop", category = "luck",  name = "Siren's Whistle", desc = "Legendary +10% spawn rate",    cost = 600,  color = {1.00, 0.80, 0.20} },

    { tab = "shop", category = "rod",   name = "Iron Rod",        desc = "Catch radius +10px",           cost = 120,  color = {0.70, 0.70, 0.80} },
    { tab = "shop", category = "rod",   name = "Coral Rod",       desc = "Catch radius +25px, +5% pts",  cost = 340,  color = {1.00, 0.45, 0.45} },
    { tab = "shop", category = "rod",   name = "Abyss Rod",       desc = "Max fish +5, depth bonus",     cost = 900,  color = {0.30, 0.20, 0.80} },
}





Market.open       = false
Market.anim       = 0
Market.activeTab  = "sell"
Market.sellScroll = 0
Market.sellScrollTarget = 0
Market.shopScroll = 0
Market.shopScrollTarget = 0
Market._closeBtn  = nil
Market._coins     = nil





function Market.toggle(scoreRef)
    Market.open  = not Market.open
    Market._coins = scoreRef
    if Market.open then
        Market.sellScroll       = 0
        Market.sellScrollTarget = 0
        Market.shopScroll       = 0
        Market.shopScrollTarget = 0
    end
end

function Market.update(dt)
    local target = Market.open and 1 or 0
    Market.anim  = Market.anim + (target - Market.anim) * math.min(1, dt * 13)

    Market.sellScroll = Market.sellScroll +
        (Market.sellScrollTarget - Market.sellScroll) * math.min(1, dt * 14)
    Market.shopScroll = Market.shopScroll +
        (Market.shopScrollTarget - Market.shopScroll) * math.min(1, dt * 14)
end

function Market.onWheel(mx, my, dy, wW, wH)
    if Market.anim < 0.05 then return end
    local px = (wW - PW) / 2
    local py = (wH - PH) / 2
    if mx >= px and mx <= px + PW and my >= py and my <= py + PH then
        if Market.activeTab == "sell" then
            Market.sellScrollTarget = Market.sellScrollTarget - dy * SCROLL_SPD
        else
            Market.shopScrollTarget = Market.shopScrollTarget - dy * SCROLL_SPD
        end
    end
end




function Market.handleClick(sx, sy, wW, wH, inventory, scoreCallback)
    if Market.anim < 0.05 then return false end

    local px = (wW - PW) / 2
    local py = (wH - PH) / 2


    if Market._closeBtn then
        local c = Market._closeBtn
        if sx >= c.x and sx <= c.x + c.w and sy >= c.y and sy <= c.y + c.h then
            Market.open = false
            return true
        end
    end


    local tabY   = py + HEADER_H
    local halfW  = PW / 2
    if sy >= tabY and sy <= tabY + TAB_H then
        if sx >= px and sx <= px + halfW then
            Market.activeTab = "sell"
            return true
        elseif sx >= px + halfW and sx <= px + PW then
            Market.activeTab = "shop"
            return true
        end
    end


    local contentTop = py + HEADER_H + TAB_H
    local contentH   = PH - HEADER_H - TAB_H

    if Market.activeTab == "sell" then

        local scroll = Market.sellScroll
        for i, f in ipairs(inventory) do
            local iy = contentTop + PAD + (i - 1) * (CARD_H + CARD_GAP) - scroll

            local bw, bh = 60, 28
            local bx = px + PW - PAD - bw
            local by = iy + (CARD_H - bh) / 2
            if sx >= bx and sx <= bx + bw and sy >= by and sy <= by + bh then
                local pts = f.def and f.def.points or 0
                scoreCallback(pts)
                table.remove(inventory, i)

                Market.sellScrollTarget = math.max(0, Market.sellScrollTarget - (CARD_H + CARD_GAP))
                return true
            end
        end

        local saW, saH = 100, 30
        local saX = px + (PW - saW) / 2
        local saY = py + PH - saH - 10
        if sx >= saX and sx <= saX + saW and sy >= saY and sy <= saY + saH then
            local total = 0
            for _, f in ipairs(inventory) do
                total = total + (f.def and f.def.points or 0)
            end
            scoreCallback(total)
            for k in pairs(inventory) do inventory[k] = nil end

            local tmp = {}
            for _, v in pairs(inventory) do tmp[#tmp + 1] = v end
            for k in pairs(inventory) do inventory[k] = nil end
            for i, v in ipairs(tmp) do inventory[i] = v end
            return true
        end

    else

        local scroll = Market.shopScroll
        for i, item in ipairs(shopItems) do
            local iy = contentTop + PAD + (i - 1) * (CARD_H + CARD_GAP) - scroll
            local bw, bh = 70, 28
            local bx = px + PW - PAD - bw
            local by = iy + (CARD_H - bh) / 2
            if sx >= bx and sx <= bx + bw and sy >= by and sy <= by + bh then

                scoreCallback(-item.cost)
                return true
            end
        end
    end


    if sx >= px and sx <= px + PW and sy >= py and sy <= py + PH then
        return true
    end
    return false
end





local rarityColors = {
    common    = {0.75, 0.85, 0.95},
    rare      = {0.35, 0.65, 1.00},
    legendary = {1.00, 0.80, 0.20},
}

local function setC(r,g,b,a) love.graphics.setColor(r,g,b,a or 1) end

local function drawNotchedRect(x,y,w,h,nc,fill,r,g,b,a)
    setC(r,g,b,a)
    love.graphics.polygon(fill,
        x+nc, y,  x+w-nc, y,
        x+w,  y+nc,  x+w,  y+h-nc,
        x+w-nc, y+h,  x+nc, y+h,
        x,  y+h-nc,  x,  y+nc)
end

function Market.draw(font, inventory, score, wW, wH)
    if Market.anim < 0.005 then return end

    local a  = Market.anim
    local px = (wW - PW) / 2
    local py = (wH - PH) / 2


    local slideY = (1 - a) * (PH * 0.4)
    love.graphics.push()
    love.graphics.translate(0, slideY)


    setC(0, 0, 0, 0.5 * a)
    love.graphics.rectangle("fill", px + 6, py + 10, PW, PH, 8, 8)


    setC(0.03, 0.07, 0.17, 0.97 * a)
    love.graphics.rectangle("fill", px, py, PW, PH, 8, 8)


    setC(0.06, 0.14, 0.28, 0.35 * a)
    love.graphics.rectangle("fill", px, py, PW, PH * 0.35, 8, 8)
    love.graphics.rectangle("fill", px, py, PW, PH * 0.35)


    setC(0.22, 0.52, 0.80, 0.65 * a)
    love.graphics.rectangle("line", px, py, PW, PH, 8, 8)


    local ca = 8
    local corners = {
        {px,        py        },
        {px+PW-ca,  py        },
        {px,        py+PH-ca  },
        {px+PW-ca,  py+PH-ca  },
    }
    setC(0.35, 0.75, 1, 0.80 * a)
    for _, c in ipairs(corners) do
        love.graphics.rectangle("fill", c[1], c[2], ca, ca)
    end


    setC(0.05, 0.13, 0.30, 0.98 * a)
    love.graphics.rectangle("fill", px, py, PW, HEADER_H, 8, 8)
    love.graphics.rectangle("fill", px, py + HEADER_H - 8, PW, 8)


    love.graphics.setFont(font.h)
    local htitle = "  HARBOUR MARKET"
    local htW    = font.h:getWidth(htitle)
    setC(0.55, 0.88, 1, a)
    love.graphics.print(htitle, px + PAD, py + (HEADER_H - font.h:getHeight()) / 2)


    love.graphics.setFont(font.sm)
    local coinTxt = " " .. score .. " pts"
    local coinW   = font.sm:getWidth(coinTxt)
    setC(1.00, 0.82, 0.25, a)
    love.graphics.print(coinTxt, px + PW - coinW - CLOSE_SZ - 16, py + (HEADER_H - font.sm:getHeight()) / 2)


    local cx = px + PW - CLOSE_SZ - 8
    local cy = py + (HEADER_H - CLOSE_SZ) / 2
    setC(0.18, 0.38, 0.65, 0.85 * a)
    love.graphics.rectangle("fill", cx, cy, CLOSE_SZ, CLOSE_SZ, 4, 4)
    setC(0.50, 0.80, 1, 0.80 * a)
    love.graphics.rectangle("line", cx, cy, CLOSE_SZ, CLOSE_SZ, 4, 4)
    love.graphics.setFont(font.sm)
    local xW = font.sm:getWidth("X")
    setC(1, 1, 1, a)
    love.graphics.print("X", cx + (CLOSE_SZ - xW) / 2, cy + (CLOSE_SZ - font.sm:getHeight()) / 2)
    Market._closeBtn = { x = cx, y = cy + slideY, w = CLOSE_SZ, h = CLOSE_SZ }


    local tabY  = py + HEADER_H
    local halfW = PW / 2
    local tabs  = { { id = "sell", label = "SELL CATCH" }, { id = "shop", label = "SHOP" } }
    for i, tab in ipairs(tabs) do
        local tx   = px + (i - 1) * halfW
        local active = (tab.id == Market.activeTab)
        setC(active and 0.08 or 0.04, active and 0.18 or 0.09, active and 0.38 or 0.19, a)
        love.graphics.rectangle("fill", tx, tabY, halfW, TAB_H)
        setC(active and 0.40 or 0.18, active and 0.75 or 0.40, active and 1 or 0.65, a * (active and 1 or 0.55))
        love.graphics.rectangle("line", tx, tabY, halfW, TAB_H)
        love.graphics.setFont(font.sm)
        local lw = font.sm:getWidth(tab.label)
        setC(active and 1 or 0.55, active and 1 or 0.75, active and 1 or 0.90, a)
        love.graphics.print(tab.label, tx + (halfW - lw) / 2, tabY + (TAB_H - font.sm:getHeight()) / 2)

        if active then
            setC(0.35, 0.75, 1, a * 0.90)
            love.graphics.rectangle("fill", tx + 6, tabY + TAB_H - 3, halfW - 12, 3, 1, 1)
        end
    end


    local contentTop = py + HEADER_H + TAB_H
    local bottomBarH = 50
    local contentH   = PH - HEADER_H - TAB_H - bottomBarH
    love.graphics.setScissor(px, contentTop, PW, contentH)

    if Market.activeTab == "sell" then
        Market._drawSellTab(font, inventory, px, contentTop, contentH, PW, a)
    else
        Market._drawShopTab(font, score, px, contentTop, contentH, PW, a)
    end

    love.graphics.setScissor()


    local barY = py + PH - bottomBarH
    setC(0.04, 0.10, 0.24, 0.95 * a)
    love.graphics.rectangle("fill", px, barY, PW, bottomBarH)
    setC(0.20, 0.48, 0.75, 0.50 * a)
    love.graphics.line(px, barY, px + PW, barY)

    if Market.activeTab == "sell" then

        local saW, saH = 100, 30
        local saX = px + (PW - saW) / 2
        local saY = barY + (bottomBarH - saH) / 2
        setC(0.08, 0.30, 0.55, 0.90 * a)
        love.graphics.rectangle("fill", saX, saY, saW, saH, 4, 4)
        setC(0.30, 0.70, 1, 0.80 * a)
        love.graphics.rectangle("line", saX, saY, saW, saH, 4, 4)
        love.graphics.setFont(font.sm)
        local sal = "SELL ALL"
        local saLW = font.sm:getWidth(sal)
        setC(1, 0.82, 0.30, a)
        love.graphics.print(sal, saX + (saW - saLW) / 2, saY + (saH - font.sm:getHeight()) / 2)


        local total = 0
        for _, f in ipairs(inventory) do total = total + (f.def and f.def.points or 0) end
        local hint = "Total: " .. total .. " pts"
        local hintW = font.sm:getWidth(hint)
        setC(0.60, 0.85, 0.70, a * 0.80)
        love.graphics.print(hint, px + PW - hintW - PAD, barY + (bottomBarH - font.sm:getHeight()) / 2)
    else
        love.graphics.setFont(font.sm)
        local info = "Upgrades are permanent and stack"
        local infoW = font.sm:getWidth(info)
        setC(0.40, 0.65, 0.80, a * 0.65)
        love.graphics.print(info, px + (PW - infoW) / 2, barY + (bottomBarH - font.sm:getHeight()) / 2)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end





function Market._drawSellTab(font, inventory, px, contentTop, contentH, pw, a)
    local scroll   = Market.sellScroll
    local listH    = #inventory * (CARD_H + CARD_GAP) - CARD_GAP
    local maxScroll = math.max(0, listH - contentH + PAD * 2)
    Market.sellScrollTarget = math.max(0, math.min(Market.sellScrollTarget, maxScroll))

    if #inventory == 0 then
        love.graphics.setFont(font.sm)
        local msg  = "Your net is empty — go catch something!"
        local msgW = font.sm:getWidth(msg)
        setC(0.40, 0.62, 0.80, a * 0.70)
        love.graphics.print(msg, px + (pw - msgW) / 2,
            contentTop + contentH / 2 - font.sm:getHeight() / 2)
        return
    end

    for i, f in ipairs(inventory) do
        local iy  = contentTop + PAD + (i - 1) * (CARD_H + CARD_GAP) - scroll
        local ix  = px + PAD
        local iw  = pw - PAD * 2
        local rar = f.def and f.def.rarity or "common"
        local rc  = rarityColors[rar] or rarityColors.common


        setC(0.05, 0.12, 0.26, 0.94 * a)
        love.graphics.rectangle("fill", ix, iy, iw, CARD_H, 5, 5)

        setC(rc[1], rc[2], rc[3], 0.90 * a)
        love.graphics.rectangle("fill", ix, iy, 4, CARD_H, 3, 3)

        setC(rc[1] * 0.6, rc[2] * 0.6, rc[3] * 0.6, 0.30 * a)
        love.graphics.rectangle("line", ix, iy, iw, CARD_H, 5, 5)


        if f.def and f.def.img then
            local img    = f.def.img
            local iSW, iSH = img:getDimensions()
            local drawH  = CARD_H - 12
            local scl    = drawH / iSH
            local drawW  = iSW * scl
            love.graphics.setColor(1, 1, 1, a)
            love.graphics.draw(img,
                ix + 10 + (f.dir == -1 and drawW or 0), iy + (CARD_H - drawH) / 2,
                0, (f.dir == -1 and -1 or 1) * scl, scl)
            local textX = ix + 10 + drawW + 10

            love.graphics.setFont(font.sm)
            setC(1, 1, 1, a)
            love.graphics.print(f.def.name or "Unknown", textX, iy + 8)
            setC(rc[1], rc[2], rc[3], 0.80 * a)
            love.graphics.print("[" .. rar:upper() .. "]", textX, iy + 8 + font.sm:getHeight() + 2)
        else

            setC(0.20, 0.40, 0.60, 0.55 * a)
            love.graphics.rectangle("fill", ix + 8, iy + 8, CARD_H - 16, CARD_H - 16, 3, 3)
        end


        local pts   = f.def and f.def.points or 0
        love.graphics.setFont(font.sm)
        local valTx = " " .. pts
        local valW  = font.sm:getWidth(valTx)
        setC(1.00, 0.82, 0.25, a)
        love.graphics.print(valTx, ix + iw - valW - 76, iy + 10)


        local bw, bh = 60, 28
        local bx = ix + iw - bw
        local by = iy + (CARD_H - bh) / 2
        setC(0.05, 0.28, 0.45, 0.92 * a)
        love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)
        setC(0.25, 0.68, 0.90, 0.70 * a)
        love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
        local sl = "SELL"
        local slW = font.sm:getWidth(sl)
        setC(0.60, 1, 0.70, a)
        love.graphics.print(sl, bx + (bw - slW) / 2, by + (bh - font.sm:getHeight()) / 2)
    end


    if listH > contentH then
        local sbH = math.max(24, contentH * (contentH / listH))
        local sbY = contentTop + (scroll / maxScroll) * (contentH - sbH)
        setC(0.25, 0.55, 0.88, 0.50 * a)
        love.graphics.rectangle("fill", px + pw - 5, sbY, 3, sbH, 2, 2)
    end
end





function Market._drawShopTab(font, score, px, contentTop, contentH, pw, a)
    local scroll    = Market.shopScroll
    local listH     = #shopItems * (CARD_H + CARD_GAP) - CARD_GAP
    local maxScroll = math.max(0, listH - contentH + PAD * 2)
    Market.shopScrollTarget = math.max(0, math.min(Market.shopScrollTarget, maxScroll))


    local lastCat = nil

    for i, item in ipairs(shopItems) do
        local iy  = contentTop + PAD + (i - 1) * (CARD_H + CARD_GAP) - scroll
        local ix  = px + PAD
        local iw  = pw - PAD * 2
        local rc  = item.color
        local canAfford = (score >= item.cost)


        if item.category ~= lastCat then
            lastCat = item.category
            local catLabel = item.category == "luck" and "— LUCK UPGRADES —" or "— ROD UPGRADES —"
            love.graphics.setFont(font.sm)
            local clW = font.sm:getWidth(catLabel)
            setC(0.35, 0.65, 0.85, a * 0.60)

        end


        setC(0.05, 0.11, 0.24, 0.94 * a)
        love.graphics.rectangle("fill", ix, iy, iw, CARD_H, 5, 5)


        setC(rc[1], rc[2], rc[3], 0.85 * a)
        love.graphics.rectangle("fill", ix, iy, 4, CARD_H, 3, 3)


        if not canAfford then
            setC(0, 0, 0, 0.35 * a)
            love.graphics.rectangle("fill", ix, iy, iw, CARD_H, 5, 5)
        end


        setC(rc[1] * 0.55, rc[2] * 0.55, rc[3] * 0.55, 0.35 * a)
        love.graphics.rectangle("line", ix, iy, iw, CARD_H, 5, 5)


        local iconSz = CARD_H - 16
        setC(rc[1] * 0.55, rc[2] * 0.55, rc[3] * 0.55, 0.65 * a)
        love.graphics.rectangle("fill", ix + 10, iy + 8, iconSz, iconSz, 4, 4)
        setC(rc[1], rc[2], rc[3], 0.50 * a)
        love.graphics.rectangle("line", ix + 10, iy + 8, iconSz, iconSz, 4, 4)

        love.graphics.setFont(font.sm)
        local sym = item.category == "luck" and "" or "⊕"
        local symW = font.sm:getWidth(sym)
        setC(1, 1, 1, a * (canAfford and 0.85 or 0.40))
        love.graphics.print(sym, ix + 10 + (iconSz - symW) / 2, iy + 8 + (iconSz - font.sm:getHeight()) / 2)


        local textX = ix + iconSz + 20
        love.graphics.setFont(font.sm)
        setC(canAfford and 1 or 0.50, canAfford and 1 or 0.55, canAfford and 1 or 0.60, a)
        love.graphics.print(item.name, textX, iy + 8)
        setC(0.55, 0.75, 0.88, a * (canAfford and 0.75 or 0.40))
        love.graphics.print(item.desc, textX, iy + 8 + font.sm:getHeight() + 3)


        local costTx = " " .. item.cost
        local costW  = font.sm:getWidth(costTx)
        local costClr = canAfford and {1.00, 0.82, 0.25} or {0.55, 0.45, 0.25}
        setC(costClr[1], costClr[2], costClr[3], a)
        love.graphics.print(costTx, ix + iw - costW - 76, iy + 10)


        local bw, bh = 64, 28
        local bx = ix + iw - bw
        local by = iy + (CARD_H - bh) / 2
        if canAfford then
            setC(0.06, 0.30, 0.18, 0.92 * a)
            love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)
            setC(0.25, 0.80, 0.45, 0.70 * a)
            love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
            setC(0.60, 1, 0.70, a)
        else
            setC(0.12, 0.14, 0.20, 0.70 * a)
            love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)
            setC(0.25, 0.30, 0.38, 0.50 * a)
            love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
            setC(0.35, 0.38, 0.42, a * 0.60)
        end
        local bl  = canAfford and "BUY" or "—"
        local blW = font.sm:getWidth(bl)
        love.graphics.print(bl, bx + (bw - blW) / 2, by + (bh - font.sm:getHeight()) / 2)
    end


    if listH > contentH then
        local sbH = math.max(24, contentH * (contentH / listH))
        local sbY = contentTop + (scroll / maxScroll) * (contentH - sbH)
        setC(0.25, 0.55, 0.88, 0.50 * a)
        love.graphics.rectangle("fill", px + pw - 5, sbY, 3, sbH, 2, 2)
    end
end

return Market
