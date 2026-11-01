local ABILITY = {}

ABILITY.Id = "packapunch"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "get" or "gets") .. " Pack-a-Punched"
end
ABILITY.Incompatible = {"throwgrenade"}

ABILITY.Cooldown = function(weight)
    return 5 / weight
end

if SERVER then
    function ABILITY.Condition()
        return TTTPAP ~= nil
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not TTTPAP then return false end
        if not IsPlayer(ally) or not ally:IsActive() then return false end

        local wep = ally:GetActiveWeapon()
        if not IsValid(wep) then return false end
        if not TTTPAP:CanOrderPAP(wep) then return false end

        TTTPAP:OrderPAP(ally, true)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
