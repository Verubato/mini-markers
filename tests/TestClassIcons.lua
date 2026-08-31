-- Class icons are an atlas the rule names after the class file name, so a client without
-- that atlas has to end up with no marker rather than an empty one.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")

local UNIT = Nameplates.UNIT

fw.describe("MiniMarkers - class icons", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyRoleIcons = false
		env.Db.FriendlyTextureIcons = false
		env.Db.FriendlyClassIcons = true
		env.Db.FriendlyBackgroundEnabled = true
		env.Db.FriendlyBorderEnabled = true
	end)

	fw.it("draws the client's own class icon", function()
		env.Atlases["classicon-warrior"] = {}

		env.Plate(UNIT)
		env.Add(UNIT)

		fw.eq(env.Icon(UNIT):GetAtlas(), "classicon-warrior", "the client's class atlas")
	end)

	fw.it("draws nothing at all on a client that has no class atlas", function()
		env.Plate(UNIT)
		env.Add(UNIT)

		fw.is_nil(env.Plates[UNIT].Marker, "no icon, and nothing drawn around one")
	end)

	fw.it("leaves the custom texture to a client that has no class atlas", function()
		env.Db.FriendlyTextureIcons = true
		env.Db.IconTexture = "custom-texture"

		env.Plate(UNIT)
		env.Add(UNIT)

		fw.eq(env.Icon(UNIT):GetTexture(), "custom-texture", "the rule below the class one")
	end)
end)
