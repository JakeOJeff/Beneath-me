local push = require "libraries.push"

function love.load()
        love.graphics.setDefaultFilter("nearest", "nearest")

    layers = {}
    mx, my = 0
    player = {
        x = 0,
        y = 0
    }
    ox, oy = 0
    wW, wH = 140, 88
    push:setupScreen(wW, wH, wW * 4, wH * 4, {fullscreen= false})

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy = love.graphics.newImage("assets/watertop/buoy.png")
end

function love.update(dt)
    mx, my = push:toGame(love.mouse.getPosition())
    ox, oy = distFromCenter(player.x, player.y)

    if love.keyboard.isDown("s") then
        player.y = player.y + 100 * dt
    end
        if love.keyboard.isDown("w") then
        player.y = player.y - 100 * dt
    end
end

function distFromCenter(x, y)
    return (wW / 2) - x, (wH / 2) - y
end

function love.draw()
    push:start()
        love.graphics.draw(stableSky, 0, -44 + oy/10)
        local horizon = -44 + oy/10 + stableSky:getHeight() - 49
        for i = 1, #layers do
            love.graphics.draw(layers[i], 0, (wH - layers[i]:getHeight()) + oy/10 * i)

        end
        love.graphics.draw(buoy, 0, (wH - layers[#layers]:getHeight()) + oy/10 * #layers - buoy:getHeight())
    push:finish()
end
