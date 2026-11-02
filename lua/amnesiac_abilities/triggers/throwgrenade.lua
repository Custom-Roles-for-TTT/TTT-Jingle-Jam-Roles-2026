local hook = hook
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
local TimerSimple = timer.Simple

local ABILITY = {}

ABILITY.Id = "throwgrenade"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you throw a grenade"
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
ABILITY.Weight = 0.4

if SERVER then
    function ABILITY.Begin(amnesiac)
        AddHook("OnEntityCreated", "Amnesiac_ThrowGrenade_OnEntityCreated_" .. amnesiac:SteamID64(), function(ent)
            if not IsValid(ent) then return end

            TimerSimple(0, function()
                if not IsValid(ent) or not IsPlayer(amnesiac) then return end
                if not amnesiac:IsActive() then return end
                if not ent.GetThrower or ent:GetThrower() ~= amnesiac then return end

                AMNESIAC:TriggerInstantAbility(amnesiac)
            end)
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("OnEntityCreated", "Amnesiac_ThrowGrenade_OnEntityCreated_" .. amnesiac:SteamID64())
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
