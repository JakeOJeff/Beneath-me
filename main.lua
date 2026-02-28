local push = require "libraries.push"

function love.load()
    layers = {}
    mx, my = 0
    ox, oy = 0
    wW, wH = 140, 88
    push:setupScreen(wW, wH, wW * 4, wH * 4, {fullscreen= false})
    love.graphics.setDefaultFilter("nearest", "nearest")

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
end

function love.update(dt)
    mx, my = push:toGame(love.mouse.getPosition())
    ox, oy = distFromCenter(mx, my)
end

function distFromCenter(x, y)
    return (wW / 2) - x, (wH / 2) - y
end

function love.draw()
    push:start()
        love.graphics.draw(stableSky, 0, -44 + oy/10)
        love.graphics.setScissor(0, -44 + oy/10 + stableSky:getHeight() - 49, wW * 4, wH * 4)
        for i = 1, #layers do
            love.graphics.draw(layers[i], 0, oy/10 * i)

        end
        love.graphics.setScissor()
    push:finish()
end
