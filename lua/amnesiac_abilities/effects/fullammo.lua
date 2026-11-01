local math = math

local MathMax = math.max

local ABILITY = {}

ABILITY.Id = "fullammo"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "get" or "gets") .. " full ammo"
end

ABILITY.Cooldown = function(weight)
    return 3 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end
        for _, wep in ipairs(ally:GetWeapons()) do
            local maxClip = wep:GetMaxClip1()
            if maxClip > 0 then
                wep:SetClip1(maxClip)
            end

            local ammoType = wep:GetPrimaryAmmoType()
            local maxReserve = wep.Primary and wep.Primary.ClipMax
            if ammoType >= 0 and maxReserve then
                ally:SetAmmo(MathMax(ally:GetAmmoCount(ammoType), maxReserve), ammoType)
            end
        end
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
