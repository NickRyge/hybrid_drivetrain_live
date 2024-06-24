-- Authored by NickRyge

local M = {}
local abs = math.abs
local clamp = clamp

-- Local variables
local mgu
local doThrottle


local hybridModes = {
    OFF = 0,
    PURE = 1,
    POWER = 2,
    CHARGE = 3
}
local currentMode
local modeNames

--- Called whenever the player resets the car
local function reset()
    -- clearly does nothing yet.
end

function UpdateHybridMode(value)
    currentMode = (currentMode + value) % 4
    gui.message("Hybrid mode updated: " .. tostring(modeNames[currentMode]))
end

local function _error(dt)
    error("No MGU attached!")
end

-- Runs when the vehicle spawns
local function init(jbeamData)
    currentMode = hybridModes.OFF
    modeNames = {}
    for k, v in pairs(hybridModes) do
        modeNames[v] = k
    end

    mgu = powertrain.getDevice("mgu") -- Set MGU

    if mgu == nil then
        log("E", "mguController.lua", "No MGU attached!")
        M.updateGFX = _error -- Throw exception. Hack.
    end
end



--- Run every graphics tick
local function updateGFX(dt)
    local battery = energyStorage.getStorage("mainBattery")
    --print(mgu.energyStorage)
    if currentMode == hybridModes.POWER or currentMode == hybridModes.PURE then
        local x = electrics.values.gearIndex
        local reverseMultiplier = (x >= 0 and 1) or -1
        electrics.values["mguThrottle"] = electrics.values["throttle"] * reverseMultiplier
        
        if currentMode == hybridModes.PURE then 
            electrics.values.throttle = 0 
        end
    end

    if currentMode == hybridModes.OFF or currentMode == hybridModes.CHARGE then
        electrics.values["mguThrottle"] = 0
    end

    print(energyStorage.getStorage((mgu.energyStorage[1])).remainingRatio)
    
    electrics.values["regenThrottle"] = (electrics.values["brake"]*2)+0.5
    
    if currentMode == hybridModes.CHARGE and battery.remainingRatio ~= 1  then
        electrics.values["regenThrottle"] = (electrics.values["brake"]*2)+0.6
    elseif electrics.values.throttle > 0 or battery.remainingRatio == 1 then
        electrics.values["regenThrottle"] = 0
    end
end

M.updateGFX = updateGFX
M.init = init
M.reset = reset

return M