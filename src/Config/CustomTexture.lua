local _, addon = ...
local config = addon.Config
---@type MiniFramework
local mini = addon.Framework
local M = {}
config.Panels.CustomTexture = M

function M:Build()
	local leftInset = config.LeftInset
	local verticalSpacing = config.VerticalSpacing
	local horizontalSpacing = config.HorizontalSpacing

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

	local textureBox, textureLbl = mini:CreateEditBox({
		Parent = panel,
		LabelText = "Texture",
		-- same width as 2 sliders plus gap
		Width = 200 * 2 + horizontalSpacing,
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

	textureLbl:SetPoint("TOP", description, "BOTTOM", 0, -verticalSpacing)
	textureLbl:SetPoint("LEFT", panel, "LEFT", leftInset, 0)
	textureBox:SetPoint("TOPLEFT", textureLbl, "BOTTOMLEFT", 0, -verticalSpacing)

	local textureRotSlider = mini:CreateSlider({
		Parent = panel,
		Min = 0,
		Max = 360,
		Step = 15,
		Width = 200,
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

	textureRotSlider:SetPoint("TOPLEFT", textureBox, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	return panel
end
