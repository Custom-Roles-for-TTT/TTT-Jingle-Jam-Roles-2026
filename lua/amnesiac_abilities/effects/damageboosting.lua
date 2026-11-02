local hook = hook
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "damageboosting"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "deal" or "deals") .. " " .. MathFloor(100 * weight) .. "% extra damage"
end

if SERVER then
    local boosted = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) then return false end
        AMNESIAC:StartStatus(ally, "damageboosting")

        boosted[amnesiac] = ally

        local scale = 1 + weight
        AddHook("EntityTakeDamage", "Amnesiac_DamageBoosting_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
            if dmginfo:GetAttacker() ~= ally then return end
            dmginfo:ScaleDamage(scale)
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageBoosting_EntityTakeDamage_" .. amnesiac:SteamID64())

        local ply = boosted[amnesiac]
        boosted[amnesiac] = nil
        if ply then
            for _, target in pairs(boosted) do
                if target == ply then
                    return
                end
            end
            AMNESIAC:EndStatus(ply, "damageboosting")
        end
    end
end

AMNESIAC:RegisterStatus("damageboosting", "particle/damageup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
