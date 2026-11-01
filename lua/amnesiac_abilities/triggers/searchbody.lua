local hook = hook

local AddHook = hook.Add
local RemoveHook = hook.Remove

local ABILITY = {}

ABILITY.Id = "searchbody"
ABILITY.Type = AMNESIAC_TYPE_TRIGGER
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return "When you search a body"
end

ABILITY.DescriptionParams = {
    ["ally"] = "you",
    ["allyPlural"] = true,
    ["enemy"] = "the nearest player",
    ["enemyPlural"] = false,
    ["bonus"] = "a random player",
    ["bonusPlural"] = false,
    ["dead"] = "that player",
    ["deadPlural"] = false
}
ABILITY.Weight = 0.5

if SERVER then
    local searchedBodies = {}
    local lastBodyOwner = {}

    function ABILITY.Begin(amnesiac)
        searchedBodies[amnesiac] = {}

        AddHook("TTTCanSearchCorpse", "Amnesiac_SearchBody_TTTCanSearchCorpse_" .. amnesiac:SteamID64(), function(ply, corpse, isCovert, isLongRange, wasTraitor)
            if ply ~= amnesiac then return end
            if not IsValid(corpse) then return end

            if not searchedBodies[amnesiac] or searchedBodies[amnesiac][corpse] then return end
            searchedBodies[amnesiac][corpse] = true

            local owner = CORPSE.GetPlayer(corpse)
            if IsPlayer(owner) then
                lastBodyOwner[amnesiac] = owner
            else
                lastBodyOwner[amnesiac] = nil
            end
            AMNESIAC:TriggerInstantAbility(amnesiac)
        end)
    end

    function ABILITY.End(amnesiac)
        RemoveHook("TTTCanSearchCorpse", "Amnesiac_SearchBody_TTTCanSearchCorpse_" .. amnesiac:SteamID64())
        searchedBodies[amnesiac] = nil
        lastBodyOwner[amnesiac] = nil
    end

    function ABILITY.GetAllyTarget(amnesiac)
        return amnesiac
    end

    function ABILITY.GetEnemyTarget(amnesiac)
        return AMNESIAC:GetNearestPlayer(amnesiac)
    end

    function ABILITY.GetBonusTarget(amnesiac, blocklist)
        return AMNESIAC:GetRandomPlayer(blocklist)
    end

    function ABILITY.GetDeadTarget(amnesiac)
        return lastBodyOwner[amnesiac]
    end
end

AMNESIAC:RegisterAbility(ABILITY)
