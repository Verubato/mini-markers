-- The glow follows whichever plate belongs to the target, so it must leave a plate the moment the
-- target moves or the plate is handed to another unit.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")
local WowMock = require("WowMock")

local UNIT = Nameplates.UNIT
local OTHER = Nameplates.OTHER_UNIT

fw.describe("MiniMarkers - target glow", function()
	local env
	local target

	---@param unit string?
	local function Target(unit)
		target = unit
		WowMock.FireEvent("PLAYER_TARGET_CHANGED")
	end

	---@param unit string
	---@return boolean
	local function IsGlowing(unit)
		local glow = env.Plates[unit].Marker.Glow
		return glow ~= nil and glow:IsShown()
	end

	fw.before_each(function()
		env = Nameplates.Build()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true
		env.Db.TargetGlowEnabled = true
		target = nil

		local plateForUnit = _G.C_NamePlate.GetNamePlateForUnit

		_G.C_NamePlate.GetNamePlateForUnit = function(unit)
			if unit == "target" then
				return target and env.Plates[target]
			end

			return plateForUnit(unit)
		end
	end)

	fw.it("starts switched off in white", function()
		local defaults = env.Addon.Config.DbDefaults

		fw.eq(defaults.TargetGlowEnabled, false, "off until asked for")
		fw.eq(defaults.TargetGlowColor.R, 1, "red")
		fw.eq(defaults.TargetGlowColor.G, 1, "green")
		fw.eq(defaults.TargetGlowColor.B, 1, "blue")
	end)

	fw.it("glows the target's marker and no other", function()
		env.Plate(UNIT)
		env.Plate(OTHER)
		env.Add(UNIT)
		env.Add(OTHER)

		Target(UNIT)

		fw.truthy(IsGlowing(UNIT), "the target glows")
		fw.falsy(IsGlowing(OTHER), "the other plate does not")
	end)

	fw.it("leaves the target alone while the option is off", function()
		env.Db.TargetGlowEnabled = false

		env.Plate(UNIT)
		env.Add(UNIT)

		Target(UNIT)

		fw.falsy(IsGlowing(UNIT), "no glow")
	end)

	fw.it("moves with the target", function()
		env.Plate(UNIT)
		env.Plate(OTHER)
		env.Add(UNIT)
		env.Add(OTHER)

		Target(UNIT)
		Target(OTHER)

		fw.falsy(IsGlowing(UNIT), "the old target lets go")
		fw.truthy(IsGlowing(OTHER), "the new target takes it")

		Target(nil)

		fw.falsy(IsGlowing(OTHER), "and no target leaves nothing glowing")
	end)

	fw.it("glows a marker drawn for a unit that was already the target", function()
		env.Plate(UNIT)
		Target(UNIT)
		env.Add(UNIT)

		fw.truthy(IsGlowing(UNIT), "picked up when the marker is drawn")
	end)

	fw.it("drops the glow when the plate is taken away", function()
		env.Plate(UNIT)
		env.Add(UNIT)
		Target(UNIT)

		env.Remove(UNIT)

		fw.falsy(IsGlowing(UNIT), "a recycled plate carries no glow")
	end)

	fw.it("tints the glow in the chosen colour", function()
		env.Db.TargetGlowColor = { R = 0.5, G = 0.25, B = 0, A = 1 }

		env.Plate(UNIT)
		env.Add(UNIT)
		Target(UNIT)

		local r, g, b = env.Plates[UNIT].Marker.Glow.Texture:GetVertexColor()

		fw.eq(r, 0.5, "red")
		fw.eq(g, 0.25, "green")
		fw.eq(b, 0, "blue")
	end)
end)
