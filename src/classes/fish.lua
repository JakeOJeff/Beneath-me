

local Fish = {}
Fish.__index = Fish

---Create a new Fish instance.
---@param def       table   fish definition from conf/fish_defs.lua
---@param x         number  starting x position (game units)
---@param y         number  starting y position (game units)
---@param dir       number  1 = swim right, -1 = swim left
---@param speed     number  horizontal speed in game-units / second
function Fish.new(def, x, y, dir, speed)
    return setmetatable({
        def        = def,
        x          = x,
        y          = y,
        dir        = dir,
        speed      = speed,
        bobPhase   = math.random() * math.pi * 2,
        alive      = true,
        flashTimer = 0,
    }, Fish)
end

---Update fish position and animation.
---@param dt     number   delta time
---@param timer  number   global game timer (for bob sync)
function Fish:update(dt, timer)
    self.x         = self.x + self.dir * self.speed * dt
    self.y         = self.y + math.sin(timer * 2 + self.bobPhase) * 0.08
    self.flashTimer = math.max(0, self.flashTimer - dt)
end

---Returns true when the fish has swum fully off screen.
function Fish:isOffScreen(mW)
    local iw = self.def.img:getWidth()
    return (self.dir == 1  and self.x > mW + iw + 5)
        or (self.dir == -1 and self.x < -iw - 5)
end

---Draw the fish at its current world position.
---@param timer number global game timer
function Fish:draw(timer)
    local img    = self.def.img
    local iw, ih = img:getDimensions()

    -- flash effect when recently clicked
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 1, 1, 0.5 + math.sin(self.flashTimer * 40) * 0.5)
    end

    if self.dir == -1 then
        love.graphics.draw(img, self.x + iw, self.y, 0, -1, 1)
    else
        love.graphics.draw(img, self.x, self.y)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- rarity glow dot above fish
    local gc = self.def.color
    love.graphics.setColor(gc[1], gc[2], gc[3], 0.85)
    love.graphics.circle("fill", self.x + iw / 2, self.y - 2, 1)
    love.graphics.setColor(1, 1, 1, 1)
end

---Returns true if the given game-space point is inside this fish's bounding box.
---@param gx          number  game-space x
---@param canvasGY    number  game-space y already adjusted for canvas scroll
function Fish:containsPoint(gx, canvasGY)
    local img    = self.def.img
    local iw, ih = img:getDimensions()
    return gx >= self.x and gx <= self.x + iw
       and canvasGY >= self.y and canvasGY <= self.y + ih
end

return Fish