function love.load()
    layers = {}
    mx, my = 0
    ox, oy = 0
    wW, wH = love.graphics.getDimensions()
    love.window.setMode(140, 88)
    stableSky = love.graphics.newImage("assets/watertop/stable.png")
    for i = 1, 4 do
        table.insert(layers, love.graphics.newImage("assets/watertop/"..i..".png"))
    end
end


function love.update(dt)
    mx, my = love.mouse.getPosition()
    ox, oy = distFromCenter(mx, my)
end

function distFromCenter(x, y)
    return (wW/2) - x, (wH/2) - y
end

function love.draw()
    love.graphics.draw(stableSky)
end