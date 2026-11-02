local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "emptyclip"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you empty a clip"
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
    local lastWeapon = {}
    local lastClip = {}

    function ABILITY.Begin(amnesiac)
        local timerId = "Amnesiac_EmptyClip_" .. amnesiac:SteamID64()
        TimerCreate(timerId, 0.1, 0, function()
            if not IsPlayer(amnesiac) then
                TimerRemove(timerId)
                return
            end

            local wep = amnesiac:GetActiveWeapon()
            if not amnesiac:IsActive() or not IsValid(wep) or wep:Clip1() < 0 then
                lastWeapon[amnesiac] = nil
                lastClip[amnesiac] = nil
                return
            end

            local clip = wep:Clip1()
            if lastWeapon[amnesiac] == wep and lastClip[amnesiac] > 0 and clip == 0 then
                AMNESIAC:TriggerInstantAbility(amnesiac)
            end

            lastWeapon[amnesiac] = wep
            lastClip[amnesiac] = clip
        end)
    end

    function ABILITY.End(amnesiac)
        TimerRemove("Amnesiac_EmptyClip_" .. amnesiac:SteamID64())
        lastWeapon[amnesiac] = nil
        lastClip[amnesiac] = nil
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
