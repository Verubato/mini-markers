-- The upgrade chain runs on every login against whatever shape the profile was last saved in, so
-- a step that misfires quietly rewrites settings the player chose.

local fw = require("TestFramework")
local harness = require("AddonHarness")

local CURRENT_VERSION = 9

---Logs in against a saved-variables table at an older shape and returns what the upgrade left.
---@param saved table
---@return table
local function Upgrade(saved)
	local context = harness.Load("MiniMarkers")

	_G.MiniMarkersDB = saved

	harness.Login(context)

	return _G.MiniMarkersDB
end

fw.describe("MiniMarkers - saved variable upgrades", function()
	fw.it("runs the whole chain for a profile that carries no version", function()
		local db = Upgrade({ GroupEnabled = false, Junk = "stale" })

		fw.eq(db.Version, CURRENT_VERSION, "stamped current")
		fw.eq(db.GroupEnabled, true, "the version one step's reset ran")
		fw.is_nil(db.Junk, "and took the keys it found with it")
	end)

	fw.it("fills a setting back in when the step that moved it had nothing to read", function()
		local db = Upgrade({ Version = 3 })

		fw.eq(db.FriendsEnabled, true, "the blanked key landed on its default")
	end)

	fw.it("leaves a profile stamped ahead of this build alone", function()
		local db = Upgrade({ Version = 99, GroupEnabled = false, FutureKey = "keep" })

		fw.eq(db.Version, 99, "the stamp a newer build wrote is kept")
		fw.eq(db.GroupEnabled, false, "so are the settings beside it")
		fw.eq(db.FutureKey, "keep", "including a key this build knows nothing about")
	end)

	fw.it("leaves a profile whose version this build cannot step alone", function()
		local db = Upgrade({ Version = "9", GroupEnabled = false })

		fw.eq(db.Version, "9", "the stamp is left as it was found")
		fw.eq(db.GroupEnabled, false, "and the settings beside it")
	end)

	fw.it("keeps the spec cache reachable through a factory reset", function()
		-- The inspector binds db.SpecCache once at login, so a reset that drops the key leaves it
		-- writing into a table the saved variables no longer hold.
		local context = harness.Load("MiniMarkers")

		_G.MiniMarkersDB = nil
		harness.Login(context)

		local cache = _G.MiniMarkersDB.SpecCache

		fw.not_nil(cache, "the cache exists after a login")

		context.Addon.Framework:ResetSavedVars(context.Addon.Config.DbDefaults)

		fw.eq(_G.MiniMarkersDB.SpecCache, cache, "the same cache instance survived the reset")
	end)

	fw.it("runs no step at all for a brand new profile", function()
		-- The end state is the same either way, so counting the resets is what shows the chain
		-- was skipped.
		local context = harness.Load("MiniMarkers")
		local framework = context.Addon.Framework
		local originalReset = framework.ResetSavedVars
		local resets = 0

		function framework:ResetSavedVars(defaults)
			resets = resets + 1
			return originalReset(self, defaults)
		end

		_G.MiniMarkersDB = nil
		harness.Login(context)
		local db = _G.MiniMarkersDB

		fw.eq(resets, 0, "nothing was reset")
		fw.eq(db.Version, CURRENT_VERSION, "stamped current")
	end)
end)
