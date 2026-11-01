local math = math
local timer = timer

local MathFloor = math.floor
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local ABILITY = {}

ABILITY.Id = "disableshop"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " cannot use the shop for " .. MathFloor(60 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 90 * weight
end

if SERVER then
    local disabled = {}

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end

        local amnesiacDisabled = disabled[amnesiac] and disabled[amnesiac][enemy]
        if not amnesiacDisabled then
            if not enemy:CanUseShop() then return false end
            if enemy:IsShopPurchaseDisabled() then return false end
        end

        disabled[amnesiac] = disabled[amnesiac] or {}
        local timerId = "Amnesiac_DisableShop_" .. amnesiac:SteamID64() .. "_" .. enemy:SteamID64()
        disabled[amnesiac][enemy] = timerId

        enemy:DisableShopPurchases()
        TimerCreate(timerId, MathFloor(60 * weight), 1, function()
            disabled[amnesiac][enemy] = nil

            TimerRemove(timerId)
            if IsPlayer(enemy) then
                enemy:EnableShopPurchases()
            end
        end)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, _ in pairs(disabled[amnesiac] or {}) do
            local timerId = disabled[amnesiac] and disabled[amnesiac][p]
            if not timerId then continue end
            disabled[amnesiac][p] = nil

            TimerRemove(timerId)
            if IsPlayer(p) then
                p:EnableShopPurchases()
            end
        end
        disabled[amnesiac] = nil
    end
end

AMNESIAC:RegisterAbility(ABILITY)
