local viewerTypes = { "EssentialCooldownViewer", "UtilityCooldownViewer" }
local function GetViewerIconBySpellId(spellID)
    print(spellID)
    if not spellID then return nil end

    for _, viewerName in ipairs(viewerTypes) do
        local viewerFrame = _G[viewerName]
        if viewerFrame then
            local cooldownIcons = {viewerFrame:GetChildren()}
            for _, icon in ipairs(cooldownIcons) do
                if icon.Icon and icon.cooldownID then

                    if icon.GetSpellID then
                        local spellIDFromIcon = icon:GetSpellID()

                        if spellIDFromIcon == spellID then
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

hooksecurefunc("ActionButtonDown", function(id)
    local btn = _G["ActionButton" .. id]
    local spellID = GetSpellIdFromButton(btn)
    local icon = GetViewerIconBySpellId(spellID)
    print(icon)
end)