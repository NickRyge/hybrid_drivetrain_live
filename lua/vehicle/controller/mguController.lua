-- Authored by NickRyge

local M = {}
local abs = math.abs
local clamp = clamp

-- Local variables
local mgu
local doThrottle
local hybridMode


--- Called whenever the player resets the car
local function reset()

end

function UpdateHybridMode(value)
    hybridMode = (hybridMode + value) % 3
    gui.message("Hybrid mode updated: " .. tostring(hybridMode))
end

-- Runs when the vehicle spawns
local function init(jbeamData)
    mgu = powertrain.getDevice("mgu")
    hybridMode = 0
    


    if mgu ~= nil then
        print("MGU online")
    else
        log("E", "mguController.lua", "No MGU attached!")
    end
end



--- Run every graphics tick
local function updateGFX(dt)
    local battery = energyStorage.getStorage("mainBattery")
    --print(mgu.energyStorage)
    if hybridMode > 0 then
        local x = electrics.values.gearIndex
        local reverseMultiplier = (x >= 0 and 1) or -1
        electrics.values["mguThrottle"] = electrics.values["throttle"] * reverseMultiplier
        if hybridMode > 1 then electrics.values.throttle = 0 end
    else
        electrics.values["mguThrottle"] = 0
    end
    print(energyStorage.getStorage((mgu.energyStorage[1])).remainingRatio)
    
    electrics.values["regenThrottle"] = (electrics.values["brake"]*2)+0.5
end

M.updateGFX = updateGFX
M.init = init
M.reset = reset

return M