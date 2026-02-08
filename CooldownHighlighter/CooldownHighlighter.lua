local CH = {}

local LAB = LibStub and LibStub("LibActionButton-1.0", true)
local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer", "CDMGroups_Essential", "CDMGroups_Utility" }
local pressedSpellByButton = {}

function CH:CreateSpellIDCollection(spellID)
    if not spellID then return nil end

    local collection = {}
    collection[spellID] = true

    local overrideSpell = C_Spell.GetOverrideSpell(spellID)
    local baseSpell = C_Spell.GetBaseSpell(spellID)

    if overrideSpell then collection[overrideSpell] = true end
    if baseSpell then collection[baseSpell] = true end
    return collection
end

local function GetSpellIDFromCooldownId(cooldownID)
    if not cooldownID then return nil end
    if type(cooldownID) ~= "number" then return nil end

    local cooldownIDInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if cooldownIDInfo.spellID then
        return cooldownIDInfo.spellID
    end
end

function CH:GetViewerIconBySpellId(spellID)
    if not spellID then return nil end

    local spellIDCollection = CH:CreateSpellIDCollection(spellID)
    if not spellIDCollection then return nil end

    for _, viewerName in ipairs(viewerTypes) do
        local viewerFrame = _G[viewerName]
        if viewerFrame then

            local cooldownIcons = {viewerFrame:GetChildren()}
            for _, icon in ipairs(cooldownIcons) do
                if icon.Icon and icon.cooldownID then
                    local cooldownIDRelatedSpellID = GetSpellIDFromCooldownId(icon.cooldownID)

                    if type(cooldownIDRelatedSpellID) == "number" and spellIDCollection[cooldownIDRelatedSpellID] then
                        return icon
                    end

                    if icon.GetSpellID then

                        -- pcall is returning boolean and the result of the handed function --
                        local isGetSpellIDSafe, iconSpellID = pcall(icon.GetSpellID, icon)

                        if isGetSpellIDSafe and iconSpellID ~= nil then

                            -- checking if indexing the sometimes secret getSpellID works before checking on it --
                            local isGetSpellIDIndexable, isSpellIdInCollection = pcall(function()
                                return spellIDCollection[iconSpellID]
                            end)

                            if isGetSpellIDIndexable and isSpellIdInCollection then
                                return icon
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

function CH:CreateOrGetTextureFrame(icon, style)
    if not icon then return nil end
    if icon.HighlightTexture then
        return icon.HighlightTexture
    end

    local frame = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    frame:SetFrameLevel(icon:GetFrameLevel() + 10)
    frame:SetAllPoints(icon)

    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(frame)

    if style == "ElvUI" then
        local ElvUI = _G.ElvUI[1]
        tex:SetTexture(ElvUI.media.blankTex)
        tex:SetBlendMode("ADD")
        tex:SetColorTexture(0.9, 0.8, 0.1, 0.3)
        if frame.SetInside then tex:SetInside() end
    else
        tex:SetAtlas("UI-HUD-ActionBar-IconFrame-Down", true)
    end


    frame.texture = tex
    frame:Hide()

    icon.HighlightTexture = frame
    return frame
end

function CH:ToggleHighlight(icon, show, style)
    if not icon then return end
    local textureFrame = self:CreateOrGetTextureFrame(icon, style)
    if show then textureFrame:Show() else textureFrame:Hide() end
end

function CH:ButtonPress(button, mouseButton, isDown, style)
    if not button then return end

    if isDown then
        local spellID = self:GetSpellIdFromButton(button)
        if not spellID then return end

        pressedSpellByButton[button] = spellID

        local icon = self:GetViewerIconBySpellId(spellID)
        if not icon then return end

        if style == "ElvUI" then
            self:ToggleHighlight(icon, isDown == true, style)
        else
            if mouseButton ~= "LeftButton" and mouseButton ~= "RightButton" then
                self:ToggleHighlight(icon, isDown == true, nil)
            end
        end
    else
        --[[
            macros are causing problems with action bar addons, if a modifier is used and released before postclick
            the determined spell id is then computed with the spell from the unmodified keypress, thus i look up the
            spell from pressedSpellByButton table
        ]]--
        local spellID = pressedSpellByButton[button]
        if not spellID then return end
        pressedSpellByButton[button] = nil

        local icon = self:GetViewerIconBySpellId(spellID)
        if not icon then return end

        if style == "ElvUI" then
            self:ToggleHighlight(icon, false, style)
        else
            if mouseButton ~= "LeftButton" and mouseButton ~= "RightButton" then
                self:ToggleHighlight(icon, false, nil)
            end
        end
    end
end

function CH:GetSpellIdFromButton(button)
    if not button or not button.action then return nil end

    local abilityType, id, _ = GetActionInfo(button.action)

    if abilityType == "spell" then
        return id
    elseif abilityType == "macro" then
        local macroName = GetActionText(button.action)
        return self:GetSpellIdFromMacroName(macroName)
    end
    return nil
end

function CH:GetSpellIdFromMacroName(macroName)
    if not macroName then return nil end
    local macroSpellID = GetMacroSpell(macroName)
    return macroSpellID or nil
end

function CH:HookCHToPreClick(button, style)
    button:HookScript("PreClick", function(self, mouseButton, down)
        CH:ButtonPress(self, mouseButton, down, style)
    end)
    button.IsCooldownHighlighterHooked = true
end

function CH:HookDominosButton(button)
    if not button then return end
    local function handler(_, mouseButton, down)
        CH:ButtonPress(button, mouseButton, down, nil)
    end
    if button.bind and not button.IsCooldownHighlighter_BindHooked then
        button.bind:HookScript("PreClick", handler)
        button.IsCooldownHighlighter_BindHooked = true
    end
    if not button.IsCooldownHighlighterHooked then
        self:HookCHToPreClick(button, nil)
    end
end

function CH:HookAllLABButtons()
    if not LAB or not LAB.activeButtons then return end

    for button in pairs(LAB.activeButtons) do
        if not button.IsCooldownHighlighterHooked then
            self:HookCHToPreClick(button, nil)
        end
    end
end

function CH:RegisterLABCallbacks()
    if not LAB then return end
    if LAB.__CooldownHighlighter_OnButtonUpdateRegistered then return end
    LAB.__CooldownHighlighter_OnButtonUpdateRegistered = true

    LAB:RegisterCallback("OnButtonUpdate", function(_, button)
        CH:HookCHToPreClick(button, nil)
    end)
end

function CH:RegisterElvUICallbacks()
    local ElvUI = _G.ElvUI and _G.ElvUI[1]
    if not ElvUI then return end
    local ElvUILAB = ElvUI.Libs and ElvUI.Libs.LAB
    if not ElvUILAB then return end
    ElvUILAB:RegisterCallback("OnButtonUpdate", function(_, button)
        CH:HookCHToPreClick(button, "ElvUI")
    end)
end

function CH:HookAllDominosButtons()
    local Dominos = _G.Dominos
    if not Dominos or not Dominos.ActionButtons or not Dominos.ActionButtons.GetAll then return end
    Dominos.RegisterCallback(Dominos, "LAYOUT_LOADED", function()
        for button in Dominos.ActionButtons:GetAll() do
            CH:HookDominosButton(button)
        end
    end)
end

local LABFrame = CreateFrame("Frame")
LABFrame:RegisterEvent("PLAYER_LOGIN")
LABFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LABFrame:SetScript("OnEvent", function()
    if not LAB then return end
    CH:RegisterLABCallbacks()
    CH:HookAllLABButtons()
end)

local DominosFrame = CreateFrame("Frame")
DominosFrame:RegisterEvent("ADDON_LOADED")
DominosFrame:SetScript("OnEvent", function(_, event, argument)
    if event == "ADDON_LOADED" and argument == "Dominos" then
        CH:HookAllDominosButtons()
    end
end)

local ElvUIFrame = CreateFrame("Frame")
ElvUIFrame:RegisterEvent("ADDON_LOADED")
ElvUIFrame:SetScript("OnEvent", function(_, event, argument)
    if event == "ADDON_LOADED" and argument == "ElvUI" then
        CH:RegisterElvUICallbacks()
    end
end)

function CH:DefaultButtonPress(btn, isDown)
    local spellID = CH:GetSpellIdFromButton(btn)
    local icon = CH:GetViewerIconBySpellId(spellID)
    if icon then
        CH:ToggleHighlight(icon, isDown)
    end
end

hooksecurefunc("ActionButtonDown", function(id)
    CH:DefaultButtonPress(_G["ActionButton" .. id], true)
end)

hooksecurefunc("ActionButtonUp", function(id)
    CH:DefaultButtonPress(_G["ActionButton" .. id], false)
end)

hooksecurefunc("MultiActionButtonDown", function(bar, id)
    CH:DefaultButtonPress(_G[bar .. "Button" .. id], true)
end)

hooksecurefunc("MultiActionButtonUp", function(bar, id)
    CH:DefaultButtonPress(_G[bar .. "Button" .. id], false)
end)
