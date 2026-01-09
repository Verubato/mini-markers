local _, addon = ...
local config = addon.Config
---@type MiniFramework
local mini = addon.Framework
local M = {}
config.Panels.Roles = M

function M:Build()
	local leftInset = config.LeftInset
	local rightInset = config.RightInset
	local settingsWidth = mini:SettingsSize()
	local verticalSpacing = config.VerticalSpacing

	---@type Db
	local db = addon.DB
	local panel = CreateFrame("Frame")
	panel.name = "Roles"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -verticalSpacing)
	title:SetText("Role Options")

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOP", title, "BOTTOM", 0, -verticalSpacing / 2)
	description:SetText("Additional role filters and colouring.")

	local friendlyDivider = mini:CreateDivider(panel, "Friendly Filters")

	friendlyDivider:SetPoint("TOP", description, "BOTTOM", 0, -verticalSpacing)
	friendlyDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	friendlyDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local columns = 3
	local usableWidth = settingsWidth - leftInset - rightInset
	local columnStep = usableWidth / (columns + 1)
	local start = math.floor(columnStep / 2)

	local friendlyTankChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Tanks",
		Tooltip = "Show icons for friendly tanks.",
		GetValue = function()
			return db.FriendlyTankEnabled
		end,
		SetValue = function(enabled)
			db.FriendlyTankEnabled = enabled
			addon:Refresh()
		end,
	})

	friendlyTankChk:SetPoint("TOP", friendlyDivider, "BOTTOM", 0, -verticalSpacing / 2)
	friendlyTankChk:SetPoint("LEFT", panel, "LEFT", start, 0)

	local friendlyHealerChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Healers",
		Tooltip = "Show icons for friendly healers.",
		GetValue = function()
			return db.FriendlyHealerEnabled
		end,
		SetValue = function(enabled)
			db.FriendlyHealerEnabled = enabled
			addon:Refresh()
		end,
	})

	friendlyHealerChk:SetPoint("LEFT", friendlyTankChk, "RIGHT", columnStep, 0)

	local friendlyDpsChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "DPS",
		Tooltip = "Show icons for friendly DPS.",
		GetValue = function()
			return db.FriendlyDpsEnabled
		end,
		SetValue = function(enabled)
			db.FriendlyDpsEnabled = enabled
			addon:Refresh()
		end,
	})

	friendlyDpsChk:SetPoint("LEFT", friendlyHealerChk, "RIGHT", columnStep, 0)

	local enemyDivider = mini:CreateDivider(panel, "Enemy Filters")

	enemyDivider:SetPoint("TOP", friendlyDpsChk, "BOTTOM", 0, -verticalSpacing)
	enemyDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	enemyDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local enemyTankChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Tanks",
		Tooltip = "Show icons for enemy tanks.",
		GetValue = function()
			return db.EnemyTankEnabled
		end,
		SetValue = function(enabled)
			db.EnemyTankEnabled = enabled
			addon:Refresh()
		end,
	})

	enemyTankChk:SetPoint("TOP", enemyDivider, "BOTTOM", 0, -verticalSpacing / 2)
	enemyTankChk:SetPoint("LEFT", panel, "LEFT", start, 0)

	local enemyHealerChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Healers",
		Tooltip = "Show icons for enemy healers.",
		GetValue = function()
			return db.EnemyHealerEnabled
		end,
		SetValue = function(enabled)
			db.EnemyHealerEnabled = enabled
			addon:Refresh()
		end,
	})

	enemyHealerChk:SetPoint("LEFT", enemyTankChk, "RIGHT", columnStep, 0)

	local enemyDpsChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "DPS",
		Tooltip = "Show icons for friendly DPS.",
		GetValue = function()
			return db.EnemyDpsEnabled
		end,
		SetValue = function(enabled)
			db.EnemyDpsEnabled = enabled
			addon:Refresh()
		end,
	})

	enemyDpsChk:SetPoint("LEFT", enemyHealerChk, "RIGHT", columnStep, 0)

	local colouringDivider = mini:CreateDivider(panel, "Enemy Coloring")

	colouringDivider:SetPoint("TOP", enemyDpsChk, "BOTTOM", 0, -verticalSpacing)
	colouringDivider:SetPoint("LEFT", panel, "LEFT", 0, 0)
	colouringDivider:SetPoint("RIGHT", panel, "RIGHT", 0, 0)

	local enemyRedChk = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Red enemies",
		Tooltip = "Show red role and textre colors for enemies.",
		GetValue = function()
			return db.EnemyRedEnabled
		end,
		SetValue = function(enabled)
			db.EnemyRedEnabled = enabled
			addon:Refresh()
		end,
	})

	enemyRedChk:SetPoint("TOP", colouringDivider, "BOTTOM", 0, -verticalSpacing / 2)
	enemyRedChk:SetPoint("LEFT", panel, "LEFT", start, 0)

	return panel
end
