local lib = require("libs.lib")
local balistic = require("libs.balisticLib")
Gun = {}
function Gun.new(VERTICAL_GEARSHIFT, HORIZONTAL_GEARSHIFT, VERTICAL_SPEEDCONTROLLER, HORIZONTAL_SPEEDCONTROLLER,
    GunMountPos, BarrelLength, InputSpeed, GunRotationRatio, facing)
    local self = {}
    self.VERTICAL_GEARSHIFT = VERTICAL_GEARSHIFT
    self.HORIZONTAL_GEARSHIFT = HORIZONTAL_GEARSHIFT

    self.VERTICAL_SPEEDCONTROLLER = VERTICAL_SPEEDCONTROLLER
    self.HORIZONTAL_SPEEDCONTROLLER = HORIZONTAL_SPEEDCONTROLLER

    self.facing = facing

    self.GunMountPos = GunMountPos
    self.GunPos = GunMountPos + vector.new(0, 3, 0)

    self.BarrelLength = BarrelLength
    self.InputSpeed = InputSpeed
    self.GunRotationRatio = GunRotationRatio

    self.gm3 = -0.05
    self.minVel = 1.98
    self.k = 0.010079

    function self.AimAt(TargetPos)
        local RelativeTargetPos = TargetPos - self.GunPos
        local FlatDistance = math.sqrt(RelativeTargetPos.x * RelativeTargetPos.x + RelativeTargetPos.z *
                                           RelativeTargetPos.z)
        local SpeedControllerSpeed = self.InputSpeed / self.GunRotationRatio * 8

        
        local HorizontalAngle = balistic.calculateHorizontalAngle(RelativeTargetPos.x, RelativeTargetPos.z, self.facing)
        local HorizontalRotationDirection = lib.sign(HorizontalAngle)

        local VerticalAngle = balistic.calculateVerticalAngle(self.gm3, self.k, self.minVel * 4, FlatDistance, self.BarrelLength,
            -RelativeTargetPos.y)
        if (VerticalAngle == "out_of_range") then
            printError("Out of Range")
            return nil
        end
        
        local VerticalDirection = lib.sign(VerticalAngle)

        if (not (HorizontalAngle == 0)) then
            HORIZONTAL_SPEEDCONTROLLER.setTargetSpeed(SpeedControllerSpeed * HorizontalRotationDirection)
            HORIZONTAL_GEARSHIFT.rotate(lib.round(HorizontalAngle * GunRotationRatio))
        end

        VERTICAL_SPEEDCONTROLLER.setTargetSpeed(SpeedControllerSpeed * VerticalDirection)
        VERTICAL_GEARSHIFT.rotate(lib.round(VerticalAngle * GunRotationRatio))
    end

    return self
end
return Gun
