local _, Cell = ...
local L = Cell.L
---@type CellFuncs
local F = Cell.funcs
---@class CellIndicatorFuncs
local I = Cell.iFuncs

-------------------------------------------------
-- CreateAoEHealing -- not support for npc
-------------------------------------------------
-- Retail has CombatLogGetCurrentEventInfo; Wrath passes the values directly
local function GetCLEUInfo(...)
    if CombatLogGetCurrentEventInfo then
        return CombatLogGetCurrentEventInfo()
    end
    return ...
end

local function Display(b)
    b.indicators.aoeHealing:Display()
end

local playerSummoned = {}
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then return end

    -- Ascension 3.3.5: raw CLEU varargs, no hideCaster, shim CombatLogGetCurrentEventInfo returns nothing
    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = ...
    -- if subevent == "SPELL_SUMMON" then print(subevent, sourceName, sourceGUID, destName, destGUID, spellName) end
    if subevent == "SPELL_SUMMON" then
        -- print(sourceGUID == Cell.vars.playerGUID, destGUID, spellName, spellId)
        if sourceGUID == Cell.vars.playerGUID and destGUID and I.IsAoEHealing(spellName, spellId) then
            local duration = I.GetSummonDuration(spellName)
            if duration then
                playerSummoned[destGUID] = GetTime() + duration -- expirationTime
                C_Timer.After(duration, function()
                    playerSummoned[destGUID] = nil
                end)
            end
        end
        -- texplore(playerSummoned)
    end
    -- if (subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL") then print(subevent, sourceName, sourceGUID, destName, spellId, spellName) end
    if subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        if destGUID then
            -- print(sourceGUID == Cell.vars.playerGUID, sourceGUID, playerSummoned[sourceGUID])
            if (sourceGUID == Cell.vars.playerGUID and I.IsAoEHealing(spellName, spellId)) or playerSummoned[sourceGUID] then
                F.HandleUnitButton("guid", destGUID, Display)
            end
        end
    end
end)

function I.CreateAoEHealing(parent)
    local aoeHealing = CreateFrame("Frame", parent:GetName().."AoEHealing", parent.widgets.indicatorFrame)
    parent.indicators.aoeHealing = aoeHealing
    aoeHealing:SetPoint("TOPLEFT", parent.widgets.healthBar)
    aoeHealing:SetPoint("TOPRIGHT", parent.widgets.healthBar)
    aoeHealing:Hide()

    aoeHealing.tex = aoeHealing:CreateTexture(nil, "ARTWORK")
    aoeHealing.tex:SetAllPoints(aoeHealing)
    aoeHealing.tex:SetTexture(Cell.vars.whiteTexture)

    -- Ascension 3.3.5: Alpha animations wipe the texture's gradient state on every tick,
    -- so the fade is done manually with frame:SetAlpha (render-level, doesn't touch the texture)
    local FADE_IN, FADE_OUT = 0.5, 0.5

    local function OnFade(self, dt)
        self._t = self._t + dt
        if self._t < FADE_IN then
            self:SetAlpha(self._t / FADE_IN)
        elseif self._t < FADE_IN + FADE_OUT then
            self:SetAlpha(1 - (self._t - FADE_IN) / FADE_OUT)
        else
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetAlpha(1)
        end
    end

    function aoeHealing:SetColor(r, g, b)
        aoeHealing.r, aoeHealing.g, aoeHealing.b = r, g, b
        Cell.Polyfill.SetGradient(aoeHealing.tex, "VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 0.77))
    end

    function aoeHealing:Display()
        if aoeHealing.r then -- reapply, Hide/Show state changes may also reset it
            Cell.Polyfill.SetGradient(aoeHealing.tex, "VERTICAL", CreateColor(aoeHealing.r, aoeHealing.g, aoeHealing.b, 0), CreateColor(aoeHealing.r, aoeHealing.g, aoeHealing.b, 0.77))
        end
        aoeHealing._t = 0
        aoeHealing:SetAlpha(0)
        aoeHealing:Show()
        aoeHealing:SetScript("OnUpdate", OnFade)
    end
end

function I.EnableAoEHealing(enabled)
    if enabled then
        eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
I.BuiltInIndicatorCreationFunctions["aoeHealing"] = I.CreateAoEHealing
