local ABILITY = {}

ABILITY.Id = "disablingshop"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " cannot use the shop"
end
ABILITY.Incompatible = {"airborne"}

if SERVER then
    local disabled = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        if not enemy:CanUseShop() or enemy:IsShopPurchaseDisabled() then return false end

        enemy:DisableShopPurchases()
        disabled[amnesiac] = enemy
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        local ply = disabled[amnesiac]
        disabled[amnesiac] = nil
        if IsPlayer(ply) then
            ply:EnableShopPurchases()
        end
    end
end

AMNESIAC:RegisterAbility(ABILITY)
