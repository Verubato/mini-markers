local _, addon = ...
local config = addon.Config
---@type MiniFramework
local mini = addon.Framework
local M = {}
config.Panels.SpecialIcons = M

function M:Build()
	---@type Db
	local db = addon.DB
	local columns = 2
	local verticalSpacing = mini.VerticalSpacing
	local columnStep = mini:ColumnWidth(columns, mini.HorizontalSpacing, 1)
	local start = 0

	local panel = CreateFrame("Frame")
	panel.name = "Special Icons"

	local header = mini:PanelHeader({
		Parent = panel,
		Title = "Special Icons",
		Description = "Use special icons for friends and guild members.",
		Y = -verticalSpacing,
		Gap = verticalSpacing / 2,
	})

	local friendsChkBox = mini:Checkbox({
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

	friendsChkBox:SetPoint("TOP", header.Anchor, "BOTTOM", 0, -verticalSpacing)
	friendsChkBox:SetPoint("LEFT", panel, "LEFT", start, 0)

	local guildChkBox = mini:Checkbox({
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
