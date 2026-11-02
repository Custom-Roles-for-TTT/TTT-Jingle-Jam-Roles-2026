local math = math
local player = player
local timer = timer

local PlayerIterator = player.Iterator
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "close"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you get close to another player"
end

ABILITY.DescriptionParams = {
    ["ally"] = "that player",
    ["allyPlural"] = false,
    ["enemy"] = "that player",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "a random dead player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.4

if SERVER then
    local wasNear = {}
    local nearestPlayer = {}

    function ABILITY.Begin(amnesiac)
        wasNear[amnesiac] = {}

        local timerId = "Amnesiac_Close_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if not amnesiac:IsActive() then
                wasNear[amnesiac] = {}
                return
            end

            local near = {}
            local newArrival
            local newArrivalDistance = math.huge

            local pos = amnesiac:GetPos()
            for _, p in PlayerIterator() do
                if p == amnesiac or not p:IsActive() then continue end

                local distance = pos:DistToSqr(p:GetPos())
                if distance > 40000 then continue end

                near[p] = true
                if not wasNear[amnesiac][p] and distance < newArrivalDistance then
                    newArrival = p
                    newArrivalDistance = distance
                end
            end
            wasNear[amnesiac] = near

            if newArrival then
                nearestPlayer[amnesiac] = newArrival
                AMNESIAC:TriggerInstantAbility(amnesiac)
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_Close_" .. amnesiac:SteamID64())
        wasNear[amnesiac] = nil
        nearestPlayer[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return nearestPlayer[amnesiac]
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return nearestPlayer[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
