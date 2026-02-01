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

local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer", "CDMGroups_Essential", "CDMGroups_Utility" }
local function GetViewerIconBySpellId(spellID)
    if not spellID then return nil end

    for _, viewerName in ipairs(viewerTypes) do
        local viewerFrame = _G[viewerName]
        if viewerFrame then
            local spellIDCollection = CreateSpellIDCollection(spellID)

            local cooldownIcons = {viewerFrame:GetChildren()}
            for _, icon in ipairs(cooldownIcons) do
                if icon.Icon and icon.GetSpellID and icon.cooldownID then
                    local cooldownIDRelatedSpellID = GetSpellIDFromCooldownId(icon.cooldownID)
                    local iconSpellID = icon:GetSpellID()

                    if cooldownIDRelatedSpellID then
                        if spellIDCollection[cooldownIDRelatedSpellID] or spellIDCollection[iconSpellID] then
                            return icon
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

local function CreateOrGetTextureFrame(icon)
    if icon.HighlightTexture then
        return icon.HighlightTexture
    end

    local frame = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    frame:SetFrameLevel(icon:GetFrameLevel() + 10)
    frame:SetAllPoints(icon)

    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(frame)
    tex:SetAtlas("UI-HUD-ActionBar-IconFrame-Down", true)

    frame.texture = tex
    frame:Hide()

    icon.HighlightTexture = frame
    return frame
end

local function EnableTexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon)
    iconFrame:Show()
end

local function DisableTexture(icon)
    local iconFrame = CreateOrGetTextureFrame(icon)
    iconFrame:Hide()
end

hooksecurefunc("ActionButtonDown", function(id)
    local btn = _G["ActionButton" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = GetViewerIconBySpellId(spellID)
    if icon then
        EnableTexture(icon)
    end
end)

hooksecurefunc("ActionButtonUp", function(id)
    local btn = _G["ActionButton" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = GetViewerIconBySpellId(spellID)
    if icon then
        DisableTexture(icon)
    end
end)

hooksecurefunc("MultiActionButtonDown", function(bar, id)
    local btn = _G[bar .. "Button" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = GetViewerIconBySpellId(spellID)
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

