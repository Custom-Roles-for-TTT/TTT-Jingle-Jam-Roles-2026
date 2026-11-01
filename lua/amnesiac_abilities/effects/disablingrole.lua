local ABILITY = {}

ABILITY.Id = "disablingrole"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "have" or "has") .. " their role ability disabled"
end
ABILITY.Incompatible = {"airborne"}

if SERVER then
    local disabled = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        if enemy:IsRoleAbilityDisabled() then return false end

        enemy:DisableRoleAbility()
        disabled[amnesiac] = enemy
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        local ply = disabled[amnesiac]
        disabled[amnesiac] = nil
        if IsPlayer(ply) then
            ply:EnableRoleAbility()
        end
    end
end

AMNESIAC:RegisterAbility(ABILITY)
