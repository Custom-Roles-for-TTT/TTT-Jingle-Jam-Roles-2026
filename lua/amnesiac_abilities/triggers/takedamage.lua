local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

local ABILITY = {}

ABILITY.Id = "takedamage"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you take damage"
end

ABILITY.DescriptionParams = {
    ["ally"] = "you",
    ["allyPlural"] = true,
    ["enemy"] = "your attacker",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "a random dead player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.5

if SERVER then
    local lastAttacker = {}

    function ABILITY.Begin(amnesiac)
        AddHook("PostEntityTakeDamage", "Amnesiac_TakeDamage_PostEntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo, took)
            if not IsPlayer(target) or target ~= amnesiac then return end
            if not took or dmginfo:GetDamage() <= 0 then return end

            local attacker = dmginfo:GetAttacker()
            if IsPlayer(attacker) and attacker ~= amnesiac then
                lastAttacker[amnesiac] = attacker
            else
                lastAttacker[amnesiac] = nil
            end
            AMNESIAC:TriggerInstantAbility(amnesiac)
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("PostEntityTakeDamage", "Amnesiac_TakeDamage_PostEntityTakeDamage_" .. amnesiac:SteamID64())
        lastAttacker[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return amnesiac
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return lastAttacker[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)