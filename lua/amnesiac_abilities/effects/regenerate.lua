local math = math
local timer = timer

local MathFloor = math.floor
local MathMin = math.min
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "regenerate"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "gain" or "gains") .. " " .. MathFloor(50 * weight) .. " health per second"
end
ABILITY.Incompatible = {"airborne", "fullhealth", "lowhealth"}

if SERVER then
    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) then return false end

        TimerCreate("Amnesiac_Regenerate_" .. amnesiac:SteamID64(), 1, 0, function()
            if not IsPlayer(ally) or not ally:IsActive() then return end

            local health = ally:Health()
            local maxHealth = ally:GetMaxHealth()
            if health >= maxHealth then return end

            ally:SetHealth(MathMin(maxHealth, health + MathFloor(50 * weight)))
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        TimerRemove("Amnesiac_Regenerate_" .. amnesiac:SteamID64())
    end
end

AMNESIAC:RegisterAbility(ABILITY)
