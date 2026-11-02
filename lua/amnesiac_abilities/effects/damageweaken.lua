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

ABILITY.Id = "damageweaken"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "deal" or "deals") .. " " .. MathFloor(100 * weight) .. "% less damage for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

if SERVER then
    local weakened = {}
    local endTimers = {}

    local function UpdateWeakenEnd(ply)
        local weakenEnd = 0
        for _, targets in pairs(weakened) do
            if targets[ply] then
                weakenEnd = MathMax(weakenEnd, targets[ply].expiry)
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageweaken")
            return
        end

        local timerId = "Amnesiac_DamageWeakenEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if CurTime() < weakenEnd then
            TimerCreate(timerId, weakenEnd - CurTime(), 1, function()
                UpdateWeakenEnd(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageweaken")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        AMNESIAC:StartStatus(enemy, "damageweaken")
        if not weakened[amnesiac] then
            weakened[amnesiac] = {}
            AddHook("EntityTakeDamage", "Amnesiac_DamageWeaken_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
                local attacker = dmginfo:GetAttacker()
                if not IsPlayer(attacker) then return end

                local weaken = weakened[amnesiac] and weakened[amnesiac][attacker]
                if not weaken or CurTime() >= weaken.expiry then return end

                dmginfo:ScaleDamage(weaken.scale)
            end)
        end

        weakened[amnesiac][enemy] = {
            expiry = CurTime() + 20,
            scale = 1 - weight
        }
        UpdateWeakenEnd(enemy)
        return true
    end

    function ABILITY.End(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageWeaken_EntityTakeDamage_" .. amnesiac:SteamID64())
        local targets = weakened[amnesiac]
        weakened[amnesiac] = nil
        for p, _ in pairs(targets or {}) do
            UpdateWeakenEnd(p)
        end
    end
end

AMNESIAC:RegisterStatus("damageweaken", "particle/damagedown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
