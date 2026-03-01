local push = require "libraries.push"

function love.load()
        love.graphics.setDefaultFilter("nearest", "nearest")

    layers = {}
    mx, my = 0
    player = {
        x = 0,
        y = 0
    }
    baseY = player.y
    ox, oy = 0
    wW, wH = 140, 88
    push:setupScreen(wW, wH, wW * 6, wH * 6, {fullscreen= false})

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy = love.graphics.newImage("assets/watertop/buoy.png")

    timer = 0
end

function love.update(dt)
    timer = timer + dt
    mx, my = push:toGame(love.mouse.getPosition())
    ox, oy = distFromCenter(player.x, player.y)

    local speed = 3
    local amplitude = 16
    local rotSpeed = 3        -- Slightly different speed for natural feel
    local rotAmplitude = 0.02 -- Radians (~4.5 degrees)

    player.y = baseY + math.sin(timer * speed) * amplitude
    player.rotation = math.sin(timer * rotSpeed) * rotAmplitude
end

function distFromCenter(x, y)
    return (wW / 2) - x, (wH / 2) - y
end

function love.draw()
    push:start()
        love.graphics.push()
        love.graphics.translate(wW/2, wH/2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)  -- Zoom in 15% to hide borders
        love.graphics.translate(-wW/2, -wH/2)

            love.graphics.draw(stableSky, 0, -44 + oy/10)
            for i = 1, #layers do
                love.graphics.draw(layers[i], 0, (wH - layers[i]:getHeight()) + oy/10 * i)
            end
            love.graphics.draw(buoy, 0, (wH - layers[#layers]:getHeight()) + oy/10 * #layers - buoy:getHeight())

        love.graphics.pop()
    push:finish()
end