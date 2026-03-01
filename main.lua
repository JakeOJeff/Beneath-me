local push = require "libraries.push"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    layers = {}
    mx, my = 0, 0
    player = { x = 0, y = 0 }
    baseY = player.y
    ox, oy = 0, 0
    wW, wH = 140, 88
    push:setupScreen(wW, wH, wW * 6, wH * 6, {fullscreen = false})

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy = love.graphics.newImage("assets/watertop/buoy.png")

    timer = 0

    -- Canvas / drag state
    canvasOffsetY = 0       -- total vertical offset of the scene
    dragActive = false
    dragLastY = 0
    dragVelocityY = 0
    friction = 0.92         -- how quickly the momentum decays (lower = stops faster)
end

function love.update(dt)
    timer = timer + dt
    mx, my = push:toGame(love.mouse.getPosition())
    ox, oy = distFromCenter(player.x, player.y)

    local speed = 3
    local amplitude = 16
    local rotSpeed = 3
    local rotAmplitude = 0.02

    player.y = baseY + math.sin(timer * speed) * amplitude
    player.rotation = math.sin(timer * rotSpeed) * rotAmplitude

    -- Apply momentum when not dragging
    if not dragActive then
        canvasOffsetY = canvasOffsetY + dragVelocityY
        dragVelocityY = dragVelocityY * friction

        -- Stop tiny drifts
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
        -- velocity carries over from last frame delta
    end
end

function love.mousemoved(x, y, dx, dy)
    if dragActive then
        local _, gdy = push:toGame(0, dy)  -- convert delta to game space
        local _, gy  = push:toGame(x, y)

        -- Track velocity as the delta this frame
        dragVelocityY = (gy - dragLastY)/2
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

            -- Apply canvas drag offset to everything
            love.graphics.push()
            love.graphics.translate(0, canvasOffsetY)

                love.graphics.draw(stableSky, 0, -44 + oy/10)
                for i = 1, #layers do
                    love.graphics.draw(layers[i], 0, (wH - layers[i]:getHeight()) + oy/10 * i)
                end
                love.graphics.draw(buoy, 0, (wH - layers[#layers]:getHeight()) + oy/10 * #layers - buoy:getHeight())

            love.graphics.pop()

        love.graphics.pop()
    push:finish()
end