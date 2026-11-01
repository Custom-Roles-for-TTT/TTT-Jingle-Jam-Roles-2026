local hook = hook
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "sprinting"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return "While you are sprinting"
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
    local sprinting = {}
    local active = {}

    function ABILITY.Begin(amnesiac)
        local sid = amnesiac:SteamID64()

        AddHook("TTTSprintStateChange", "Amnesiac_Sprinting_TTTSprintStateChange_" .. sid, function(ply, isSprinting, wasSprinting)
            if ply ~= amnesiac then return end
            sprinting[amnesiac] = isSprinting
        end)

        local timerId = "Amnesiac_Sprinting_" .. sid
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            local isActive = amnesiac:IsActive() and sprinting[amnesiac]
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
        local sid = amnesiac:SteamID64()
        RemoveHook("TTTSprintStateChange", "Amnesiac_Sprinting_TTTSprintStateChange_" .. sid)
        TimerRemove("Amnesiac_Sprinting_" .. sid)
        sprinting[amnesiac] = nil
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
