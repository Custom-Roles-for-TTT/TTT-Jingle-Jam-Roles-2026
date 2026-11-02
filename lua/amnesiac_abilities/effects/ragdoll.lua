local hook = hook
local math = math
local timer = timer

local AddHook = hook.Add
local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "ragdoll"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "ragdoll" or "ragdolls") .. " for " .. MathFloor(15 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 30 * weight
end

AddHook("StartCommand", "Amnesiac_Ragdoll_StartCommand", function(ply, cmd)
    if not ply:GetNWBool("TTTAmnesiacRagdolled") then return end
    cmd:ClearButtons()
    cmd:ClearMovement()
end)

if SERVER then
    local ragdolled = {}

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        if not ragdolled[amnesiac] then
            ragdolled[amnesiac] = {}
        end

        if not ragdolled[amnesiac][enemy] then
            enemy:Ragdoll(0, true, true)
            ragdolled[amnesiac][enemy] = true
        end

        TimerCreate("Amnesiac_Ragdoll_" .. amnesiac:SteamID64() .. "_" .. enemy:SteamID64(), 15 * weight, 1, function()
            enemy:UnRagdoll()
            ragdolled[amnesiac][enemy] = nil
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(ragdolled[amnesiac] or {}) do
            p:UnRagdoll()
            TimerRemove("Amnesiac_Ragdoll_" .. amnesiac:SteamID64() .. "_" .. p:SteamID64())
        end
        ragdolled[amnesiac] = nil
    end
end

AMNESIAC:RegisterAbility(ABILITY)
