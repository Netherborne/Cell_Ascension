local _, Cell = ...
local L = Cell.L
local F = Cell.funcs
local P = Cell.pixelPerfectFuncs

local changelogsFrame

local function CreateChangelogsFrame()
    changelogsFrame = Cell.CreateMovableFrame("Cell "..L["Changelogs"], "CellChangelogsFrame", 400, 450, "DIALOG", 1, true)
    Cell.frames.changelogsFrame = changelogsFrame
    changelogsFrame:SetToplevel(true)

    Cell.Polyfill.HookScript(changelogsFrame.header.closeBtn, "OnClick", function()
        CellDB["changelogsViewed"] = Cell.version
    end)

    Cell.CreateScrollFrame(changelogsFrame)
    changelogsFrame.scrollFrame:SetScrollStep(37)

    local content = CreateFrame("SimpleHTML", "CellChangelogsContent", changelogsFrame.scrollFrame.content)
    content:SetSpacing("h1", 9)
    content:SetSpacing("h2", 7)
    content:SetSpacing("p", 5)
    content:SetFontObject("h1", _G["CELL_ASCENSION_FONT_CLASS_TITLE"] or GameFontNormal)
    content:SetFontObject("h2", _G["CELL_ASCENSION_FONT_CLASS"] or GameFontNormal)
    if LOCALE_zhCN then
        content:SetFontObject("p", _G["CELL_ASCENSION_FONT_WIDGET"] or GameFontNormal)
    else
        content:SetFontObject("p", _G["CELL_ASCENSION_FONT_CHINESE"] or GameFontNormal)
    end
    content:SetPoint("TOP", 0, -10)
    content:SetWidth(changelogsFrame:GetWidth() - 30)
    content:SetHyperlinkFormat("|H%s|h|cFFFFD100%s|r|h")

       changelogsFrame:SetScript("OnShow", function()
        local text = L["CHANGELOGS"] or ""
        text = string.gsub(text, "\r", "")
        content:SetText("<html><body>" .. text .. "</body></html>")
        C_Timer.After(0, function()
            local height
            if content.GetContentHeight then
                height = Cell.Polyfill.GetContentHeight(content)
            else
                -- 3.3.5 fallback: use current frame height, or a sane default
                height = content:GetHeight()
                if height == 0 then
                    height = 400
                end
            end

            content:SetHeight(height)
            changelogsFrame.scrollFrame.content:SetHeight(height + 100)
            P.PixelPerfectPoint(changelogsFrame)
        end)
    end)


    content:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
        if linkData == "older" then
            local text = L["OLDER_CHANGELOGS"] or ""
            text = string.gsub(text, "\r", "")
            content:SetText("<html><body>" .. text .. "</body></html>")
        elseif linkData == "recent" then
            local text = L["CHANGELOGS"] or ""
            text = string.gsub(text, "\r", "")
            content:SetText("<html><body>" .. text .. "</body></html>")
        end

        C_Timer.After(0, function()
            local height
            if content.GetContentHeight then
                height = Cell.Polyfill.GetContentHeight(content)
            else
                height = content:GetHeight()
                if height == 0 then
                    height = 400
                end
            end

            content:SetHeight(height)
            changelogsFrame.scrollFrame.content:SetHeight(height + 30)
            changelogsFrame.scrollFrame:ResetScroll()
        end)
    end)
end

function F.CheckWhatsNew(show)
    if show or CellDB["changelogsViewed"] ~= Cell.version then
        if not init then
            init = true
            CreateChangelogsFrame()
        end

        if changelogsFrame:IsShown() then
            changelogsFrame:Hide()
        else
            changelogsFrame:ClearAllPoints()
            changelogsFrame:SetPoint("CENTER")
            changelogsFrame:Show()
        end
    end
end