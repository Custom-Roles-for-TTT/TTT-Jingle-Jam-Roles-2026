local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

local ABILITY = {}

ABILITY.Id = "death"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you die"
end

ABILITY.DescriptionParams = {
    ["ally"] = "a random player",
    ["allyPlural"] = false,
    ["enemy"] = "your killer",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "you",
    ["deadPlural"] = true
}
ABILITY.Weight = 1

if SERVER then
    local killers = {}

    function ABILITY.Begin(amnesiac)
        AddHook("PlayerDeath", "Amnesiac_Death_PlayerDeath_" .. amnesiac:SteamID64(), function(victim, inflictor, attacker)
            if not IsPlayer(victim) or victim ~= amnesiac then return end

            if IsPlayer(attacker) and attacker ~= amnesiac then
                killers[amnesiac] = attacker
            else
                killers[amnesiac] = nil
            end
            AMNESIAC:TriggerInstantAbility(amnesiac)
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("PlayerDeath", "Amnesiac_Death_PlayerDeath_" .. amnesiac:SteamID64())
        killers[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return AMNESIAC:GetRandomAlly(amnesiac, {killers[amnesiac]})
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return killers[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return amnesiac
    end
end

AMNESIAC:RegisterAbility(ABILITY)