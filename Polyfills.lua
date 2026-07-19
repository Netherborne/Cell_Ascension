local addonName, ns = ...
-- Use a single global Cell table for everything
_G.Cell = _G.Cell or ns or {}
local Cell = _G.Cell

-------------------------------------------------
-- securecallfunction polyfill
-- Some 3.3.5 builds lack this helper; Ace libraries expect it.
-------------------------------------------------
if type(securecallfunction) ~= "function" then
    function securecallfunction(func, ...)
        if type(func) ~= "function" then return end
        local ok, r1, r2, r3, r4, r5 = pcall(func, ...)
        if ok then
            return r1, r2, r3, r4, r5
        end
        -- Swallow errors to mimic securecallfunction behavior in newer clients
    end
end


-------------------------------------------------
-- PROJECT / FLAVOR SHIM FOR 3.3.5a
-------------------------------------------------
-- On real Retail/Classic, WOW_PROJECT_ID is a number.
-- On 3.3.5a private clients, it's usually nil, which breaks addons
-- that rely on it. So we fake the constants and pretend to be Wrath Classic.
if type(WOW_PROJECT_ID) ~= "number" then
    -- Fake Blizzard project constants
    WOW_PROJECT_MAINLINE          = 1
    WOW_PROJECT_CLASSIC           = 2
    WOW_PROJECT_WRATH_CLASSIC     = 11
    WOW_PROJECT_CATACLYSM_CLASSIC = 12
    WOW_PROJECT_MISTS_CLASSIC     = 13

    -- Tell the addon we're Wrath Classic
    WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC
end

-- Initialize flavor + flags once based on WOW_PROJECT_ID
if not Cell.flavor then
    if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
        Cell.flavor = "wrath"
    elseif WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        Cell.flavor = "retail"
    elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        Cell.flavor = "vanilla"
    elseif WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
        Cell.flavor = "cata"
    elseif WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
        Cell.flavor = "mists"
    else
        Cell.flavor = "retail"
    end
end

Cell.isRetail  = (Cell.flavor == "retail")
Cell.isWrath   = (Cell.flavor == "wrath")
Cell.isVanilla = (Cell.flavor == "vanilla")
Cell.isCata    = (Cell.flavor == "cata")
Cell.isMists   = (Cell.flavor == "mists")
Cell.isTWW     = false -- definitely not TWW on 3.3.5a

-------------------------------------------------

if not IsMetaKeyDown then
    function IsMetaKeyDown() return false end
end

if not CreateVector2D then
    function CreateVector2D(x, y)
        return {
            x = x or 0,
            y = y or 0,
            GetXY = function(self) return self.x, self.y end,
            SetXY = function(self, x, y) self.x = x; self.y = y end
        }
    end
end

-- Initialize supporters tables if not present
Cell.supporters1 = Cell.supporters1 or {}
Cell.supporters2 = Cell.supporters2 or {}

-------------------------------------------------
-- Polyfills for WotLK 3.3.5a
-------------------------------------------------

-------------------------------------------------
-- Screen size polyfill for WotLK
-------------------------------------------------
if not GetPhysicalScreenSize then
    -- WotLK uses GetScreenWidth() and GetScreenHeight() instead
    function GetPhysicalScreenSize()
        return GetScreenWidth(), GetScreenHeight()
    end
end

-------------------------------------------------
-- PixelUtil polyfill (doesn't exist in WotLK)
-------------------------------------------------
if not PixelUtil then
    PixelUtil = {}

    -- Polyfill for GetNearestPixelSize
    -- Returns a pixel-perfect size based on the desired size and scale
    function PixelUtil.GetNearestPixelSize(desiredSize, scale)
        if not desiredSize or desiredSize == 0 then
            return 0
        end

        -- Handle nil or zero scale
        if not scale or scale == 0 then
            scale = 1
        end

        -- Round to nearest pixel
        local pixelSize = desiredSize * scale
        if pixelSize >= 0 then
            pixelSize = math.floor(pixelSize + 0.5)
        else
            pixelSize = math.ceil(pixelSize - 0.5)
        end

        -- Ensure minimum size of 1 pixel
        if desiredSize > 0 and pixelSize < 1 then
            pixelSize = 1
        elseif desiredSize < 0 and pixelSize > -1 then
            pixelSize = -1
        end

        return pixelSize / scale
    end

    -- Polyfill for SetPoint
    -- Just wraps the standard SetPoint method
    function PixelUtil.SetPoint(frame, ...)
        if frame and frame.SetPoint then
            frame:SetPoint(...)
        end
    end

    -- Polyfill for GetPixelToUIUnitFactor (used in some addons)
    function PixelUtil.GetPixelToUIUnitFactor()
        local scale = UIParent:GetEffectiveScale()
        return 1 / (768 / GetScreenHeight()) / scale
    end
end


if not CreateVector2D then
    function CreateVector2D(x, y)
        return {
            x = x or 0,
            y = y or 0,
            GetXY = function(self) return self.x, self.y end,
            SetXY = function(self, x, y) self.x = x; self.y = y end
        }
    end
end


-------------------------------------------------
-- CellDropdownList shim
-- Retail has a shared dropdown list frame; Wrath port just needs a dummy to hide.
-------------------------------------------------
if not CellDropdownList then
    local f = CreateFrame("Frame", "CellDropdownList", UIParent)
    f:Hide()
    _G.CellDropdownList = f
end



-- Texture:SetGradient polyfill to support CreateColor tables on 3.3.5a


-- Mouse click / motion polyfill for Wrath





-------------------------------------------------
-- FontString SetRotation polyfill for WotLK
-- Text rotation doesn't exist in WotLK, so this is a no-op
-------------------------------------------------

-------------------------------------------------
-- CreateColor polyfill for WotLK
-- In retail, CreateColor creates a Color object with helper methods
-- In WotLK, we need to create a table with the same interface
-------------------------------------------------
if not CreateColor then
    function CreateColor(r, g, b, a)
        local color = {r = r or 1, g = g or 1, b = b or 1, a = a or 1}

        function color:GetRGB()
            return self.r, self.g, self.b
        end

        function color:GetRGBA()
            return self.r, self.g, self.b, self.a
        end

        function color:WrapTextInColorCode(text)
            -- Format: |cAARRGGBB + text + |r
            -- AA = alpha (255 for opaque), RR = red, GG = green, BB = blue
            local a = math.floor((self.a or 1) * 255)
            local r = math.floor(self.r * 255)
            local g = math.floor(self.g * 255)
            local b = math.floor(self.b * 255)
            return string.format("|c%02x%02x%02x%02x%s|r", a, r, g, b, text)
        end

        return color
    end
else
    -- CreateColor exists, but WrapTextInColorCode might not
    -- Add WrapTextInColorCode to existing Color objects if missing
    local testColor = CreateColor(1, 1, 1, 1)
    if testColor and not testColor.WrapTextInColorCode then
        local mt = getmetatable(testColor)
        if mt and mt.__index then
            function mt.__index:WrapTextInColorCode(text)
                local a = math.floor((self.a or 1) * 255)
                local r = math.floor(self.r * 255)
                local g = math.floor(self.g * 255)
                local b = math.floor(self.b * 255)
                return string.format("|c%02x%02x%02x%02x%s|r", a, r, g, b, text)
            end
        end
    end
end

-------------------------------------------------
-- Frame CreateFontString polyfill for WotLK
-- Ensures all created font strings have a default font set
-- This prevents "Font not set" errors when calling SetText
-------------------------------------------------
-------------------------------------------------
-- Frame CreateFontString polyfill for WotLK
-- REMOVED TO PREVENT UI TAINT
-------------------------------------------------
do
    -- Removed
end

-- SmoothStatusBarMixin polyfill for WotLK
if not SmoothStatusBarMixin then
    SmoothStatusBarMixin = {}

    function SmoothStatusBarMixin:OnLoad()
        -- no-op on 3.3.5
    end

    function SmoothStatusBarMixin:SetSmoothedValue(value)
        if self.SetValue then
            self:SetValue(value)
        end
    end

    function SmoothStatusBarMixin:SetMinMaxSmoothedValue(minVal, maxVal)
        if self.SetMinMaxValues then
            self:SetMinMaxValues(minVal, maxVal)
        end
    end

    -- Retail uses this to reset the smoothing state; on 3.3.5 we just snap to current value.
    function SmoothStatusBarMixin:ResetSmoothedValue()
        if self.GetValue and self.SetValue then
            self:SetValue(self:GetValue())
        end
    end
end

-------------------------------------------------
-- StatusBar GetStatusBarTexture polyfill for WotLK
-- In WotLK, GetStatusBarTexture() can return nil immediately after SetStatusBarTexture
-- We wrap it to ensure it always returns a valid texture
-------------------------------------------------
do
    -- Removed to prevent UI taint
end

-------------------------------------------------
-- Retail unit API polyfills
-------------------------------------------------

if not UnitInOtherParty then
    -- Retail API: returns true if unit is in a different party/instance group.
    -- WotLK/Ascension doesn't have that concept, so just say "no".
    function UnitInOtherParty(unit)
        return false
    end
end

-- UnitHasIncomingResurrection
if not UnitHasIncomingResurrection then
    -- Retail API: returns true if unit has an incoming resurrection (like Battle Res)
    -- WotLK doesn't have this API, always return false
    function UnitHasIncomingResurrection(unit)
        return false
    end
end

-- UnitInPhase
if not UnitInPhase then
    -- Retail API: returns true if unit is in the same phase as player
    -- WotLK doesn't have this API or handles phasing differently, assume always in phase
    function UnitInPhase(unit)
        return true
    end
end

-- UnitGroupRolesAssigned
if not UnitGroupRolesAssigned then
    -- WotLK 3.3.5a NATIVE API: returns THREE BOOLEANS (isTank, isHealer, isDamage)
    -- This is DIFFERENT from Retail which returns a single string
    -- WotLK has role detection through GetRaidRosterInfo and LFG system
    
    -- Debug flag for role detection (toggle with /cell debug role)
    local roleDebugEnabled = false
    
    function UnitGroupRolesAssigned(unit)
        if not unit then return false, false, false end
        
        local isTank, isHealer, isDamage = false, false, false
        local roleSource = "none"

        -- For raid members, get role from GetRaidRosterInfo
        if UnitInRaid(unit) then
            for i = 1, GetNumRaidMembers() do
                -- GetRaidRosterInfo returns: name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole
                local name, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
                local raidUnit = "raid" .. i

                if UnitIsUnit(unit, raidUnit) then
                    -- role is returned from GetRaidRosterInfo (from LFG/Dungeon Finder system or raid assignments)
                    if role and role ~= "NONE" and role ~= "" then
                        roleSource = "GetRaidRosterInfo"
                        -- Convert WotLK role format to booleans
                        if role == "MAINTANK" or role == "TANK" then
                            isTank = true
                        elseif role == "HEALER" then
                            isHealer = true
                        elseif role == "MAINASSIST" or role == "DAMAGER" or role == "DPS" then
                            isDamage = true
                        end
                    end
                    break
                end
            end
        end

        -- Fallback: Check party assignments (Main Tank/Main Assist)
        if not isTank and not isHealer and not isDamage then
            if GetPartyAssignment("MAINTANK", unit) then
                isTank = true
                roleSource = "MainTank assignment"
            elseif GetPartyAssignment("MAINASSIST", unit) then
                isDamage = true
                roleSource = "MainAssist assignment"
            end
        end
        
        -- Fallback: Use spec-based detection via LibGroupInfo
        if not isTank and not isHealer and not isDamage then
            local LibGroupInfo = LibStub and LibStub:GetLibrary("LibGroupInfo", true)
            if LibGroupInfo then
                local guid = UnitGUID(unit)
                if guid then
                    local cachedInfo = LibGroupInfo:GetCachedInfo(guid)
                    if cachedInfo then
                        -- GetCachedInfo returns a table with assignedRole and specRole fields
                        local specRole = cachedInfo.assignedRole or cachedInfo.specRole
                        if specRole and specRole ~= "NONE" then
                            roleSource = "LibGroupInfo (spec-based)"
                            if specRole == "TANK" then
                                isTank = true
                            elseif specRole == "HEALER" then
                                isHealer = true
                            elseif specRole == "DAMAGER" or specRole == "MELEE" or specRole == "RANGED" then
                                isDamage = true
                            end
                        end
                    end
                end
            end
        end
        
        -- Final fallback: Default to DAMAGER if still no role detected
        -- This helps on custom servers like Ascension where spec detection may not work
        if not isTank and not isHealer and not isDamage then
            isDamage = true
            roleSource = "default fallback"
        end
        
        -- Debug output
        if roleDebugEnabled then
            local roleName = isTank and "TANK" or isHealer and "HEALER" or "DAMAGER"
            print(string.format("[Role Debug] %s -> %s (source: %s)", 
                UnitName(unit) or unit, roleName, roleSource))
        end

        return isTank, isHealer, isDamage
    end
    
    -- Debug command toggle - create sFuncs table if needed
    if _G.Cell then
        _G.Cell.sFuncs = _G.Cell.sFuncs or {}
        _G.Cell.sFuncs.ToggleRoleDebug = function()
            roleDebugEnabled = not roleDebugEnabled
            print(string.format("[Cell] Role debug: %s", roleDebugEnabled and "enabled" or "disabled"))
        end
    end
end

-- UnitClassBase
if not UnitClassBase then
    -- Retail API: returns the class filename (e.g. "WARRIOR")
    -- WotLK: UnitClass returns (localizedName, fileName, classIndex)
    function UnitClassBase(unit)
        return select(2, UnitClass(unit))
    end
end

-- GetSpellBookItemName (doesn't exist in WotLK 3.3.5)
-- In WotLK, use GetSpellInfo(index, bookType) which returns name as first value
if not GetSpellBookItemName then
    function GetSpellBookItemName(index, bookType)
        local spellName = GetSpellInfo(index, bookType)
        return spellName
    end
end

-- Ambiguate (doesn't exist in WotLK 3.3.5)
-- In retail, Ambiguate formats player names by removing/keeping realm suffixes
-- In WotLK, we implement a simple version
if not Ambiguate then
    function Ambiguate(fullName, context)
        if not fullName then return "" end

        -- context values: "none", "short", "mail", "guild"
        -- For WotLK, we'll implement basic realm removal
        if context == "none" or context == "short" or context == "mail" then
            -- Remove realm suffix (everything after the hyphen)
            local name = string.match(fullName, "^([^%-]+)")
            return name or fullName
        end

        -- Default: return full name with realm
        return fullName
    end
end


-------------------------------------------------
-- StatusBar smoothing helpers polyfill
-------------------------------------------------




-- HookScript polyfill for 3.3.5a





-------------------------------------------------
-- SecureHandler_SetFrameRef polyfill
-- Ignore invalid/nil reference frames instead of erroring.
-------------------------------------------------
do
    if type(SecureHandler_SetFrameRef) == "function" and not _G._CellOrigSecureHandlerSetFrameRef then
        _G._CellOrigSecureHandlerSetFrameRef = SecureHandler_SetFrameRef

        function SecureHandler_SetFrameRef(self, refKey, refFrame)
            -- If refFrame is missing or not a frame-like table, just skip.
            if not refFrame or type(refFrame) ~= "table" or type(refFrame.GetName) ~= "function" then
                -- silently ignore bad refs
                return
            end

            return _G._CellOrigSecureHandlerSetFrameRef(self, refKey, refFrame)
        end
    end
end




-- Cooldown OnCooldownDone polyfill for 3.3.5a (ignore unsupported script type)
do
    -- Removed to prevent UI taint
end




-------------------------------------------------
-- FlipBook / ParentKey / ChildKey polyfills
-------------------------------------------------










-- C_Timer - per-key fills for WotLK 3.3.5 / Ascension
-- 335-patch: REWORK. The old block wholesale-replaced C_Timer (clobbering Ascension's
-- native, working C_Timer.After), allocated one CreateFrame PER timer call (never pooled,
-- never GC'd -> unbounded frame growth), silently pcall-swallowed callback errors, and
-- parsed-but-DROPPED NewTicker's iterations arg (finite tickers became immortal; live
-- victims: Details LibOpenRaid, DF schedules). New shape: respect native C_Timer with
-- per-key fills only; ONE shared driver frame for all NewTimer/NewTicker timers; ticker
-- iterations honored (nil = infinite, after N fires auto-cancel); callback errors reported
-- via geterrorhandler() and never abort other timers; driver hides itself when idle.
do
    C_Timer = C_Timer or {} -- 335-patch: keep the native table; fill only what's missing

    local TimerMixin = {}
    TimerMixin.__index = TimerMixin

    function TimerMixin:Cancel()
        self._cancelled = true
    end

    function TimerMixin:IsCancelled()
        return self._cancelled and true or false
    end

    local activeTimers = {} -- array of live timer objects, all driven by ONE frame
    local driver            -- lazily created shared driver frame

    local function ReportError(err)
        local eh = geterrorhandler and geterrorhandler()
        if eh then pcall(eh, err) end
    end

    local function DriverOnUpdate(self, elapsed)
        -- iterate downward so table.remove is safe; timers added during a callback
        -- land above the captured range and first tick on the NEXT frame
        for i = #activeTimers, 1, -1 do
            local timer = activeTimers[i]
            if timer._cancelled then
                table.remove(activeTimers, i)
            else
                timer._remaining = timer._remaining - elapsed
                if timer._remaining <= 0 then
                    local ok, err
                    if timer._passSelf then
                        ok, err = pcall(timer._callback, timer)
                    else
                        ok, err = pcall(timer._callback)
                    end
                    if not ok then
                        ReportError(err) -- report, never silent-swallow; other timers unaffected
                    end
                    if timer._ticker and not timer._cancelled then
                        timer._remaining = timer._remaining + timer._duration
                        if timer._remaining <= 0 then
                            timer._remaining = timer._duration -- no catch-up bursts after long stalls
                        end
                        if timer._iterations then
                            timer._iterations = timer._iterations - 1
                            if timer._iterations <= 0 then
                                timer._cancelled = true -- finite ticker done: auto-cancel
                                table.remove(activeTimers, i)
                            end
                        end
                    else
                        timer._cancelled = true
                        table.remove(activeTimers, i)
                    end
                end
            end
        end
        if #activeTimers == 0 then
            self:Hide() -- idle: stop OnUpdate until the next timer is added
        end
    end

    local function AddTimer(duration, callback, isTicker, iterations, passSelf)
        -- Validate arguments - use defaults instead of erroring (old block's behavior, kept)
        if type(duration) ~= "number" then
            duration = 0.01
        end
        if type(callback) ~= "function" then
            callback = function() end
        end
        local timer = setmetatable({
            _duration  = duration,
            _remaining = duration,
            _callback  = callback,
            _ticker    = isTicker or nil,
            _passSelf  = passSelf or nil,
        }, TimerMixin)
        if isTicker and type(iterations) == "number" then
            if iterations <= 0 then
                timer._cancelled = true -- zero/negative iterations: never fires
                return timer            -- don't enqueue or wake the driver for a dead ticker
            else
                timer._iterations = math.floor(iterations)
            end
        end
        if not driver then
            driver = CreateFrame("Frame")
            driver:Hide()
            driver:SetScript("OnUpdate", DriverOnUpdate)
        end
        activeTimers[#activeTimers + 1] = timer
        driver:Show()
        return timer
    end

    if not C_Timer.After then -- 335-patch: Ascension provides a native After; this fill is a fallback only
        C_Timer.After = function(durationOrSelf, callbackOrDuration, maybeCallback)
            -- Handle both C_Timer.After(duration, callback) and C_Timer:After(duration, callback)
            local duration, callback
            if type(durationOrSelf) == "table" and durationOrSelf == C_Timer then
                duration = callbackOrDuration
                callback = maybeCallback
            else
                duration = durationOrSelf
                callback = callbackOrDuration
            end
            AddTimer(duration, callback, false, nil, false)
        end
    end

    if not C_Timer.NewTimer then
        C_Timer.NewTimer = function(durationOrSelf, callbackOrDuration, maybeCallback)
            local duration, callback
            if type(durationOrSelf) == "table" and durationOrSelf == C_Timer then
                duration = callbackOrDuration
                callback = maybeCallback
            else
                duration = durationOrSelf
                callback = callbackOrDuration
            end
            return AddTimer(duration, callback, false, nil, true)
        end
    end

    if not C_Timer.NewTicker then
        C_Timer.NewTicker = function(durationOrSelf, callbackOrDuration, iterationsOrCallback, maybeIterations)
            local duration, callback, iterations
            if type(durationOrSelf) == "table" and durationOrSelf == C_Timer then
                duration = callbackOrDuration
                callback = iterationsOrCallback
                iterations = maybeIterations
            else
                duration = durationOrSelf
                callback = callbackOrDuration
                iterations = iterationsOrCallback
            end
            return AddTimer(duration, callback, true, iterations, true)
        end
    end
end

-- C_Spell
if not C_Spell then
    C_Spell = {}
end

-- Retail: C_Spell.GetSpellInfo(spellID) → table { name, iconID, ... }
if not C_Spell.GetSpellInfo then
    function C_Spell.GetSpellInfo(spellId)
        local name, _, icon = GetSpellInfo(spellId)
        if not name then
            return nil
        end
        return {
            name   = name,
            iconID = icon,
        }
    end
end

if not C_Spell.GetSpellTexture then
    function C_Spell.GetSpellTexture(spellId)
        local _, _, icon = GetSpellInfo(spellId)
        return icon
    end
end

if not C_Spell.IsSpellInRange then
    function C_Spell.IsSpellInRange(spellId, unit)
        -- Retail uses spellID directly; 3.3.5 IsSpellInRange wants name
        local name = GetSpellInfo(spellId)
        if not name then return nil end
        return IsSpellInRange(name, unit)
    end
end

if not C_Spell.GetSpellCooldown then
    function C_Spell.GetSpellCooldown(spellId)
        -- Old API: start, duration, enabled
        -- Retail C_Spell: start, duration, enabled, modRate
        local start, duration, enabled = GetSpellCooldown(spellId)
        return start, duration, enabled, 1
    end
end

if not C_Spell.GetSpellLink then
    function C_Spell.GetSpellLink(spellId)
        return GetSpellLink(spellId)
    end
end

if not C_Spell.GetSpellCharges then
    function C_Spell.GetSpellCharges(spellId)
        -- 3.3.5 has no real charges → emulate “no charges” behavior
        return nil
    end
end

-- C_Item
if not C_Item then
    C_Item = {}
    function C_Item.IsItemInRange(itemId, unit)
        return IsItemInRange(itemId, unit)
    end
    function C_Item.IsUsableItem(itemId)
        return IsUsableItem(itemId)
    end
elseif not C_Item.IsUsableItem then
    function C_Item.IsUsableItem(itemId)
        return IsUsableItem(itemId)
    end
end

-------------------------------------------------
-- UnitAura safety wrapper for addons that pass bad params
-- WotLK errors on nil/empty unit or nil index/name; retail is lenient.
-------------------------------------------------
if not _G._CellOriginalUnitAura then
    _G._CellOriginalUnitAura = UnitAura
    function UnitAura(unit, indexOrName, ...)
        if not unit or unit == "" or indexOrName == nil then
            return
        end
        return _G._CellOriginalUnitAura(unit, indexOrName, ...)
    end
end

-------------------------------------------------
-- UnitBuff/UnitDebuff wrappers for Cell (NOT global overrides)
-- WotLK returns: name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable, shouldConsolidate, spellId
-- Retail returns: name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, ...
-- We create Cell-specific wrappers instead of modifying the global API
-------------------------------------------------
-- Store original functions for Cell to use
_G._CellOriginalUnitBuff = _G._CellOriginalUnitBuff or UnitBuff
_G._CellOriginalUnitDebuff = _G._CellOriginalUnitDebuff or UnitDebuff

-- Create Cell namespace wrappers (don't override global)
if Cell then
    Cell.UnitBuff = function(unit, index, filter)
        local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable, shouldConsolidate, spellId = _G._CellOriginalUnitBuff(unit, index, filter)
        if not name then return nil end
        -- Return in retail format: name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId
        return name, icon, count, debuffType, duration, expirationTime, caster, isStealable, nil, spellId, nil, nil, nil, nil, nil, nil
    end

    Cell.UnitDebuff = function(unit, index, filter)
        local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable, shouldConsolidate, spellId = _G._CellOriginalUnitDebuff(unit, index, filter)
        if not name then return nil end
        return name, icon, count, debuffType, duration, expirationTime, caster, isStealable, nil, spellId, nil, nil, nil, nil, nil, nil
    end
end

-- C_UnitAuras
if not C_UnitAuras then
    C_UnitAuras = {}
    function C_UnitAuras.GetAuraDataBySlot(unit, slot)
        -- This is a simplified mapping. Real C_UnitAuras returns a table.
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, slot)
        if name then
            return {
                name = name,
                icon = icon,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                sourceUnit = unitCaster,
                isStealable = isStealable,
                spellId = spellId,
                points = {} -- Placeholder
            }
        end
        return nil
    end

    function C_UnitAuras.GetAuraDataBySpellName(unit, spellName, filter)
        for i = 1, 40 do
            local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura(unit, i, filter)
            if not name then break end
            if name == spellName then
                return {
                    name = name,
                    icon = icon,
                    count = count,
                    debuffType = debuffType,
                    duration = duration,
                    expirationTime = expirationTime,
                    sourceUnit = unitCaster,
                    isStealable = isStealable,
                    spellId = spellId,
                    points = {} -- Placeholder
                }
            end
        end
        return nil
    end

    function C_UnitAuras.GetAuraSlots(unit, filter, maxSlots)
        -- WotLK polyfill: Iterate through auras and return slot table
        local slots = {}
        local index = 1
        local max = maxSlots or 40 -- Default max auras

        while index <= max do
            local name = UnitAura(unit, index, filter)
            if name then
                table.insert(slots, index)
                index = index + 1
            else
                break
            end
        end

        return slots
    end

    -- Stub functions for private aura anchors (retail feature not in WotLK)
    function C_UnitAuras.AddPrivateAuraAnchor(...)
        -- No-op in WotLK
        return nil
    end

    function C_UnitAuras.RemovePrivateAuraAnchor(...)
        -- No-op in WotLK
        return nil
    end
end

-- C_Map
if not C_Map then
    C_Map = {}
end

if not C_Map.GetBestMapForUnit then
    function C_Map.GetBestMapForUnit(unit)
        -- Very basic fallback - try GetCurrentMapAreaID if it exists
        if GetCurrentMapAreaID then
            return GetCurrentMapAreaID()
        end
        -- Otherwise return a safe default
        return 0
    end
end

-- C_ChatInfo
if not C_ChatInfo then
    C_ChatInfo = {}
    function C_ChatInfo.SendAddonMessage(prefix, text, channel, target)
        -- Avoid hard Lua errors if callers pass bad params (seen on some addons)
        if type(channel) ~= "string" or channel == "" then return end
        if channel == "WHISPER" and (not target or target == "") then return end
        if prefix == nil then prefix = "" end
        if text == nil then text = "" end
        SendAddonMessage(prefix, text, channel, target)
    end
    function C_ChatInfo.RegisterAddonMessagePrefix(prefix)
        -- In WotLK 3.3.5, addon message prefixes are automatically registered
        -- when first used with SendAddonMessage, so this is a no-op
        return true
    end
    function C_ChatInfo.SendAddonMessageLogged(prefix, text, channel, target)
        -- In WotLK 3.3.5, SendAddonMessageLogged doesn't exist
        -- Just use the regular SendAddonMessage
        return C_ChatInfo.SendAddonMessage(prefix, text, channel, target)
    end
end

-- RegisterAddonMessagePrefix polyfill (global function for WotLK)
if not RegisterAddonMessagePrefix then
    function RegisterAddonMessagePrefix(prefix)
        -- In WotLK 3.3.5, addon message prefixes are automatically registered
        -- when first used with SendAddonMessage, so this is a no-op
        return true
    end
end

-- BNSendGameData polyfill (Battle.net doesn't exist in WotLK 3.3.5)
if not BNSendGameData then
    function BNSendGameData(gameAccountID, addonPrefix, addonMessage)
        -- Battle.net game data messaging doesn't exist in WotLK
        -- This is a no-op to prevent errors from libraries that try to hook it
        return
    end
end

C_AddOns = C_AddOns or {}

-- Mirror the modern C_AddOns API to the classic global functions so other addons
-- can safely hook them (e.g. Details! calls hooksecurefunc on LoadAddOn).
if not C_AddOns.GetAddOnMetadata then
    function C_AddOns.GetAddOnMetadata(addon, field)
        if GetAddOnMetadata then
            return GetAddOnMetadata(addon, field)
        end
    end
end

if not C_AddOns.IsAddOnLoaded then
    function C_AddOns.IsAddOnLoaded(addon)
        if IsAddOnLoaded then
            return IsAddOnLoaded(addon)
        end
        return false
    end
end

if not C_AddOns.LoadAddOn then
    function C_AddOns.LoadAddOn(addon)
        if LoadAddOn then
            return LoadAddOn(addon)
        end
        return false, "MISSING"
    end
end

if not C_AddOns.GetNumAddOns then
    function C_AddOns.GetNumAddOns()
        if GetNumAddOns then
            return GetNumAddOns()
        end
        return 0
    end
end

if not C_AddOns.GetAddOnInfo then
    function C_AddOns.GetAddOnInfo(addonIndexOrName)
        if GetAddOnInfo then
            return GetAddOnInfo(addonIndexOrName)
        end
    end
end

if not C_AddOns.GetAddOnDependencies then
    function C_AddOns.GetAddOnDependencies(addonName)
        if GetAddOnDependencies then
            local deps = {GetAddOnDependencies(addonName)}
            if #deps > 0 then
                return deps
            end
        end
        return {}
    end
end

-- 335-patch: GetAddOnEnableState - accept BOTH call shapes and return Enum.AddOnEnableState.
-- Retail order is (name, character) / (index, character); the legacy global (and the old
-- polyfill here) used (character, addonName). Other addons sharing this global C_AddOns
-- (e.g. Chattynator Skins/Main.lua) call with retail order, which the old polyfill fed to
-- the native legacy-order global backwards. Detect which arg is the addon, then resolve.
Enum = Enum or {}
if not Enum.AddOnEnableState then
    Enum.AddOnEnableState = { None = 0, Some = 1, All = 2 }
elseif Enum.AddOnEnableState.None == nil then -- per-key fill if a partial enum exists
    Enum.AddOnEnableState.None = 0
    Enum.AddOnEnableState.Some = Enum.AddOnEnableState.Some or 1
    Enum.AddOnEnableState.All = Enum.AddOnEnableState.All or 2
end
if not C_AddOns.GetAddOnEnableState then
    local function LooksLikeAddOn(v)
        if type(v) == "number" then return true end -- addon index is always the addon arg
        if type(v) ~= "string" or v == "" then return false end
        if GetAddOnInfo then
            local ok, name = pcall(GetAddOnInfo, v)
            return ok and name ~= nil
        end
        return true -- cannot verify without GetAddOnInfo; assume a non-empty string is a name
    end
    function C_AddOns.GetAddOnEnableState(a, b)
        -- shape detection: retail (name/index, character) vs legacy (character, addonName)
        local addon, character
        if type(a) == "number" then
            addon, character = a, b -- index first is always retail order
        elseif a == nil then
            addon, character = b, nil -- legacy (nil character, addonName)
        elseif b == nil then
            addon, character = a, nil -- single arg: the addon
        else
            local aIsAddon = LooksLikeAddOn(a)
            local bIsAddon = LooksLikeAddOn(b)
            if aIsAddon and not bIsAddon then
                addon, character = a, b -- retail order
            elseif bIsAddon and not aIsAddon then
                addon, character = b, a -- legacy order
            else
                addon, character = a, b -- ambiguous: assume retail order (modern callers)
            end
        end
        -- native legacy-order global, if this client has one
        if GetAddOnEnableState then
            local ok, state = pcall(GetAddOnEnableState, character, addon)
            if ok and type(state) == "number" then
                return state
            end
        end
        -- 3.3.5 fallback: GetAddOnInfo's 4th return is the enabled flag
        if GetAddOnInfo then
            local ok, name, _, _, enabled = pcall(GetAddOnInfo, addon)
            if ok and name ~= nil then
                return enabled and Enum.AddOnEnableState.All or Enum.AddOnEnableState.None
            end
        end
        local loaded = C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(addon)
        return loaded and Enum.AddOnEnableState.All or Enum.AddOnEnableState.None
    end
end

if not C_AddOns.EnableAddOn then
    function C_AddOns.EnableAddOn(addonName, characterName)
        if EnableAddOn then
            return EnableAddOn(addonName, characterName)
        end
        return false
    end
end

if not C_AddOns.DisableAddOn then
    function C_AddOns.DisableAddOn(addonName, characterName)
        if DisableAddOn then
            return DisableAddOn(addonName, characterName)
        end
        return false
    end
end

-- LoadAddOn polyfill (ensure it exists as a global function for other addons to hook)
if not LoadAddOn then
    -- WotLK has LoadAddOn, but it might not be available on all custom servers
    -- Create a basic implementation using the native API if it exists
    function LoadAddOn(addonName)
        -- Try to use native LoadAddOn if it exists (shouldn't happen, but safe)
        if _G._CellOriginalLoadAddOn then
            return _G._CellOriginalLoadAddOn(addonName)
        end
        -- Fallback: return false (addon not loaded)
        return false
    end
elseif type(LoadAddOn) ~= "function" then
    -- LoadAddOn exists but isn't a function (corrupted?), fix it
    local old = LoadAddOn
    function LoadAddOn(addonName)
        return false
    end
end

-- C_PvP
if not C_PvP then
    C_PvP = {}
    function C_PvP.IsBattleground()
        local inInstance, instanceType = IsInInstance()
        return instanceType == "pvp"
    end
end

-- C_TooltipInfo
if not C_TooltipInfo then
    C_TooltipInfo = {}
    function C_TooltipInfo.GetSpellByID(spellId)
        -- Placeholder, returns empty table or minimal info
        return { lines = {} }
    end
end


-- SOUNDKIT
Cell.SOUNDKIT = {
    U_CHAT_SCROLL_BUTTON = "igChatScrollUp",
    IG_MAINMENU_OPTION_CHECKBOX_ON = "igMainMenuOptionCheckBoxOn",
    IG_MAINMENU_OPTION_CHECKBOX_OFF = "igMainMenuOptionCheckBoxOff",
    IG_MAINMENU_OPEN = "igMainMenuOpen",
    IG_MAINMENU_CLOSE = "igMainMenuClose",
    IG_ABILITY_PAGE_TURN = "igAbilityPageTurn",
    IG_CHARACTER_INFO_TAB = "igCharacterInfoTab",
    IG_BACKPACK_OPEN = "igBackPackOpen",
    IG_BACKPACK_CLOSE = "igBackPackClose",
}


-- C_ClassTalents (Retail talent system, not in WotLK)
if not C_ClassTalents then
    C_ClassTalents = {}
    function C_ClassTalents.GetActiveConfigID()
        -- WotLK uses GetActiveTalentGroup() which returns 1 or 2
        return GetActiveTalentGroup()
    end
end

-- C_Traits (Retail talent tree system, not in WotLK)
if not C_Traits then
    C_Traits = {}
    function C_Traits.GetNodeInfo(configID, nodeID)
        -- WotLK doesn't have trait nodes
        -- Return nil to indicate node info not available
        return nil
    end
end

-- C_SpecializationInfo (MoP+ spec system, not in WotLK)
if not C_SpecializationInfo then
    C_SpecializationInfo = {}
    function C_SpecializationInfo.GetSpecialization()
        -- WotLK doesn't have specializations (added in MoP)
        -- Return nil to indicate no spec system
        return nil
    end
    function C_SpecializationInfo.GetSpecializationInfo(specIndex)
        -- Return nil to indicate no spec info available
        return nil
    end
end

-- C_NamePlate (Modern nameplate API, not in WotLK)
if not C_NamePlate then
    C_NamePlate = {}
    function C_NamePlate.GetNamePlates(issecure)
        -- WotLK has no nameplate API
        -- Return empty table
        return {}
    end
end

-------------------------------------------------
-- SecureHandlerStateTemplate:SetFrameRef polyfill
-- Ignore bad / nil reference frames instead of erroring.
-------------------------------------------------
do
    -- Removed to prevent UI taint
end




-- Wrath: alias RegisterAttributeDriver/UnregisterAttributeDriver to StateDriver versions
if not RegisterAttributeDriver and RegisterStateDriver then
    function RegisterAttributeDriver(frame, attribute, state)
        return RegisterStateDriver(frame, attribute, state)
    end
end

if not UnregisterAttributeDriver and UnregisterStateDriver then
    function UnregisterAttributeDriver(frame, attribute)
        return UnregisterStateDriver(frame, attribute)
    end
end

-- GetNumClasses (doesn't exist in WotLK 3.3.5a)
if not GetNumClasses then
    function GetNumClasses()
        -- WotLK has 10 classes: Warrior, Paladin, Hunter, Rogue, Priest, Death Knight, Shaman, Mage, Warlock, Druid
        return 10
    end
end

-- Font constants (don't exist in WotLK 3.3.5a)
if not UNIT_NAME_FONT_CHINESE then
    -- Use standard WotLK font as fallback
    UNIT_NAME_FONT_CHINESE = "Fonts\\FRIZQT__.TTF"
end

-- User requested fonts
if not UNIT_NAME_FONT_KOREAN then
    UNIT_NAME_FONT_KOREAN = "Fonts\\FRIZQT__.TTF"
end
if not UNIT_NAME_FONT_ROMAN then
    UNIT_NAME_FONT_ROMAN = "Fonts\\FRIZQT__.TTF"
end

-- GetClassColor (doesn't exist in WotLK 3.3.5a)
if not GetClassColor then
    function GetClassColor(classFile)
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if color then
            return color.r, color.g, color.b, string.format("%02x%02x%02x%02x", 255, color.r * 255, color.g * 255, color.b * 255)
        end
        -- Fallback to white if class not found
        return 1, 1, 1, "ffffffff"
    end
end

-- Add GetRGB and GetRGBA methods to RAID_CLASS_COLORS entries in WotLK
-- In WotLK, these are simple tables without methods
if RAID_CLASS_COLORS then
    for class, color in pairs(RAID_CLASS_COLORS) do
        if type(color) == "table" and not color.GetRGB then
            function color:GetRGB()
                return self.r, self.g, self.b
            end
            function color:GetRGBA()
                return self.r, self.g, self.b, self.a or 1
            end
        end
    end
end

-- Difficulty constants (don't exist in WotLK 3.3.5a)
-- Mythic difficulty was added in later expansions
if not PLAYER_DIFFICULTY6 then
    PLAYER_DIFFICULTY6 = "Mythic"
end

-- MapUtil (doesn't exist in WotLK 3.3.5a)
if not MapUtil then
    MapUtil = {}
    function MapUtil.GetMapParentInfo(mapID, mapType, topMost)
        -- WotLK doesn't have the modern map system
        -- Return basic zone info using legacy API
        local zoneName = GetZoneText()
        if zoneName and zoneName ~= "" then
            return {
                name = zoneName,
                mapID = mapID or 0
            }
        end
        return nil
    end
end

-- Enum (doesn't exist in WotLK 3.3.5a)
if not Enum then
    Enum = {}
end

-- UIMapType enum (retail feature, doesn't exist in WotLK)
if not Enum.UIMapType then
    Enum.UIMapType = {
        Cosmic = 0,
        World = 1,
        Continent = 2,
        Zone = 3,
        Dungeon = 4,
        Micro = 5,
        Orphan = 6
    }
end

-- UnitIsGroupLeader (doesn't exist in WotLK 3.3.5a)
if not UnitIsGroupLeader then
    function UnitIsGroupLeader(unit)
        -- In WotLK, we need to check differently for party vs raid
        if UnitInRaid(unit) then
            -- In raid, check if unit is the raid leader
            if UnitIsUnit(unit, "player") then
                return IsRaidLeader()
            else
                -- For other units in raid, we can't directly check in WotLK
                -- This is a limitation of the WotLK API
                return false
            end
        else
            -- In party, check if unit is the party leader
            return UnitIsPartyLeader(unit)
        end
    end
end

-- UnitIsGroupAssistant (doesn't exist in WotLK 3.3.5a)
if not UnitIsGroupAssistant then
    function UnitIsGroupAssistant(unit)
        -- Only applies to raids in WotLK
        if UnitInRaid(unit) then
            if UnitIsUnit(unit, "player") then
                return IsRaidOfficer()
            else
                -- For other units in raid, we can't directly check in WotLK
                -- This is a limitation of the WotLK API
                return false
            end
        end
        return false
    end
end

-- PlaySound wrapper for WotLK compatibility
-- In WotLK 3.3.5a, PlaySound signature is different from retail
-- Store original PlaySound and wrap it to handle errors gracefully
do
-- PlaySound wrapper removed as overwriting the global function taints the UI's secure execution paths.
end

-- GetNormalizedRealmName
-- In WotLK 3.3.5a (Ascension), this function exists but might be broken (calls nil 'Sub')
-- We overwrite it to ensure it works correctly
GetNormalizedRealmName = function()
    local realm = GetRealmName()
    if not realm then return "" end
    -- Remove spaces to normalize
    return string.gsub(realm, "%s+", "")
end

-- IsEncounterInProgress (doesn't exist in WotLK 3.3.5a)
-- Always override to ensure it exists
function IsEncounterInProgress()
    -- WotLK doesn't have encounter tracking API
    -- Return false to allow UI updates (no encounter in progress)
    return false
end

-- Group API polyfills
if not IsInRaid then
    function IsInRaid()
        return GetNumRaidMembers() > 0
    end
end

if not IsInGroup then
    function IsInGroup()
        return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
    end
end

-- GetNumGroupMembers polyfill (doesn't exist in WotLK 3.3.5a)
if not GetNumGroupMembers then
    function GetNumGroupMembers()
        if GetNumRaidMembers() > 0 then
            return GetNumRaidMembers()
        elseif GetNumPartyMembers() > 0 then
            return GetNumPartyMembers() + 1 -- +1 for player
        else
            return 1 -- Just player (solo)
        end
    end
end

-------------------------------------------------
-- GROUP_ROSTER_UPDATE Event Compatibility Layer
-- In WotLK 3.3.5a, GROUP_ROSTER_UPDATE doesn't exist.
-- Instead, we have PARTY_MEMBERS_CHANGED and RAID_ROSTER_UPDATE.
--
-- This global proxy provides a fallback for frames that may not
-- have been updated yet.
-------------------------------------------------
do
    -- Track frames that have registered GROUP_ROSTER_UPDATE handlers
    local groupRosterFrames = setmetatable({}, {__mode = "k"}) -- weak keys
    local function ProxyDebug(...)
        if _G.Cell and _G.Cell.funcs and _G.Cell.funcs.Debug then
            _G.Cell.funcs.Debug(...)
        else
            -- Fallback to plain print for early-load cases
            -- print("|cFF33CC33[Cell RosterProxy]|r", ...)
        end
    end

    -- The proxy frame that listens to actual WotLK events
    local proxyFrame = CreateFrame("Frame", "CellGroupRosterProxy")
    proxyFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    proxyFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    proxyFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
    proxyFrame:RegisterEvent("PARTY_MEMBER_DISABLE")

    local lastFireTime = 0
    proxyFrame:SetScript("OnEvent", function(self, event)

        -- Debounce to avoid firing multiple times per frame
        local DEBOUNCE_TIME = 0.1

        local now = GetTime()
        if now - lastFireTime < DEBOUNCE_TIME then
            return
        end
        lastFireTime = now
        local count = 0
        for _ in pairs(groupRosterFrames) do count = count + 1 end
        ProxyDebug("RosterProxy fired from", event, "dispatching to", tostring(count), "frames")

        -- Fire GROUP_ROSTER_UPDATE on all registered frames
        for frame in pairs(groupRosterFrames) do
            if frame then
                local handler = frame:GetScript("OnEvent")
                if handler then
                    -- Use pcall to prevent errors from breaking the loop
                    pcall(handler, frame, "GROUP_ROSTER_UPDATE")
                end
            end
        end
    end)
    
    -- Provide a way to register frames for the proxy
    function Cell_RegisterForGroupRosterProxy(frame)
        if frame then
            groupRosterFrames[frame] = true
            ProxyDebug("Registered frame for roster proxy:", frame:GetName() or tostring(frame))
        end
    end
    
    -- Provide a way to unregister frames from the proxy
    function Cell_UnregisterFromGroupRosterProxy(frame)
        if frame then
            groupRosterFrames[frame] = nil
            ProxyDebug("Unregistered frame from roster proxy:", frame:GetName() or tostring(frame))
        end
    end
    
    -- Provide a way to manually trigger GROUP_ROSTER_UPDATE (for init)
    function Cell_FireGroupRosterUpdate()
        for frame in pairs(groupRosterFrames) do
            if frame then
                local handler = frame:GetScript("OnEvent")
                if handler then
                    pcall(handler, frame, "GROUP_ROSTER_UPDATE")
                end
            end
        end
    end

    -- Hook removed to prevent taint. Addons must explicitly call Cell_RegisterForGroupRosterProxy.
end

-- LocalizedClassList
if not LocalizedClassList then
    function LocalizedClassList(gender)
        local t = {}
        for i = 1, GetNumClasses() do
            local name, tag, id = GetClassInfo(i)
            if tag then
                t[tag] = name
            end
        end
        return t
    end
end

-- Mixin
if not Mixin then
    function Mixin(object, ...)
        for i = 1, select("#", ...) do
            local mixin = select(i, ...)
            for k, v in pairs(mixin) do
                object[k] = v
            end
        end
        return object
    end
end

-------------------------------------------------
-- Frame/Widget SetEnabled polyfill for WotLK
-- In retail, frames/widgets have SetEnabled(bool) to enable/disable
-- In WotLK, use Enable() and Disable() methods instead
-------------------------------------------------

-------------------------------------------------
-- SimpleHTML GetContentHeight polyfill for WotLK
-- In retail, SimpleHTML frames have GetContentHeight() to get rendered height
-- In WotLK, we approximate this with GetHeight()
-------------------------------------------------

-------------------------------------------------
-- Slider OnValueChanged userChanged parameter polyfill for WotLK
-- In WotLK 3.3.5a, the userChanged parameter in OnValueChanged is always nil
-- We wrap SetValue to flag programmatic changes so callbacks can distinguish
-------------------------------------------------
do
    -- Removed to prevent UI taint
end

-------------------------------------------------
-- REMOVED: All global font polyfills and hooks
-- They were masking the root cause, not fixing it
-------------------------------------------------

-------------------------------------------------


-- Fonts
-- NOTE: Font objects are created in Widgets/Widgets.lua and Indicators/Built-in.lua
-- No need to pre-create them here since no code uses them before those files load
-- Removed redundant font creation that was causing conflicts with STANDARD_TEXT_FONT vs GameFontNormal

-------------------------------------------------
-- Frame :Run() polyfill for WotLK
-- In retail, frames in restricted execution have :Run() to execute Lua snippets
-- In WotLK, this doesn't exist, so we polyfill it
-------------------------------------------------

-------------------------------------------------
-- Ensure CellMainFrame is always shown
-- In WotLK, child frames won't show if parent is hidden
-------------------------------------------------
local function EnsureCellMainFrameShown()
    if CellMainFrame and not CellMainFrame:IsShown() then
        CellMainFrame:Show()
    end
end

-- Check immediately when addon loads and on events
local checkFrame = CreateFrame("Frame")
checkFrame:RegisterEvent("ADDON_LOADED")
checkFrame:RegisterEvent("PLAYER_LOGIN")
checkFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Cell_Ascension" then
        -- Check after Cell loads
        C_Timer.After(0.1, EnsureCellMainFrameShown)
    elseif event == "PLAYER_LOGIN" then
        -- Check after login
        C_Timer.After(0.1, EnsureCellMainFrameShown)
    end
end)

-- Also check immediately
C_Timer.After(0.5, EnsureCellMainFrameShown)

-------------------------------------------------
-- Wrap PixelPerfect functions to handle nil frames gracefully
-- Some widgets may not exist in WotLK that exist in retail
-------------------------------------------------
-- Hook immediately when Cell.pixelPerfectFuncs is created
local function WrapPixelPerfectFunctions()
    if Cell and Cell.pixelPerfectFuncs and not Cell.pixelPerfectFuncs._CellWrapped then
        local P = Cell.pixelPerfectFuncs
        Cell.pixelPerfectFuncs._CellWrapped = true

        -- List of functions that take a frame as first parameter
        local frameFunctions = {
            "Repoint", "Resize", "ClearPoints", "Size", "Point",
            "Reborder", "Width", "Height", "PixelPerfectPoint"
        }

        for _, funcName in ipairs(frameFunctions) do
            if P[funcName] then
                local originalFunc = P[funcName]
                P[funcName] = function(frame, ...)
                    if not frame then
                        -- Silently ignore nil frames instead of erroring
                        return
                    end
                    return originalFunc(frame, ...)
                end
            end
        end
    end
end

-- Create event frame to wrap after addon loads
local pixelPerfectWrapperFrame = CreateFrame("Frame")
pixelPerfectWrapperFrame:RegisterEvent("ADDON_LOADED")
pixelPerfectWrapperFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Cell_Ascension" then
        -- Wrap immediately after addon loads
        WrapPixelPerfectFunctions()
        -- Also try with small delays
        C_Timer.After(0.1, WrapPixelPerfectFunctions)
        C_Timer.After(0.5, WrapPixelPerfectFunctions)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-------------------------------------------------
-- Wrap Cell.funcs.RotateTexture to handle nil textures
-- Some widgets may not exist in WotLK that exist in retail
-------------------------------------------------
C_Timer.After(0.1, function()
    if Cell and Cell.funcs and Cell.funcs.RotateTexture then
        local originalRotateTexture = Cell.funcs.RotateTexture
        Cell.funcs.RotateTexture = function(texture, angle)
            if not texture then return end
            return originalRotateTexture(texture, angle)
        end
    end
end)

-------------------------------------------------
-- Wrap Cell.bFuncs.SetOrientation to handle nil widgets
-- SpotlightFrame and other special frames may not have all widgets
-------------------------------------------------
local function WrapSetOrientation()
    if Cell and Cell.bFuncs and Cell.bFuncs.SetOrientation then
        local originalSetOrientation = Cell.bFuncs.SetOrientation
        Cell.bFuncs.SetOrientation = function(button, orientation, rotateTexture)
            -- Check if button is nil first
            if not button then
                -- Silently return if button is nil
                return
            end

            -- Get all the widgets (some may be nil)
            local widgets = button.widgets
            if not widgets then return end

            local healthBar = widgets.healthBar
            local powerBar = widgets.powerBar
            local gapTexture = widgets.gapTexture

            -- Check if this button has the minimum required widgets
            -- SpotlightFrame buttons don't have powerBar or gapTexture
            if not healthBar or not powerBar or not gapTexture then
                -- Skip SetOrientation for buttons without basic widgets
                return
            end

            -- Call original function
            return originalSetOrientation(button, orientation, rotateTexture)
        end
    else
        C_Timer.After(0.5, WrapSetOrientation)
    end
end

-- Wrap Cell.bFuncs.SetPowerSize to handle nil buttons
local function WrapSetPowerSize()
    if Cell and Cell.bFuncs and Cell.bFuncs.SetPowerSize then
        local originalSetPowerSize = Cell.bFuncs.SetPowerSize
        Cell.bFuncs.SetPowerSize = function(button, size)
            -- Check if button is nil first
            if not button then
                -- Silently return if button is nil (pet buttons might not exist)
                return
            end
            -- Call original function
            return originalSetPowerSize(button, size)
        end
    else
        C_Timer.After(0.5, WrapSetPowerSize)
    end
end

-- Create event frame to wrap after addon loads
local buttonFunctionsWrapperFrame = CreateFrame("Frame")
buttonFunctionsWrapperFrame:RegisterEvent("ADDON_LOADED")
buttonFunctionsWrapperFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Cell_Ascension" then
        -- Wrap SetOrientation
        WrapSetOrientation()
        C_Timer.After(0.1, WrapSetOrientation)
        C_Timer.After(0.5, WrapSetOrientation)
        C_Timer.After(1, WrapSetOrientation)

        -- Wrap SetPowerSize
        WrapSetPowerSize()
        C_Timer.After(0.1, WrapSetPowerSize)
        C_Timer.After(0.5, WrapSetPowerSize)
        C_Timer.After(1, WrapSetPowerSize)

        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-------------------------------------------------
-- AnimationGroup CreateAnimation compatibility wrapper
-- Ensures compatibility with DetailsWotlkPort and other addons
-- This prevents conflicts when other addons expect animation type to be a string
-------------------------------------------------

-------------------------------------------------
-- Fix LibCustomGlow AutoCastGlow info initialization
-- Ensure info table is properly initialized before use
-------------------------------------------------
C_Timer.After(0.5, function()
    if LibStub then
        local LCG = LibStub("LibCustomGlow-1.0-Cell", true)
        if LCG and LCG.AutoCastGlow_Start then
            local origStart = LCG.AutoCastGlow_Start
            LCG.AutoCastGlow_Start = function(r, color, N, frequency, scale, xOffset, yOffset, key, frameLevel)
                -- Call original function
                origStart(r, color, N, frequency, scale, xOffset, yOffset, key, frameLevel)

                -- Ensure info fields are initialized
                key = key or ""
                local f = r["_AutoCastGlow"..key]
                if f and f.info then
                    -- Force initial size calculation
                    local width, height = f:GetSize()
                    if width and height and width > 0 and height > 0 then
                        f.info.width = width
                        f.info.height = height
                        f.info.perimeter = 2 * (width + height)
                        f.info.bottomlim = height * 2 + width
                        f.info.rightlim = height + width
                        f.info.space = f.info.perimeter / f.info.N
                    else
                        -- Frame not sized yet, set safe defaults to prevent nil errors
                        f.info.width = 0
                        f.info.height = 0
                        f.info.perimeter = 0
                        f.info.bottomlim = 0
                        f.info.rightlim = 0
                        f.info.space = 0
                    end
                end
            end
        end
    end
end)

-------------------------------------------------
-- Click-Castings Fixes
-------------------------------------------------
do


    -- Fix 1: ScrollFrame eats clicks
    function PatchCreateScrollFrame()
        if not Cell or not Cell.CreateScrollFrame then return end
        if Cell._ScrollFramePatchedForBindings then return end
        Cell._ScrollFramePatchedForBindings = true

        local orig_CreateScrollFrame = Cell.CreateScrollFrame
        Cell.CreateScrollFrame = function(parent, top, bottom, color, border)
            local ret = orig_CreateScrollFrame(parent, top, bottom, color, border)

            if parent:GetName() == "ClickCastingsTab_BindingsFrame" then
                local scroll = parent.scrollFrame
                if scroll then
                    if scroll.EnableMouse then scroll:EnableMouse(false) end
                    if scroll.content and scroll.content.EnableMouse then scroll.content:EnableMouse(true) end
                end
            end
            
            return ret
        end
    end

    -- Fix 2: BindingListButton grids have too low frame level (6 vs 530+)
    function PatchBindingListButton()
        if not Cell or not Cell.CreateBindingListButton then return end
        if Cell._BindingListButtonPatched then return end
        Cell._BindingListButtonPatched = true

        local orig_CreateBindingListButton = Cell.CreateBindingListButton
        Cell.CreateBindingListButton = function(parent, modifier, bindKey, bindType, bindAction)
            local b = orig_CreateBindingListButton(parent, modifier, bindKey, bindType, bindAction)
            
            -- Fix frame levels of grids
            local level = b:GetFrameLevel() + 1
            if b.keyGrid then b.keyGrid:SetFrameLevel(level) end
            if b.typeGrid then b.typeGrid:SetFrameLevel(level) end
            if b.actionGrid then b.actionGrid:SetFrameLevel(level) end
            
            return b
        end
    end

    -- Fix 3: GetClickCastingSpellList fails with mixed-case class names
    local function PatchGetClickCastingSpellList()
        if not Cell or not Cell.funcs or not Cell.funcs.GetClickCastingSpellList then return end
        if Cell._GetClickCastingSpellListPatched then return end
        Cell._GetClickCastingSpellListPatched = true

        local orig_GetClickCastingSpellList = Cell.funcs.GetClickCastingSpellList
        Cell.funcs.GetClickCastingSpellList = function(class)
            if class and type(class) == "string" then
                class = string.upper(class)
            end
            return orig_GetClickCastingSpellList(class)
        end
    end
    -- Add to the event handler
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addonName)
        if addonName == "Cell_Ascension" then
            PatchCreateScrollFrame()
            PatchBindingListButton()
            PatchGetClickCastingSpellList()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

-------------------------------------------------
-- WotLK 3.3.5a: IsEveryoneAssistant doesn't exist
-------------------------------------------------
if not IsEveryoneAssistant then
    _G.IsEveryoneAssistant = function()
        return GetNumGroupMembers() > 0 and GetRaidRosterInfo(1) == nil
    end
end

-------------------------------------------------
-- WotLK 3.3.5a: Button creation and positioning now handled inline in PartyFrame.lua and RaidFrame.lua
-------------------------------------------------

-------------------------------------------------
-- BackdropTemplate polyfill for WotLK 3.3.5a
-- In Wrath, backdrop functions (SetBackdrop, SetBackdropColor, etc.) are natively
-- available on all frames. However, the BackdropTemplate itself doesn't exist.
-- In retail 9.0.1+, Blizzard moved these functions into BackdropTemplate.
-- We create an empty template here so CreateFrame(..., "BackdropTemplate") doesn't error.
-------------------------------------------------
if not BackdropTemplateMixin then
    -- Create an empty mixin (backdrop functions already exist natively in Wrath)
    BackdropTemplateMixin = {}
end


-------------------------------------------------
-- Cell.Polyfill Safe Namespace
-- Replaces tainted mt.__index global modifications
-------------------------------------------------

Cell.Polyfill = Cell.Polyfill or {}
local Polyfill = Cell.Polyfill

function Polyfill.SetEnabled(frame, enabled)
    if not frame then return end
    if enabled then
        if frame.Enable then frame:Enable() end
    else
        if frame.Disable then frame:Disable() end
    end
end

function Polyfill.SetGradient(texture, orientation, ...)
    if not texture or not texture.SetGradient then return end
    local c1, c2 = ...
    if type(c1) == "table" and type(c2) == "table" then
        local r1, g1, b1, a1 = c1.r or c1[1] or 1, c1.g or c1[2] or 1, c1.b or c1[3] or 1, c1.a or c1[4] or 1
        local r2, g2, b2, a2 = c2.r or c2[1] or 1, c2.g or c2[2] or 1, c2.b or c2[3] or 1, c2.a or c2[4] or 1
        if texture.SetGradientAlpha then
            return texture:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
        end
    end
    return texture:SetGradient(orientation, ...)
end

function Polyfill.SetGradientAlpha(texture, orientation, ...)
    if not texture or not texture.SetGradientAlpha then return end
    local args = {...}
    if #args == 2 and type(args[1]) == "table" and type(args[2]) == "table" then
        local c1, c2 = args[1], args[2]
        local r1, g1, b1, a1 = c1.r or c1[1] or 1, c1.g or c1[2] or 1, c1.b or c1[3] or 1, c1.a or c1[4] or 1
        local r2, g2, b2, a2 = c2.r or c2[1] or 1, c2.g or c2[2] or 1, c2.b or c2[3] or 1, c2.a or c2[4] or 1
        return texture:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    end
    return texture:SetGradientAlpha(orientation, ...)
end

function Polyfill.SetColorTexture(texture, r, g, b, a)
    if not texture then return end
    if texture.SetColorTexture then
        texture:SetColorTexture(r, g, b, a)
    elseif texture.SetTexture then
        texture:SetTexture(r or 1, g or 1, b or 1, a or 1)
    end
end

function Polyfill.SetAtlas(texture, atlasName, useAtlasSize, filterMode)
    if not texture then return end
    if texture.SetAtlas then
        local success = pcall(texture.SetAtlas, texture, atlasName, useAtlasSize, filterMode)
        if not success and texture.SetTexture then
            texture:SetTexture(nil)
        end
    end
end

function Polyfill.SetMouseClickEnabled(region, enabled)
    if not region then return end
    if region.SetMouseClickEnabled then
        region:SetMouseClickEnabled(enabled)
    elseif region.EnableMouse then
        region:EnableMouse(not not enabled)
    end
end

function Polyfill.SetMouseMotionEnabled(region, enabled)
    if not region then return end
    if region.SetMouseMotionEnabled then
        region:SetMouseMotionEnabled(enabled)
    elseif region.EnableMouse then
        region:EnableMouse(not not enabled)
    end
end

function Polyfill.IsTruncated(fs)
    if not fs then return false end
    if fs.IsTruncated then
        return fs:IsTruncated()
    end
    if fs.GetStringWidth and fs.GetWidth then
        local w1 = fs:GetStringWidth()
        local w2 = fs:GetWidth()
        if w2 == 0 then return false end
        return w1 > w2
    end
    return false
end

function Polyfill.SetRotation(fs, angle)
    if not fs then return end
    if fs.SetRotation then
        fs:SetRotation(angle)
    end
end

function Polyfill.SetSmoothedValue(sb, value)
    if not sb then return end
    if sb.SetSmoothedValue then
        sb:SetSmoothedValue(value)
    elseif sb.SetValue then
        sb:SetValue(value)
    end
end

function Polyfill.SetMinMaxSmoothedValue(sb, minVal, maxVal)
    if not sb then return end
    if sb.SetMinMaxSmoothedValue then
        sb:SetMinMaxSmoothedValue(minVal, maxVal)
    elseif sb.SetMinMaxValues then
        sb:SetMinMaxValues(minVal, maxVal)
    end
end

function Polyfill.ResetSmoothedValue(sb)
    if not sb then return end
    if sb.ResetSmoothedValue then
        sb:ResetSmoothedValue()
    elseif sb.GetValue and sb.SetValue then
        sb:SetValue(sb:GetValue())
    end
end

-- Animation alpha/scale Polyfills
function Polyfill.SetFromAlpha(anim, value)
    if not anim then return end
    if anim.SetFromAlpha then
        anim:SetFromAlpha(value)
    else
        anim._fromAlpha = value
        if anim.SetChange and anim._toAlpha then
            anim:SetChange(anim._toAlpha - value)
        end
    end
end

function Polyfill.SetToAlpha(anim, value)
    if not anim then return end
    if anim.SetToAlpha then
        anim:SetToAlpha(value)
    else
        anim._toAlpha = value
        if anim.SetChange and anim._fromAlpha then
            anim:SetChange(value - anim._fromAlpha)
        end
    end
end

function Polyfill.SetScaleFrom(anim, x, y)
    if not anim then return end
    anim._fromX = x
    anim._fromY = y
    local toX = anim._toX or 1
    local toY = anim._toY or 1
    local fX = x == 0 and 0.001 or x
    local fY = y == 0 and 0.001 or y
    if anim.SetScale then
        anim:SetScale(toX / fX, toY / fY)
    end
end

function Polyfill.SetScaleTo(anim, x, y)
    if not anim then return end
    anim._toX = x
    anim._toY = y
    local fromX = anim._fromX or 1
    local fromY = anim._fromY or 1
    local fX = fromX == 0 and 0.001 or fromX
    local fY = fromY == 0 and 0.001 or fromY
    if anim.SetScale then
        anim:SetScale(x / fX, y / fY)
    end
end

function Polyfill.HookScript(frame, scriptType, handler)
    if not frame or not scriptType or not handler then return end
    
    if type(frame.HookScript) == "function" then
        frame:HookScript(scriptType, handler)
        return
    end
    
    local getScript = frame.GetScript
    local setScript = frame.SetScript
    if type(getScript) == "function" and type(setScript) == "function" then
        local prev = getScript(frame, scriptType)
        if prev then
            setScript(frame, scriptType, function(...)
                prev(...)
                handler(...)
            end)
        else
            setScript(frame, scriptType, handler)
        end
    end
end

function Polyfill.SetSwipeTexture(cd, texture) end
function Polyfill.SetSwipeColor(cd, r, g, b, a) end
function Polyfill.SetDrawEdge(cd, flag) end
function Polyfill.SetDrawBling(cd, flag) end
function Polyfill.SetHideCountdownNumbers(cd, flag) end

function Polyfill.SetReverseFill(sb, reverse)
    if not sb then return end
    if sb.SetReverseFill then
        sb:SetReverseFill(reverse)
    end
end

function Polyfill.SetParentKey(tex, key) end
function Polyfill.SetChildKey(anim, key) end
function Polyfill.SetFlipBookFrames(anim, frames) end
function Polyfill.SetFlipBookFrameWidth(anim, w) end
function Polyfill.SetFlipBookFrameHeight(anim, h) end
function Polyfill.SetFlipBookRows(anim, r) end
function Polyfill.SetFlipBookColumns(anim, c) end

function Polyfill.CreateAnimation(ag, animType, name, inherits)
    if not ag then return end
    if animType == "FlipBook" then
        animType = "Alpha"
    end
    if not name then name = animType end
    
    local anim
    if ag.CreateAnimation then
        anim = ag:CreateAnimation(animType, name, inherits)
    end
    
    if anim then
        -- Attach our custom play hook
        if not ag._cellAnimations then ag._cellAnimations = {} end
        table.insert(ag._cellAnimations, anim)
    end
    
    return anim
end

-- Securely hook the global AnimationGroup:Play method to apply WotLK fixes
-- We use hooksecurefunc to avoid UI taint that comes from directly overwriting metatable methods
do
    local f = CreateFrame("Frame")
    local ag = f:CreateAnimationGroup()
    local mt = getmetatable(ag)
    if mt and mt.__index and mt.__index.Play and not Cell._AnimationSystemPlayHooked then
        hooksecurefunc(mt.__index, "Play", function(self)
            if self._cellAnimations then
                for _, a in ipairs(self._cellAnimations) do
                    if a._fromAlpha then
                        local region = a:GetParent() and a:GetParent():GetParent()
                        if region and region.SetAlpha then 
                            region:SetAlpha(a._fromAlpha) 
                            if a._toAlpha and a.SetChange then
                                a:SetChange(a._toAlpha - a._fromAlpha)
                            end
                        end
                    end
                    if a._fromX or a._fromY then
                        local region = a:GetParent() and a:GetParent():GetParent()
                        if region and region.SetScale then 
                            local s = math.max(a._fromX or 0, a._fromY or 0)
                            region:SetScale(s == 0 and 0.001 or s) 
                            local toS = math.max(a._toX or 1, a._toY or 1)
                            if a.SetScale then
                                local fromS = s == 0 and 0.001 or s
                                a:SetScale(toS / fromS, toS / fromS)
                            end
                        end
                    end
                end
            end
        end)
        Cell._AnimationSystemPlayHooked = true
    end
end

function Polyfill.CreateMaskTexture(frame)
    if not frame then return end
    if frame.CreateMaskTexture then
        return frame:CreateMaskTexture()
    end
    local mask = CreateFrame("Frame", nil, frame)
    mask:SetAllPoints(frame)
    if mask.EnableMouse then mask:EnableMouse(false) end
    mask.SetTexture = function() end
    mask.SetRotated = function() end
    return mask
end

function Polyfill.AddMaskTexture(texture, mask) end

function Polyfill.SetSpellByID(tooltip, spellID)
    if not tooltip or not spellID then return end
    if tooltip.SetSpellByID then
        tooltip:SetSpellByID(spellID)
        return
    end
    local link = GetSpellLink(spellID)
    if link and tooltip.SetHyperlink then
        tooltip:SetHyperlink(link)
    elseif tooltip.ClearLines then
        tooltip:ClearLines()
    end
end

function Polyfill.GetContentHeight(html)
    if not html then return 0 end
    if html.GetContentHeight then
        return html:GetContentHeight()
    end
    return html.GetHeight and html:GetHeight() or 0
end

function Polyfill.Run(frame, snippet)
    if not frame or not snippet then return end
    if frame.Run then
        frame:Run(snippet)
        return
    end
    local func = loadstring(snippet)
    if func then
        setfenv(func, setmetatable({self = frame}, {__index = _G}))
        pcall(func)
    end
end
