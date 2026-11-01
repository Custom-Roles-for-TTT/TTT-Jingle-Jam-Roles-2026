local timer = timer
local util = util

local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local UtilTraceLine = util.TraceLine

local ABILITY = {}

ABILITY.Id = "lookingat"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While you are looking at another player"
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
    local viewedPlayer = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_LookingAt_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            local target
            if amnesiac:IsActive() then
                local startPos = amnesiac:EyePos()
                local tr = UtilTraceLine({
                    start = startPos,
                    endpos = startPos + amnesiac:GetAimVector() * 10000,
                    filter = amnesiac,
                    mask = MASK_SHOT
                })
                if IsPlayer(tr.Entity) and tr.Entity:IsActive() then
                    target = tr.Entity
                end
            end

            if viewedPlayer[amnesiac] and viewedPlayer[amnesiac] ~= target then
                viewedPlayer[amnesiac] = nil
                AMNESIAC:StopOngoingAbility(amnesiac)
            end

            if target and not viewedPlayer[amnesiac] then
                viewedPlayer[amnesiac] = target
                AMNESIAC:StartOngoingAbility(amnesiac)
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_LookingAt_" .. amnesiac:SteamID64())
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
