local lib = require("libs.lib")

balistic = {}

function balistic.calculateVerticalAngle(g, k, v0, x, l, H)
    local A = (0.0495 + g / k) / v0
    local D = (l + lib.round(v0) + 2)
    local B = A * D + H
    local C = x + A / 2
    local E = (1 + 2 * A * x)/2
    local F = g / (k * k)

    local lastError = 999999999999999
    local step = 0.01 /180 * math.pi
    for ang = -math.pi / 6, math.pi / 3, step do
        local Cos = math.cos(ang)
        local Sin = math.sin(ang)
        local L = (x - D * Cos - 0.5 * Sin)
        local v0x = v0 * Cos
        --GOD equasion
        local predictedHeight = B + C * Sin / Cos - E /Cos - F * math.log(1 - k * L / v0x) 
        
        if(predictedHeight > 0) then
            if(math.abs(predictedHeight) < math.abs(lastError)) then
                return math.deg(ang)
            else
                return math.deg(ang - step)
            end
                
        end
        lastError = predictedHeight
    end
    return "out_of_range"
end
function balistic.calculateHorizontalAngle(x, z, facing)
    if(facing == "NORTH") then
        return math.deg(math.atan2(-x, -z))
    end
    if (facing == "SOUTH") then
        return math.deg(math.atan2(x, z))
    end
    if (facing == "WEST") then
        return -math.deg(math.atan2(-z, -x))
    end
    if (facing == "EAST") then
        return -math.deg(math.atan2(z, x))
    end
    return nil
end
return balistic