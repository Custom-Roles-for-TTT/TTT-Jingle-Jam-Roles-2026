local ents = ents
local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove
local CreateEntity = ents.Create

local ABILITY = {}

ABILITY.Id = "ghosting"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_ONGOING
ABILITY.Description = function(params, weight)
    return params["dead"] .. " " .. (params["deadPlural"] and "become" or "becomes") .. " a visible ghost"
end
ABILITY.Incompatible = {"fullhealth"}

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

    local function RemoveGhost(amnesiac)
        local data = ghosts[amnesiac]
        ghosts[amnesiac] = nil
        if data then
            SafeRemoveEntity(data.ent)
        end

        local sid = amnesiac:SteamID64()
        RemoveHook("Think", "Amnesiac_Ghosting_Think_" .. sid)
        RemoveHook("EntityTakeDamage", "Amnesiac_Ghosting_EntityTakeDamage_" .. sid)
    end

    function ABILITY.StartEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(dead) or dead:Alive() or dead:GetRole() == ROLE_NONE then return false end

        RemoveGhost(amnesiac)

        local ghost = CreateGhost(dead)
        if not ghost then return false end

        ghosts[amnesiac] = {
            ply = dead,
            ent = ghost
        }

        local sid = amnesiac:SteamID64()
        AddHook("Think", "Amnesiac_Ghosting_Think_" .. sid, function()
            local data = ghosts[amnesiac]
            if not data then return end

            if not IsPlayer(data.ply) or data.ply:Alive() or not IsValid(data.ent) then
                RemoveGhost(amnesiac)
                return
            end

            data.ent:SetPos(data.ply:GetPos())
            data.ent:SetAngles(data.ply:EyeAngles())
        end)

        AddHook("EntityTakeDamage", "Amnesiac_Ghosting_EntityTakeDamage_" .. sid, function(ent, dmginfo)
            if ent.AmnesiacGhost then return true end
        end)
        return true
    end

    function ABILITY.StopEffect(amnesiac)
        RemoveGhost(amnesiac)
    end
end

AMNESIAC:RegisterAbility(ABILITY)
