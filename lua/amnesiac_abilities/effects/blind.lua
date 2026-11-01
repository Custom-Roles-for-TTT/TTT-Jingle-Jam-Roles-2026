local hook = hook
local math = math

local AddHook = hook.Add
local MathFloor = math.floor
local MathMax = math.max

local ABILITY = {}

ABILITY.Id = "blind"
ABILITY.Type = AMNESIAC_TYPE_EFFECT
ABILITY.Timing = AMNESIAC_TIMING_INSTANT
ABILITY.Description = function(params, weight)
    return params["enemy"] .. " " .. (params["enemyPlural"] and "are" or "is") .. " blinded for " .. MathFloor(15 * weight) .. " seconds"
end

ABILITY.Cooldown = function(weight)
    return 30 * weight
end

if CLIENT then
    local client

    local function IsBlinded()
        if not IsPlayer(client) then client = LocalPlayer() end
        return client:IsActive() and CurTime() < client:GetNWFloat("TTTAmnesiacBlindEnd")
    end

    local blur = Material("pp/blurscreen")

    AddHook("HUDPaintBackground", "Amnesiac_Blind_HUDPaintBackground", function()
        if not IsBlinded() then return end

        surface.SetMaterial(blur)
        surface.SetDrawColor(255, 255, 255, 255)
        for i = 1, 3 do
            blur:SetFloat("$blur", (i / 3) * 50)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end

        surface.SetDrawColor(0, 0, 0, 252)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end)

    AddHook("HUDShouldDraw", "Amnesiac_Blind_HUDShouldDraw", function(name)
        if name ~= "TTTTargetID" then return end
        if IsBlinded() then return false end
    end)
end

if SERVER then
    local blinded = {}

    local function UpdateBlind(ply)
        local blindEnd = 0
        for _, expiry in pairs(blinded[ply] or {}) do
            blindEnd = MathMax(blindEnd, expiry)
        end
        if IsPlayer(ply) then
            ply:SetNWFloat("TTTAmnesiacBlindEnd", blindEnd)
        end
    end

    function ABILITY.InstantEffect(amnesiac, ally, enemy, bonus, dead, weight)
        if not IsPlayer(enemy) or not enemy:IsActive() then return false end
        blinded[enemy] = blinded[enemy] or {}
        blinded[enemy][amnesiac] = CurTime() + MathFloor(15 * weight)
        UpdateBlind(enemy)
        return true
    end

    function ABILITY.End(amnesiac)
        for p, sources in pairs(blinded) do
            if not sources[amnesiac] then continue end
            sources[amnesiac] = nil
            UpdateBlind(p)
            if not next(sources) then
                blinded[p] = nil
            end
        end
    end
end

AMNESIAC:RegisterAbility(ABILITY)
