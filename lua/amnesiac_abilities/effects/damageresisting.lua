local hook = hook
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "damageresisting"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "take" or "takes") .. " " .. MathFloor(100 * weight) .. "% less damage"
end

if SERVER then
    local resisting = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) then return false end
        AMNESIAC:StartStatus(ally, "damageresisting")

        resisting[amnesiac] = ally

        local scale = 1 - weight
        AddHook("EntityTakeDamage", "Amnesiac_DamageResisting_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
            if target ~= ally then return end
            dmginfo:ScaleDamage(scale)
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageResisting_EntityTakeDamage_" .. amnesiac:SteamID64())

        local ply = resisting[amnesiac]
        resisting[amnesiac] = nil
        if ply then
            for _, target in pairs(resisting) do
                if target == ply then
                    return
                end
            end
            AMNESIAC:EndStatus(ply, "damageresisting")
        end
    end
end

AMNESIAC:RegisterStatus("damageresisting", "particle/resistup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
