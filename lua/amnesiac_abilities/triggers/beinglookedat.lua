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

ABILITY.Id = "beinglookedat"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While another player is looking at you"
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
    local watchingPlayer = {}

    local function IsLookingAt(ply, target)
        if not IsPlayer(ply) or not ply:IsActive() then return false end

        local startPos = ply:EyePos()
        local tr = UtilTraceLine({
            start = startPos,
            endpos = startPos + ply:GetAimVector() * 10000,
            filter = ply,
            mask = MASK_SHOT
        })
        return tr.Entity == target
    end

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_BeingLookedAt_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if watchingPlayer[amnesiac] and (not amnesiac:IsActive() or not IsLookingAt(watchingPlayer[amnesiac], amnesiac)) then
                watchingPlayer[amnesiac] = nil
                AMNESIAC:StopOngoingAbility(amnesiac)
            end

            if not watchingPlayer[amnesiac] and amnesiac:IsActive() then
                local watchers = {}
                for _, p in PlayerIterator() do
                    if p ~= amnesiac and IsLookingAt(p, amnesiac) then
                        TableInsert(watchers, p)
                    end
                end

                if #watchers > 0 then
                    watchingPlayer[amnesiac] = watchers[MathRandom(#watchers)]
                    AMNESIAC:StartOngoingAbility(amnesiac)
                end
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_BeingLookedAt_" .. amnesiac:SteamID64())
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
