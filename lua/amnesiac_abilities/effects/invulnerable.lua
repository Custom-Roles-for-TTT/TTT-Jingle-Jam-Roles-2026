local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "invulnerable"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "are" or "is") .. " invulnerable for 10 seconds"
end

ABILITY.Cooldown = function(weight)
    return 5 / weight
end

if SERVER then
    local invulnerable = {}

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end

        local amnesiacInvulnerable = invulnerable[amnesiac] and invulnerable[amnesiac][ally]
        if not amnesiacInvulnerable and ally:IsInvulnerable() then return false end

        invulnerable[amnesiac] = invulnerable[amnesiac] or {}
        local timerId = "Amnesiac_Invulnerable_" .. amnesiac:SteamID64() .. "_" .. ally:SteamID64()

        if not amnesiacInvulnerable then
            ally:SetInvulnerable(true, true)
        end
        invulnerable[amnesiac][ally] = timerId

        TimerCreate(timerId, 10, 1, function()
            if invulnerable[amnesiac] then
                invulnerable[amnesiac][ally] = nil
            end
            if IsPlayer(ally) then
                ally:SetInvulnerable(false, true)
            end
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, timerId in pairs(invulnerable[amnesiac] or {}) do
            TimerRemove(timerId)
            if IsPlayer(p) then
                p:SetInvulnerable(false, false)
            end
        end
        invulnerable[amnesiac] = nil
    end
end

AMNESIAC:RegisterAbility(ABILITY)
