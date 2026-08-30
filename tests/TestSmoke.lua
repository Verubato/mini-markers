-- Loads the whole addon into a mocked client and drives it through login.
-- The shared body lives in build/Lua/SmokeTest.lua.

local fw = require("TestFramework")
local smoke = require("SmokeTest")
local WowMock = require("WowMock")

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

---A caption is a plain region on its parent frame, not a field a test can reach directly, so
---this walks every frame's regions looking for the text.
---@param text string
---@return table?
local function FindLabel(text)
	for _, frame in ipairs(WowMock.Frames) do
		for _, region in ipairs({ frame:GetRegions() }) do
			if region.GetText and region:GetText() == text then
				return region
			end
		end
	end
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

smoke.Run("MiniMarkers", {
	extra = function(context)
		fw.eq(context.Addon.Framework.CustomStyling, true, "custom styling on")
		fw.eq(context.Addon.Framework.CustomStylingOverrides.Button, false, "stock buttons")
		-- Main, Custom Texture and Special Icons each get one.
		fw.eq(CountDividers("SETTINGS"), 3, "a settings section rule under each panel's header")

		local textureLabel = FindLabel("Texture")
		fw.not_nil(textureLabel, "the custom texture panel's Texture label")
		fw.eq(FindPointOffset(textureLabel, "LEFT"), 0, "the custom texture panel's controls start flush at the left")

		local textureBox = FindAnchoredTo(textureLabel)
		fw.not_nil(textureBox, "the custom texture panel's Texture field")
		fw.eq(FindPointOffset(textureBox, "TOPLEFT"), 6, "the field's border art lands inside the panel")
	end,
})
