local hook = hook
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "damageweakening"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "deal" or "deals") .. " " .. MathFloor(100 * weight) .. "% less damage"
end

if SERVER then
    local weakened = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) then return false end
        AMNESIAC:StartStatus(enemy, "damageweakening")

        weakened[amnesiac] = enemy

        local scale = 1 - weight
        AddHook("EntityTakeDamage", "Amnesiac_DamageWeakening_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
            if dmginfo:GetAttacker() ~= enemy then return end
            dmginfo:ScaleDamage(scale)
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageWeakening_EntityTakeDamage_" .. amnesiac:SteamID64())

        local ply = weakened[amnesiac]
        weakened[amnesiac] = nil
        if ply then
            for _, target in pairs(weakened) do
                if target == ply then
                    return
                end
            end
            AMNESIAC:EndStatus(ply, "damageweakening")
        end
    end
end

AMNESIAC:RegisterStatus("damageweakening", "particle/damagedown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
