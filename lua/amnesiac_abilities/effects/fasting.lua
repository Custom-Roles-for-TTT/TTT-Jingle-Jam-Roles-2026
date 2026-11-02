local hook = hook
local math = math
local table = table

local AddHook = hook.Add
local MathFloor = math.floor
local MathMax = math.max
local TableInsert = table.insert

local ABILITY = {}

ABILITY.Id = "fasting"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "move" or "moves") .. " " .. MathFloor(100 * weight) .. "% faster"
end
ABILITY.Incompatible = {"airborne", "standingstill"}

AddHook("TTTSpeedMultiplier", "Amnesiac_Fasting_TTTSpeedMultiplier", function(ply, mults)
    local mult = ply:GetNWFloat("TTTAmnesiacFastingMult", 1)
    if mult == 1 then return end
    TableInsert(mults, mult)
end)

if SERVER then
    local boosted = {}

    local function UpdateMult(ply)
        local mult = 1
        for _, sourceMult in pairs(boosted[ply] or {}) do
            mult = MathMax(mult, sourceMult)
        end
        if IsPlayer(ply) then
            ply:SetNWFloat("TTTAmnesiacFastingMult", mult)
        end
    end

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) then return false end
        AMNESIAC:StartStatus(ally, "fasting")

        boosted[ally] = boosted[ally] or {}
        boosted[ally][amnesiac] = 1 + weight
        UpdateMult(ally)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        for p, sources in pairs(boosted) do
            if not sources[amnesiac] then continue end
            sources[amnesiac] = nil
            UpdateMult(p)
            if not next(sources) then
                boosted[p] = nil
                AMNESIAC:EndStatus(p, "fasting")
            end
        end
    end
end

AMNESIAC:RegisterStatus("fasting", "particle/speedup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
