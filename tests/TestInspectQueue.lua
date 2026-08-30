-- Asking for a spec the inspector does not have queues an async inspect. A crowded zone asks
-- far more often than the client will answer, so what the queue drops matters as much as what
-- it keeps.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")
local WowMock = require("WowMock")

local PRIORITY_MAX = 10

fw.describe("MiniMarkers - the inspect queue", function()
	local env
	local inspected

	---One pass of the run loop, followed by the reply that frees it to start the next inspect.
	local function Drain(passes)
		for _ = 1, passes do
			WowMock.RunTimers(1)
			WowMock.FireEvent("INSPECT_READY")
		end
	end

	local function Ask(unit)
		WowMock.State.Units[unit] = true
		env.Addon.Inspector:GetUnitSpecId(unit)
	end

	fw.before_each(function()
		env = Nameplates.Build()
		inspected = {}

		_G.CanInspect = function()
			return true
		end

		-- The client never answers, so nothing is cached and every ask stays a queue question.
		_G.GetInspectSpecialization = function()
			return 0
		end

		_G.hooksecurefunc("NotifyInspect", function(unit)
			inspected[#inspected + 1] = unit
		end)
	end)

	fw.it("inspects the newest request first, and each unit once however often it is asked for", function()
		Ask("nameplate1")
		Ask("nameplate1")
		Ask("nameplate2")

		Drain(4)

		fw.eq(#inspected, 2, "two inspects out of three asks")
		fw.eq(inspected[1], "nameplate2", "the newest request goes first")
		fw.eq(inspected[2], "nameplate1", "then the one behind it")
	end)

	fw.it("drops the oldest requests once the queue is full", function()
		for i = 1, PRIORITY_MAX + 2 do
			Ask("nameplate" .. i)
		end

		Drain(PRIORITY_MAX + 4)

		fw.eq(#inspected, PRIORITY_MAX, "the queue never grew past its cap")
		fw.eq(inspected[1], "nameplate12", "the newest is still first")

		for _, unit in ipairs(inspected) do
			fw.neq(unit, "nameplate1", "the oldest request was dropped")
			fw.neq(unit, "nameplate2", "and the one after it")
		end
	end)
end)

fw.describe("MiniMarkers - where a spec comes from", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
	end)

	fw.it("prefers another addon's live answer to its own", function()
		WowMock.State.Units[Nameplates.UNIT] = true

		_G.FrameSortApi = {
			v3 = {
				Inspector = {
					GetUnitSpecId = function()
						return 999
					end,
				},
			},
		}

		fw.eq(env.Addon.InspectorFacade:GetUnitSpecId(Nameplates.UNIT), 999, "answered before the local cache")
	end)

	fw.it("falls back to the broadcast spec for an arena opponent, who cannot be inspected", function()
		WowMock.State.Units["arena2"] = true

		-- Neither call has a mock; an arena opponent's spec is broadcast rather than inspected.
		_G.GetArenaOpponentSpec = function(index)
			return 250 + index
		end
		_G.GetNumArenaOpponentSpecs = function()
			return 3
		end

		fw.eq(env.Addon.InspectorFacade:GetUnitSpecId("arena2"), 252, "read off the opponent's own slot")
	end)
end)
