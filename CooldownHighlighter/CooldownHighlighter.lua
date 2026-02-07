local CH = {}

local LAB = LibStub and LibStub("LibActionButton-1.0", true)
local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer", "CDMGroups_Essential", "CDMGroups_Utility" }

local function CreateSpellIDCollection(spellID)
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

    local cooldownIDInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    if cooldownIDInfo.spellID then
        return cooldownIDInfo.spellID
    end
end

function CH:GetViewerIconBySpellId(spellID)
    if not spellID then return nil end

    local spellIDCollection = CreateSpellIDCollection(spellID)
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
end

local function GetSpellIdFromMacroName(macroName)
    if not macroName then return nil end

    local macroSpellID = GetMacroSpell(macroName)

    if macroSpellID then return macroSpellID
    end
end

local function GetSpellIdFromButton(btn)
    if not btn or not btn.action then return nil end

    local abilityType, id, subType = GetActionInfo(btn.action)

    if abilityType == "spell" then
        return id
    elseif abilityType == "macro" then
        local macroName = GetActionText(btn.action)
        return GetSpellIdFromMacroName(macroName)
    end
    return nil
end

local function CreateOrGetTextureFrame(icon, isElvUI)
    if not icon then return nil end
    if icon.HighlightTexture then
        return icon.HighlightTexture
    end

    local frame = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    frame:SetFrameLevel(icon:GetFrameLevel() + 10)
    frame:SetAllPoints(icon)

    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(frame)

    if isElvUI then
        local E = _G.ElvUI[1]
        tex:SetTexture(E.media.blankTex)
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

local function EnableTexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon, false)
    iconFrame:Show()
end

local function DisableTexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon, false)
    iconFrame:Hide()
end

local function EnableElvUITexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon, true)
    iconFrame:Show()
end

local function DisableElvUITexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon, true)
    iconFrame:Hide()
end

local function OnThirdPartyButtonPress(btn, key, isDown)
    local spellID = GetSpellIdFromButton(btn)
    local icon = CH.GetViewerIconBySpellId(spellID)

    if not icon then
        return
    end

    if key ~= "LeftButton" and key ~= "RightButton" and isDown == true then
        EnableTexture(icon)
    elseif key ~= "LeftButton" and key ~= "RightButton" and isDown == false then
        DisableTexture(icon)
    end
end

local function OnElvUIButtonPress(btn, key, isDown)
    local spellID = GetSpellIdFromButton(btn)
    local icon = CH.GetViewerIconBySpellId(spellID)

    if not icon then
        return
    end

    if isDown == true then
        EnableElvUITexture(icon)
    elseif isDown == false then
        DisableElvUITexture(icon)
    end
end

local function HookCooldownHighlighterToLABButton(button)
    button:HookScript("PreClick", function(self, mouseButton, down)
        OnThirdPartyButtonPress(self, mouseButton, down)
    end)
end

local function HookCooldownHighlighterToElvUIButton(button)
    button:HookScript("PreClick", function(self, mouseButton, down)
        OnElvUIButtonPress(self, mouseButton, down)
    end)
end

local function HookCooldownHighlighterToDominosButton(button)
    local function handle(self, mouseButton, down)
        OnThirdPartyButtonPress(button, mouseButton, down)
    end

    if button.bind and not button.IsCooldownHighlighter_BindHooked then
        button.bind:HookScript("PreClick", handle)
        button.IsCooldownHighlighter_BindHooked = true
    end
end

local function HookAllLABButtons()
    if not LAB or not LAB.GetAllButtons then
        return
    end

    local allButtons = LAB.activeButtons
    if not allButtons then
        return
    end

    for button in pairs(allButtons) do
        if not button.IsCooldownHighlighterHooked then
            HookCooldownHighlighterToLABButton(button)
            button.IsCooldownHighlighterHooked = true
        end
    end
end

local function HookAllDominosButtons()
    local Dominos = _G.Dominos

    Dominos.RegisterCallback(Dominos, "LAYOUT_LOADED", function()
        for button in Dominos.ActionButtons:GetAll() do
            if not button.IsCooldownHighlighterHooked then
                HookCooldownHighlighterToDominosButton(button)
                button.IsCooldownHighlighterHooked = true
            end
        end
    end)
end

local function OnLABButtonUpdate(event, button)
    if not button or button.IsCooldownHighlighterHooked then return end
    HookCooldownHighlighterToLABButton(button)
    button.IsCooldownHighlighterHooked = true
end

local function OnElvUIButtonUpdate(event, button)
    if not button or button.IsCooldownHighlighterHooked then return end
    HookCooldownHighlighterToElvUIButton(button)
    button.IsCooldownHighlighterHooked = true
end

local function RegisterLABCallbacks()
    if LAB.__CooldownHighlighter_OnButtonUpdateRegistered then return end
    LAB.__CooldownHighlighter_OnButtonUpdateRegistered = true

    LAB:RegisterCallback("OnButtonUpdate", OnLABButtonUpdate)
end

local function RegisterElvUICallbacks()
    local ElvUI = _G.ElvUI and _G.ElvUI[1]
    if not ElvUI then return end

    local ElvUILibActionButtons = ElvUI.Libs and ElvUI.Libs.LAB
    if not ElvUILibActionButtons then return end

    ElvUILibActionButtons:RegisterCallback("OnButtonUpdate", OnElvUIButtonUpdate)

end

local LABFrame = CreateFrame("Frame")
LABFrame:RegisterEvent("PLAYER_LOGIN")
LABFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LABFrame:SetScript("OnEvent", function()
    if not LAB then
        return
    end
    RegisterLABCallbacks()
    -- initial button hooking for LAB --
    HookAllLABButtons()
end)

local DominosFrame = CreateFrame("Frame")
DominosFrame:RegisterEvent("PLAYER_LOGIN")
DominosFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
DominosFrame:RegisterEvent("ADDON_LOADED")
DominosFrame:SetScript("OnEvent", function(self, event, argument)
    if event == "ADDON_LOADED" and argument == "Dominos" then
        HookAllDominosButtons()
    end
end)

local ElvUIFrame = CreateFrame("Frame")
ElvUIFrame:RegisterEvent("PLAYER_LOGIN")
ElvUIFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
ElvUIFrame:RegisterEvent("ADDON_LOADED")
ElvUIFrame:SetScript("OnEvent", function(self, event, argument)
    if event == "ADDON_LOADED" and argument == "ElvUI" then
        RegisterElvUICallbacks()
    end
end)

hooksecurefunc("ActionButtonDown", function(id)
    local btn = _G["ActionButton" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = CH.GetViewerIconBySpellId(spellID)
    if icon then
        EnableTexture(icon)
    end
end)

hooksecurefunc("ActionButtonUp", function(id)
    local btn = _G["ActionButton" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = CH.GetViewerIconBySpellId(spellID)
    if icon then
        DisableTexture(icon)
    end
end)

hooksecurefunc("MultiActionButtonDown", function(bar, id)
    local btn = _G[bar .. "Button" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = CH.GetViewerIconBySpellId(spellID)
    if icon then
        EnableTexture(icon)
    end
end)

hooksecurefunc("MultiActionButtonUp", function(bar, id)
    local btn = _G[bar .. "Button" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = GetViewerIconBySpellId(spellID)
    if icon then
        DisableTexture(icon)
    end
end)

