local hook = hook
local math = math
local player = player
local string = string
local table = table
local timer = timer

local AddHook = hook.Add
local MathFloor = math.floor
local MathMax = math.max
local MathRand = math.Rand
local MathRandom = math.random
local PlayerIterator = player.Iterator
local StringRep = string.rep
local StringSub = string.sub
local StringUpper = string.upper
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRandom = table.Random
local TimerCreate = timer.Create

local ROLE = {}

ROLE.nameraw = "amnesiac"
ROLE.name = "Amnesiac"
ROLE.nameplural = "Amnesiacs"
ROLE.nameext = "an Amnesiac"
ROLE.nameshort = "amn"

ROLE.desc = [[You are {role}! You do not
know what your ability is to begin with, but
you learn it slowly over time.]]
ROLE.shortdesc = "Has an unknown randomly generated ability that is learned over time."

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars = {
    {
        cvar = "ttt_amnesiac_ability_reveal_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_amnesiac_ability_success_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_amnesiac_show_status_effects",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["amnesiac_config_ability_alignment_x"] = "Ability position, X-axis alignment",
        ["amnesiac_config_ability_offset_y"] = "Ability position, Y-axis offset",
        ["amnesiac_config_ability_offset_reset"] = "Reset ability position to default",
    }
}

ROLE.onroleassigned = function(ply)
    if SERVER and not ply:GetNWBool("TTTAmnesiacNonAmnesiacAbility") then
        AMNESIAC:AssignAbility(ply)
    end
end

RegisterRole(ROLE)

AMNESIAC_TYPE_TRIGGER = 0
AMNESIAC_TYPE_EFFECT = 1

AMNESIAC_TIMING_INSTANT = 0
AMNESIAC_TIMING_ONGOING = 1

AMNESIAC_ABILITY_ALIGN_LEFT = 0
AMNESIAC_ABILITY_ALIGN_CENTER = 1
AMNESIAC_ABILITY_ALIGN_RIGHT = 2

------------------
-- ROLE CONVARS --
------------------

local amnesiac_ability_reveal_time = CreateConVar("ttt_amnesiac_ability_reveal_time", "300", FCVAR_REPLICATED, "How long it takes for the Amnesiac's ability to be fully revealed to them", 1, 600)
local amnesiac_ability_success_sound = CreateConVar("ttt_amnesiac_ability_success_sound", "1", FCVAR_REPLICATED, "Whether a sound plays for the player whose Amnesiac ability successfully runs", 0, 1)
local amnesiac_show_status_effects = CreateConVar("ttt_amnesiac_show_status_effects", "1", FCVAR_REPLICATED, "Whether particles and sounds play for buffs and debuffs from Amnesiac abilities", 0, 1)

--------------------------
-- ABILITY REGISTRATION --
--------------------------

AMNESIAC = {
    Triggers = {},
    InstantEffects = {},
    OngoingEffects = {}
}

function AMNESIAC:RegisterAbility(ability)
    ability.Id = ability.Id or ability.id or ability.ID

    if AMNESIAC.Triggers[ability.Id] or AMNESIAC.InstantEffects[ability.Id] or AMNESIAC.OngoingEffects[ability.Id] then
        ErrorNoHalt("[AMNESIAC] Amnesiac ability already exists with ID '" .. ability.Id .. "'\n")
        return
    end

    local enabled = CreateConVar("ttt_amnesiac_" .. ability.Id .. "_enabled", 1, FCVAR_REPLICATED)
    ability.Enabled = function()
        return enabled:GetBool()
    end
    TableInsert(ROLE_CONVARS[ROLE_AMNESIAC], {
        cvar = "ttt_amnesiac_" .. ability.Id .. "_enabled",
        type = ROLE_CONVAR_TYPE_BOOL
    })

    if ability.Type == AMNESIAC_TYPE_TRIGGER then
        AMNESIAC.Triggers[ability.Id] = ability
    elseif ability.Type == AMNESIAC_TYPE_EFFECT then
        if ability.Timing == AMNESIAC_TIMING_INSTANT then
            AMNESIAC.InstantEffects[ability.Id] = ability
        elseif ability.Timing == AMNESIAC_TIMING_ONGOING then
            AMNESIAC.OngoingEffects[ability.Id] = ability
        end
    end
end

-------------------------
-- STATUS REGISTRATION --
-------------------------

AMNESIAC.Statuses = {}

function AMNESIAC:RegisterStatus(statusId, material, isBuff)
    local status = {
        Id = statusId,
        NWKey = "TTTAmnesiacStatus_" .. statusId,
        MaterialPath = material,
        IsBuff = isBuff
    }
    if CLIENT then
        status.Material = Material(material)
    end

    AMNESIAC.Statuses[statusId] = status
end

------------------
-- FILE LOADING --
------------------

local triggerFiles, _ = file.Find("amnesiac_abilities/triggers/*.lua", "LUA")
for _, fil in ipairs(triggerFiles) do
    if SERVER then AddCSLuaFile("amnesiac_abilities/triggers/" .. fil) end
    include("amnesiac_abilities/triggers/" .. fil)
end

local effectFiles, _ = file.Find("amnesiac_abilities/effects/*.lua", "LUA")
for _, fil in ipairs(effectFiles) do
    if SERVER then AddCSLuaFile("amnesiac_abilities/effects/" .. fil) end
    include("amnesiac_abilities/effects/" .. fil)
end

----------------------
-- ABILITY HELPERS --
----------------------

function AMNESIAC:GetAbility(ply)
    local triggerId = ply:GetNWString("TTTAmnesiacTrigger")
    local effectId = ply:GetNWString("TTTAmnesiacEffect")
    if #triggerId == 0 or #effectId == 0 then return end

    local trigger = AMNESIAC.Triggers[triggerId]
    if not trigger then return end

    local effect
    if trigger.Timing == AMNESIAC_TIMING_INSTANT then
        effect = AMNESIAC.InstantEffects[effectId]
    elseif trigger.Timing == AMNESIAC_TIMING_ONGOING then
        effect = AMNESIAC.OngoingEffects[effectId]
    end
    if not effect then return end

    return trigger, effect
end

function AMNESIAC:GetAbilityText(ply, punctuation)
    local trigger, effect = AMNESIAC:GetAbility(ply)
    if not trigger then return end

    local abilityText = trigger.Description(trigger.DescriptionParams, trigger.Weight)
    if punctuation then abilityText = abilityText .. "," end
    abilityText = abilityText .. " " .. effect.Description(trigger.DescriptionParams, trigger.Weight)
    if trigger.Timing == AMNESIAC_TIMING_INSTANT then
        if punctuation then
            abilityText = abilityText .. " (" .. MathFloor(effect.Cooldown(trigger.Weight)) .. " second cooldown)"
        else
            abilityText = abilityText .. "   " .. MathFloor(effect.Cooldown(trigger.Weight)) .. " second cooldown"
        end
    end
    return abilityText
end

if SERVER then
    ------------------------
    -- ABILITY ASSIGNMENT --
    ------------------------

    function AMNESIAC:AssignAbility(ply)
        local triggerIds = {}
        for id, ability in pairs(AMNESIAC.Triggers) do
            if not ability.Enabled() then continue end
            if ability.Condition and not ability.Condition() then continue end
            TableInsert(triggerIds, id)
        end
        if #triggerIds == 0 then return false end

        local triggerId = triggerIds[MathRandom(#triggerIds)]
        local trigger = AMNESIAC.Triggers[triggerId]

        local effects
        if trigger.Timing == AMNESIAC_TIMING_INSTANT then
            effects = AMNESIAC.InstantEffects
        elseif trigger.Timing == AMNESIAC_TIMING_ONGOING then
            effects = AMNESIAC.OngoingEffects
        end

        local effectIds = {}
        for id, ability in pairs(effects) do
            if not ability.Enabled() then continue end
            if ability.Condition and not ability.Condition() then continue end
            if ability.Incompatible and TableHasValue(ability.Incompatible, triggerId) then continue end
            TableInsert(effectIds, id)
        end
        if #effectIds == 0 then return false end

        ply:SetNWString("TTTAmnesiacTrigger", triggerId)
        ply:SetNWString("TTTAmnesiacEffect", effectIds[MathRandom(#effectIds)])
        trigger.Begin(ply)
        return true
    end

    ------------
    -- SOUNDS --
    ------------

    util.AddNetworkString("TTT_AmnesiacTriggerSound")

    local function PlayTriggerSound(amnesiac)
        if not amnesiac_ability_success_sound:GetBool() then return end

        net.Start("TTT_AmnesiacTriggerSound")
        net.Send(amnesiac)
    end

    local statuses = {}

    function AMNESIAC:StartStatus(ply, statusId)
        local status = AMNESIAC.Statuses[statusId]
        if not status or not IsPlayer(ply) then return end

        statuses[statusId] = statuses[statusId] or {}
        statuses[statusId][ply] = true
        ply:SetNWBool(status.NWKey, true)

        if amnesiac_show_status_effects:GetBool() then
            ply:EmitSound(status.IsBuff and "amnesiac/buff.wav" or "amnesiac/debuff.wav")
        end
    end

    function AMNESIAC:EndStatus(ply, statusId)
        local status = AMNESIAC.Statuses[statusId]
        if not status or not statuses[statusId] or not statuses[statusId][ply] then return end
        statuses[statusId][ply] = nil
        if not IsPlayer(ply) then return end

        ply:SetNWBool(status.NWKey, false)

        if ply:IsActive() and amnesiac_show_status_effects:GetBool() then
            ply:EmitSound("invulnerableend.wav", 75, 100, 0.25)
        end
    end

    ---------------------
    -- ABILITY TRIGGER --
    ---------------------

    local lastTrigger = {}

    function AMNESIAC:TriggerInstantAbility(amnesiac)
        if amnesiac:IsRoleAbilityDisabled() then return end

        local triggerId = amnesiac:GetNWString("TTTAmnesiacTrigger")
        local effectId = amnesiac:GetNWString("TTTAmnesiacEffect")
        if #triggerId == 0 or #effectId == 0 then return end

        local trigger = AMNESIAC.Triggers[triggerId]
        local effect = AMNESIAC.InstantEffects[effectId]

        if lastTrigger[amnesiac] and CurTime() < lastTrigger[amnesiac] + effect.Cooldown(trigger.Weight) then return end

        local ally = trigger.GetAllyTarget(amnesiac)
        local enemy = trigger.GetEnemyTarget(amnesiac)
        local bonus = trigger.GetBonusTarget(amnesiac, {ally, enemy})
        local dead = trigger.GetDeadTarget(amnesiac)

        lastTrigger[amnesiac] = CurTime()
        if effect.InstantEffect(amnesiac, ally, enemy, bonus, dead, trigger.Weight) then
            PlayTriggerSound(amnesiac)
        else
            lastTrigger[amnesiac] = nil
        end
    end

    local ongoingRequested = {}
    local ongoingRunning = {}

    local function UpdateOngoingAbility(amnesiac)
        local triggerId = amnesiac:GetNWString("TTTAmnesiacTrigger")
        local effectId = amnesiac:GetNWString("TTTAmnesiacEffect")
        if #triggerId == 0 or #effectId == 0 then return end

        local trigger = AMNESIAC.Triggers[triggerId]
        local effect = AMNESIAC.OngoingEffects[effectId]
        local canRun = ongoingRequested[amnesiac] and not amnesiac:IsRoleAbilityDisabled()

        if ongoingRunning[amnesiac] and not canRun then
            ongoingRunning[amnesiac] = nil
            effect.StopEffect(amnesiac)
        elseif canRun and not ongoingRunning[amnesiac] then
            local ally = trigger.GetAllyTarget(amnesiac)
            local enemy = trigger.GetEnemyTarget(amnesiac)
            local bonus = trigger.GetBonusTarget(amnesiac, {ally, enemy})
            local dead = trigger.GetDeadTarget(amnesiac)

            if effect.StartEffect(amnesiac, ally, enemy, bonus, dead, trigger.Weight) then
                ongoingRunning[amnesiac] = true
                PlayTriggerSound(amnesiac)
            end
        end
    end

    function AMNESIAC:StartOngoingAbility(amnesiac)
        ongoingRequested[amnesiac] = true
        UpdateOngoingAbility(amnesiac)
    end

    function AMNESIAC:StopOngoingAbility(amnesiac)
        ongoingRequested[amnesiac] = nil
        UpdateOngoingAbility(amnesiac)
    end

    TimerCreate("Amnesiac_UpdateOngoingAbilities", 0.1, 0, function()
        for amnesiac, _ in pairs(ongoingRequested) do
            if IsPlayer(amnesiac) then
                UpdateOngoingAbility(amnesiac)
            else
                ongoingRequested[amnesiac] = nil
                ongoingRunning[amnesiac] = nil
            end
        end
    end)

    --------------------
    -- ABILITY REVEAL --
    --------------------

    AddHook("TTTEndRound", "Amnesiac_TTTEndRound", function(result)
        for _, p in PlayerIterator() do
            if not p:IsAmnesiac() then continue end

            local abilityText = AMNESIAC:GetAbilityText(p, true)
            if not abilityText then continue end

            p:QueueMessage(MSG_PRINTTALK, "Your ability was: " .. abilityText)
        end
    end)

    --------------------
    -- TARGET HELPERS --
    --------------------

    function AMNESIAC:GetNearestPlayer(amnesiac, blocklist)
        local pos = amnesiac:GetPos()
        local nearestPlayer
        local nearestDistance = math.huge
        for _, p in PlayerIterator() do
            if not p:IsActive() or p == amnesiac or TableHasValue(blocklist or {}, p) then continue end

            local distance = pos:DistToSqr(p:GetPos())
            if distance < nearestDistance then
                nearestPlayer = p
                nearestDistance = distance
            end
        end
        return nearestPlayer
    end

    function AMNESIAC:GetRandomPlayer(blocklist)
        local options = {}
        for _, p in PlayerIterator() do
            if p:IsActive() and not TableHasValue(blocklist or {}, p) then
                TableInsert(options, p)
            end
        end
        if #options > 0 then
            return options[MathRandom(#options)]
        end
    end

    function AMNESIAC:GetRandomAlly(amnesiac, blocklist)
        local options = {}
        local teamOptions = {}
        for _, p in PlayerIterator() do
            if p:IsActive() and not TableHasValue(blocklist or {}, p) then
                TableInsert(options, p)
                if p:IsSameTeam(amnesiac) then
                    TableInsert(teamOptions, p)
                end
            end
        end
        if #teamOptions > 0 then
            return teamOptions[MathRandom(#teamOptions)]
        elseif #options > 0 then
            return options[MathRandom(#options)]
        end
    end

    function AMNESIAC:GetRandomDeadAlly(amnesiac, blocklist)
        local options = {}
        local teamOptions = {}
        for _, p in PlayerIterator() do
            if not p:Alive() and p:GetRole() ~= ROLE_NONE and not TableHasValue(blocklist or {}, p) then
                TableInsert(options, p)
                if p:IsSameTeam(amnesiac) then
                    TableInsert(teamOptions, p)
                end
            end
        end
        if #teamOptions > 0 then
            return teamOptions[MathRandom(#teamOptions)]
        elseif #options > 0 then
            return options[MathRandom(#options)]
        end
    end

    -------------
    -- CLEANUP --
    -------------

    function AMNESIAC:Cleanup(ply)
        local triggerId = ply:GetNWString("TTTAmnesiacTrigger")
        if #triggerId == 0 then return end

        local trigger = AMNESIAC.Triggers[triggerId]
        if trigger.End then trigger.End(ply) end
        lastTrigger[ply] = nil

        local effectId = ply:GetNWString("TTTAmnesiacEffect")
        if #effectId == 0 then return end

        if trigger.Timing == AMNESIAC_TIMING_INSTANT then
            local effect = AMNESIAC.InstantEffects[effectId]
            if effect.End then effect.End(ply) end
        elseif trigger.Timing == AMNESIAC_TIMING_ONGOING then
            local effect = AMNESIAC.OngoingEffects[effectId]
            effect.StopEffect(ply)
            if effect.End then effect.End(ply) end
            ongoingRequested[ply] = nil
            ongoingRunning[ply] = nil
        end

        ply:SetNWString("TTTAmnesiacTrigger", "")
        ply:SetNWString("TTTAmnesiacEffect", "")
    end

    AddHook("TTTPrepareRound", "Amnesiac_TTTPrepareRound", function()
        for _, p in PlayerIterator() do
            AMNESIAC:Cleanup(p)

            for _, status in pairs(AMNESIAC.Statuses) do
                p:SetNWBool(status.NWKey, false)
            end
        end
        statuses = {}
    end)

    AddHook("TTTPlayerRoleChanged", "Amnesiac_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole ~= ROLE_AMNESIAC or ply:GetNWBool("TTTAmnesiacNonAmnesiacAbility") then return end
        AMNESIAC:Cleanup(ply)
    end)

    AddHook("PlayerDisconnected", "Amnesiac_PlayerDisconnected", function(ply)
        AMNESIAC:Cleanup(ply)
    end)
elseif CLIENT then
    local client

    ------------
    -- SOUNDS --
    ------------

    net.Receive("TTT_AmnesiacTriggerSound", function()
        surface.PlaySound("amnesiac/trigger.wav")
    end)

    --------------------
    -- STATUS EFFECTS --
    --------------------

    AddHook("HUDPaintBackground", "Amnesiac_Status_HUDPaintBackground", function()
        if not IsPlayer(client) then client = LocalPlayer() end

        local isActive = client:IsActive()
        for _, status in pairs(AMNESIAC.Statuses) do
            CRHUD:PaintStatusEffect(isActive and client:GetNWBool(status.NWKey), status.IsBuff and ROLE_COLORS[ROLE_INNOCENT] or ROLE_COLORS[ROLE_TRAITOR], status.Material, "Amnesiac_" .. status.Id)
        end
    end)

    AddHook("Think", "Amnesiac_Status_Think", function()
        if not IsPlayer(client) then client = LocalPlayer() end

        local now = CurTime()
        local clientPos = client:GetPos()
        for _, p in PlayerIterator() do
            local hasStatus = false
            if amnesiac_show_status_effects:GetBool() and p ~= client and p:IsActive() then
                local pos = p:GetPos()
                local inRange = clientPos:DistToSqr(pos) <= 9000000
                for _, status in pairs(AMNESIAC.Statuses) do
                    if not p:GetNWBool(status.NWKey) then continue end
                    hasStatus = true
                    if not inRange then continue end

                    if not p.AmnesiacStatusEmitter then
                        p.AmnesiacStatusEmitter = ParticleEmitter(pos)
                        p.AmnesiacStatusNextPart = {}
                    end
                    if now < (p.AmnesiacStatusNextPart[status.Id] or 0) then continue end
                    p.AmnesiacStatusNextPart[status.Id] = now + MathRand(0.02, 0.04)

                    p.AmnesiacStatusEmitter:SetPos(pos)
                    local vec = Vector(MathRand(-8, 8), MathRand(-8, 8), MathRand(-25, 25))
                    local particle = p.AmnesiacStatusEmitter:Add(status.MaterialPath, p:LocalToWorld(vec + Vector(0, 0, 35)))
                    particle:SetVelocity(vec:GetNormalized() * 50)
                    particle:SetDieTime(MathRand(0.2, 0.5))
                    particle:SetStartAlpha(MathRandom(150, 220))
                    particle:SetEndAlpha(0)
                    local size = MathRandom(2, 5)
                    particle:SetStartSize(size)
                    particle:SetEndSize(size + 1)
                    particle:SetRoll(0)
                    particle:SetRollDelta(0)
                    local color = status.IsBuff and ROLE_COLORS[ROLE_INNOCENT] or ROLE_COLORS[ROLE_TRAITOR]
                    particle:SetColor(color.r, color.g, color.b)
                end
            end

            if not hasStatus and p.AmnesiacStatusEmitter then
                p.AmnesiacStatusEmitter:Finish()
                p.AmnesiacStatusEmitter = nil
                p.AmnesiacStatusNextPart = nil
            end
        end
    end)

    AddHook("EntityRemoved", "Amnesiac_Status_EntityRemoved", function(ent)
        if not ent.AmnesiacStatusEmitter then return end
        ent.AmnesiacStatusEmitter:Finish()
        ent.AmnesiacStatusEmitter = nil
    end)

    local characterMargin = 2
    local characterWidth = 18
    local characterHeight = 22
    local spaceWidth = 8

    -------------
    -- CONVARS --
    -------------

    local ability_alignment_x = CreateClientConVar("ttt_amnesiac_ability_alignment_x", "1", true, false, "The text alignment to render the Amnesiac's ability with")
    local ability_offset_y = CreateClientConVar("ttt_amnesiac_ability_offset_y", "10", true, false, "The screen offset from the top of the screen to render the Amnesiac's ability at (up-and-down)")

    concommand.Add("ttt_amnesiac_ability_offset_reset", function()
        ability_alignment_x:SetInt(ability_alignment_x:GetDefault())
        ability_offset_y:SetInt(ability_offset_y:GetDefault())
    end)

    AddHook("TTTSettingsRolesTabSections", "Amnesiac_TTTSettingsRolesTabSections", function(role, parentForm)
        if role ~= ROLE_AMNESIAC then return end

        local combobox = parentForm:ComboBox(LANG.GetTranslation("amnesiac_config_ability_alignment_x"), "ttt_amnesiac_ability_alignment_x")
        combobox:AddChoice("Left", 0)
        combobox:AddChoice("Center", 1)
        combobox:AddChoice("Right", 2)
        parentForm:NumSlider(LANG.GetTranslation("amnesiac_config_ability_offset_y"), "ttt_amnesiac_ability_offset_y", 0, ScrH() - characterHeight, 0)
        parentForm:Button(LANG.GetTranslation("amnesiac_config_ability_offset_reset"), "ttt_amnesiac_ability_offset_reset")
        return true
    end)

    ---------------------
    -- ABILITY OVERLAY --
    ---------------------

    surface.CreateFont("AmnesiacAbilityReveal", {
        font = "Roboto",
        size = 18,
        weight = 800
    })

    local function GetTextWidth(text)
        local characterCount = 0
        local spaceCount = 0
        for i = 1, #text do
            if StringSub(text, i, i) == " " then
                spaceCount = spaceCount + 1
            else
                characterCount = characterCount + 1
            end
        end
        return (characterCount * characterWidth) + (spaceCount * spaceWidth) + ((characterCount + spaceCount - 1) * characterMargin), characterCount
    end

    local cachedAbilityKey
    local cachedScreenWidth
    local cachedLines
    local cachedCharacterCount
    local abilityBitMask
    local nextLetterReveal

    AddHook("HUDPaint", "Amnesiac_HUDPaint", function()
        if not IsPlayer(client) then client = LocalPlayer() end

        if not client:IsActive() or (not client:IsAmnesiac() and not client:GetNWBool("TTTAmnesiacNonAmnesiacAbility")) then return end

        local triggerId = client:GetNWString("TTTAmnesiacTrigger")
        local effectId = client:GetNWString("TTTAmnesiacEffect")
        if #triggerId == 0 or #effectId == 0 then return end

        local abilityKey = triggerId .. "_" .. effectId
        if abilityKey ~= cachedAbilityKey or ScrW() ~= cachedScreenWidth then
            local abilityText = AMNESIAC:GetAbilityText(client, false)
            if not abilityText then return end

            if cachedAbilityKey and abilityKey ~= cachedAbilityKey then
                abilityBitMask = nil
                nextLetterReveal = nil
            end

            local width, characterCount = GetTextWidth(abilityText)
            cachedCharacterCount = characterCount
            if width + (2 * characterMargin) <= ScrW() then
                cachedLines = {StringUpper(abilityText)}
            else
                local splitIndex
                local splitWidth = math.huge
                for i = 1, #abilityText do
                    if StringSub(abilityText, i, i) ~= " " then continue end

                    local lineWidth = MathMax((GetTextWidth(StringSub(abilityText, 1, i - 1))), (GetTextWidth(StringSub(abilityText, i + 1))))
                    if lineWidth < splitWidth then
                        splitIndex = i
                        splitWidth = lineWidth
                    else
                        break
                    end
                end

                if splitIndex then
                    cachedLines = {StringUpper(StringSub(abilityText, 1, splitIndex - 1)), StringUpper(StringSub(abilityText, splitIndex + 1))}
                else
                    cachedLines = {StringUpper(abilityText)}
                end
            end
            cachedAbilityKey = abilityKey
            cachedScreenWidth = ScrW()
        end

        if not abilityBitMask or #abilityBitMask == 0 then
            abilityBitMask = StringRep("0", cachedCharacterCount)
        end

        if nextLetterReveal then
            if CurTime() >= nextLetterReveal then
                local unrevealedCharacters = {}
                for i = 1, #abilityBitMask do
                    local bit = StringSub(abilityBitMask, i, i)
                    if bit == "0" then
                        TableInsert(unrevealedCharacters, i)
                    end
                end

                if #unrevealedCharacters > 0 then
                    local index = TableRandom(unrevealedCharacters)
                    abilityBitMask = StringSub(abilityBitMask, 1, index - 1) .. "1" .. StringSub(abilityBitMask, index + 1)
                    nextLetterReveal = CurTime() + (amnesiac_ability_reveal_time:GetInt() / #abilityBitMask)
                else
                    nextLetterReveal = math.huge
                end
            end
        else
            nextLetterReveal = CurTime() + (amnesiac_ability_reveal_time:GetInt() / #abilityBitMask)
        end

        local alignment = ability_alignment_x:GetInt()
        local y = ability_offset_y:GetInt()

        local characterBit = 0
        for _, line in ipairs(cachedLines) do
            local x
            local width = GetTextWidth(line)
            if alignment == AMNESIAC_ABILITY_ALIGN_LEFT then
                x = characterMargin
            elseif alignment == AMNESIAC_ABILITY_ALIGN_CENTER then
                x = (ScrW() - width) / 2
            else
                x = ScrW() - width - characterMargin
            end

            for i = 1, #line do
                local char = StringSub(line, i, i)
                if char == " " then
                    x = x + spaceWidth + characterMargin
                else
                    surface.SetDrawColor(0, 0, 0, 192)
                    surface.DrawRect(x, y, characterWidth, characterHeight)
                    characterBit = characterBit + 1
                    if StringSub(abilityBitMask, characterBit, characterBit) == "0" then
                        draw.SimpleText("?", "AmnesiacAbilityReveal", x + (characterWidth / 2), y + (characterHeight / 2), COLOR_GRAY, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText(char, "AmnesiacAbilityReveal", x + (characterWidth / 2), y + (characterHeight / 2), COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    x = x + characterWidth + characterMargin
                end
            end

            y = y + characterHeight + characterMargin
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Amnesiac_TTTPrepareRound", function()
        abilityBitMask = nil
        nextLetterReveal = nil
    end)

    AddHook("TTTPlayerRoleChanged", "Amnesiac_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if not IsPlayer(client) then client = LocalPlayer() end

        if ply ~= client then return end
        if oldRole ~= ROLE_AMNESIAC then return end
        if newRole == ROLE_AMNESIAC then return end
        if ply:GetNWBool("TTTAmnesiacNonAmnesiacAbility") then return end
        abilityBitMask = nil
        nextLetterReveal = nil
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Amnesiac_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_AMNESIAC then return end

        local T = LANG.GetTranslation
        local roleColor = ROLE_COLORS[ROLE_INNOCENT]

        local html = "The " .. ROLE_STRINGS[ROLE_AMNESIAC] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. T("innocent") .. " team</span> who has an unknown randomly generated ability."

        html = html .. "<span style='display: block; margin-top: 10px;'>Their ability is revealed to them letter by letter over <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. amnesiac_ability_reveal_time:GetInt() .. " seconds</span>."

        return html
    end)
end