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

ABILITY.Id = "damageresist"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "take" or "takes") .. " " .. MathFloor(100 * weight) .. "% less damage for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

if SERVER then
    local resisting = {}
    local endTimers = {}

    local function UpdateResistEnd(ply)
        local resistEnd = 0
        for _, targets in pairs(resisting) do
            if targets[ply] then
                resistEnd = MathMax(resistEnd, targets[ply].expiry)
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageresist")
            return
        end

        local timerId = "Amnesiac_DamageResistEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if CurTime() < resistEnd then
            TimerCreate(timerId, resistEnd - CurTime(), 1, function()
                UpdateResistEnd(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damageresist")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end
        AMNESIAC:StartStatus(ally, "damageresist")
        if not resisting[amnesiac] then
            resisting[amnesiac] = {}
            AddHook("EntityTakeDamage", "Amnesiac_DamageResist_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
                if not IsPlayer(target) then return end

                local resist = resisting[amnesiac] and resisting[amnesiac][target]
                if not resist or CurTime() >= resist.expiry then return end

                dmginfo:ScaleDamage(resist.scale)
            end)
        end

        resisting[amnesiac][ally] = {
            expiry = CurTime() + 20,
            scale = 1 - weight
        }
        UpdateResistEnd(ally)
        return true
    end

    function ABILITY.End(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageResist_EntityTakeDamage_" .. amnesiac:SteamID64())
        local targets = resisting[amnesiac]
        resisting[amnesiac] = nil
        for p, _ in pairs(targets or {}) do
            UpdateResistEnd(p)
        end
    end
end

AMNESIAC:RegisterStatus("damageresist", "particle/resistup.vmt", true)
AMNESIAC:RegisterAbility(ABILITY)
