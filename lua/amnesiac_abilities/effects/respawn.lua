local timer = timer

local TimerSimple = timer.Simple

local ABILITY = {}

ABILITY.Id = "respawn"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["dead"] .. " " .. (params["deadPlural"] and "respawn" or "respawns")
end

ABILITY.Cooldown = function(weight)
    return 30 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(dead) or dead:Alive() or dead:GetRole() == ROLE_NONE then return false end
        TimerSimple(0.1, function()
            if not IsPlayer(dead) or dead:Alive() then return end
            if GetRoundState() ~= ROUND_ACTIVE then return end

            local body = dead.server_ragdoll or dead:GetRagdollEntity()
            local credits = CORPSE.GetCredits(body, 0) or 0

            dead:SpawnForRound(true)
            dead:SetCredits(credits)
            dead:SetHealth(dead:GetMaxHealth())
            if IsValid(body) then
                dead:SetPos(body:GetPos() + Vector(0, 0, 10))
                dead:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            end

            dead:QueueMessage(MSG_PRINTCENTER, "You have been revived by " .. ROLE_STRINGS_EXT[ROLE_AMNESIAC] .. "!")

            SafeRemoveEntity(body)
        end)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
