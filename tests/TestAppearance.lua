-- The appearance block on the main panel, on the modern client that shows it without tabs.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

local SIZE_RULE = "SIZE & POSITION & BACKGROUND"

---Opens the settings, optionally as a Midnight client, the only one that lays the appearance
---controls out without tabs.
---@param midnight boolean?
---@return table
local function OpenSettings(midnight)
	local context = harness.Load("MiniMarkers")

	if midnight then
		_G.LE_EXPANSION_LEVEL_CURRENT = _G.LE_EXPANSION_MIDNIGHT
	end

	harness.Login(context)

	for _, name in ipairs(WowMock.SlashCommands()) do
		_G.SlashCmdList[name]("")
	end

	return context
end

---@param frame table
---@return boolean
local function IsSizeRule(frame)
	return frame and frame.Label ~= nil and frame.Label.GetText ~= nil and frame.Label:GetText() == SIZE_RULE
end

---The container is a local, so a test finds it by the rule it hangs from.
---@return table?
local function FindAppearanceContainer()
	for _, frame in ipairs(WowMock.Frames) do
		for index = 1, frame:GetNumPoints() do
			local _, relativeTo = frame:GetPoint(index)

			if IsSizeRule(relativeTo) then
				return frame
			end
		end
	end
end

---@param frame table
---@param pointName string
---@return table? relativeTo
local function PointOn(frame, pointName)
	for index = 1, frame:GetNumPoints() do
		local point, relativeTo = frame:GetPoint(index)

		if point == pointName then
			return relativeTo
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

---The divider is a local too, and is only ever found by the label it carries.
---@return table?
local function FindTargetDivider()
	for _, frame in ipairs(WowMock.Frames) do
		if frame.Label and frame.Label.GetText and frame.Label:GetText() == "TARGET" then
			return frame
		end
	end
end

---Stands in for the real colour picker: SetupColorPickerAndShow just remembers the callbacks,
---and the test fires swatchFunc itself once it has picked a colour to hand back.
---@return table
local function MockColorPicker()
	local picker = { r = 1, g = 1, b = 1, a = 1 }

	function picker:GetColorRGB()
		return self.r, self.g, self.b
	end

	function picker:GetColorAlpha()
		return self.a
	end

	function picker:SetupColorPickerAndShow(config)
		self.config = config
	end

	return picker
end

fw.describe("MiniMarkers - the appearance block", function()
	-- The container's left and right points pin its centre, so it needs a height of its own.
	fw.it("reserves the block the tabbed layout reserves", function()
		OpenSettings(true)

		local untabbed = FindAppearanceContainer()

		fw.not_nil(untabbed, "the container under the " .. SIZE_RULE .. " rule")

		local height = untabbed:GetHeight()

		OpenSettings()

		local tabbed = FindAppearanceContainer()

		fw.not_nil(tabbed, "the tab container under the " .. SIZE_RULE .. " rule")
		fw.eq(height, tabbed:GetHeight(), "as tall as the tabbed layout makes its own")
	end)
end)

fw.describe("MiniMarkers - the Target section", function()
	for _, midnight in ipairs({ true, false }) do
		local layout = midnight and "the single block layout" or "the tabbed layout"

		fw.it("anchors the Target divider to the appearance block on " .. layout, function()
			OpenSettings(midnight)

			local appearanceBlock = FindAppearanceContainer()
			local targetDivider = FindTargetDivider()

			fw.not_nil(appearanceBlock, "the appearance block")
			fw.not_nil(targetDivider, "the Target divider")
			fw.eq(PointOn(targetDivider, "TOP"), appearanceBlock, "the divider hangs off the appearance block")
		end)

		fw.it("flips TargetGlowEnabled when the Glow checkbox is clicked on " .. layout, function()
			local context = OpenSettings(midnight)
			local db = context.Addon.DB

			local checkbox = FindHangingOff(FindTargetDivider(), "TOP")
			fw.not_nil(checkbox, "the Glow checkbox")

			local before = db.TargetGlowEnabled
			checkbox:Click()

			fw.eq(db.TargetGlowEnabled, not before, "the click flips the saved option")
		end)

		fw.it("writes the picked colour to TargetGlowColor on " .. layout, function()
			local context = OpenSettings(midnight)
			local db = context.Addon.DB

			local checkbox = FindHangingOff(FindTargetDivider(), "TOP")
			local swatch = FindHangingOff(checkbox, "LEFT")
			fw.not_nil(swatch, "the Glow Colour swatch")

			_G.ColorPickerFrame = MockColorPicker()
			swatch:Click()

			local picker = _G.ColorPickerFrame
			picker.r, picker.g, picker.b = 0.2, 0.4, 0.6
			picker.config.swatchFunc()

			fw.eq(db.TargetGlowColor.R, 0.2, "red")
			fw.eq(db.TargetGlowColor.G, 0.4, "green")
			fw.eq(db.TargetGlowColor.B, 0.6, "blue")
		end)
	end
end)
