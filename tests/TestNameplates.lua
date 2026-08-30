-- Nameplate events arrive in bursts and share one deferred pass, so what a plate ends up
-- showing depends on the whole queue rather than the last event alone.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")
local WowMock = require("WowMock")

local UNIT = Nameplates.UNIT

fw.describe("MiniMarkers - the nameplate queue", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true
		env.Db.FriendlyBackgroundEnabled = true
		env.Db.FriendlyBorderEnabled = true
	end)

	fw.it("draws the border for a normal unit's real class colour", function()
		env.Plate(UNIT)
		env.Add(UNIT)

		fw.truthy(env.Plates[UNIT].Marker.Border.Square:IsShown(), "a real class colour draws it")
	end)

	fw.it("hides every part of the marker when the plate is removed", function()
		env.Plate(UNIT)
		env.Add(UNIT)

		fw.not_nil(env.Icon(UNIT), "marked while the plate is up")

		env.Remove(UNIT)

		local marker = env.Plates[UNIT].Marker

		fw.is_nil(env.Icon(UNIT), "the icon is gone")
		fw.falsy(marker.Background.Square:IsShown(), "so is the background")
		fw.falsy(marker.Border.Square:IsShown(), "and the border")
	end)

	fw.it("reuses the same marker on a plate that comes back", function()
		env.Plate(UNIT)
		env.Add(UNIT)

		local first = env.Plates[UNIT].Marker

		env.Remove(UNIT)
		env.Add(UNIT)

		fw.eq(env.Plates[UNIT].Marker, first, "the same textures, not a second set left behind")
		fw.not_nil(env.Icon(UNIT), "and drawing again")
	end)

	fw.it("lets a removal in the same frame settle the plate the add queued", function()
		env.Plate(UNIT)

		WowMock.FireEvent("NAME_PLATE_UNIT_ADDED", UNIT)
		WowMock.FireEvent("NAME_PLATE_UNIT_REMOVED", UNIT)
		env.Flush()

		fw.is_nil(env.Plates[UNIT].Marker, "nothing was drawn for a plate that had already gone")
	end)

	fw.it("ignores a removal for a unit the client has no plate for", function()
		fw.no_error(function()
			env.Remove("nameplate9")
		end, "a removal with no plate behind it")
	end)

	fw.it("redraws every plate on a roster update", function()
		env.Plate(UNIT)
		env.Db.FriendlyTextureIcons = false
		env.Add(UNIT)

		fw.is_nil(env.Plates[UNIT].Marker, "no icon rule was on when the plate arrived")

		env.Db.FriendlyTextureIcons = true
		WowMock.FireEvent("GROUP_ROSTER_UPDATE")
		env.Flush()

		fw.not_nil(env.Icon(UNIT), "the roster update swept every plate")
	end)
end)
