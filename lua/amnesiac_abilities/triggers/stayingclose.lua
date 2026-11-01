local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "stayingclose"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While you are close to another player"
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
    local closePlayer = {}

    local function IsClose(amnesiac, ply)
        return IsPlayer(ply) and ply:IsActive() and amnesiac:GetPos():DistToSqr(ply:GetPos()) <= 40000
    end

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_StayingClose_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            if closePlayer[amnesiac] and (not amnesiac:IsActive() or not IsClose(amnesiac, closePlayer[amnesiac])) then
                closePlayer[amnesiac] = nil
                AMNESIAC:StopOngoingAbility(amnesiac)
            end

            if not closePlayer[amnesiac] and amnesiac:IsActive() then
                local nearest = AMNESIAC:GetNearestPlayer(amnesiac)
                if IsClose(amnesiac, nearest) then
                    closePlayer[amnesiac] = nearest
                    AMNESIAC:StartOngoingAbility(amnesiac)
                end
            end
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_StayingClose_" .. amnesiac:SteamID64())
        closePlayer[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return closePlayer[amnesiac]
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return closePlayer[amnesiac]
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return AMNESIAC:GetRandomDeadAlly(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
