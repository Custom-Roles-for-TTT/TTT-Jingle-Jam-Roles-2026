local math = math

local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "damage"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "take" or "takes") .. " " .. MathFloor(50 * weight) .. " damage"
end

ABILITY.Cooldown = function(weight)
    return 10
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(MathFloor(50 * weight))
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetAttacker(amnesiac)
        dmginfo:SetInflictor(amnesiac)
        enemy:TakeDamageInfo(dmginfo)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
