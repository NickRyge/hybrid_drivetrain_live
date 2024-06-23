local M = {}

-- Local variables
local timer = 0
local blink_interval_on
local blink_interval_off
local total_interval
local isVehicleSpawned = false
local isCrashNotified = false
local isCrashed = false

local abs = math.abs
local state = "idle"
local brakeThreshold = 0
local crashCounter = 0
local crashCountThreshold = 0
local lastThrottle = 0

local function init(jbeamData)
    -- Timer setup
    blink_interval_on = 0.5
    blink_interval_off = 0.5
    total_interval = blink_interval_on + blink_interval_off
    timer = 0

    electrics.values.postCrashBrakeTriggered = nil
    state = "idle"
    crashCounter = 0
    lastThrottle = 0
    brakeThreshold = jbeamData.brakeThreshold or 50
    crashCountThreshold = jbeamData.crashCountThreshold or 3
    isVehicleSpawned = false
    isCrashNotified = false
    isCrashed = false

end

local function updateGFX(dt)
    -- isCrashed = detectCrash()
    if(not isVehicleSpawned) then
        gui.message("Hybrid system is armed", 10, "nil", "favorite_outline")
        isVehicleSpawned = true
    end
    
    -- Timer counter modulo the total interval
    timer = (timer + dt) % total_interval

    -- Check if timer is within the "blink on" interval
    local is_on = timer < blink_interval_on

    -- Set the electrics.value based on the condition and timer state
    electrics.values["rallyhy_dangerblink"] = (isCrashed and is_on) or 0
    electrics.values["rallyhy_danger"] = isCrashed or 0
    if(isCrashed and not isCrashNotified) then
        gui.message("Vehicle is unsafe", 10, "nil", "favorite_outline")
        isCrashNotified = true
    end
end

local function detectCrash()
    local isCrashedDetected = false
    if state == "idle" then
        --we specifically DO care for the sign of Z here to avoid false trigges on jumps and heavy compressions
        if (abs(sensors.gx2) > brakeThreshold or abs(sensors.gy2) > brakeThreshold) or ((sensors.gz2 - powertrain.currentGravity) > brakeThreshold) then
            state = "braking"
            crashCounter = crashCounter + 1
            gui.message("Vehicle is unsafe", 10, "nil", "warning")
            isCrashedDetected = true
            electrics.values.postCrashBrakeTriggered = 1
        end
        elseif state == "braking" then
            electrics.values.brake = 1
            electrics.values.throttle = 0
            if abs(electrics.values.wheelspeed) < 0.5 or electrics.values.gearIndex < 0 then
                state = "holding"
                lastThrottle = input.throttle
            end
            elseif state == "holding" then
                electrics.values.brake = 1
                if input.throttle > lastThrottle * 1.1 or abs(electrics.values.wheelspeed) > 5 then
                    isCrashedDetected = false
                    state = crashCounter <= crashCountThreshold and "idle" or "disabled"
                end
                lastThrottle = input.throttle
            end    
        end    
    end
    return isCrashedDetected
end

M.updateGFX = updateGFX
M.init = init

return M



