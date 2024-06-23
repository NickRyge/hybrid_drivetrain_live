-- Authored by NickRyge

local M = {}
local abs = math.abs

-- Local variables
local timer
local blink_interval_on
local blink_interval_off
local total_interval

local isCrashed = false

local brakeThreshold
local crashCounter


--- Called whenever the player resets the car
local function reset()
    -- Reset the crashcounter, isCrashed and 
    crashCounter = 0
    isCrashed = false
    electrics.values.crashDetected = 0
end


-- Runs when the vehicle spawns
local function init(jbeamData)
    -- How long the lights stay on for.
    blink_interval_on = 0.2

    -- How long the lights stay off for
    blink_interval_off = 0.2

    -- Total interval (For modulo)
    total_interval = blink_interval_on + blink_interval_off
    timer = 0

    brakeThreshold = jbeamData.brakeThreshold or 50 -- set brake threshold

    reset() -- call reset to make sure everything is initialized and at 0.
end

--- Function that detects whether the car us currently crashing. If we are crashing, isCrashed = true.
local function detectCrash() 
    -- Logic stolen from the postCrashBrake.
    if (abs(sensors.gx2) > brakeThreshold or abs(sensors.gy2) > brakeThreshold) or ((sensors.gz2 - powertrain.currentGravity) > brakeThreshold) then

        crashCounter = crashCounter + 1 -- Amount of time the car has crashed. You can use that for further thresholds.

        guihooks.message("Impact detected, battery unsafe.", 10, "vehicle.postCrashBrake.impact")
        electrics.values.crashDetected = 1 -- Can be used for other controllers to know whether the car is crashed or not.
        isCrashed = true
    end
end


--- Run every graphics tick
local function updateGFX(dt)

    -- First, detect if we are currently crashing.
    detectCrash()

    -- Timer counter modulo the total interval
    timer = (timer + dt) % total_interval

    -- Set value of crashlight to 1 / 0.4 respectively.
    electrics.values["crashLight"] = isCrashed and ((timer < blink_interval_on) and 0.4 or 0) or 1 -- Its a bit hacky.
end

M.updateGFX = updateGFX
M.init = init
M.reset = reset

return M