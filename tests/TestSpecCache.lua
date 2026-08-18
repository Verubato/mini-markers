-- The spec cache lives in MiniMarkersDB, so a reload must not clear it. Config:Init runs the
-- saved-variable migrations before the inspector attaches to the table, and either half could
-- drop the cache without anything else noticing: a stale spec icon looks the same as a fresh one.

local fw = require("TestFramework")
local harness = require("AddonHarness")

local ADDON = "MiniMarkers"

fw.describe(ADDON .. " - spec cache", function()
	fw.it("creates the cache on a first load", function()
		harness.Run(ADDON)

		fw.not_nil(_G.MiniMarkersDB, "saved variables")
		fw.not_nil(_G.MiniMarkersDB.SpecCache, "SpecCache")
	end)

	fw.it("keeps cached specs across a reload", function()
		harness.Run(ADDON)

		local guid = "Player-1234-ABCDEF01"

		_G.MiniMarkersDB.SpecCache[guid] = { SpecId = 256, LastSeen = os.time() }

		-- A second pass over the saved variables the first one wrote, which is what /reload does.
		harness.Run(ADDON)

		local entry = _G.MiniMarkersDB.SpecCache[guid]

		fw.not_nil(entry, "cache entry after reload")
		fw.eq(entry.SpecId, 256, "cached spec id")
	end)

	fw.it("drops entries older than the expiry", function()
		harness.Run(ADDON)

		local fresh = "Player-1234-0000FRESH"
		local stale = "Player-1234-0000STALE"
		local fourDays = 60 * 60 * 24 * 4

		_G.MiniMarkersDB.SpecCache[fresh] = { SpecId = 256, LastSeen = os.time() }
		_G.MiniMarkersDB.SpecCache[stale] = { SpecId = 257, LastSeen = os.time() - fourDays }

		harness.Run(ADDON)

		fw.not_nil(_G.MiniMarkersDB.SpecCache[fresh], "fresh entry survives")
		fw.is_nil(_G.MiniMarkersDB.SpecCache[stale], "stale entry purged")
	end)
end)
