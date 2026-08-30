-- The icon appearance defaults a fresh install starts with.

local fw = require("TestFramework")
local harness = require("AddonHarness")
fw.describe("MiniMarkers - appearance defaults", function()
	fw.it("starts with no background and a border", function()
		local context = harness.Load("MiniMarkers")
		local defaults = context.Addon.Config.DbDefaults

		fw.eq(defaults.FriendlyBackgroundEnabled, false, "friendly background off")
		fw.eq(defaults.EnemyBackgroundEnabled, false, "enemy background off")
		fw.eq(defaults.FriendlyBorderEnabled, true, "friendly border on")
		fw.eq(defaults.EnemyBorderEnabled, true, "enemy border on")
	end)
end)
