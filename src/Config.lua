local addonName, addon = ...
local verticalSpacing = 20
local horizontalSpacing = 40
local checkboxWidth = 150
---@type Db
local db
---@class Db
local dbDefaults = {
	Version = 1,

	ClassIcons = true,
	GroupOnly = true,

	OffsetX = 0,
	OffsetY = 0,

	IconTexture = "covenantsanctum-renown-doublearrow-depressed",
	IconWidth = 32,
	IconHeight = 32,
	IconRotation = 90,
	IconClassColors = true,
	IconDesaturated = true,
}

local M = {
	DbDefaults = dbDefaults,
}
addon.Config = M

local function CopyTable(src, dst)
	if type(dst) ~= "table" then
		dst = {}
	end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopyTable(v, dst[k])
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

local function ClampInt(v, minV, maxV, fallback)
	v = tonumber(v)
	if not v then
		return fallback
	end
	v = math.floor(v + 0.5)
	if v < minV then
		return minV
	end
	if v > maxV then
		return maxV
	end
	return v
end

local function CreateEditBox(parent, numeric, labelText, width, getValue, setValue)
	local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetText(labelText)

	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width or 80, 20)
	box:SetAutoFocus(false)

	if numeric then
		-- can't use SetNumeric(true) because it doesn't allow negatives
		box:SetScript("OnTextChanged", function(self, userInput)
			if not userInput then
				return
			end

			local text = self:GetText()

			-- allow: "", "-", "-123", "123"
			if text == "" or text == "-" or text:match("^%-?%d+$") then
				return
			end

			-- strip invalid chars
			text = text:gsub("[^%d%-]", "")
			-- only one leading '-'
			text = text:gsub("%-+", "-")

			if text:sub(1, 1) ~= "-" then
				text = text:gsub("%-", "")
			else
				text = "-" .. text:sub(2):gsub("%-", "")
			end

			self:SetText(text)
		end)
	end

	local function Commit()
		local new = box:GetText()

		setValue(new)

		box:SetText(tostring(getValue()))
		box:SetCursorPosition(0)
	end

	box:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		Commit()
	end)

	box:SetScript("OnEditFocusLost", Commit)

	function box:Refresh()
		box:SetText(tostring(getValue()))
		box:SetCursorPosition(0)
	end

	box:Refresh()

	return label, box
end

local function CreateSettingCheckbox(panel, setting)
	local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	checkbox.Text:SetText(" " .. setting.Name)
	checkbox.Text:SetFontObject("GameFontNormal")
	checkbox:SetChecked(setting.Enabled())
	checkbox:HookScript("OnClick", function()
		setting.OnChanged(checkbox:GetChecked())
	end)

	checkbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(setting.Name, 1, 0.82, 0)
		GameTooltip:AddLine(setting.Tooltip, 1, 1, 1, true)
		GameTooltip:Show()
	end)

	checkbox:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	function checkbox:Refresh()
		checkbox:SetChecked(setting.Enabled())
	end

	return checkbox
end

function CanOpenOptionsDuringCombat()
	if LE_EXPANSION_LEVEL_CURRENT == nil or LE_EXPANSION_MIDNIGHT == nil then
		return true
	end

	return LE_EXPANSION_LEVEL_CURRENT < LE_EXPANSION_MIDNIGHT
end

local function AddCategory(panel)
	if Settings then
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)

		return category
	elseif InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)

		return panel
	end

	return nil
end

function M:Init()
	MiniMarkersDB = MiniMarkersDB or {}
	db = CopyTable(dbDefaults, MiniMarkersDB)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = AddCategory(panel)

	if not category then
		return
	end

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOPLEFT", title, 0, -verticalSpacing)
	description:SetText("Show markers above nameplates.")

	local groupOnlyChkBox = CreateSettingCheckbox(panel, {
		Name = "Group only",
		Tooltip = "Only show markers for group members.",
		Enabled = function()
			return db.GroupOnly
		end,
		OnChanged = function(enabled)
			db.GroupOnly = enabled
			addon:Refresh()
		end,
	})

	groupOnlyChkBox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)

	local classIconsChkBox = CreateSettingCheckbox(panel, {
		Name = "Class Icons",
		Tooltip = "Use class icons, or when unchecked use a default arrow icon.",
		Enabled = function()
			return db.ClassIcons
		end,
		OnChanged = function(enabled)
			db.ClassIcons = enabled
			addon:Refresh()
		end,
	})

	classIconsChkBox:SetPoint("LEFT", groupOnlyChkBox, "RIGHT", checkboxWidth, 0)

	local textureLbl, textureBox = CreateEditBox(panel, false, "Texture", 400, function()
		return db.IconTexture
	end, function(value)
		if db.IconTexture == value then
			return
		end

		db.IconTexture = value
		addon:Refresh()
	end)

	textureLbl:SetPoint("TOPLEFT", groupOnlyChkBox, "BOTTOMLEFT", 0, -verticalSpacing)
	textureBox:SetPoint("TOPLEFT", textureLbl, "BOTTOMLEFT", 4, -8)

	local textureWidthLbl, textureWidthBox = CreateEditBox(panel, true, "Width", 50, function()
		return tonumber(db.IconWidth)
	end, function(value)
		if db.IconWidth == value then
			return
		end

		db.IconWidth = ClampInt(value, 1, 500, dbDefaults.IconWidth)
		addon:Refresh()
	end)

	textureWidthLbl:SetPoint("TOPLEFT", textureBox, "BOTTOMLEFT", -4, -verticalSpacing)
	textureWidthBox:SetPoint("TOPLEFT", textureWidthLbl, "BOTTOMLEFT", 4, -8)

	local textureHeightLbl, textureHeightBox = CreateEditBox(panel, true, "Height", 50, function()
		return tonumber(db.IconHeight)
	end, function(value)
		if db.IconHeight == value then
			return
		end

		db.IconHeight = ClampInt(value, 1, 500, dbDefaults.IconHeight)
		addon:Refresh()
	end)

	textureHeightLbl:SetPoint("LEFT", textureWidthBox, "RIGHT", horizontalSpacing, textureWidthBox:GetHeight() + 4)
	textureHeightBox:SetPoint("TOPLEFT", textureHeightLbl, "BOTTOMLEFT", 4, -8)

	local textureRotLbl, textureRotBox = CreateEditBox(panel, true, "Rotation (degrees)", 50, function()
		return tonumber(db.IconRotation)
	end, function(value)
		if db.IconRotation == value then
			return
		end

		db.IconRotation = ClampInt(value, 0, 360, 0)
		addon:Refresh()
	end)

	textureRotLbl:SetPoint("LEFT", textureHeightBox, "RIGHT", horizontalSpacing, textureHeightBox:GetHeight() + 4)
	textureRotBox:SetPoint("TOPLEFT", textureRotLbl, "BOTTOMLEFT", 4, -8)

	local offsetXLbl, offsetXBox = CreateEditBox(panel, true, "X Offset", 50, function()
		return tonumber(db.OffsetX)
	end, function(value)
		if db.OffsetX == value then
			return
		end

		db.OffsetX = ClampInt(value, -200, 200, 0)
		addon:Refresh()
	end)

	offsetXLbl:SetPoint("TOPLEFT", textureWidthBox, "BOTTOMLEFT", -4, -verticalSpacing)
	offsetXBox:SetPoint("TOPLEFT", offsetXLbl, "BOTTOMLEFT", 4, -8)

	local offsetYLbl, offsetYBox = CreateEditBox(panel, true, "Y Offset", 50, function()
		return tonumber(db.OffsetY)
	end, function(value)
		if db.OffsetY == value then
			return
		end

		db.OffsetY = ClampInt(value, -200, 200, 0)
		addon:Refresh()
	end)

	offsetYLbl:SetPoint("LEFT", offsetXBox, "RIGHT", horizontalSpacing, offsetXBox:GetHeight() + 4)
	offsetYBox:SetPoint("TOPLEFT", offsetYLbl, "BOTTOMLEFT", 4, -8)

	panel.Controls = {
		groupOnlyChkBox,
		classIconsChkBox,
		textureBox,
		textureWidthBox,
		textureHeightBox,
		textureRotBox,
		offsetXBox,
		offsetYBox,
	}

	function panel.Refresh()
		for _, c in ipairs(panel.Controls) do
			if c.Refresh then
				c:Refresh()
			end
		end
	end

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(120, 26)
	resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 16)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			addon:Notify("Can't reset during combat.")
			return
		end

		for k in pairs(db) do
			db[k] = nil
		end

		db = CopyTable(dbDefaults, db)
		MiniMarkersDB = db

		addon:Refresh()
		panel:Refresh()
		addon:Notify("Settings reset to default.")
	end)

	SLASH_MINIMARKERS1 = "/minimarkers"
	SLASH_MINIMARKERS2 = "/minim"
	SLASH_MINIMARKERS3 = "/mm"

	SlashCmdList.MINIMARKERS = function()
		if Settings and Settings.OpenToCategory then
			if not InCombatLockdown() or CanOpenOptionsDuringCombat() then
				Settings.OpenToCategory(category:GetID())
			else
				addon:Notify("Can't open options during combat.")
			end
		elseif InterfaceOptionsFrame_OpenToCategory then
			-- workaround the classic bug where the first call opens the Game interface
			-- and a second call is required
			InterfaceOptionsFrame_OpenToCategory(panel)
			InterfaceOptionsFrame_OpenToCategory(panel)
		end
	end
end
