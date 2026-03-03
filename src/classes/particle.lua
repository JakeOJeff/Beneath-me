

local Particle = {}
Particle.__index = Particle

---@param x   number  screen-space spawn x
---@param y   number  screen-space spawn y
---@param r   number  red   [0-1]
---@param g   number  green [0-1]
---@param b   number  blue  [0-1]
function Particle.new(x, y, r, g, b)
    return setmetatable({
        x    = x,
        y    = y,
        vx   = math.random(-80, 80),
        vy   = math.random(-120, -20),
        life = math.random(5, 12) / 10,
        r    = r,
        g    = g,
        b    = b,
    }, Particle)
end

function Particle:update(dt)
    self.x    = self.x + self.vx * dt
    self.y    = self.y + self.vy * dt
    self.vy   = self.vy + 30 * dt
    self.life = self.life - dt
end

function Particle:isDead()
    return self.life <= 0
end

function Particle:draw()
    local a = math.min(1, self.life * 2)
    love.graphics.setColor(self.r, self.g, self.b, a)
    love.graphics.rectangle("fill", self.x, self.y, 4, 4)
end

return Particle