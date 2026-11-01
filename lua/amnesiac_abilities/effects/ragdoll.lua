local ents = ents
local hook = hook
local math = math
local timer = timer
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local CreateEntity = ents.Create
local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local UtilTraceHull = util.TraceHull

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
    local function FindStandPos(ply, rag, fallback)
        if not IsValid(rag) then return fallback end

        local pos = rag:GetPos() + Vector(0, 0, 10)
        local tr = UtilTraceHull({
            start = pos + Vector(0, 0, 32),
            endpos = pos - Vector(0, 0, 32),
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            filter = { ply, rag },
            mask = MASK_PLAYERSOLID
        })
        if tr.StartSolid then
            return fallback
        end
        return tr.HitPos
    end

    local function CreateRagdoll(ply)
        local rag = CreateEntity("prop_ragdoll")
        if not IsValid(rag) then return end

        rag:SetModel(ply:GetModel())
        rag:SetPos(ply:GetPos())
        rag:SetAngles(Angle(0, ply:EyeAngles().y, 0))
        rag:SetSkin(ply:GetSkin())
        for _, group in ipairs(ply:GetBodyGroups()) do
            rag:SetBodygroup(group.id, ply:GetBodygroup(group.id))
        end
        rag:SetColor(ply:GetColor())
        rag:Spawn()
        rag:Activate()
        rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local vel = ply:GetVelocity()
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local phys = rag:GetPhysicsObjectNum(i)
            if IsValid(phys) then
                local bonePos, boneAng = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))
                if bonePos then
                    phys:SetPos(bonePos)
                    phys:SetAngles(boneAng)
                end
                phys:SetVelocity(vel)
            end
        end

        rag.AmnesiacRagdollOwner = ply
        return rag
    end

    local function RemoveRagdoll(amnesiac, ply, restore)
        local data = ragdolled[amnesiac] and ragdolled[amnesiac][ply]
        if not data then return end
        ragdolled[amnesiac][ply] = nil

        TimerRemove(data.timerId)
        local rag = data.ragdoll

        if IsPlayer(ply) then
            ply:SetParent(nil)
            ply:SetNoDraw(false)
            ply:SetNotSolid(false)
            ply:DrawShadow(true)
            ply:DrawWorldModel(true)
            ply:DrawViewModel(true)
            ply:SetNWBool("TTTAmnesiacRagdolled", false)

            if restore and ply:Alive() then
                ply:UnSpectate()
                ply:SetMoveType(MOVETYPE_WALK)
                ply:SetPos(FindStandPos(ply, rag, data.startPos))

                if IsValid(rag) then
                    ply:SetEyeAngles(Angle(0, rag:GetAngles().yaw, 0))
                    ply:SetVelocity(rag:GetVelocity())
                end
            end
        end

        SafeRemoveEntity(rag)
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        local alreadyRagdolled = ragdolled[amnesiac] and ragdolled[amnesiac][enemy]
        if not alreadyRagdolled and enemy:GetObserverMode() ~= OBS_MODE_NONE then return false end

        if not ragdolled[amnesiac] then
            ragdolled[amnesiac] = {}
            local sid = amnesiac:SteamID64()

            AddHook("EntityTakeDamage", "Amnesiac_Ragdoll_EntityTakeDamage_" .. sid, function(target, dmginfo)
                local owner = target.AmnesiacRagdollOwner
                if not IsPlayer(owner) then return end
                if not ragdolled[amnesiac] or not ragdolled[amnesiac][owner] then return end
                if dmginfo:IsDamageType(DMG_CRUSH) and not IsPlayer(dmginfo:GetAttacker()) then return end

                owner:TakeDamageInfo(dmginfo)
            end)

            AddHook("PlayerDeath", "Amnesiac_Ragdoll_PlayerDeath_" .. sid, function(victim)
                RemoveRagdoll(amnesiac, victim, false)
            end)

            AddHook("PlayerSpawn", "Amnesiac_Ragdoll_PlayerSpawn_" .. sid, function(ply)
                RemoveRagdoll(amnesiac, ply, false)
            end)

            AddHook("PlayerDisconnected", "Amnesiac_Ragdoll_PlayerDisconnected_" .. sid, function(ply)
                RemoveRagdoll(amnesiac, ply, false)
            end)
        end

        local timerId = "Amnesiac_Ragdoll_" .. amnesiac:SteamID64() .. "_" .. enemy:SteamID64()

        if not alreadyRagdolled then
            if enemy:InVehicle() then
                enemy:ExitVehicle()
            end

            local rag = CreateRagdoll(enemy)
            if not rag then return false end

            ragdolled[amnesiac][enemy] = {
                ragdoll = rag,
                startPos = enemy:GetPos(),
                timerId = timerId
            }

            enemy:SetParent(rag)
            enemy:Spectate(OBS_MODE_CHASE)
            enemy:SpectateEntity(rag)
            enemy:SetNoDraw(true)
            enemy:SetNotSolid(true)
            enemy:DrawShadow(false)
            enemy:DrawWorldModel(false)
            enemy:DrawViewModel(false)
            enemy:SetNWBool("TTTAmnesiacRagdolled", true)
        end

        TimerCreate(timerId, MathFloor(15 * weight), 1, function()
            RemoveRagdoll(amnesiac, enemy, true)
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(ragdolled[amnesiac] or {}) do
            RemoveRagdoll(amnesiac, p, true)
        end
        ragdolled[amnesiac] = nil

        local sid = amnesiac:SteamID64()
        RemoveHook("EntityTakeDamage", "Amnesiac_Ragdoll_EntityTakeDamage_" .. sid)
        RemoveHook("PlayerDeath", "Amnesiac_Ragdoll_PlayerDeath_" .. sid)
        RemoveHook("PlayerSpawn", "Amnesiac_Ragdoll_PlayerSpawn_" .. sid)
        RemoveHook("PlayerDisconnected", "Amnesiac_Ragdoll_PlayerDisconnected_" .. sid)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
