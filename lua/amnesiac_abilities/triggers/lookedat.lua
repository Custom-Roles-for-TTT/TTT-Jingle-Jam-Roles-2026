local math = math
local player = player
local table = table
local timer = timer
local util = util

local MathRandom = math.random
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local UtilTraceLine = util.TraceLine

local ABILITY = {}

ABILITY.Id = "lookedat"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When another player looks at you"
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
ABILITY.Weight = 0.2

if SERVER then
    local watchers = {}
    local watchingPlayer = {}

    function ABILITY.Begin(amnesiac)
        watchers[amnesiac] = {}

        local timerId = "Amnesiac_LookedAt_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if not amnesiac:IsActive() then
                watchers[amnesiac] = {}
                return
            end

            local current = {}
            local newWatchers = {}

            for _, p in PlayerIterator() do
                if p == amnesiac or not p:IsActive() then continue end

                local startPos = p:EyePos()
                local tr = UtilTraceLine({
                    start = startPos,
                    endpos = startPos + p:GetAimVector() * 10000,
                    filter = p,
                    mask = MASK_SHOT
                })

                if tr.Entity == amnesiac then
                    current[p] = true
                    if not watchers[amnesiac][p] then
                        TableInsert(newWatchers, p)
                    end
                end
            end
            watchers[amnesiac] = current

            if #newWatchers > 0 then
                watchingPlayer[amnesiac] = newWatchers[MathRandom(#newWatchers)]
                AMNESIAC:TriggerInstantAbility(amnesiac)
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_LookedAt_" .. amnesiac:SteamID64())
        watchers[amnesiac] = nil
        watchingPlayer[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return amnesiac
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return watchingPlayer[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
