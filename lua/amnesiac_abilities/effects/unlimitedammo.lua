local timer = timer

local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "unlimitedammo"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "get" or "gets") .. " unlimited ammo"
end

if SERVER then
    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) then return false end

        TimerCreate("Amnesiac_UnlimitedAmmo_" .. amnesiac:SteamID64(), 0.1, 0, function()
            if not IsPlayer(ally) or not ally:IsActive() then return end

            local wep = ally:GetActiveWeapon()
            if not IsValid(wep) then return end

            local maxClip = wep:GetMaxClip1()
            if maxClip > 0 and wep:Clip1() < maxClip then
                wep:SetClip1(maxClip)
            end
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        TimerRemove("Amnesiac_UnlimitedAmmo_" .. amnesiac:SteamID64())
    end
end

AMNESIAC:RegisterAbility(ABILITY)
