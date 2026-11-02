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

ABILITY.Id = "damagevulnerable"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "take" or "takes") .. " " .. MathFloor(100 * weight) .. "% extra damage for the next 20 seconds"
end

ABILITY.Cooldown = function(weight)
    return 30
end

if SERVER then
    local vulnerable = {}
    local endTimers = {}

    local function UpdateVulnerableEnd(ply)
        local vulnerableEnd = 0
        for _, targets in pairs(vulnerable) do
            if targets[ply] then
                vulnerableEnd = MathMax(vulnerableEnd, targets[ply].expiry)
            end
        end
        if not IsPlayer(ply) then
            if endTimers[ply] then TimerRemove(endTimers[ply]) end
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damagevulnerable")
            return
        end

        local timerId = "Amnesiac_DamageVulnerableEnd_" .. ply:SteamID64()
        endTimers[ply] = timerId
        if CurTime() < vulnerableEnd then
            TimerCreate(timerId, vulnerableEnd - CurTime(), 1, function()
                UpdateVulnerableEnd(ply)
            end)
        else
            TimerRemove(timerId)
            endTimers[ply] = nil
            AMNESIAC:EndStatus(ply, "damagevulnerable")
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        AMNESIAC:StartStatus(enemy, "damagevulnerable")
        if not vulnerable[amnesiac] then
            vulnerable[amnesiac] = {}
            AddHook("EntityTakeDamage", "Amnesiac_DamageVulnerable_EntityTakeDamage_" .. amnesiac:SteamID64(), function(target, dmginfo)
                if not IsPlayer(target) then return end

                local vuln = vulnerable[amnesiac] and vulnerable[amnesiac][target]
                if not vuln or CurTime() >= vuln.expiry then return end

                dmginfo:ScaleDamage(vuln.scale)
            end)
        end

        vulnerable[amnesiac][enemy] = {
            expiry = CurTime() + 20,
            scale = 1 + weight
        }
        UpdateVulnerableEnd(enemy)
        return true
    end

    function ABILITY.End(amnesiac)
        RemoveHook("EntityTakeDamage", "Amnesiac_DamageVulnerable_EntityTakeDamage_" .. amnesiac:SteamID64())
        local targets = vulnerable[amnesiac]
        vulnerable[amnesiac] = nil
        for p, _ in pairs(targets or {}) do
            UpdateVulnerableEnd(p)
        end
    end
end

AMNESIAC:RegisterStatus("damagevulnerable", "particle/resistdown.vmt", false)
AMNESIAC:RegisterAbility(ABILITY)
