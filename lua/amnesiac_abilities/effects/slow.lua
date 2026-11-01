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

ABILITY.Id = "slow"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "move" or "moves") .. " " .. MathFloor((100 * weight) / (1 + weight)) .. "% slower for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

AddHook("TTTSpeedMultiplier", "Amnesiac_Slow_TTTSpeedMultiplier", function(ply, mults)
    if CurTime() >= ply:GetNWFloat("TTTAmnesiacSlowEnd") then return end
    TableInsert(mults, ply:GetNWFloat("TTTAmnesiacSlowMult", 1))
end)

if SERVER then
    local slowed = {}
    local endTimers = {}

    local function UpdateSlow(ply)
        local best
        for _, slow in pairs(slowed[ply] or {}) do
            if CurTime() < slow.expiry and (not best or slow.expiry > best.expiry) then
                best = slow
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "slow")
            return
        end

        ply:SetNWFloat("TTTAmnesiacSlowMult", best and best.mult or 1)
        ply:SetNWFloat("TTTAmnesiacSlowEnd", best and best.expiry or 0)

        local timerId = "Amnesiac_SlowEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if best then
            TimerCreate(timerId, best.expiry - CurTime(), 1, function()
                UpdateSlow(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "slow")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        AMNESIAC:StartStatus(enemy, "slow")
        slowed[enemy] = slowed[enemy] or {}
        slowed[enemy][amnesiac] = {
            mult = 1 - (weight / (1 + weight)),
            expiry = CurTime() + 20
        }
        UpdateSlow(enemy)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, sources in pairs(slowed) do
            if not sources[amnesiac] then continue end
            sources[amnesiac] = nil
            UpdateSlow(p)
            if not next(sources) then
                slowed[p] = nil
            end
        end
    end
end

AMNESIAC:RegisterStatus("slow", "particle/speeddown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
