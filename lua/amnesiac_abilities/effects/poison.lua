local math = math
local timer = timer

local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "poison"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "take" or "takes") .. " " .. MathFloor(50 * weight) .. " damage per second"
end
ABILITY.Incompatible = {"airborne", "fullhealth"}

if SERVER then
    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) then return false end

        TimerCreate("Amnesiac_Poison_" .. amnesiac:SteamID64(), 1, 0, function()
            if not IsPlayer(enemy) or not enemy:IsActive() then return end

            local dmginfo = DamageInfo()
            dmginfo:SetDamage(MathFloor(50 * weight))
            dmginfo:SetDamageType(DMG_GENERIC)
            dmginfo:SetAttacker(amnesiac)
            dmginfo:SetInflictor(amnesiac)
            enemy:TakeDamageInfo(dmginfo)
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        TimerRemove("Amnesiac_Poison_" .. amnesiac:SteamID64())
    end
end

AMNESIAC:RegisterAbility(ABILITY)
