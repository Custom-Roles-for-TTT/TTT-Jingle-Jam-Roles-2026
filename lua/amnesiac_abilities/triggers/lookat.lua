local timer = timer
local util = util

local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local UtilTraceLine = util.TraceLine

local ABILITY = {}

ABILITY.Id = "lookat"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you look at another player"
end

ABILITY.DescriptionParams = {
    ["ally"] = "that player",
    ["allyPlural"] = false,
    ["enemy"] = "that player",
    ["enemyPlural"] = false,
    ["bonus"] = "you",
    ["bonusPlural"] = true,
    ["dead"] = "a random dead player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.2

if SERVER then
    local lookingAt = {}
    local viewedPlayer = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_LookAt_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if not amnesiac:IsActive() then
                lookingAt[amnesiac] = nil
                return
            end

            local startPos = amnesiac:EyePos()
            local tr = UtilTraceLine({
                start = startPos,
                endpos = startPos + amnesiac:GetAimVector() * 10000,
                filter = amnesiac,
                mask = MASK_SHOT
            })

            local target = tr.Entity
            if not IsPlayer(target) or not target:IsActive() then
                target = nil
            end

            if target and target ~= lookingAt[amnesiac] then
                viewedPlayer[amnesiac] = target
                AMNESIAC:TriggerInstantAbility(amnesiac)
            end
            lookingAt[amnesiac] = target
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_LookAt_" .. amnesiac:SteamID64())
        lookingAt[amnesiac] = nil
        viewedPlayer[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return viewedPlayer[amnesiac]
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return viewedPlayer[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return amnesiac
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
