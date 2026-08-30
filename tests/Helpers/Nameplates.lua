-- Builds a mocked client with nameplates a test can add, remove, and read markers off, since
-- everything the addon draws hangs off a plate frame the client hands back.

local harness = require("AddonHarness")
local WowMock = require("WowMock")

local M = {}

M.UNIT = "nameplate1"
M.OTHER_UNIT = "nameplate2"

---Runs the addon's deferred nameplate work. The flush gives work queued in the current frame
---one frame of grace, so the clock has to move before it will do anything.
local function Flush()
	WowMock.AdvanceTime(1)
	WowMock.RunTimers()
end

---The next Build reinstalls the mock's own predicate, so a failed assertion cannot leak the
---override into another test.
function M.MarkSecret(...)
	local secrets = { ... }

	_G.issecretvalue = function(value)
		for _, secret in ipairs(secrets) do
			if rawequal(value, secret) then
				return true
			end
		end

		return false
	end
end

---The texture the addon drew into, which differs by whether the icon carries a colour.
---@param plate table?
---@return table?
function M.Icon(plate)
	local marker = plate and plate.Marker

	if not marker then
		return nil
	end

	if marker.WithColor:IsShown() then
		return marker.WithColor
	end

	if marker.WithoutColor:IsShown() then
		return marker.WithoutColor
	end

	return nil
end

---@return table env
function M.Build()
	local env = { Plates = {}, Atlases = {} }

	-- Saved variables outlive an Install, so an earlier file's settings would otherwise decide
	-- what this one draws.
	_G.MiniMarkersDB = nil

	env.Context = harness.Load("MiniMarkers")

	-- The Battle.net friend list has no mock, and the friend rule reads it for every plate.
	_G.BNGetNumFriends = function()
		return 0
	end
	_G.BNET_CLIENT_WOW = "WoW"

	-- The mock's own GetAtlasInfo answers for every name, which would send file paths down the
	-- atlas branch as well.
	_G.C_Texture.GetAtlasInfo = function(name)
		return env.Atlases[name]
	end

	_G.C_NamePlate.GetNamePlateForUnit = function(unit)
		return env.Plates[unit]
	end

	_G.C_NamePlate.GetNamePlates = function()
		local plates = {}

		for _, plate in pairs(env.Plates) do
			plates[#plates + 1] = plate
		end

		return plates
	end

	harness.Login(env.Context)

	env.Addon = env.Context.Addon
	env.Db = _G.MiniMarkersDB
	env.Flush = Flush

	---@param unit string
	---@return table plate
	function env.Plate(unit)
		local plate = _G.CreateFrame("Frame")
		plate.UnitFrame = _G.CreateFrame("Frame", nil, plate)
		plate.UnitFrame.unit = unit

		env.Plates[unit] = plate
		WowMock.State.Units[unit] = true

		return plate
	end

	---@param unit string
	function env.Add(unit)
		WowMock.FireEvent("NAME_PLATE_UNIT_ADDED", unit)
		Flush()
	end

	---@param unit string
	function env.Remove(unit)
		WowMock.FireEvent("NAME_PLATE_UNIT_REMOVED", unit)
		Flush()
	end

	---@param unit string
	---@return table?
	function env.Icon(unit)
		return M.Icon(env.Plates[unit])
	end

	-- Login leaves its own refresh queued; draining it here keeps it from swallowing the
	-- nameplate event a test fires next.
	Flush()

	return env
end

return M
