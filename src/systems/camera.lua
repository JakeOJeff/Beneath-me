

local Camera = {}

function Camera.init(maxDepth)
    Camera.offsetY    = Settings.INITIAL_OFFSET_Y
    Camera.maxDepth   = maxDepth
    Camera.dragActive = false
    Camera.dragLastY  = 0
    Camera.velocityY  = 0
end


function Camera.update(dt)
    if not Camera.dragActive then
        Camera.offsetY  = math.min(Camera.offsetY + Camera.velocityY, Settings.INITIAL_OFFSET_Y)
        Camera.offsetY  = math.max(Camera.offsetY, Camera.maxDepth)
        Camera.velocityY = Camera.velocityY * Settings.FRICTION
        if math.abs(Camera.velocityY) < 0.01 then Camera.velocityY = 0 end
    end
end


function Camera.startDrag(screenY)
    Camera.dragActive = true
    Camera.dragLastY  = screenY / Settings.SCALE
    Camera.velocityY  = 0
end

function Camera.endDrag()
    Camera.dragActive = false
end


function Camera.onDrag(screenY)
    if not Camera.dragActive then return end
    local gy = screenY / Settings.SCALE
    Camera.velocityY  = gy - Camera.dragLastY
    Camera.dragLastY  = gy
    Camera.offsetY    = math.min(Camera.offsetY + Camera.velocityY, Settings.INITIAL_OFFSET_Y)
    Camera.offsetY    = math.max(Camera.offsetY, Camera.maxDepth)
end


function Camera.returnToSurface()
    local dist = math.abs(Camera.offsetY - Settings.INITIAL_OFFSET_Y)
    Camera.velocityY = dist * 0.12
    Camera.dragActive = false
end

function Camera.isInDepthZone()
    return Camera.offsetY < Settings.DEPTH_ZONE_THRESHOLD
end


function Camera.depthFraction(maxDepth)
    local range = (maxDepth or Camera.maxDepth) - Settings.DEPTH_ZONE_THRESHOLD
    return math.min(1, math.max(0,
        (Camera.offsetY - Settings.DEPTH_ZONE_THRESHOLD) / range))
end

return Camera
