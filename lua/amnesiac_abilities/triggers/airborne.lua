local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "airborne"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While you are in the air"
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
    local active = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_Airborne_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            local isActive = amnesiac:IsActive() and not amnesiac:OnGround() and amnesiac:GetMoveType() == MOVETYPE_WALK
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
        TimerRemove("Amnesiac_Airborne_" .. amnesiac:SteamID64())
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
