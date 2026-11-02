local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

local ABILITY = {}

ABILITY.Id = "sprint"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you sprint"
end

ABILITY.DescriptionParams = {
    ["ally"] = "you",
    ["allyPlural"] = true,
    ["enemy"] = "the nearest player",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "a random dead player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.2

if SERVER then
    function ABILITY.Begin(amnesiac)
        AddHook("TTTSprintStateChange", "Amnesiac_Sprint_TTTSprintStateChange_" .. amnesiac:SteamID64(), function(ply, sprinting, wasSprinting)
            if ply ~= amnesiac then return end
            if not amnesiac:IsActive() then return end
            if not sprinting or wasSprinting then return end

            AMNESIAC:TriggerInstantAbility(amnesiac)
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("TTTSprintStateChange", "Amnesiac_Sprint_TTTSprintStateChange_" .. amnesiac:SteamID64())
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return amnesiac
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return AMNESIAC:GetNearestPlayer(amnesiac)
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
