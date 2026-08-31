---@class LapidaryKitFrame
---@field private table
local LapidaryKitFrame = LapidaryLoader:CreateModule("LapidaryKitFrame")
local private = LapidaryKitFrame.private

---@type LapidaryKits
local LapidaryKits = LapidaryLoader:ImportModule("LapidaryKits")
---@type LapidaryVendorFrame
local LapidaryVendorFrame = LapidaryLoader:ImportModule("LapidaryVendorFrame")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryFavorites
local LapidaryFavorites = LapidaryLoader:ImportModule("LapidaryFavorites")
---@type LapidarySkin
local LapidarySkin = LapidaryLoader:ImportModule("LapidarySkin")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PADDING = 12
local COLUMN_WIDTH = 253
local COLUMN_GAP = 10
local WIDTH = PADDING * 2 + COLUMN_WIDTH * 2 + COLUMN_GAP
local ROW_HEIGHT = 24
local HEADER_HEIGHT = 18
local GROUP_GAP = 10
local ICON = 18
local GAP_FROM_MERCHANT = 12
local STEP_WIDTH = 16
local STEP_BIG = 10

local CONTROLS_Y = -34
local SUMMARY_Y = -62
local BUY_Y = -84
local GROUPS_TOP = -112

local COLUMNS = {
    { "primary", "secondary" },
    { "hybrid", "tank" },
}

local function createSmallButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 18)
    button:RegisterForClicks("LeftButtonUp")
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    button:SetFontString(label)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(1, 1, 1, 0.15)
    local highlight = button:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    highlight:SetTexture(1, 1, 1, 0.25)
    button:SetHighlightTexture(highlight)
    return button
end

---A row for one gem: icon, name and a [-] count [+] stepper on the right.
---@param frame table
---@param entry LapidaryGemEntry
---@return table
local function createRow(frame, entry)
    local row = CreateFrame("Button", nil, frame)
    row:SetSize(COLUMN_WIDTH, ROW_HEIGHT)
    row:EnableMouse(true)

    row.gemId = entry.id
    row.gemUpgradeId = entry.upgradeId
    row.offeredId = LapidaryMerchant:GetDisplayItemId(entry.id, entry.upgradeId)
    row.labelKey = entry.key

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(1, 1, 1, 0.12)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON, ICON)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexture(GetItemIcon(row.offeredId))
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.plus = createSmallButton(row, "+", STEP_WIDTH)
    row.plus:SetPoint("RIGHT", -2, 0)
    row.plus:SetScript("OnClick", function()
        local kit = LapidaryKits:GetActive()
        local source = kit and LapidaryFavorites:FindEntry(row.gemId)

        if kit and source then
            LapidaryKits:AddGem(kit, source, IsShiftKeyDown() and STEP_BIG or 1)
            LapidaryKitFrame:Refresh()
        end
    end)
    row.plus:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row.plus, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_STEP_ADD)
        GameTooltip:AddLine(format(L.KIT_STEP_ADD_BIG, STEP_BIG), 1, 1, 1)
        GameTooltip:Show()
    end)
    row.plus:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.count:SetPoint("RIGHT", row.plus, "LEFT", -2, 0)
    row.count:SetJustifyH("RIGHT")

    row.minus = createSmallButton(row, "-", STEP_WIDTH)
    row.minus:SetPoint("RIGHT", row.count, "LEFT", -2, 0)
    row.minus:SetScript("OnClick", function()
        local kit = LapidaryKits:GetActive()
        local source = kit and LapidaryFavorites:FindEntry(row.gemId)

        if kit and source then
            LapidaryKits:RemoveGem(kit, source, IsShiftKeyDown() and STEP_BIG or 1)
            LapidaryKitFrame:Refresh()
        end
    end)
    row.minus:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row.minus, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_STEP_REMOVE)
        GameTooltip:AddLine(format(L.KIT_STEP_REMOVE_BIG, STEP_BIG), 1, 1, 1)
        GameTooltip:Show()
    end)
    row.minus:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", ICON + 6, 0)
    row.label:SetPoint("RIGHT", row.minus, "LEFT", -4, 0)
    row.label:SetJustifyH("LEFT")
    local fontPath, fontSize, fontFlags = row.label:GetFont()
    row.label:SetFont(fontPath, fontSize - 1, fontFlags)

    row:SetScript("OnEnter", function()
        row.highlight:Show()
        local kit = LapidaryKits:GetActive()
        if not kit then
            return
        end
        local offeredId = LapidaryMerchant:GetDisplayItemId(row.gemId, row.gemUpgradeId)
        row.offeredId = offeredId
        local item = LapidaryKits:GetItem(kit, row.offeredId)
        local owned = LapidaryKits:GetOwned(item or { id = row.offeredId }, row.offeredId)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. row.offeredId)
        GameTooltip:AddLine(" ")
        if item then
            local missing = math.max(0, item.count - owned)
            GameTooltip:AddLine(format(L.KIT_ROW_OWNED, item.count, owned), 1, 1, 1)
            if missing > 0 then
                GameTooltip:AddLine(format(L.KIT_ROW_MISSING, missing), 1, 0.82, 0)
            else
                GameTooltip:AddLine(L.KIT_NO_MISSING, 0.2, 1, 0.3)
            end
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        row.highlight:Hide()
        GameTooltip:Hide()
    end)

    return row
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryKitPanel", UIParent)
    local anchor = LapidaryVendorFrame:GetFrame()
    if anchor then
        frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", GAP_FROM_MERCHANT, 0)
    else
        frame:SetPoint("TOPRIGHT", MerchantFrame, "TOPLEFT", -GAP_FROM_MERCHANT, 0)
    end
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame.rows = {}

    LapidarySkin:Frame(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L.KIT_TITLE)

    frame.del = createSmallButton(frame, "x", 22)
    frame.del:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, CONTROLS_Y)
    frame.del:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.del, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_DELETE)
        GameTooltip:Show()
    end)
    frame.del:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.del:SetScript("OnClick", function()
        local index = LapidaryKits:GetActiveIndex()
        if index and LapidaryKits:Delete(index) then
            LapidaryKitFrame:Refresh()
        end
    end)

    frame.picker = CreateFrame("Button", "LapidaryKitDropDown", frame)
    frame.picker:SetSize(120, 18)
    frame.picker:SetPoint("TOPLEFT", frame.del, "TOPRIGHT", 4, 0)
    frame.picker:RegisterForClicks("LeftButtonUp")
    frame.picker:EnableMouse(true)
    frame.picker.bg = frame.picker:CreateTexture(nil, "BACKGROUND")
    frame.picker.bg:SetAllPoints()
    frame.picker.bg:SetTexture(0, 0, 0, 0.75)
    frame.picker.borderTop = frame.picker:CreateTexture(nil, "BORDER")
    frame.picker.borderTop:SetPoint("TOPLEFT")
    frame.picker.borderTop:SetPoint("TOPRIGHT")
    frame.picker.borderTop:SetHeight(1)
    frame.picker.borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.picker.borderTop:SetVertexColor(0.3, 0.3, 0.3, 1)
    frame.picker.borderBottom = frame.picker:CreateTexture(nil, "BORDER")
    frame.picker.borderBottom:SetPoint("BOTTOMLEFT")
    frame.picker.borderBottom:SetPoint("BOTTOMRIGHT")
    frame.picker.borderBottom:SetHeight(1)
    frame.picker.borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.picker.borderBottom:SetVertexColor(0.3, 0.3, 0.3, 1)
    frame.picker.borderLeft = frame.picker:CreateTexture(nil, "BORDER")
    frame.picker.borderLeft:SetPoint("TOPLEFT", 0, -1)
    frame.picker.borderLeft:SetPoint("BOTTOMLEFT", 0, 1)
    frame.picker.borderLeft:SetWidth(1)
    frame.picker.borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.picker.borderLeft:SetVertexColor(0.3, 0.3, 0.3, 1)
    frame.picker.borderRight = frame.picker:CreateTexture(nil, "BORDER")
    frame.picker.borderRight:SetPoint("TOPRIGHT", 0, -1)
    frame.picker.borderRight:SetPoint("BOTTOMRIGHT", 0, 1)
    frame.picker.borderRight:SetWidth(1)
    frame.picker.borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.picker.borderRight:SetVertexColor(0.3, 0.3, 0.3, 1)
    frame.picker.text = frame.picker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.picker.text:SetPoint("LEFT", 2, 0)
    frame.picker.text:SetPoint("RIGHT", -20, 0)
    frame.picker.text:SetJustifyH("CENTER")
    if frame.picker.text.SetWordWrap then
        frame.picker.text:SetWordWrap(false)
    end
    frame.picker.arrow = CreateFrame("Button", nil, frame.picker)
    frame.picker.arrow:SetSize(16, 16)
    frame.picker.arrow:SetPoint("RIGHT", -1, 0)
    local arrowText = frame.picker.arrow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrowText:SetPoint("CENTER", 0, 1)
    arrowText:SetText("v")
    frame.picker.arrow:EnableMouse(false)
    frame.pickerMenu = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    frame.pickerMenu:SetSize(1, 1)
    frame.pickerMenu:SetPoint("TOPLEFT", frame.picker, "TOPLEFT")
    frame.pickerMenu:SetAlpha(0)
    frame.pickerMenu:EnableMouse(false)
    for _, child in ipairs({ frame.pickerMenu:GetChildren() }) do
        child:EnableMouse(false)
        child:Hide()
    end
    frame.picker:SetScript("OnClick", function(self)
        if self.menuOpen then
            self.menuOpen = false
            CloseDropDownMenus()
            return
        end
        self.menuOpen = true
        ToggleDropDownMenu(1, nil, frame.pickerMenu, frame.picker, 0, 0)
    end)
    frame.picker:SetScript("OnEnter", function(self)
        self.bg:SetTexture(0.08, 0.08, 0.08, 0.9)
    end)
    frame.picker:SetScript("OnLeave", function(self)
        self.bg:SetTexture(0, 0, 0, 0.75)
    end)
    frame.pickerMenu:SetScript("OnHide", function()
        frame.picker.menuOpen = false
    end)
    UIDropDownMenu_Initialize(frame.pickerMenu, function()
        local kits = LapidaryKits:Get()
        local active = LapidaryKits:GetActiveIndex()
        local added = false
        for index, kit in ipairs(kits) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = kit.name
            info.checked = (index == active)
            info.func = function()
                frame.picker.menuOpen = false
                LapidaryKits:SetActive(index)
                LapidaryKitFrame:Refresh()
            end
            UIDropDownMenu_AddButton(info)
            added = true
        end
        if not added then
            local info = UIDropDownMenu_CreateInfo()
            info.text = L.KIT_NONE
            info.disabled = true
            UIDropDownMenu_AddButton(info)
        end
    end)
    frame.nameBox = CreateFrame("EditBox", nil, frame)
    frame.nameBox:SetSize(190, 18)
    frame.nameBox:SetFontObject("GameFontNormalSmall")
    frame.nameBox:SetAutoFocus(false)
    frame.nameBox:SetMaxLetters(40)
    frame.nameBox:SetTextInsets(4, 4, 0, 0)
    frame.nameBox:SetPoint("TOPLEFT", frame.picker, "TOPRIGHT", 2, 0)
    local nameBg = frame.nameBox:CreateTexture(nil, "BACKGROUND")
    nameBg:SetAllPoints()
    nameBg:SetTexture(0, 0, 0, 0.5)
    frame.nameBox:SetScript("OnEnterPressed", function(self)
        local kit = LapidaryKits:GetActive()
        if kit then
            LapidaryKits:SetName(kit, self:GetText())
            self:SetText(kit.name)
        end
        self:ClearFocus()
        LapidaryKitFrame:Refresh()
    end)

    frame.rename = createSmallButton(frame, "R", 22)
    frame.rename:SetPoint("TOPLEFT", frame.nameBox, "TOPRIGHT", 4, 0)
    frame.rename:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.rename, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_RENAME)
        GameTooltip:Show()
    end)
    frame.rename:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.rename:SetScript("OnClick", function()
        local kit = LapidaryKits:GetActive()
        if kit then
            frame.nameBox:SetText(kit.name)
            frame.nameBox:SetFocus()
            frame.nameBox:HighlightText()
        end
    end)

    frame.add = createSmallButton(frame, "+", 22)
    frame.add:SetPoint("TOPLEFT", frame.rename, "TOPRIGHT", 4, 0)
    frame.add:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.add, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_NEW)
        GameTooltip:Show()
    end)
    frame.add:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.add:SetScript("OnClick", function()
        LapidaryKits:Create(L.KIT_DEFAULT_NAME)
        LapidaryKitFrame:Refresh()
    end)

    frame.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.summary:SetPoint("TOPLEFT", PADDING, SUMMARY_Y)
    frame.summary:SetJustifyH("LEFT")
    frame.summary:SetTextColor(1, 0.82, 0)

    frame.buyAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.buyAll:SetSize(WIDTH - PADDING * 2, 22)
    frame.buyAll:SetPoint("TOPLEFT", PADDING, BUY_Y)
    LapidarySkin:Button(frame.buyAll)
    frame.buyAll:SetScript("OnClick", function()
        local kit = LapidaryKits:GetActive()
        if not (kit and LapidaryMerchant:IsCuttingVendor()) then
            return
        end
        frame.buyAll:Disable()
        local started = LapidaryKits:Buy(kit, function()
            LapidaryKitFrame:Refresh()
        end)
        if not started then
            LapidaryKitFrame:Refresh()
        end
    end)

    local top = GROUPS_TOP
    local lowest = top
    local y = top
    for columnIndex = 1, #COLUMNS do
        local x = PADDING + (columnIndex - 1) * (COLUMN_WIDTH + COLUMN_GAP)
        y = top
        for _, groupKey in ipairs(COLUMNS[columnIndex]) do
            local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            header:SetText(L[LapidaryConstants.GROUP_TITLE_KEYS[groupKey]])
            header:SetJustifyH("LEFT")
            header:SetTextColor(1, 0.82, 0)
            header:SetPoint("TOPLEFT", x, y)
            y = y - HEADER_HEIGHT

            for _, entry in ipairs(LapidaryConstants.GEM_GROUPS[groupKey]) do
                local row = createRow(frame, entry)
                row:SetPoint("TOPLEFT", x, y)
                frame.rows[#frame.rows + 1] = row
                y = y - ROW_HEIGHT
            end
            y = y - GROUP_GAP
        end
        if y < lowest then
            lowest = y
        end
    end

    frame:SetWidth(WIDTH)
    frame:SetHeight(math.abs(lowest) + PADDING)

    return frame
end

function LapidaryKitFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end

    local kit = LapidaryKits:GetActive()

    if not kit then
        if not frame.nameBox:HasFocus() then
            frame.nameBox:SetText("")
        end
        frame.picker.text:SetText(L.KIT_NONE_SHORT)
        frame.summary:SetText("")
        frame.buyAll:Disable()
        frame.buyAll:SetText(L.KIT_NONE)

        for _, row in ipairs(frame.rows) do
            row.minus:Disable()
            row.minus:SetAlpha(0.3)
            row.count:SetText("")
            row.count:SetTextColor(0.6, 0.6, 0.6)
        end
        return
    end

    if not frame.nameBox:HasFocus() then
        frame.nameBox:SetText(kit.name)
    end
    frame.picker.text:SetText(kit.name)

    local need, _, missing = LapidaryKits:GetTotals(kit)
    frame.summary:SetText(format(L.KIT_SUMMARY, need, missing))

    if missing > 0 then
        frame.buyAll:Enable()
        frame.buyAll:SetText(format(L.KIT_BUY_ALL_FMT, missing))
    else
        frame.buyAll:Disable()
        frame.buyAll:SetText(L.KIT_COMPLETE)
    end

    for _, row in ipairs(frame.rows) do
        local offeredId = LapidaryMerchant:GetDisplayItemId(row.gemId, row.gemUpgradeId)
        row.offeredId = offeredId
        local item = LapidaryKits:GetItem(kit, row.offeredId)
        local count = item and item.count or 0
        row.count:SetText(count > 0 and tostring(count) or "")

        if count > 0 then
            local itemMissing = LapidaryKits:GetMissing(item, row.offeredId)
            if itemMissing > 0 then
                row.count:SetTextColor(1, 0.82, 0)
            else
                row.count:SetTextColor(0.2, 1, 0.3)
            end
            row.minus:Enable()
            row.minus:SetAlpha(1)
        else
            row.count:SetTextColor(0.6, 0.6, 0.6)
            row.minus:Disable()
            row.minus:SetAlpha(0.3)
        end

        local stats = LapidaryMerchant:GetStatText(row.offeredId)
        row.label:SetText(stats or L[row.labelKey] or GetItemInfo(row.offeredId) or "?")
        row.icon:SetTexture(GetItemIcon(row.offeredId))
    end
end

---@return boolean
function LapidaryKitFrame:IsShown()
    return private.frame ~= nil and private.frame:IsShown()
end

---Opens the editor when the gem vendor is open and the frame is hidden,
---otherwise closes it. Never shown automatically with the merchant.
---@return boolean @True when the frame is shown after the toggle
function LapidaryKitFrame:Toggle()
    if self:IsShown() then
        self:Hide()
        return false
    end
    if not LapidaryMerchant:IsCuttingVendor() then
        return false
    end
    if not private.frame then
        private.frame = createFrame()
    end
    private.frame:Show()
    self:Refresh()
    return true
end

function LapidaryKitFrame:Hide()
    if private.frame then
        private.frame:Hide()
    end
end