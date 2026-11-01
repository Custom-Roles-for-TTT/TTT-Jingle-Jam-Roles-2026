local file = file
local math = math

local FileExists = file.Exists
local MathRandom = math.random

local ABILITY = {}

ABILITY.Id = "fling"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "get" or "gets") .. " flung away"
end

ABILITY.Cooldown = function(weight)
    return 3 / weight
end

if SERVER then
    -- Sound from the "Make a Randomat!" event, only played if that addon is installed
    local hasSound = FileExists("sound/make/cartoon_fling_sound.mp3", "GAME")

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        local pos = enemy:GetPos()
        pos.z = pos.z + 10
        enemy:SetPos(pos)

        enemy:SetVelocity(Vector(MathRandom() - 0.5, MathRandom() - 0.5, 1) * 1000)

        if hasSound then
            enemy:EmitSound("make/cartoon_fling_sound.mp3")
        end
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
