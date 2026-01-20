local _, addon = ...
local config = addon.Config
---@type MiniFramework
local mini = addon.Framework
local M = {}
config.Panels.CustomTexture = M

local atlasList = {
	-- single arrow
	{ Texture = "plunderstorm-glues-logoarrow", Rotation = 0 },
	-- double arrow
	{ Texture = "covenantsanctum-renown-doublearrow-depressed", Rotation = 90 },
	-- nice triangle
	{ Texture = "UI-QuestPoiImportant-QuestNumber-SuperTracked", Rotation = 0 },
	-- smiley
	{ Texture = "1f604", Rotation = 0 },
	-- exclamation mark
	{ Texture = "Crosshair_Quest_128", Rotation = 0 },
	-- question mark
	{ Texture = "Crosshair_Questturnin_128", Rotation = 0 },
	-- love heart
	{ Texture = "Interface\\PVPFrame\\PVP-Banner-Emblem-4", Rotation = 0 },
}

function M:Build()
	local leftInset = mini.HorizontalSpacing
	local verticalSpacing = mini.VerticalSpacing
	local horizontalSpacing = mini.HorizontalSpacing
	local columns = 4
	local columnWidth = mini:ColumnWidth(columns, horizontalSpacing, 0)
	local fullWidth = columns * columnWidth

	---@type Db
	local db = addon.DB
	local panel = CreateFrame("Frame")
	panel.name = "Custom Texture"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -verticalSpacing)
	title:SetText("Custom Texture")

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOP", title, "BOTTOM", 0, -verticalSpacing)
	description:SetText("Specify a custom texture to use.")

	local texture = mini:EditBox({
		Parent = panel,
		LabelText = "Texture",
		Width = fullWidth,
		GetValue = function()
			return db.IconTexture
		end,
		SetValue = function(value)
			if db.IconTexture == value then
				return
			end

			db.IconTexture = tostring(value)
			addon:Refresh()
		end,
	})

	texture.Label:SetPoint("TOP", description, "BOTTOM", 0, -verticalSpacing)
	texture.Label:SetPoint("LEFT", panel, "LEFT", leftInset, 0)
	texture.EditBox:SetPoint("TOPLEFT", texture.Label, "BOTTOMLEFT", 0, -verticalSpacing)

	local textureRot = mini:Slider({
		Parent = panel,
		Min = 0,
		Max = 360,
		Step = 15,
		Width = fullWidth,
		LabelText = "Rotation",
		GetValue = function()
			return tonumber(db.IconRotation) or dbDefaults.IconRotation
		end,
		SetValue = function(value)
			if db.IconRotation == value then
				return
			end

			db.IconRotation = mini:ClampInt(value, 0, 360, 0)
			addon:Refresh()
		end,
	})

	textureRot.Slider:SetPoint("TOPLEFT", texture.EditBox, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local atlasPicker = addon.Config.AtlasPicker:AtlasPicker({
		Parent = panel,
		Width = fullWidth,
		Height = 300,
		GetValue = function()
			return {
				Texture = db.IconTexture,
				Rotation = db.IconRotation,
			}
		end,
		SetValue = function(entry)
			db.IconTexture = entry.Texture
			db.IconRotation = entry.Rotation or 0
			panel:MiniRefresh()
			addon:Refresh()
		end,
		AtlasList = atlasList,
	})

	atlasPicker:SetPoint("TOPLEFT", textureRot.Slider, "BOTTOMLEFT", 0, -mini.VerticalSpacing * 2)
	return panel
end
