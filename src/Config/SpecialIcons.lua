local _, addon = ...
local config = addon.Config
---@type MiniFramework
local mini = addon.Framework
local M = {}
config.Panels.SpecialIcons = M

function M:Build()
	---@type Db
	local db = addon.DB
	local leftInset = config.LeftInset
	local rightInset = config.RightInset
	local settingsWidth = mini:SettingsSize()
	local verticalSpacing = config.VerticalSpacing
	local columns = 2
	local usableWidth = settingsWidth - leftInset - rightInset
	local columnStep = usableWidth / (columns + 1)
	local start = usableWidth / 4

	local panel = CreateFrame("Frame")
	panel.name = "Special Icons"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -verticalSpacing)
	title:SetText("Special Icons")

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOP", title, "BOTTOM", 0, -verticalSpacing / 2)
	description:SetText("Use special icons for friends and guild members.")

	local friendsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Friends",
		Tooltip = "Use a special icon for btag friends.",
		GetValue = function()
			return db.FriendsEnabled
		end,
		SetValue = function(enabled)
			db.FriendsEnabled = enabled
			addon:Refresh()
		end,
	})

	friendsChkBox:SetPoint("TOP", description, "BOTTOM", 0, -verticalSpacing)
	friendsChkBox:SetPoint("LEFT", panel, "LEFT", start, 0)

	local guildChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Guild",
		Tooltip = "Use a special icon for guild members.",
		GetValue = function()
			return db.GuildEnabled
		end,
		SetValue = function(enabled)
			db.GuildEnabled = enabled
			addon:Refresh()
		end,
	})

	guildChkBox:SetPoint("LEFT", friendsChkBox, "RIGHT", columnStep, 0)

	return panel
end
