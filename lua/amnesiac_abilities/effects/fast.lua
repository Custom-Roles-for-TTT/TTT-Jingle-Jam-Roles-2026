local hook = hook
local math = math
local table = table
local timer = timer

local AddHook = hook.Add
local MathFloor = math.floor
local TableInsert = table.insert
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "fast"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "move" or "moves") .. " " .. MathFloor(100 * weight) .. "% faster for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

AddHook("TTTSpeedMultiplier", "Amnesiac_Fast_TTTSpeedMultiplier", function(ply, mults)
    if CurTime() >= ply:GetNWFloat("TTTAmnesiacFastEnd") then return end
    TableInsert(mults, ply:GetNWFloat("TTTAmnesiacFastMult", 1))
end)

if SERVER then
    local boosted = {}
    local endTimers = {}

    local function UpdateBoost(ply)
        local best
        for _, boost in pairs(boosted[ply] or {}) do
            if CurTime() < boost.expiry and (not best or boost.expiry > best.expiry) then
                best = boost
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "fast")
            return
        end

        ply:SetNWFloat("TTTAmnesiacFastMult", best and best.mult or 1)
        ply:SetNWFloat("TTTAmnesiacFastEnd", best and best.expiry or 0)

        local timerId = "Amnesiac_FastEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if best then
            TimerCreate(timerId, best.expiry - CurTime(), 1, function()
                UpdateBoost(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "fast")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end
        AMNESIAC:StartStatus(ally, "fast")
        boosted[ally] = boosted[ally] or {}
        boosted[ally][amnesiac] = {
            mult = 1 + weight,
            expiry = CurTime() + 20
        }
        UpdateBoost(ally)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, sources in pairs(boosted) do
            if not sources[amnesiac] then continue end
            sources[amnesiac] = nil
            UpdateBoost(p)
            if not next(sources) then
                boosted[p] = nil
            end
        end
    end
end

AMNESIAC:RegisterStatus("fast", "particle/speedup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
