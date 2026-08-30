-- The inspector answers a plate's spec question from a GUID-keyed cache the client fills in
-- asynchronously, so these drive NotifyInspect and INSPECT_READY the way a real session does.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")
local WowMock = require("WowMock")

local UNIT = Nameplates.UNIT
local GUID = "Player-1-" .. UNIT
local SPEC = 256

local function Cached()
	return _G.MiniMarkersDB.SpecCache[GUID]
end

fw.describe("MiniMarkers - inspect results", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
		env.Db.FriendlySpecIcons = true
		env.Db.FriendlyTextureIcons = false

		_G.CanInspect = function()
			return true
		end
		_G.GetInspectSpecialization = function()
			return SPEC
		end

		env.Plate(UNIT)
	end)

	fw.it("caches what an inspect answers and puts the spec icon on the plate", function()
		env.Add(UNIT)

		fw.is_nil(env.Plates[UNIT].Marker, "nothing to draw before the inspect answers")

		_G.NotifyInspect(UNIT)
		WowMock.FireEvent("INSPECT_READY")
		env.Flush()

		fw.eq(Cached().SpecId, SPEC, "cached against the unit's guid")

		local icon = env.Icon(UNIT)

		fw.not_nil(icon, "the plate picked the result up")
		fw.truthy(icon:GetTexture():find("Specs\\" .. SPEC .. ".tga", 1, true) ~= nil, "the spec's own icon")
	end)

	fw.it("drops the cached spec when the unit changes specialization", function()
		_G.NotifyInspect(UNIT)
		WowMock.FireEvent("INSPECT_READY")
		env.Flush()

		fw.eq(Cached().SpecId, SPEC, "cached before the change")

		WowMock.FireEvent("PLAYER_SPECIALIZATION_CHANGED", UNIT)

		fw.is_nil(Cached(), "the stale entry is gone")

		env.Add(UNIT)

		fw.is_nil(env.Icon(UNIT), "and the plate has no spec to draw")
	end)

	fw.it("does not read the spec cache with a guid the client will not hand over", function()
		_G.MiniMarkersDB.SpecCache[GUID] = { SpecId = SPEC, LastSeen = _G.time() }

		Nameplates.MarkSecret(GUID)

		fw.is_nil(env.Addon.Inspector:GetUnitSpecId(UNIT), "an unreadable guid answers nothing")
	end)

	fw.it("does not cache a spec the client will not let it read", function()
		Nameplates.MarkSecret(SPEC)

		_G.NotifyInspect(UNIT)
		WowMock.FireEvent("INSPECT_READY")

		fw.is_nil(Cached(), "an unreadable spec is worth nothing to anyone reading the cache later")
	end)
end)

fw.describe("MiniMarkers - the tooltip fast path", function()
	local env

	---@param leftText string
	local function TooltipSays(leftText)
		_G.C_TooltipInfo.GetUnit = function()
			return { lines = { { leftText = leftText } } }
		end
	end

	fw.before_each(function()
		env = Nameplates.Build()
		env.Plate(UNIT)
	end)

	-- The mock names every spec "Spec", so a warrior's phrases are all "Spec Warrior" and the
	-- first of its three specs is the one a tail match lands on.
	fw.it("reads a spec straight out of a tooltip line", function()
		TooltipSays("Spec Warrior")

		fw.eq(env.Addon.Inspector:GetUnitSpecId(UNIT), 253, "the phrase matched a known spec")
	end)

	fw.it("matches the tail of a line the spec is folded into", function()
		TooltipSays("Level 80 Spec Warrior")

		fw.eq(env.Addon.Inspector:GetUnitSpecId(UNIT), 251, "matched against this unit's own class specs")
	end)

	fw.it("skips a tooltip line the client will not hand over", function()
		TooltipSays("Spec Warrior")
		Nameplates.MarkSecret("Spec Warrior")

		fw.is_nil(env.Addon.Inspector:GetUnitSpecId(UNIT), "an unreadable line matches nothing")
	end)

	fw.it("cannot narrow a tail match to a class the client will not hand over", function()
		TooltipSays("Level 80 Spec Warrior")
		Nameplates.MarkSecret("WARRIOR")

		fw.is_nil(env.Addon.Inspector:GetUnitSpecId(UNIT), "no per-class phrases to match the tail against")
	end)
end)
