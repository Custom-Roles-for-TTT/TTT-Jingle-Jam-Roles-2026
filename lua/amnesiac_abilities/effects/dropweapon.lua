local ABILITY = {}

ABILITY.Id = "dropweapon"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "drop" or "drops") .. " their held weapon"
end

ABILITY.Cooldown = function(weight)
    return 3 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        local wep = enemy:GetActiveWeapon()
        if not IsValid(wep) or wep.AllowDrop == false then return false end

        enemy:DropWeapon(wep)
        enemy:SetFOV(0, 0.2)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
