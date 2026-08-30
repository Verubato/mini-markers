-- The client hands a Midnight addon values it must not compare, concatenate, or use as a table
-- key. Each of these drives the branch a guard protects, through the real nameplate pipeline.

local fw = require("TestFramework")
local Nameplates = require("Nameplates")

local UNIT = Nameplates.UNIT
local ENEMY = Nameplates.OTHER_UNIT

fw.describe("MiniMarkers - secret values", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
	end)

	fw.it("does not build a friend key out of a name the client will not hand over", function()
		local secretName = {}

		env.Db.FriendsEnabled = true
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true

		Nameplates.MarkSecret(secretName)

		_G.UnitName = function()
			return secretName, nil
		end

		env.Plate(UNIT)

		fw.no_error(function()
			env.Add(UNIT)
		end, "a unit whose name is secret")

		fw.not_nil(env.Icon(UNIT), "the ally rule still marks it")
	end)

	fw.it("does not read a totem out of a creature type the client will not hand over", function()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true

		Nameplates.MarkSecret("Totem")

		_G.UnitCreatureType = function()
			return "Totem", 11
		end

		env.Plate(UNIT)
		env.Add(UNIT)

		fw.not_nil(env.Icon(UNIT), "an unreadable creature type is nobody's totem")
	end)

	fw.it("leaves the border off when the class its colour comes from is secret", function()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true
		env.Db.FriendlyBorderEnabled = true
		env.Db.FriendlyBackgroundEnabled = false
		env.Db.IconClassColors = false

		Nameplates.MarkSecret("WARRIOR")

		env.Plate(UNIT)
		env.Add(UNIT)

		fw.falsy(env.Plates[UNIT].Marker.Border.Square:IsShown(), "no colour to draw a border in")
	end)

	fw.it("does not build a class texture path out of a class file name the client will not hand over", function()
		local secretClass = {}

		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyClassIcons = true
		env.Db.FriendlyTextureIcons = false
		env.Db.FriendlyBorderEnabled = false

		Nameplates.MarkSecret(secretClass)

		_G.UnitClass = function()
			return "Warrior", secretClass, 1
		end

		env.Plate(UNIT)

		fw.no_error(function()
			env.Add(UNIT)
		end, "a unit whose class file name is secret")

		fw.is_nil(env.Plates[UNIT].Marker, "no icon rule was left to draw one")
	end)

	fw.it("drops enemy markers on a client that produces secret values, keeping friendly ones", function()
		env.Db.FriendlySpecIcons = false
		env.Db.EnemySpecIcons = false
		env.Db.FriendlyTextureIcons = true
		env.Db.EnemyTextureIcons = true

		_G.LE_EXPANSION_LEVEL_CURRENT = _G.LE_EXPANSION_MIDNIGHT

		_G.UnitIsFriend = function(_, unit)
			return unit ~= ENEMY
		end
		_G.UnitIsEnemy = function(_, unit)
			return unit == ENEMY
		end

		env.Plate(UNIT)
		env.Plate(ENEMY)
		env.Add(UNIT)
		env.Add(ENEMY)

		fw.not_nil(env.Icon(UNIT), "the ally still gets a marker")
		fw.is_nil(env.Plates[ENEMY].Marker, "the enemy does not")
	end)

	fw.it("does not hand a texture the client will not let it read to any texture api", function()
		local secretTexture = {}

		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true

		Nameplates.MarkSecret(secretTexture)

		env.Db.IconTexture = secretTexture

		env.Plate(UNIT)
		env.Add(UNIT)

		local icon = env.Icon(UNIT)

		fw.not_nil(icon, "the marker is still placed")
		fw.is_nil(icon:GetAtlas(), "no atlas resolved from it")
		fw.is_nil(icon:GetTexture(), "and no texture set from it")
	end)
end)

fw.describe("MiniMarkers - resolving the texture option", function()
	local env

	fw.before_each(function()
		env = Nameplates.Build()
		env.Db.FriendlySpecIcons = false
		env.Db.FriendlyTextureIcons = true
		env.Plate(UNIT)
	end)

	fw.it("draws a name the client knows as an atlas", function()
		env.Atlases["plunderstorm-glues-logoarrow"] = { file = 0 }
		env.Db.IconTexture = "plunderstorm-glues-logoarrow"

		env.Add(UNIT)

		local icon = env.Icon(UNIT)

		fw.eq(icon:GetAtlas(), "plunderstorm-glues-logoarrow", "resolved as an atlas")
		fw.is_nil(icon:GetTexture(), "not as a file")
	end)

	fw.it("draws a name the client does not know as a file path", function()
		env.Db.IconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

		env.Add(UNIT)

		local icon = env.Icon(UNIT)

		fw.eq(icon:GetTexture(), "Interface\\Icons\\INV_Misc_QuestionMark", "resolved as a file")
		fw.is_nil(icon:GetAtlas(), "not as an atlas")
	end)

	fw.it("turns a file id stored as text back into a number", function()
		env.Db.IconTexture = "134400"

		env.Add(UNIT)

		fw.eq(env.Icon(UNIT):GetTexture(), 134400, "a file id reaches SetTexture as a number")
	end)
end)
