local math = math

local MathFloor = math.floor
local MathMin = math.min

local ABILITY = {}

ABILITY.Id = "heal"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "gain" or "gains") .. " " .. MathFloor(50 * weight) .. " health"
end

ABILITY.Cooldown = function(weight)
    return 10
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end

        local health = ally:Health()
        local maxHealth = ally:GetMaxHealth()
        if health >= maxHealth then return false end

        ally:SetHealth(MathMin(maxHealth, health + MathFloor(50 * weight)))
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
