local hook = hook
local math = math
local table = table

local AddHook = hook.Add
local MathFloor = math.floor
local MathMin = math.min
local TableInsert = table.insert

local ABILITY = {}

ABILITY.Id = "slowing"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "move" or "moves") .. " " .. MathFloor(100 * weight) .. "% slower"
end

AddHook("TTTSpeedMultiplier", "Amnesiac_Slowing_TTTSpeedMultiplier", function(ply, mults)
    local mult = ply:GetNWFloat("TTTAmnesiacSlowingMult", 1)
    if mult == 1 then return end
    TableInsert(mults, mult)
end)

if SERVER then
    local slowed = {}

    local function UpdateMult(ply)
        local mult = 1
        for _, sourceMult in pairs(slowed[ply] or {}) do
            mult = MathMin(mult, sourceMult)
        end
        if IsPlayer(ply) then
            ply:SetNWFloat("TTTAmnesiacSlowingMult", mult)
        end
    end

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) then return false end
        AMNESIAC:StartStatus(enemy, "slowing")

        slowed[enemy] = slowed[enemy] or {}
        slowed[enemy][amnesiac] = 1 - weight
        UpdateMult(enemy)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        for p, sources in pairs(slowed) do
            if not sources[amnesiac] then continue end
            sources[amnesiac] = nil
            UpdateMult(p)
            if not next(sources) then
                slowed[p] = nil
                AMNESIAC:EndStatus(p, "slowing")
            end
        end
    end
end

AMNESIAC:RegisterStatus("slowing", "particle/speeddown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
