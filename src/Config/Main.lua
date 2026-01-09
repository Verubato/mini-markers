local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local config = addon.Config
local verticalSpacing = 14
local horizontalSpacing = 20
local leftInset = horizontalSpacing
local rightInset = horizontalSpacing
---@class Db
local dbDefaults = config.DbDefaults
local M = {}
addon.Config.Panels.Main = M

function M:Build()
	---@type Db
	local db = addon.DB
	local columns = 4
	local settingsWidth, _ = mini:SettingsSize()
	local usableWidth = settingsWidth - leftInset - rightInset
	local columnStep = usableWidth / (columns + 1)

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOP", title, "BOTTOM", 0, -verticalSpacing / 2)
	description:SetText("Show markers above nameplates.")

	local priority = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	priority:SetPoint("TOP", description, "BOTTOM", 0, -verticalSpacing / 2)
	priority:SetText("Priority: spec > class > role > texture.")

	local friendlyTypesDivider = mini:CreateDivider(panel, "Friendly Icon Types")

	friendlyTypesDivider:SetPoint("TOP", priority, "BOTTOM", 0, -verticalSpacing)
	friendlyTypesDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	friendlyTypesDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local classIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Class Icons",
		Tooltip = "Use special high quality class icons.",
		GetValue = function()
			return db.FriendlyClassIcons
		end,
		SetValue = function(enabled)
			db.FriendlyClassIcons = enabled
			addon:Refresh()
		end,
	})

	classIconsChkBox:SetPoint("TOP", friendlyTypesDivider, "BOTTOM", 0, -verticalSpacing / 2)
	classIconsChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local specIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Spec Icons",
		Tooltip = "Use spec icons. Requires FrameSort for this to work.",
		GetValue = function()
			return db.FriendlySpecIcons
		end,
		SetValue = function(enabled)
			if enabled and not (FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector) then
				mini:ShowDialog("Spec icons requires FrameSort 7.8.1+ to function.")
				return
			end

			db.FriendlySpecIcons = enabled
			addon:Refresh()
		end,
	})

	specIconsChkBox:SetPoint("LEFT", classIconsChkBox, "RIGHT", columnStep, 0)

	local roleIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Role Icons",
		Tooltip = "Use tank/healer/dps role icons.",
		GetValue = function()
			return db.FriendlyRoleIcons
		end,
		SetValue = function(enabled)
			db.FriendlyRoleIcons = enabled
			addon:Refresh()
		end,
	})

	roleIconsChkBox:SetPoint("LEFT", specIconsChkBox, "RIGHT", columnStep, 0)

	local textureIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Texture Icons",
		Tooltip = "Use the specified texture for icons.",
		GetValue = function()
			return db.FriendlyTextureIcons
		end,
		SetValue = function(enabled)
			db.FriendlyTextureIcons = enabled
			addon:Refresh()
		end,
	})

	textureIconsChkBox:SetPoint("LEFT", roleIconsChkBox, "RIGHT", columnStep, 0)

	local enemyTypesDivider = mini:CreateDivider(panel, "Enemy Icon Types")

	enemyTypesDivider:SetPoint("TOP", textureIconsChkBox, "BOTTOM", 0, -verticalSpacing)
	enemyTypesDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	enemyTypesDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local enemyClassIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Class Icons",
		Tooltip = "Use special high quality class icons.",
		GetValue = function()
			return db.EnemyClassIcons
		end,
		SetValue = function(enabled)
			db.EnemyClassIcons = enabled
			addon:Refresh()
		end,
	})

	enemyClassIconsChkBox:SetPoint("TOP", enemyTypesDivider, "BOTTOM", 0, -verticalSpacing / 2)
	enemyClassIconsChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local enemySpecIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Spec Icons",
		Tooltip = "Use spec icons. Requires FrameSort for this to work.",
		GetValue = function()
			return db.EnemySpecIcons
		end,
		SetValue = function(enabled)
			if enabled and not (FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector) then
				mini:ShowDialog("Spec icons requires FrameSort 7.8.1+ to function.")
				return
			end

			db.EnemySpecIcons = enabled
			addon:Refresh()
		end,
	})

	enemySpecIconsChkBox:SetPoint("LEFT", enemyClassIconsChkBox, "RIGHT", columnStep, 0)

	local enemyRoleIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Role Icons",
		Tooltip = "Use tank/healer/dps role icons.",
		GetValue = function()
			return db.EnemyRoleIcons
		end,
		SetValue = function(enabled)
			db.EnemyRoleIcons = enabled
			addon:Refresh()
		end,
	})

	enemyRoleIconsChkBox:SetPoint("LEFT", enemySpecIconsChkBox, "RIGHT", columnStep, 0)

	local enemyTextureIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Texture Icons",
		Tooltip = "Use the specified texture for icons.",
		GetValue = function()
			return db.EnemyTextureIcons
		end,
		SetValue = function(enabled)
			db.EnemyTextureIcons = enabled
			addon:Refresh()
		end,
	})

	enemyTextureIconsChkBox:SetPoint("LEFT", enemyRoleIconsChkBox, "RIGHT", columnStep, 0)

	local filtersDivider = mini:CreateDivider(panel, "Filters")

	filtersDivider:SetPoint("TOP", enemyClassIconsChkBox, "BOTTOM", 0, -verticalSpacing / 2)
	filtersDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	filtersDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local everyoneChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Everyone",
		Tooltip = "Show markers for everyone.",
		GetValue = function()
			return db.EveryoneEnabled
		end,
		SetValue = function(enabled)
			db.EveryoneEnabled = enabled
			addon:Refresh()
		end,
	})

	everyoneChkBox:SetPoint("TOP", filtersDivider, "BOTTOM", 0, -verticalSpacing / 2)
	everyoneChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local groupChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Group",
		Tooltip = "Show markers for group members.",
		GetValue = function()
			return db.GroupEnabled
		end,
		SetValue = function(enabled)
			db.GroupEnabled = enabled
			addon:Refresh()
		end,
	})

	groupChkBox:SetPoint("LEFT", everyoneChkBox, "RIGHT", columnStep, 0)

	local alliesChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Allies",
		Tooltip = "Show markers for friendly players.",
		GetValue = function()
			return db.AlliesEnabled
		end,
		SetValue = function(enabled)
			db.AlliesEnabled = enabled
			addon:Refresh()
		end,
	})

	alliesChkBox:SetPoint("LEFT", groupChkBox, "RIGHT", columnStep, 0)

	local enemiesChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Enemies",
		Tooltip = "Show markers for enemy players.",
		GetValue = function()
			return db.EnemiesEnabled
		end,
		SetValue = function(enabled)
			db.EnemiesEnabled = enabled
			addon:Refresh()
		end,
	})

	enemiesChkBox:SetPoint("LEFT", alliesChkBox, "RIGHT", columnStep, 0)

	local npcsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "NPCs",
		Tooltip = "Show markers for NPCs.",
		GetValue = function()
			return db.NpcsEnabled
		end,
		SetValue = function(enabled)
			db.NpcsEnabled = enabled
			addon:Refresh()
		end,
	})

	npcsChkBox:SetPoint("TOPLEFT", everyoneChkBox, "BOTTOMLEFT", 0, -verticalSpacing / 4)

	local petsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Pets",
		Tooltip = "Show markers for pets.",
		GetValue = function()
			return db.PetsEnabled
		end,
		SetValue = function(enabled)
			db.PetsEnabled = enabled
			addon:Refresh()
		end,
	})

	petsChkBox:SetPoint("LEFT", npcsChkBox, "RIGHT", columnStep, 0)

	local sizeDivider = mini:CreateDivider(panel, "Size & Position & Background")

	sizeDivider:SetPoint("TOP", petsChkBox, "BOTTOM", 0, -verticalSpacing / 2)
	sizeDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	sizeDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local backgroundChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Background",
		Tooltip = "Add a background behind the icons.",
		GetValue = function()
			return db.BackgroundEnabled
		end,
		SetValue = function(enabled)
			db.BackgroundEnabled = enabled
			addon:Refresh()
		end,
	})

	backgroundChkBox:SetPoint("TOP", sizeDivider, "BOTTOM", 0, -verticalSpacing / 2)
	backgroundChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	-- not sure why it needs horizontalSpacing / 2, would have thought just horizontalSpacing itself should do it
	local sliderWidth = (usableWidth / 2) - horizontalSpacing / 2
	local sizeSlider, textureSizeBox = mini:CreateSlider({
		Parent = panel,
		LabelText = "Size",
		Min = 20,
		Max = 200,
		Step = 5,
		Width = sliderWidth,
		GetValue = function()
			return tonumber(db.IconWidth) or dbDefaults.IconWidth
		end,
		SetValue = function(value)
			local size = mini:ClampInt(value, 20, 200, dbDefaults.IconWidth)

			if db.IconWidth == value and db.IconHeight == value then
				return
			end

			db.IconWidth = size
			db.IconHeight = size
			addon:Refresh()
		end,
	})

	sizeSlider:SetPoint("TOP", backgroundChkBox, "BOTTOM", 0, -verticalSpacing * 3)
	sizeSlider:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local backgroundPaddingSlider, backgroundPaddingBox = mini:CreateSlider({
		LabelText = "Padding",
		Parent = panel,
		Min = 0,
		Max = 30,
		Step = 1,
		Width = sliderWidth,
		GetValue = function()
			return tonumber(db.BackgroundPadding) or dbDefaults.BackgroundPadding
		end,
		SetValue = function(value)
			if db.BackgroundPadding == value then
				return
			end

			db.BackgroundPadding = mini:ClampInt(value, 0, 30, 0)
			addon:Refresh()
		end,
	})

	backgroundPaddingSlider:SetPoint("LEFT", sizeSlider, "RIGHT", horizontalSpacing, 0)

	local offsetXSlider, offsetXBox = mini:CreateSlider({
		LabelText = "X Offset",
		Parent = panel,
		Min = -200,
		Max = 200,
		Step = 5,
		Width = sliderWidth,
		GetValue = function()
			return tonumber(db.OffsetX) or dbDefaults.OffsetX
		end,
		SetValue = function(value)
			if db.OffsetX == value then
				return
			end

			db.OffsetX = mini:ClampInt(value, -200, 200, 0)
			addon:Refresh()
		end,
	})

	offsetXSlider:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local offsetYSlider, offsetYBox = mini:CreateSlider({
		Parent = panel,
		Min = -200,
		Max = 200,
		Step = 5,
		Width = sliderWidth,
		LabelText = "Y Offset",
		GetValue = function()
			return tonumber(db.OffsetY) or dbDefaults.OffsetY
		end,
		SetValue = function(value)
			if db.OffsetY == value then
				return
			end

			db.OffsetY = mini:ClampInt(value, -200, 200, 0)
			addon:Refresh()
		end,
	})

	offsetYSlider:SetPoint("LEFT", offsetXSlider, "RIGHT", horizontalSpacing, 0)

	mini:WireTabNavigation({
		textureSizeBox,
		backgroundPaddingBox,
		offsetXBox,
		offsetYBox,
	})

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(120, 26)
	resetBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			mini:NotifyCombatLockdown()
			return
		end

		db = mini:ResetSavedVars(dbDefaults)

		panel:MiniRefresh()
		addon:Refresh()
		mini:Notify("Settings reset to default.")
	end)

	return panel
end
