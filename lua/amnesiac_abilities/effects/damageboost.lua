local hook = hook
local math = math
local timer = timer

local AddHook = hook.Add
local RemoveHook = hook.Remove
local MathFloor = math.floor
local MathMax = math.max
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "damageboost"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "deal" or "deals") .. " " .. MathFloor(100 * weight) .. "% extra damage for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

if SERVER then
    local boosted = {}
    local endTimers = {}

    local function UpdateBoostEnd(ply)
        local boostEnd = 0
        for _, targets in pairs(boosted) do
            if targets[ply] then
                boostEnd = MathMax(boostEnd, targets[ply].expiry)
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageboost")
            return
        end

        local timerId = "Amnesiac_DamageBoostEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if CurTime() < boostEnd then
            TimerCreate(timerId, boostEnd - CurTime(), 1, function()
                UpdateBoostEnd(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageboost")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end
        AMNESIAC:StartStatus(ally, "damageboost")
        if not boosted[amnesiac] then
            boosted[amnesiac] = {}
            AddHook("EntityTakeDamage", "Amnesiac_DamageBoost_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
                local attacker = dmginfo:GetAttacker()
                if not IsPlayer(attacker) then return end

                local boost = boosted[amnesiac] and boosted[amnesiac][attacker]
                if not boost or CurTime() >= boost.expiry then return end

                dmginfo:ScaleDamage(boost.scale)
            end)
        end

        boosted[amnesiac][ally] = {
            expiry = CurTime() + 20,
            scale = 1 + weight
        }
        UpdateBoostEnd(ally)
        return true
    end

    function ABILITY.End(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageBoost_EntityTakeDamage_" .. amnesiac:SteamID64())
        local targets = boosted[amnesiac]
        boosted[amnesiac] = nil
        for p, _ in pairs(targets or {}) do
            UpdateBoostEnd(p)
        end
    end
end

AMNESIAC:RegisterStatus("damageboost", "particle/damageup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
