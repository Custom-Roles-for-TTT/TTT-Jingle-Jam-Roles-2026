local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "standstill"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you stand still for 5 seconds"
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
    local stillSince = {}
    local triggered = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_StandStill_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if not amnesiac:IsActive() or amnesiac:GetVelocity():LengthSqr() > 10 then
                stillSince[amnesiac] = nil
                triggered[amnesiac] = false
                return
            end

            local now = CurTime()
            if not stillSince[amnesiac] then
                stillSince[amnesiac] = now
                return
            end

            if not triggered[amnesiac] and now - stillSince[amnesiac] >= 5 then
                triggered[amnesiac] = true
                AMNESIAC:TriggerInstantAbility(amnesiac)
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_StandStill_" .. amnesiac:SteamID64())
        stillSince[amnesiac] = nil
        triggered[amnesiac] = nil
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
