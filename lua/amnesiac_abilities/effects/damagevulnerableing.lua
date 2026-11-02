local hook = hook
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "damagevulnerableing"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "take" or "takes") .. " " .. MathFloor(100 * weight) .. "% extra damage"
end

if SERVER then
    local vulnerable = {}

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) then return false end
        AMNESIAC:StartStatus(enemy, "damagevulnerableing")

        vulnerable[amnesiac] = enemy

        local scale = 1 + weight
        AddHook("EntityTakeDamage", "Amnesiac_DamageVulnerableing_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
            if target ~= enemy then return end
            dmginfo:ScaleDamage(scale)
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageVulnerableing_EntityTakeDamage_" .. amnesiac:SteamID64())

        local ply = vulnerable[amnesiac]
        vulnerable[amnesiac] = nil
        if ply then
            for _, target in pairs(vulnerable) do
                if target == ply then
                    return
                end
            end
            AMNESIAC:EndStatus(ply, "damagevulnerableing")
        end
    end
end

AMNESIAC:RegisterStatus("damagevulnerableing", "particle/resistdown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
