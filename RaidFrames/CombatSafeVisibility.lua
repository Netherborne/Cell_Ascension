local _, Cell = ...
local F = Cell.funcs

--[[
    CombatSafeVisibility.lua
    ========================
    Manages the visibility of CellSoloFrame, CellPartyFrame, and CellRaidFrame
    during combat lockdown without triggering taint or "Action blocked" errors.

    Architecture:
    - A single SecureHandlerStateTemplate frame (CellGroupStateDriver) drives
      group-state visibility using RegisterStateDriver + macro conditionals.
    - RegisterStateDriver runs entirely in WoW's protected (secure) environment,
      so it fires immediately even during combat — no deferral needed.
    - The conditional string is pre-baked (out of combat, via F.UpdateLayout →
      F.RebuildGroupStateDriver) to encode isHidden "hide" layout settings as
      the "hidden" token, preventing hidden-layout frames from flashing mid-combat.
    - Lua code (sizing, anchoring, sorting) remains deferred via PLAYER_REGEN_ENABLED
      as before — only visibility is handled here.

    States produced by the driver:
      "solo"   → show soloFrame,  hide party/raidFrame
      "party"  → show partyFrame, hide solo/raidFrame
      "raid"   → show raidFrame,  hide solo/partyFrame
      "hidden" → hide ALL frames  (layout auto-switch set to "hide" for that type)
]]

-------------------------------------------------
-- Central group-state driver frame
-------------------------------------------------
local stateDriver = CreateFrame("Frame", "CellGroupStateDriver", UIParent,
    "SecureHandlerStateTemplate")

-- Store frame refs so the secure handler can reach them without Lua upvalues
SecureHandlerSetFrameRef(stateDriver, "soloFrame",  Cell.frames.soloFrame)
SecureHandlerSetFrameRef(stateDriver, "partyFrame", Cell.frames.partyFrame)
SecureHandlerSetFrameRef(stateDriver, "raidFrame",  Cell.frames.raidFrame)

--[[
    _onstate-groupstate runs in the secure (restricted) environment.
    newstate is one of: "solo", "party", "raid", "hidden"
    All Show()/Hide() calls here are on frames that are children of
    CellMainFrame (SecureFrameTemplate), so they are allowed in combat.
]]
stateDriver:SetAttribute("_onstate-groupstate", [[
    local soloFrame  = self:GetFrameRef("soloFrame")
    local partyFrame = self:GetFrameRef("partyFrame")
    local raidFrame  = self:GetFrameRef("raidFrame")

    if newstate == "hidden" then
        soloFrame:Hide()
        partyFrame:Hide()
        raidFrame:Hide()
        return
    end

    if newstate == "solo" then
        soloFrame:Show()
        partyFrame:Hide()
        raidFrame:Hide()
    elseif newstate == "party" then
        soloFrame:Hide()
        partyFrame:Show()
        raidFrame:Hide()
    elseif newstate == "raid" then
        soloFrame:Hide()
        partyFrame:Hide()
        raidFrame:Show()
    end
]])

-------------------------------------------------
-- F.RebuildGroupStateDriver
-- Called from F.UpdateLayout (always out of combat) to pre-bake the
-- isHidden layout settings into the RegisterStateDriver conditional.
-- This ensures that mid-combat group transitions respect "hide" layout
-- settings without any Lua intervention.
-------------------------------------------------
function F.RebuildGroupStateDriver()
    -- layoutAutoSwitch may not be set yet at startup — guard it
    local autoSwitch = Cell.vars.layoutAutoSwitch
    if not autoSwitch then return end

    -- Determine which group-type states should map to "hidden"
    -- A group type is hidden when its layout auto-switch value is "hide"
    local raidState  = (autoSwitch["raid_outdoor"] == "hide"
                        and autoSwitch["raid10"]    == "hide"
                        and autoSwitch["raid25"]    == "hide")
                       and "hidden" or "raid"

    local partyState = (autoSwitch["party"] == "hide") and "hidden" or "party"
    local soloState  = (autoSwitch["solo"]  == "hide") and "hidden" or "solo"

    -- Build the macro conditional string.
    -- [@raid1,exists]   — reliable WotLK check for raid membership
    -- [@party1,exists]  — reliable WotLK check for party membership (non-raid)
    local conditional = string.format(
        "[@raid1,exists] %s; [@party1,exists] %s; %s",
        raidState, partyState, soloState
    )

    RegisterStateDriver(stateDriver, "groupstate", conditional)
end

-------------------------------------------------
-- Initial driver registration
-- At load time we don't yet have layoutAutoSwitch, so install a safe
-- default. F.RebuildGroupStateDriver() will replace this on first
-- F.UpdateLayout call (which runs out of combat on PLAYER_LOGIN).
-------------------------------------------------
RegisterStateDriver(stateDriver, "groupstate",
    "[@raid1,exists] raid; [@party1,exists] party; solo")
