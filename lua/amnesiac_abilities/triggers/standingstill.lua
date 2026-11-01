local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "standingstill"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While you are standing still for more than 5 seconds"
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
    local active = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_StandingStill_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            local isStill = amnesiac:IsActive() and amnesiac:GetVelocity():LengthSqr() <= 10
            if not isStill then
                stillSince[amnesiac] = nil
            elseif not stillSince[amnesiac] then
                stillSince[amnesiac] = CurTime()
            end

            local isActive = isStill and CurTime() - stillSince[amnesiac] >= 5
            if isActive and not active[amnesiac] then
                active[amnesiac] = true
                AMNESIAC:StartOngoingAbility(amnesiac)
            elseif not isActive and active[amnesiac] then
                active[amnesiac] = nil
                AMNESIAC:StopOngoingAbility(amnesiac)
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_StandingStill_" .. amnesiac:SteamID64())
        stillSince[amnesiac] = nil
        active[amnesiac] = nil
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
