
local ParticleManager = {}

local pool = {}

function ParticleManager.init()
    pool = {}
end

---Emit a burst of particles at a screen-space position.
---@param x     number  screen x
---@param y     number  screen y
---@param r,g,b number  burst colour
---@param count number  number of particles (default 20)
function ParticleManager.burst(x, y, r, g, b, count)
    count = count or 20
    for _ = 1, count do
        table.insert(pool, Particle.new(x, y, r, g, b))
    end
end

function ParticleManager.update(dt)
    for i = #pool, 1, -1 do
        pool[i]:update(dt)
        if pool[i]:isDead() then table.remove(pool, i) end
    end
end

function ParticleManager.draw()
    for _, p in ipairs(pool) do
        p:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ParticleManager