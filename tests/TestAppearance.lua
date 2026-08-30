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
