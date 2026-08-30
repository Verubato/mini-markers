-- UnitIsPVP can come back secret for a nameplate unit under Midnight, so this drives the
-- real event pipeline and checks the unit is left alone.

local fw = require("TestFramework")
local harness = require("AddonHarness")
local WowMock = require("WowMock")

local TEST_UNIT = "nameplate6"

fw.describe("MiniMarkers - secret PvP status", function()
	fw.it("does not mark an enemy player whose PvP status comes back secret", function()
		local context = harness.Load("MiniMarkers")
		harness.Login(context)

		-- Login's own settle events leave a refresh queued; drain it before staging this
		-- scenario so it does not swallow the nameplate event this test fires below.
		WowMock.AdvanceTime(1)
		WowMock.RunTimers()

		WowMock.State.Units[TEST_UNIT] = true
		WowMock.State.InInstance = true
		WowMock.State.InstanceType = "arena"

		_G.UnitIsFriend = function(_, unit)
			return unit ~= TEST_UNIT
		end
		_G.UnitIsEnemy = function(_, unit)
			return unit == TEST_UNIT
		end

		-- Nothing in a Lua-only harness is really secret, so this table is nominated as the
		-- stand-in, the same way the framework's other tests do it.
		local secretPvp = {}

		_G.issecretvalue = function(value)
			return value == secretPvp
		end

		_G.UnitIsPVP = function()
			return secretPvp
		end

		local nameplate = _G.CreateFrame("Frame")
		nameplate.UnitFrame = _G.CreateFrame("Frame", nil, nameplate)

		_G.C_NamePlate.GetNamePlateForUnit = function(unit)
			return unit == TEST_UNIT and nameplate or nil
		end

		local db = _G.MiniMarkersDB
		db.EnemiesEnabled = false
		-- BNGetNumFriends has no mock, so this stays off to keep IsFriend from calling it.
		db.FriendsEnabled = false
		db.AlliesEnabled = true
		db.GroupEnabled = false
		db.NpcsEnabled = false
		db.PvPEnabled = true
		db.ArenaOnlyEnabled = true
		-- Forces GetIconOptions to hand back a texture once `pass` is true, so a leaked secret
		-- shows up as a marker instead of silently vanishing further down the pipeline.
		db.EnemyTextureIcons = true
		db.EnemyBackgroundEnabled = false
		db.EnemyBorderEnabled = false
		db.FriendlyBorderEnabled = false

		WowMock.FireEvent("NAME_PLATE_UNIT_ADDED", TEST_UNIT)
		-- Flush defers a frame, and it only runs once GetTime has moved past when it was queued.
		WowMock.AdvanceTime(1)
		WowMock.RunTimers()

		fw.is_nil(nameplate.Marker, "an enemy with an unreadable PvP flag gets no marker")
	end)
end)
