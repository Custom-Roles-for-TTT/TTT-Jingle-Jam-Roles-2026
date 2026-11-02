local math = math

local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "ignite"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "ignite" or "ignites") .. " for " .. MathFloor(15 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 30 * weight
end

if SERVER then
    local ignited = {}

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        enemy:Ignite(15 * weight)

        ignited[enemy] = ignited[enemy] or {}
        ignited[enemy][amnesiac] = CurTime() + (15 * weight)
        return true
    end

    function ABILITY.End(amnesiac)
        local now = CurTime()
        for p, sources in pairs(ignited) do
            local expiry = sources[amnesiac]
            if not expiry then continue end
            sources[amnesiac] = nil

            local otherBurning = false
            for _, otherExpiry in pairs(sources) do
                if now < otherExpiry then
                    otherBurning = true
                    break
                end
            end
            if now < expiry and not otherBurning and IsPlayer(p) then
                p:Extinguish()
            end

            if not next(sources) then
                ignited[p] = nil
            end
        end
    end
end

AMNESIAC:RegisterAbility(ABILITY)
