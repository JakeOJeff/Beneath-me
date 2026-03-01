function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    layers = {}
    mx, my = 0, 0
    player = { x = 0, y = 0 }
    baseY = player.y
    ox, oy = 0, 0

    mW, mH = 140, 88
    scale = 10
    wW = mW * scale
    wH = mH * scale

    love.window.setMode(wW, wH)

    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    buoy = love.graphics.newImage("assets/watertop/buoy.png")

    depths = {
        love.graphics.newImage("assets/depths/1.png"),        love.graphics.newImage("assets/depths/2.png")
    }

    ruler = love.graphics.newImage("assets/depth-bar.png")
    pointer = love.graphics.newImage("assets/pointer.png")
    timer = 0

    -- Drag system
    canvasOffsetY = -10
    dragActive = false
    dragLastY = 0
    dragVelocityY = 0
    friction = 0.92
end

function love.update(dt)
    timer = timer + dt
    ox, oy = distFromCenter(player.x, player.y)

    local speed = 3
    local amplitude = (canvasOffsetY < -90) and 1 or 12
    local rotSpeed = 3
    local rotAmplitude = 0.02

    player.y = baseY + math.sin(timer * speed) * amplitude
    player.rotation = math.sin(timer * rotSpeed) * rotAmplitude

    -- Momentum
    if not dragActive then
        canvasOffsetY = math.min(canvasOffsetY + dragVelocityY, -10)
        dragVelocityY = dragVelocityY * friction

        if math.abs(dragVelocityY) < 0.01 then
            dragVelocityY = 0
        end
    end
end

function distFromCenter(x, y)
    return (mW / 2) - x, (mH / 2) - y
end

function love.mousepressed(x, y, button)
    if button == 1 then
        dragActive = true
        dragLastY = y / scale -- convert to game space
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
        local gy = y / scale

        dragVelocityY = gy - dragLastY
        dragLastY = gy

        canvasOffsetY = math.min(canvasOffsetY + dragVelocityY, -10)

    end
end

function love.draw()
    love.graphics.push()
    love.graphics.scale(scale, scale)

        -- Rotate around center (use mW/mH, not wW/wH)
        love.graphics.push()
        love.graphics.translate(mW/2, mH/2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)
        love.graphics.translate(-mW/2, -mH/2)

            -- Apply vertical drag
            love.graphics.push()
            love.graphics.translate(0, canvasOffsetY)

                love.graphics.draw(depths[2], 0, (mH - layers[#layers]:getHeight()) + 35 + depths[1]:getHeight())
                love.graphics.draw(depths[1], 0, (mH - layers[#layers]:getHeight()) + 35)

                love.graphics.draw(stableSky, 0, -44 + oy/10)

                for i = 1, #layers do
                    love.graphics.draw(layers[i], 0,
                        (mH - layers[i]:getHeight()) + oy/10 * i)
                end

                love.graphics.draw(buoy, 0,
                    (mH - layers[#layers]:getHeight()) +
                    oy/10 * #layers - buoy:getHeight())

            love.graphics.pop()
        love.graphics.pop()

    love.graphics.pop()

    love.graphics.print(canvasOffsetY)
end