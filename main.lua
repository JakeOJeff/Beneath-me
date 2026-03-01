local push = require "libraries.push"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    layers = {}
    mx, my = 0, 0
    player = { x = 0, y = 0 }
    baseY = player.y
    ox, oy = 0, 0
    wW, wH = 140, 88
    push:setupScreen(wW, wH, wW * 10, wH * 10, {fullscreen = false})

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy = love.graphics.newImage("assets/watertop/buoy.png")

    depths = {
        love.graphics.newImage("assets/depths/1.png")
    }

    timer = 0
    squeezeX = 1

    -- Canvas / drag state
    canvasOffsetY = -10
    dragActive = false
    dragLastY = 0
    dragVelocityY = 0
    friction = 0.92
end

function love.update(dt)
    timer = timer + dt
    mx, my = push:toGame(love.mouse.getPosition())
    ox, oy = distFromCenter(player.x, player.y)

    local speed = 3
    local amplitude = 12
    local rotSpeed = 3
    local rotAmplitude = 0.02

    player.y = baseY + math.sin(timer * speed) * amplitude
    player.rotation = math.sin(timer * rotSpeed) * rotAmplitude

    -- Squeeze based on depth
    local depth = math.max(-canvasOffsetY, 0)
    squeezeX = math.max(1 - (depth * 0.002), 0.6)

    -- Apply momentum when not dragging
    if not dragActive then
        canvasOffsetY = canvasOffsetY + dragVelocityY
        dragVelocityY = dragVelocityY * friction

        if math.abs(dragVelocityY) < 0.01 then
            dragVelocityY = 0
        end
    end
end

function distFromCenter(x, y)
    return (wW / 2) - x, (wH / 2) - y
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local gx, gy = push:toGame(x, y)
        dragActive = true
        dragLastY = gy
        dragVelocityY = 0
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        dragActive = false
    end
end

function love.mousemoved(x, y, dx, dy)
    if dragActive then
        local _, gy = push:toGame(x, y)

        dragVelocityY = gy - dragLastY
        dragLastY = gy

        canvasOffsetY = canvasOffsetY + dragVelocityY
    end
end

function love.draw()
    push:start()
        love.graphics.push()
        love.graphics.translate(wW/2, wH/2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)
        love.graphics.translate(-wW/2, -wH/2)

            love.graphics.push()
            love.graphics.translate(0, canvasOffsetY)

                -- Depth image drawn BEFORE squeeze, unaffected
                love.graphics.draw(depths[1], 0, (wH - layers[#layers]:getHeight()) + 35)

                -- Squeeze only Y, only for ocean layers
                love.graphics.translate(0, wH/2)
                love.graphics.scale(1, squeezeX)  -- X stays 1, Y squeezes
                love.graphics.translate(0, -wH/2)

                love.graphics.draw(stableSky, 0, -44 + oy/10)

                for i = 1, #layers do
                    love.graphics.draw(layers[i], 0, (wH - layers[i]:getHeight()) + oy/10 * i)
                end

                love.graphics.draw(buoy, 0, (wH - layers[#layers]:getHeight()) + oy/10 * #layers - buoy:getHeight())

            love.graphics.pop()

        love.graphics.pop()
    push:finish()
end