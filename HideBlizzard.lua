local _, Cell = ...
local F = Cell.funcs

-- We no longer use a hidden parent as it causes taint in modern/wrath clients.
-- We use RegisterStateDriver to securely hide the frames instead.

local function SecureHide(frame)
    if not frame then return end
    -- The secure way to hide default frames without tainting them
    RegisterStateDriver(frame, "visibility", "hide")
end

function F.HideBlizzardParty()
    _G.UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

    if _G.CompactPartyFrame then
        SecureHide(_G.CompactPartyFrame)
    end

    if _G.PartyFrame then
        SecureHide(_G.PartyFrame)
        for frame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
            SecureHide(frame)
        end
    else
        for i = 1, 4 do
            SecureHide(_G["PartyMemberFrame"..i])
            SecureHide(_G["CompactPartyMemberFrame"..i])
        end
        if _G.PartyMemberBackground then _G.PartyMemberBackground:Hide() end
    end
end

function F.HideBlizzardRaid()
    _G.UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

    if _G.CompactRaidFrameContainer then
        SecureHide(_G.CompactRaidFrameContainer)
    end
end

function F.HideBlizzardRaidManager()
    if CompactRaidFrameManager_SetSetting then
        CompactRaidFrameManager_SetSetting("IsShown", "0")
    end

    if _G.CompactRaidFrameManager then
        SecureHide(_G.CompactRaidFrameManager)
    end
end