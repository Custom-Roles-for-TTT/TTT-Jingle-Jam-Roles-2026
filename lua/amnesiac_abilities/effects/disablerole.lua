local math = math
local timer = timer

local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "disablerole"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "have" or "has") .. " their role ability disabled for " .. MathFloor(15 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 30 * weight
end

if SERVER then
    local disabled = {}

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        local amnesiacDisabled = disabled[amnesiac] and disabled[amnesiac][enemy]
        if not amnesiacDisabled and enemy:IsRoleAbilityDisabled() then return false end

        disabled[amnesiac] = disabled[amnesiac] or {}
        local timerId = "Amnesiac_DisableRole_" .. amnesiac:SteamID64() .. "_" .. enemy:SteamID64()
        disabled[amnesiac][enemy] = timerId

        enemy:DisableRoleAbility()
        TimerCreate(timerId, 15 * weight, 1, function()
            disabled[amnesiac][enemy] = nil

            TimerRemove(timerId)
            if IsPlayer(enemy) then
                enemy:EnableRoleAbility()
            end
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(disabled[amnesiac] or {}) do
            local timerId = disabled[amnesiac] and disabled[amnesiac][p]
            if not timerId then continue end
            disabled[amnesiac][p] = nil

            TimerRemove(timerId)
            if IsPlayer(p) then
                p:EnableRoleAbility()
            end
        end
        disabled[amnesiac] = nil
    end
end

AMNESIAC:RegisterAbility(ABILITY)
