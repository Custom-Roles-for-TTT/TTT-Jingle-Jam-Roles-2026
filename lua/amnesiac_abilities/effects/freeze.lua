local math = math
local timer = timer

local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "freeze"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "freeze" or "freezes") .. " for " .. MathFloor(15 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 30 * weight
end

if SERVER then
    local frozen = {}

    local function Unfreeze(ply, amnesiac)
        local sources = frozen[ply]
        if not sources or not sources[amnesiac] then return end

        TimerRemove(sources[amnesiac])
        sources[amnesiac] = nil
        if next(sources) then return end

        frozen[ply] = nil
        if IsPlayer(ply) then
            ply:Freeze(false)
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        frozen[enemy] = frozen[enemy] or {}
        local timerId = "Amnesiac_Freeze_" .. amnesiac:SteamID64() .. "_" .. enemy:SteamID64()
        frozen[enemy][amnesiac] = timerId

        enemy:Freeze(true)
        TimerCreate(timerId, MathFloor(15 * weight), 1, function()
            Unfreeze(enemy, amnesiac)
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(frozen) do
            Unfreeze(p, amnesiac)
        end
    end
end

AMNESIAC:RegisterAbility(ABILITY)
