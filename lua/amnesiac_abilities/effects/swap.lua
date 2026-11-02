local ABILITY = {}

ABILITY.Id = "swap"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "swap" or "swaps") .. " positions with " .. params["bonus"]
end

ABILITY.Cooldown = function(weight)
    return 1 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end
        if not IsPlayer(bonus) or not bonus:IsActive() then return false end

        local allyPos = ally:GetPos()
        local bonusPos = bonus:GetPos()
        local allyVel = ally:GetVelocity()
        local bonusVel = bonus:GetVelocity()

        ally:SetPos(bonusPos)
        bonus:SetPos(allyPos)

        ally:SetVelocity(bonusVel - allyVel)
        bonus:SetVelocity(allyVel - bonusVel)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
