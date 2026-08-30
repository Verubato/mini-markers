-- Loads the whole addon into a mocked client and drives it through login.
-- The shared body lives in build/Lua/SmokeTest.lua.

local fw = require("TestFramework")
local smoke = require("SmokeTest")
local WowMock = require("WowMock")

-- Mirrors MiniFramework's own SliderChipOverhang and VerticalSpacing.
local SLIDER_CHIP_OVERHANG = 30
local VERTICAL_SPACING = 16

---The section rule is built by the framework and never handed back to the addon, so a test
---finds it the way a player sees it, by its label.
---@param text string
---@return number
local function CountDividers(text)
	local count = 0

	for _, frame in ipairs(WowMock.Frames) do
		if frame.Label and frame.Label.GetText and frame.Label:GetText() == text then
			count = count + 1
		end
	end

	return count
end

---@param frame table
---@param pointName string
---@return number? x
local function FindPointOffset(frame, pointName)
	for index = 1, frame:GetNumPoints() do
		local point, _, _, x = frame:GetPoint(index)

		if point == pointName then
			return x
		end
	end
end

---The field is never handed back, so a test finds it as the frame hanging off its label.
---@param relative table
---@return table?
local function FindAnchoredTo(relative)
	for _, frame in ipairs(WowMock.Frames) do
		for index = 1, frame:GetNumPoints() do
			local point, relativeTo = frame:GetPoint(index)

			if point == "TOPLEFT" and relativeTo == relative then
				return frame
			end
		end
	end
end

---Both the friendly and the enemy tab carry a control of each name, so a layout check has to
---see both rather than stop at whichever was built first.
---@param text string
---@return table[]
local function FindLabels(text)
	local found = {}

	for _, frame in ipairs(WowMock.Frames) do
		for _, region in ipairs({ frame:GetRegions() }) do
			if region.GetText and region:GetText() == text then
				found[#found + 1] = region
			end
		end
	end

	return found
end

---A caption is a plain region on its parent frame, not a field a test can reach directly.
---@param text string
---@return table?
local function FindLabel(text)
	return FindLabels(text)[1]
end

---@param frame table
---@param pointName string
---@return table? relativeTo
---@return string? relativePoint
---@return number? y
local function PointOn(frame, pointName)
	for index = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, _, y = frame:GetPoint(index)

		if point == pointName then
			return relativeTo, relativePoint, y
		end
	end
end

---@param relative table
---@param pointName string
---@return table?
local function FindHangingOff(relative, pointName)
	for _, frame in ipairs(WowMock.Frames) do
		if PointOn(frame, pointName) == relative then
			return frame
		end
	end
end

smoke.Run("MiniMarkers", {
	extra = function(context)
		fw.eq(context.Addon.Framework.CustomStyling, true, "custom styling on")
		fw.eq(context.Addon.Framework.CustomStylingOverrides.Button, false, "stock buttons")
		-- Custom Texture and Special Icons each get one. The main panel's rule names the
		-- section it opens instead.
		fw.eq(CountDividers("SETTINGS"), 2, "a settings section rule under each subpanel's header")
		fw.eq(CountDividers("FRIENDLY ICON TYPES"), 1, "one rule opening the friendly icon types")
		local blurb = FindLabel("Show markers above nameplates.")
		local priority = FindLabel("Priority: spec > role -> class -> texture.")
		fw.not_nil(blurb, "the blurb's first line")
		fw.not_nil(priority, "the priority line is on the panel")
		-- FindLabel would find it standing loose on the panel too.
		fw.eq(PointOn(priority, "TOPLEFT"), blurb, "the priority line sits under the blurb's first line")

		local textureLabel = FindLabel("Texture")
		fw.not_nil(textureLabel, "the custom texture panel's Texture label")
		fw.eq(FindPointOffset(textureLabel, "LEFT"), 0, "the custom texture panel's controls start flush at the left")

		local textureBox = FindAnchoredTo(textureLabel)
		fw.not_nil(textureBox, "the custom texture panel's Texture field")
		fw.eq(FindPointOffset(textureBox, "TOPLEFT"), 6, "the field's border art lands inside the panel")

		local shapeLabels = FindLabels("Shape")
		fw.eq(#shapeLabels, 2, "a Shape label on each appearance tab")

		for index, shapeLabel in ipairs(shapeLabels) do
			local shapeDropdown = PointOn(shapeLabel, "RIGHT")
			fw.not_nil(shapeDropdown, "tab " .. index .. " has a shape dropdown")

			local bgChkBox = FindHangingOff(shapeDropdown, "LEFT")
			fw.not_nil(bgChkBox, "tab " .. index .. " has a background toggle beside the shape dropdown")
			fw.eq(bgChkBox:GetNumPoints(), 1, "tab " .. index .. "'s background toggle only takes its row from that point")

			local _, relativePoint = PointOn(bgChkBox, "LEFT")
			fw.eq(relativePoint, "RIGHT", "tab " .. index .. "'s background toggle sits right of the shape dropdown")

			local borderChkBox = FindHangingOff(bgChkBox, "LEFT")
			fw.not_nil(borderChkBox, "tab " .. index .. " has a border toggle beside the background toggle")

			local _, borderRelative = PointOn(borderChkBox, "LEFT")
			fw.eq(borderRelative, "RIGHT", "tab " .. index .. "'s border toggle sits right of the background toggle")

			local sizeSlider = FindHangingOff(shapeDropdown, "TOP")
			fw.not_nil(sizeSlider, "tab " .. index .. " has a slider under the shape dropdown")

			-- The chip floats above the slider's own top edge, so the row's gap is whatever
			-- is left after the overhang rather than the offset itself.
			local _, _, sliderY = PointOn(sizeSlider, "TOP")
			local chipGap = -sliderY - SLIDER_CHIP_OVERHANG

			fw.truthy(chipGap >= VERTICAL_SPACING, "tab " .. index .. "'s slider chip clears the dropdown by a full row gap")
		end
	end,
})
