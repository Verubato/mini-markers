-- The icon appearance defaults a fresh install starts with.

local fw = require("TestFramework")
local harness = require("AddonHarness")
fw.describe("MiniMarkers - appearance defaults", function()
	fw.it("starts with a background, a border, and the tightest padding", function()
		local context = harness.Load("MiniMarkers")
		local defaults = context.Addon.Config.DbDefaults

		fw.eq(defaults.FriendlyBackgroundEnabled, true, "friendly background on")
		fw.eq(defaults.EnemyBackgroundEnabled, true, "enemy background on")
		fw.eq(defaults.FriendlyBorderEnabled, true, "friendly border on")
		fw.eq(defaults.EnemyBorderEnabled, true, "enemy border on")
		fw.eq(defaults.FriendlyBackgroundPadding, 1, "friendly padding of one")
		fw.eq(defaults.EnemyBackgroundPadding, 1, "enemy padding of one")
	end)

	fw.it("starts on spec icons alone for both teams", function()
		local context = harness.Load("MiniMarkers")
		local defaults = context.Addon.Config.DbDefaults

		fw.eq(defaults.FriendlySpecIcons, true, "friendly spec icons on")
		fw.eq(defaults.FriendlyClassIcons, false, "friendly class icons off")
		fw.eq(defaults.FriendlyTextureIcons, false, "friendly texture icons off")
		fw.eq(defaults.FriendlyRoleIcons, false, "friendly role icons off")

		fw.eq(defaults.EnemySpecIcons, true, "enemy spec icons on")
		fw.eq(defaults.EnemyClassIcons, false, "enemy class icons off")
		fw.eq(defaults.EnemyTextureIcons, false, "enemy texture icons off")
		fw.eq(defaults.EnemyRoleIcons, false, "enemy role icons off")
	end)
end)
