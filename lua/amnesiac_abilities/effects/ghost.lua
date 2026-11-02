local ents = ents
local hook = hook
local math = math

local AddHook = hook.Add
local RemoveHook = hook.Remove
local CreateEntity = ents.Create
local MathFloor = math.floor

local ABILITY = {}

ABILITY.Id = "ghost"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["dead"] .. " " .. (params["deadPlural"] and "become" or "becomes") .. " a visible ghost for " .. MathFloor(30 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 40 * weight
end

if SERVER then
    local ghosts = {}

    local function CreateGhost(ply)
        local ghost = CreateEntity("npc_kleiner")
        if not IsValid(ghost) then return end

        ghost:SetModel(ply:GetModel())
        ghost:SetSkin(ply:GetSkin())
        for _, group in ipairs(ply:GetBodyGroups()) do
            ghost:SetBodygroup(group.id, ply:GetBodygroup(group.id))
        end

        ghost:SetPos(ply:GetPos())
        ghost:Spawn()
        ghost:SetNotSolid(true)
        ghost:SetColor(Color(245, 245, 245, 100))
        ghost:SetRenderMode(RENDERMODE_GLOW)

        ghost.AmnesiacGhost = true
        return ghost
    end

    local function RemoveGhost(amnesiac, ply)
        local data = ghosts[amnesiac] and ghosts[amnesiac][ply]
        if not data then return end
        ghosts[amnesiac][ply] = nil
        SafeRemoveEntity(data.ent)
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(dead) or dead:Alive() or dead:GetRole() == ROLE_NONE then return false end
        if not ghosts[amnesiac] then
            ghosts[amnesiac] = {}

            local sid = amnesiac:SteamID64()
            AddHook("Think", "Amnesiac_Ghost_Think_" .. sid, function()
                local playerGhosts = ghosts[amnesiac]
                if not playerGhosts then return end

                local now = CurTime()
                for ply, data in pairs(playerGhosts) do
                    if not IsPlayer(ply) or ply:Alive() or now >= data.expiry or not IsValid(data.ent) then
                        RemoveGhost(amnesiac, ply)
                        continue
                    end

                    data.ent:SetPos(ply:GetPos())
                    data.ent:SetAngles(ply:EyeAngles())
                end
            end)

            AddHook("EntityTakeDamage", "Amnesiac_Ghost_EntityTakeDamage_" .. sid, function(ent, dmginfo)
                if ent.AmnesiacGhost then return true end
            end)

            AddHook("PlayerDisconnected", "Amnesiac_Ghost_PlayerDisconnected_" .. sid, function(ply)
                RemoveGhost(amnesiac, ply)
            end)
        end

        local expiry = CurTime() + (30 * weight)
        local existing = ghosts[amnesiac][dead]
        if existing and IsValid(existing.ent) then
            existing.expiry = expiry
            return true
        end

        local ghost = CreateGhost(dead)
        if not ghost then return false end

        ghosts[amnesiac][dead] = {
            ent = ghost,
            expiry = expiry
        }
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(ghosts[amnesiac] or {}) do
            RemoveGhost(amnesiac, p)
        end
        ghosts[amnesiac] = nil

        local sid = amnesiac:SteamID64()
        RemoveHook("Think", "Amnesiac_Ghost_Think_" .. sid)
        RemoveHook("EntityTakeDamage", "Amnesiac_Ghost_EntityTakeDamage_" .. sid)
        RemoveHook("PlayerDisconnected", "Amnesiac_Ghost_PlayerDisconnected_" .. sid)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
