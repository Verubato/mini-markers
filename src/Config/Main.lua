local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local config = addon.Config
---@class Db
local dbDefaults = config.DbDefaults
local M = {}
addon.Config.Panels.Main = M

StaticPopupDialogs["MINIMARKERS_CONFIRM_RESET"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, data)
		if data and data.OnYes then
			data.OnYes()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function M:Build()
	---@type Db
	local db = addon.DB
	local verticalSpacing = mini.VerticalSpacing
	local horizontalSpacing = mini.HorizontalSpacing
	local leftInset = horizontalSpacing
	local columns = 4
	local columnStep = mini:ColumnWidth(columns, horizontalSpacing, 1)

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
	priority:SetText("Priority: spec > role -> class -> texture.")

	local friendlyTypesDivider = mini:Divider({ Parent = panel, Text = "Friendly Icon Types" })

	friendlyTypesDivider:SetPoint("TOP", priority, "BOTTOM", 0, -verticalSpacing)
	friendlyTypesDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	friendlyTypesDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local specIconsChkBox = mini:Checkbox({
		Parent = panel,
		LabelText = "Spec Icons",
		Tooltip = "Use spec icons. Requires FrameSort for this to work.",
		GetValue = function()
			return db.FriendlySpecIcons
		end,
		SetValue = function(enabled)
			if enabled and not (FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector) then
				mini:ShowDialog({ Text = "Spec icons requires FrameSort 7.8.1+ to function." })
				return
			end

			db.FriendlySpecIcons = enabled
			addon:Refresh()
		end,
	})

	specIconsChkBox:SetPoint("TOP", friendlyTypesDivider, "BOTTOM", 0, -verticalSpacing / 2)
	specIconsChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local roleIconsChkBox = mini:Checkbox({
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

	local classIconsChkBox = mini:Checkbox({
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

	classIconsChkBox:SetPoint("LEFT", roleIconsChkBox, "RIGHT", columnStep, 0)

	local textureIconsChkBox = mini:Checkbox({
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

	textureIconsChkBox:SetPoint("LEFT", classIconsChkBox, "RIGHT", columnStep, 0)

	local lastIconTypesWidget = textureIconsChkBox

	if not mini:HasSecrets() then
		-- bgs don't allow us to determin specs in midnight
		local enemyTypesDivider = mini:Divider({ Parent = panel, Text = "Enemy Icon Types" })

		enemyTypesDivider:SetPoint("TOP", textureIconsChkBox, "BOTTOM", 0, -verticalSpacing)
		enemyTypesDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
		enemyTypesDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

		local enemySpecIconsChkBox = mini:Checkbox({
			Parent = panel,
			LabelText = "Spec Icons",
			Tooltip = "Use spec icons. Requires FrameSort for this to work.",
			GetValue = function()
				return db.EnemySpecIcons
			end,
			SetValue = function(enabled)
				if enabled and not (FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector) then
					mini:ShowDialog({ Text = "Spec icons requires FrameSort 7.8.1+ to function." })
					return
				end

				db.EnemySpecIcons = enabled
				addon:Refresh()
			end,
		})

		enemySpecIconsChkBox:SetPoint("TOP", enemyTypesDivider, "BOTTOM", 0, -verticalSpacing / 2)
		enemySpecIconsChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

		local enemyRoleIconsChkBox = mini:Checkbox({
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

		local enemyClassIconsChkBox = mini:Checkbox({
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

		enemyClassIconsChkBox:SetPoint("LEFT", enemyRoleIconsChkBox, "RIGHT", columnStep, 0)

		local enemyTextureIconsChkBox = mini:Checkbox({
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

		enemyTextureIconsChkBox:SetPoint("LEFT", enemyClassIconsChkBox, "RIGHT", columnStep, 0)

		lastIconTypesWidget = enemyClassIconsChkBox
	end

	local filtersDivider = mini:Divider({ Parent = panel, Text = "Filters" })

	filtersDivider:SetPoint("TOP", lastIconTypesWidget, "BOTTOM", 0, -verticalSpacing / 2)
	filtersDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	filtersDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local alliesChkBox = mini:Checkbox({
		Parent = panel,
		LabelText = "Allies",
		Tooltip = "Show markers for all friendly players.",
		GetValue = function()
			return db.AlliesEnabled
		end,
		SetValue = function(enabled)
			db.AlliesEnabled = enabled
			addon:Refresh()
		end,
	})

	alliesChkBox:SetPoint("TOP", filtersDivider, "BOTTOM", 0, -verticalSpacing / 2)
	alliesChkBox:SetPoint("LEFT", panel, "LEFT", leftInset, 0)

	local lastFilterWidget = alliesChkBox

	if not mini:HasSecrets() then
		local enemiesChkBox = mini:Checkbox({
			Parent = panel,
			LabelText = "Enemies",
			Tooltip = "Show markers for all enemy players.",
			GetValue = function()
				return db.EnemiesEnabled
			end,
			SetValue = function(enabled)
				db.EnemiesEnabled = enabled
				addon:Refresh()
			end,
		})

		enemiesChkBox:SetPoint("LEFT", alliesChkBox, "RIGHT", columnStep, 0)
		lastFilterWidget = enemiesChkBox
	end

	local groupChkBox = mini:Checkbox({
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

	groupChkBox:SetPoint("LEFT", lastFilterWidget, "RIGHT", columnStep, 0)

	local pvpChkBox = mini:Checkbox({
		Parent = panel,
		LabelText = "PvP Flagged",
		Tooltip = "Show markers for pvp flagged members.",
		GetValue = function()
			return db.PvPEnabled
		end,
		SetValue = function(enabled)
			db.PvPEnabled = enabled
			addon:Refresh()
		end,
	})

	pvpChkBox:SetPoint("LEFT", groupChkBox, "RIGHT", columnStep, 0)

	local petsChkBox = mini:Checkbox({
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

	petsChkBox:SetPoint("TOPLEFT", alliesChkBox, "BOTTOMLEFT", 0, -verticalSpacing / 4)

	local npcsChkBox = mini:Checkbox({
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

	npcsChkBox:SetPoint("LEFT", petsChkBox, "RIGHT", columnStep, 0)

	local arenaOnlyChkBox = mini:Checkbox({
		Parent = panel,
		LabelText = "Arena Only",
		Tooltip = "Show markers only inside arenas.",
		GetValue = function()
			return db.ArenaOnlyEnabled
		end,
		SetValue = function(enabled)
			db.ArenaOnlyEnabled = enabled
			addon:Refresh()
		end,
	})

	arenaOnlyChkBox:SetPoint("LEFT", npcsChkBox, "RIGHT", columnStep, 0)

	local sizeDivider = mini:Divider({ Parent = panel, Text = "Size & Position & Background" })

	sizeDivider:SetPoint("TOP", petsChkBox, "BOTTOM", 0, -verticalSpacing / 2)
	sizeDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	sizeDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local settingsWidth = mini:SettingsSize()
	local usableWidth = settingsWidth - leftInset
	local sliderWidth = (usableWidth / 2) - horizontalSpacing

	local friendlyEditBoxes = {}
	local enemyEditBoxes = {}

	local function BuildFriendlyContent(content)
		local bgChkBox = mini:Checkbox({
			Parent = content,
			LabelText = "Background",
			Tooltip = "Add a background behind friendly icons.",
			GetValue = function()
				return db.FriendlyBackgroundEnabled
			end,
			SetValue = function(enabled)
				db.FriendlyBackgroundEnabled = enabled
				addon:Refresh()
			end,
		})

		bgChkBox:SetPoint("TOP", content, "TOP", 0, 0)
		bgChkBox:SetPoint("LEFT", content, "LEFT", 0, 0)

		local sizeSlider = mini:Slider({
			Parent = content,
			LabelText = "Size",
			Min = 20,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.FriendlyIconWidth) or dbDefaults.FriendlyIconWidth
			end,
			SetValue = function(value)
				local size = mini:ClampInt(value, 20, 200, dbDefaults.FriendlyIconWidth)

				if db.FriendlyIconWidth == size and db.FriendlyIconHeight == size then
					return
				end

				db.FriendlyIconWidth = size
				db.FriendlyIconHeight = size
				addon:Refresh()
			end,
		})

		sizeSlider.Slider:SetPoint("TOP", bgChkBox, "BOTTOM", 0, -verticalSpacing * 2)
		sizeSlider.Slider:SetPoint("LEFT", content, "LEFT", 0, 0)

		local paddingSlider = mini:Slider({
			Parent = content,
			LabelText = "Padding",
			Min = 0,
			Max = 30,
			Step = 1,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.FriendlyBackgroundPadding) or dbDefaults.FriendlyBackgroundPadding
			end,
			SetValue = function(value)
				if db.FriendlyBackgroundPadding == value then
					return
				end

				db.FriendlyBackgroundPadding = mini:ClampInt(value, 0, 30, 0)
				addon:Refresh()
			end,
		})

		paddingSlider.Slider:SetPoint("LEFT", sizeSlider.Slider, "RIGHT", horizontalSpacing, 0)

		local offsetXSlider = mini:Slider({
			Parent = content,
			LabelText = "X Offset",
			Min = -200,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.FriendlyOffsetX) or dbDefaults.FriendlyOffsetX
			end,
			SetValue = function(value)
				if db.FriendlyOffsetX == value then
					return
				end

				db.FriendlyOffsetX = mini:ClampInt(value, -200, 200, 0)
				addon:Refresh()
			end,
		})

		offsetXSlider.Slider:SetPoint("TOPLEFT", sizeSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

		local offsetYSlider = mini:Slider({
			Parent = content,
			LabelText = "Y Offset",
			Min = -200,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.FriendlyOffsetY) or dbDefaults.FriendlyOffsetY
			end,
			SetValue = function(value)
				if db.FriendlyOffsetY == value then
					return
				end

				db.FriendlyOffsetY = mini:ClampInt(value, -200, 200, 0)
				addon:Refresh()
			end,
		})

		offsetYSlider.Slider:SetPoint("LEFT", offsetXSlider.Slider, "RIGHT", horizontalSpacing, 0)

		friendlyEditBoxes[1] = sizeSlider.EditBox
		friendlyEditBoxes[2] = paddingSlider.EditBox
		friendlyEditBoxes[3] = offsetXSlider.EditBox
		friendlyEditBoxes[4] = offsetYSlider.EditBox
	end

	local function BuildEnemyContent(content)
		local bgChkBox = mini:Checkbox({
			Parent = content,
			LabelText = "Background",
			Tooltip = "Add a background behind enemy icons.",
			GetValue = function()
				return db.EnemyBackgroundEnabled
			end,
			SetValue = function(enabled)
				db.EnemyBackgroundEnabled = enabled
				addon:Refresh()
			end,
		})

		bgChkBox:SetPoint("TOP", content, "TOP", 0, 0)
		bgChkBox:SetPoint("LEFT", content, "LEFT", 0, 0)

		local sizeSlider = mini:Slider({
			Parent = content,
			LabelText = "Size",
			Min = 20,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.EnemyIconWidth) or dbDefaults.EnemyIconWidth
			end,
			SetValue = function(value)
				local size = mini:ClampInt(value, 20, 200, dbDefaults.EnemyIconWidth)

				if db.EnemyIconWidth == size and db.EnemyIconHeight == size then
					return
				end

				db.EnemyIconWidth = size
				db.EnemyIconHeight = size
				addon:Refresh()
			end,
		})

		sizeSlider.Slider:SetPoint("TOP", bgChkBox, "BOTTOM", 0, -verticalSpacing * 2)
		sizeSlider.Slider:SetPoint("LEFT", content, "LEFT", 0, 0)

		local paddingSlider = mini:Slider({
			Parent = content,
			LabelText = "Padding",
			Min = 0,
			Max = 30,
			Step = 1,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.EnemyBackgroundPadding) or dbDefaults.EnemyBackgroundPadding
			end,
			SetValue = function(value)
				if db.EnemyBackgroundPadding == value then
					return
				end

				db.EnemyBackgroundPadding = mini:ClampInt(value, 0, 30, 0)
				addon:Refresh()
			end,
		})

		paddingSlider.Slider:SetPoint("LEFT", sizeSlider.Slider, "RIGHT", horizontalSpacing, 0)

		local offsetXSlider = mini:Slider({
			Parent = content,
			LabelText = "X Offset",
			Min = -200,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.EnemyOffsetX) or dbDefaults.EnemyOffsetX
			end,
			SetValue = function(value)
				if db.EnemyOffsetX == value then
					return
				end

				db.EnemyOffsetX = mini:ClampInt(value, -200, 200, 0)
				addon:Refresh()
			end,
		})

		offsetXSlider.Slider:SetPoint("TOPLEFT", sizeSlider.Slider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

		local offsetYSlider = mini:Slider({
			Parent = content,
			LabelText = "Y Offset",
			Min = -200,
			Max = 200,
			Step = 5,
			Width = sliderWidth,
			GetValue = function()
				return tonumber(db.EnemyOffsetY) or dbDefaults.EnemyOffsetY
			end,
			SetValue = function(value)
				if db.EnemyOffsetY == value then
					return
				end

				db.EnemyOffsetY = mini:ClampInt(value, -200, 200, 0)
				addon:Refresh()
			end,
		})

		offsetYSlider.Slider:SetPoint("LEFT", offsetXSlider.Slider, "RIGHT", horizontalSpacing, 0)

		enemyEditBoxes[1] = sizeSlider.EditBox
		enemyEditBoxes[2] = paddingSlider.EditBox
		enemyEditBoxes[3] = offsetXSlider.EditBox
		enemyEditBoxes[4] = offsetYSlider.EditBox
	end

	if mini:HasSecrets() then
		local content = CreateFrame("Frame", nil, panel)
		content:SetPoint("TOP", sizeDivider, "BOTTOM", 0, -verticalSpacing / 2)
		content:SetPoint("LEFT", panel, "LEFT", leftInset, 0)
		content:SetPoint("RIGHT", panel, "RIGHT", -horizontalSpacing, 0)

		BuildFriendlyContent(content)
		mini:WireTabNavigation(friendlyEditBoxes)
	else
		local tabContainer = CreateFrame("Frame", nil, panel)
		tabContainer:SetPoint("TOP", sizeDivider, "BOTTOM", 0, 0)
		tabContainer:SetPoint("LEFT", panel, "LEFT", 0, 0)
		tabContainer:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
		tabContainer:SetHeight(210)

		local tabCtrl = mini:CreateTabs({
			Parent = tabContainer,
			TabFitToParent = true,
			ContentInsets = { Left = leftInset, Right = horizontalSpacing, Top = verticalSpacing / 2, Bottom = 0 },
			Tabs = {
				{ Key = "Friendly", Title = "Friendly", Build = BuildFriendlyContent },
				{ Key = "Enemy",    Title = "Enemy",    Build = BuildEnemyContent },
			},
		})

		mini:WireTabNavigation(friendlyEditBoxes)
		mini:WireTabNavigation(enemyEditBoxes)

		panel.OnMiniRefresh = function()
			local friendlyContent = tabCtrl:GetContent("Friendly")
			if friendlyContent and friendlyContent.MiniRefresh then
				friendlyContent:MiniRefresh()
			end

			local enemyContent = tabCtrl:GetContent("Enemy")
			if enemyContent and enemyContent.MiniRefresh then
				enemyContent:MiniRefresh()
			end
		end
	end

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(120, 26)
	resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			mini:NotifyCombatLockdown()
			return
		end

		StaticPopup_Show("MINIMARKERS_CONFIRM_RESET", "Are you sure you want to reset to default settings?", nil, {
			OnYes = function()
				db = mini:ResetSavedVars(dbDefaults)

				local hasFs = FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector

				if hasFs then
					db.FriendlySpecIcons = true
				end

				panel:MiniRefresh()
				addon:Refresh()
				mini:Notify("Settings reset to default.")
			end,
		})
	end)

	return panel
end
