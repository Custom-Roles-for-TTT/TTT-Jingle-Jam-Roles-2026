local ABILITY = {}

ABILITY.Id = "drainclip"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "empty" or "empties") .. " their clip"
end

ABILITY.Cooldown = function(weight)
    return 3 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        local wep = enemy:GetActiveWeapon()
        if not IsValid(wep) or wep:Clip1() <= 0 then return false end

        wep:SetClip1(0)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
