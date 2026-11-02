local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

local ABILITY = {}

ABILITY.Id = "dealdamage"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you damage another player"
end

ABILITY.DescriptionParams = {
    ["ally"] = "you",
    ["allyPlural"] = true,
    ["enemy"] = "that player",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "a random dead player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.5

if SERVER then
    local lastDamaged = {}

    function ABILITY.Begin(amnesiac)
        AddHook("PostEntityTakeDamage", "Amnesiac_DealDamage_PostEntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo, took)
            if not IsPlayer(amnesiac) or not amnesiac:IsActive() then return end
            if not took or dmginfo:GetDamage() <= 0 then return end

            local attacker = dmginfo:GetAttacker()
            if not IsPlayer(attacker) or attacker ~= amnesiac then return end

            if IsPlayer(target) and target ~= amnesiac then
                lastDamaged[amnesiac] = target
                AMNESIAC:TriggerInstantAbility(amnesiac)
            else
                lastDamaged[amnesiac] = nil
            end
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("PostEntityTakeDamage", "Amnesiac_DealDamage_PostEntityTakeDamage_" .. amnesiac:SteamID64())
        lastDamaged[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return amnesiac
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return lastDamaged[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)