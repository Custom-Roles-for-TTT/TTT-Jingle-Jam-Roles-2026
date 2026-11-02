local hook = hook
local table = table
local util = util

local HookRun = hook.Run
local TableHasValue = table.HasValue
local TableRandom = table.Random
local UtilCanRoleSpawn = util.CanRoleSpawn

local ABILITY = {}

ABILITY.Id = "shopitem"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["ally"] .. " " .. (params["allyPlural"] and "get" or "gets") .. " a random shop item"
end

ABILITY.Cooldown = function(weight)
    return 5 / weight
end

if SERVER then
    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(ally) or not ally:IsActive() then return false end

        local shopItems = {}
        local hasItems = false
        for role = ROLE_NONE, ROLE_MAX do
            if SHOP_ROLES[role] and UtilCanRoleSpawn(role) then
                for _, w in ipairs(weapons.GetList()) do
                    if w and not w.AutoSpawnable and w.CanBuy and #w.CanBuy > 0 and TableHasValue(w.CanBuy, role) and not ally:HasWeapon(w.ClassName) then
                        shopItems[w.ClassName] = w
                        hasItems = true
                    end
                end
            end
        end
        if not hasItems then return false end

        local item = TableRandom(shopItems)
        ally:Give(item.ClassName)
        HookRun("TTTOrderedEquipment", ally, item.ClassName, false)
        return true
    end
end

AMNESIAC:RegisterAbility(ABILITY)
