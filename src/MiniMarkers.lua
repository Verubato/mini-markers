local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
---@type Db
local db
---@type Db
local dbDefaults = addon.Config.DbDefaults
local eventsFrame
local bnCacheInvalidator
local bnFriendCache = {}
local bnCacheValid = false
local backgroundCircle = 1
local backgroundSquare = 2
local borderThickness = 2
local creatureTypeTotem = 11
local texturesRoot = "Interface\\AddOns\\" .. addonName .. "\\Textures\\"
local friendIconTexture = texturesRoot .. "Friend.tga"
local guildIconTexture = texturesRoot .. "Guild.tga"
local petIconTexture = texturesRoot .. "Pet.tga"
local ownPetIconTexture = texturesRoot .. "OwnPet.blp"
local circleShapeTexture = texturesRoot .. "Shapes\\Circle128x128.tga"
local squareShapeTexture = texturesRoot .. "Shapes\\White128x128.tga"

local function ResolveShape(shapeName)
	if shapeName == "circle" then
		return backgroundCircle
	end
	return backgroundSquare
end

---@class Marker
---@field WithColor table
---@field WithoutColor table
---@field IconMask table
---@field Background table
---@field Border table

local function IsUnitInMyGroup(unit)
	return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit)
end

local function NormalizeRealm(realm)
	if not realm or realm == "" then
		return GetNormalizedRealmName()
	end

	return realm
end

local function BnKey(name, realm)
	return name .. "-" .. NormalizeRealm(realm)
end

local function RebuildBNFriendCache()
	wipe(bnFriendCache)

	for i = 1, BNGetNumFriends() do
		local info = C_BattleNet.GetFriendAccountInfo(i)
		if info and info.gameAccountInfo then
			local game = info.gameAccountInfo

			if game.clientProgram == BNET_CLIENT_WOW and game.isOnline then
				local name = game.characterName
				local realm = game.realmName

				if name then
					bnFriendCache[BnKey(name, realm)] = true
				end
			end
		end
	end

	bnCacheValid = true
end

local function IsFriend(unit)
	if not bnCacheValid then
		RebuildBNFriendCache()
	end

	local name, realm = UnitName(unit)
	if not name then
		return false
	end

	if mini:IsSecret(name) or mini:IsSecret(realm) then
		return false
	end

	local key = BnKey(name, realm)
	return bnFriendCache[key] == true
end

local function IsOwnPet(unit)
	return UnitIsUnit(unit, "pet")
end

local function IsPet(unit)
	if IsOwnPet(unit) then
		return true
	end

	if UnitIsOtherPlayersPet(unit) then
		return true
	end

	return false
end

local function IsTotem(unit)
	local creatureType, creatureTypeId = UnitCreatureType(unit)

	-- in midnight we can't tell
	if mini:IsSecret(creatureType) or mini:IsSecret(creatureTypeId) then
		return false
	end

	return creatureType == "Totem" or creatureTypeId == creatureTypeTotem
end

local function IsArenaInstance()
	local inInstance, instanceType = IsInInstance()
	return inInstance and instanceType == "arena"
end

local function HasAnyRoleFilter(isFriendly, isEnemy)
	if isFriendly then
		return not db.FriendlyTankEnabled or not db.FriendlyHealerEnabled or not db.FriendlyDpsEnabled
	end

	if isEnemy then
		return not db.EnemyTankEnabled or not db.EnemyHealerEnabled or not db.EnemyDpsEnabled
	end

	return false
end

local function IsRoleEnabled(role, isFriendly, isEnemy)
	if isFriendly then
		if role == "TANK" then
			return db.FriendlyTankEnabled
		elseif role == "HEALER" then
			return db.FriendlyHealerEnabled
		elseif role == "DAMAGER" then
			return db.FriendlyDpsEnabled
		end
	elseif isEnemy then
		if role == "TANK" then
			return db.EnemyTankEnabled
		elseif role == "HEALER" then
			return db.EnemyHealerEnabled
		elseif role == "DAMAGER" then
			return db.EnemyDpsEnabled
		end
	end

	return false
end

-- Resolves whether a unit should be treated as friendly or enemy.
-- Group members are always friendly: opposite-faction arena teammates (cross-faction /
-- mercenary mode) can make UnitIsEnemy report them as hostile, which would otherwise
-- route them down the enemy path and drop their marker.
local function GetUnitReaction(unit)
	if IsUnitInMyGroup(unit) then
		return true, false
	end

	local isFriendly = UnitIsFriend("player", unit)
	local isEnemy = UnitIsEnemy("player", unit)

	-- treat neutrals as friendly
	if not isFriendly and not isEnemy then
		isFriendly = true
	end

	return isFriendly, isEnemy
end

local function GetClassColor(unit)
	local _, classTag = UnitClass(unit)
	local color = classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]
	return color and { R = color.r, G = color.g, B = color.b, A = 1 }
end

local function GetUnitColor(unit)
	local _, isEnemy = GetUnitReaction(unit)

	if isEnemy and db.EnemyRedEnabled then
		return { R = 1, G = 0, B = 0, A = 1 }
	end

	if db.IconClassColors then
		return GetClassColor(unit)
	end

	return { R = 1, G = 1, B = 1, A = 1 }
end

local function GetNameplateAnchor(nameplate)
	-- nameplate addons hide the UnitFrame but not the nameplate
	return nameplate.UnitFrame:IsVisible() and nameplate.UnitFrame or nameplate
end

-- Selects an icon for a unit in priority order: spec -> role -> class -> texture.
-- Used for both the single-unit path and the per-arena-unit multi-icon path.
local function GetIconOptions(unit, isFriendly, isEnemy, backgroundEnabled)
	local iconWidth = isEnemy and (db.EnemyIconWidth or dbDefaults.EnemyIconWidth) or (db.FriendlyIconWidth or dbDefaults.FriendlyIconWidth)
	local iconHeight = isEnemy and (db.EnemyIconHeight or dbDefaults.EnemyIconHeight) or (db.FriendlyIconHeight or dbDefaults.FriendlyIconHeight)
	local backgroundPadding = isEnemy and (db.EnemyBackgroundPadding or dbDefaults.EnemyBackgroundPadding) or (db.FriendlyBackgroundPadding or dbDefaults.FriendlyBackgroundPadding)
	local shapeName = isEnemy and (db.EnemyIconShape or dbDefaults.EnemyIconShape) or (db.FriendlyIconShape or dbDefaults.FriendlyIconShape)
	local shape = ResolveShape(shapeName)
	local borderEnabled = isEnemy and db.EnemyBorderEnabled or db.FriendlyBorderEnabled
	local borderColor = borderEnabled and GetClassColor(unit) or nil
	local fs = FrameSortApi and FrameSortApi.v3

	if
		UnitIsPlayer(unit)
		and GetSpecializationInfoByID
		and ((isFriendly and db.FriendlySpecIcons) or (isEnemy and db.EnemySpecIcons))
		and fs
		and fs.Inspector
		and fs.Inspector.GetUnitSpecId
	then
		local specId = fs.Inspector:GetUnitSpecId(unit)

		if specId then
			local _, _, _, icon = GetSpecializationInfoByID(specId)
			local texture = texturesRoot .. "Specs\\" .. specId .. ".tga"

			return {
				Texture = texture,
				FallbackTexture = icon,
				BackgroundEnabled = backgroundEnabled,
				BackgroundShape = shape,
				BackgroundPadding = backgroundPadding,
				BorderEnabled = borderEnabled and borderColor ~= nil,
				BorderColor = borderColor,
				Width = iconWidth,
				Height = iconHeight,
			}
		end
	end

	if (isFriendly and db.FriendlyRoleIcons) or (isEnemy and db.EnemyRoleIcons) then
		local role

		if IsUnitInMyGroup(unit) then
			role = UnitGroupRolesAssigned(unit)
		elseif GetSpecializationInfoByID and fs and fs.Inspector and fs.Inspector.GetUnitSpecId then
			local specId = fs.Inspector:GetUnitSpecId(unit)

			if specId then
				local _, _, _, _, specRole = GetSpecializationInfoByID(specId)
				role = specRole
			end
		end

		if role and role ~= "NONE" then
			return {
				Texture = texturesRoot .. "Roles\\" .. role .. ".tga",
				BackgroundEnabled = backgroundEnabled,
				BackgroundShape = shape,
				BackgroundPadding = backgroundPadding,
				BorderEnabled = borderEnabled and borderColor ~= nil,
				BorderColor = borderColor,
				Width = iconWidth,
				Height = iconHeight,
				Color = GetUnitColor(unit),
				Desaturated = db.IconDesaturated or dbDefaults.IconDesaturated,
			}
		end
	end

	if (isFriendly and db.FriendlyClassIcons) or (isEnemy and db.EnemyClassIcons) then
		local _, classFilename = UnitClass(unit)

		if classFilename then
			return {
				Texture = texturesRoot .. "Classes\\" .. classFilename .. ".tga",
				BackgroundEnabled = backgroundEnabled,
				BackgroundShape = shape,
				BackgroundPadding = backgroundPadding,
				BorderEnabled = borderEnabled and borderColor ~= nil,
				BorderColor = borderColor,
				Width = iconWidth,
				Height = iconHeight,
			}
		end
	end

	if (isFriendly and db.FriendlyTextureIcons) or (isEnemy and db.EnemyTextureIcons) then
		return {
			Texture = db.IconTexture or dbDefaults.IconTexture,
			BackgroundEnabled = backgroundEnabled,
			BackgroundShape = shape,
			BackgroundPadding = backgroundPadding,
			BorderEnabled = borderEnabled and borderColor ~= nil,
			BorderColor = borderColor,
			Rotation = db.IconRotation or dbDefaults.IconRotation,
			Width = iconWidth,
			Height = iconHeight,
			Color = GetUnitColor(unit),
			Desaturated = db.IconDesaturated or dbDefaults.IconDesaturated,
		}
	end

	return nil
end

local function GetTextureForUnit(unit)
	if not UnitExists(unit) then
		return nil
	end

	if UnitIsUnit(unit, "player") then
		-- prevent anchoring to the personal resource display
		return nil
	end

	-- ignore totems
	if IsTotem(unit) then
		return nil
	end

	local isArena = IsArenaInstance()

	if db.ArenaOnlyEnabled and not isArena then
		return nil
	end

	local iconWidth = db.FriendlyIconWidth or dbDefaults.FriendlyIconWidth
	local iconHeight = db.FriendlyIconHeight or dbDefaults.FriendlyIconHeight
	local friendlyBackgroundPadding = db.FriendlyBackgroundPadding or dbDefaults.FriendlyBackgroundPadding
	local friendlyShape = ResolveShape(db.FriendlyIconShape or dbDefaults.FriendlyIconShape)
	local friendlyBorderColor = db.FriendlyBorderEnabled and GetClassColor(unit) or nil
	local friendlyBorderEnabled = db.FriendlyBorderEnabled and friendlyBorderColor ~= nil

	if IsPet(unit) then
		local isOwnPet = IsOwnPet(unit)

		if isOwnPet then
			if not db.OwnPetEnabled then
				return nil
			end
		elseif not db.PetsEnabled then
			return nil
		end

		-- own pet is a deliberate highlight, so render it at full marker size;
		-- other pets keep the de-emphasized pet scale
		local petScale = isOwnPet and 1 or (db.PetIconScale or dbDefaults.PetIconScale)
		return {
			Texture = isOwnPet and ownPetIconTexture or petIconTexture,
			BackgroundEnabled = db.FriendlyBackgroundEnabled,
			BackgroundShape = friendlyShape,
			BackgroundPadding = friendlyBackgroundPadding,
			BorderEnabled = friendlyBorderEnabled,
			BorderColor = friendlyBorderColor,
			Width = iconWidth * petScale,
			Height = iconHeight * petScale,
			Color = db.IconClassColors and GetClassColor(unit) or nil,
		}
	end

	if db.FriendsEnabled and IsFriend(unit) then
		return {
			Texture = friendIconTexture,
			BackgroundEnabled = db.FriendlyBackgroundEnabled,
			BackgroundShape = friendlyShape,
			BackgroundPadding = friendlyBackgroundPadding,
			BorderEnabled = friendlyBorderEnabled,
			BorderColor = friendlyBorderColor,
			Width = iconWidth,
			Height = iconHeight,
		}
	end

	if db.GuildEnabled and UnitIsInMyGuild(unit) then
		return {
			Texture = guildIconTexture,
			BackgroundEnabled = db.FriendlyBackgroundEnabled,
			BackgroundShape = friendlyShape,
			BackgroundPadding = friendlyBackgroundPadding,
			BorderEnabled = friendlyBorderEnabled,
			BorderColor = friendlyBorderColor,
			Width = iconWidth,
			Height = iconHeight,
		}
	end

	local isPlayer = UnitIsPlayer(unit)
	local isFriendly, isEnemy = GetUnitReaction(unit)

	local pass = false
	local backgroundEnabled = (isFriendly and db.FriendlyBackgroundEnabled) or (isEnemy and db.EnemyBackgroundEnabled)

	if db.EnemiesEnabled then
		if mini:HasSecrets() then
			-- enemy markers are broken in Midnight
			if isEnemy then
				return nil
			end
		end

		pass = pass or (isPlayer and isEnemy)
	end

	if db.AlliesEnabled then
		pass = pass or (isPlayer and isFriendly)
	end

	if db.GroupEnabled then
		pass = pass or (isPlayer and IsUnitInMyGroup(unit))
	end

	if db.NpcsEnabled then
		pass = pass or not isPlayer
	end

	if db.PvPEnabled then
		pass = pass or (isPlayer and UnitIsPVP(unit))
	end

	if not pass then
		return nil
	end

	if HasAnyRoleFilter(isFriendly, isEnemy) then
		local role
		local fs = FrameSortApi and FrameSortApi.v3

		if IsUnitInMyGroup(unit) then
			role = UnitGroupRolesAssigned(unit)
		else
			local specId = fs and fs.Inspector and fs.Inspector:GetUnitSpecId(unit)

			if specId then
				local _, _, _, _, specRole = GetSpecializationInfoByID(specId)
				role = specRole
			end
		end

		pass = role and IsRoleEnabled(role, isFriendly, isEnemy)
	end

	if not pass then
		return nil
	end

	return GetIconOptions(unit, isFriendly, isEnemy, backgroundEnabled)
end

-- nameplates move at sub-pixel positions; the default pixel-grid snapping rounds
-- each texture's edges to the device grid independently, so the border rim shifts
-- by +/-1px frame-to-frame as a unit drifts, which reads as flickering. Disabling
-- snapping keeps every texture aligned to the icon at exact (fractional) positions.
local function DisablePixelSnapping(texture)
	texture:SetSnapToPixelGrid(false)
	texture:SetTexelSnappingBias(0)
end

---@return Marker
local function GetOrCreateMarker(nameplate)
	local marker = nameplate.Marker
	local ignoreAlpha = not db.EnableDistanceFading

	if marker then
		-- in case the db value has changed
		marker.WithColor:SetIgnoreParentAlpha(ignoreAlpha)
		marker.WithoutColor:SetIgnoreParentAlpha(ignoreAlpha)
		marker.Background.Circle:SetIgnoreParentAlpha(ignoreAlpha)
		marker.Background.Square:SetIgnoreParentAlpha(ignoreAlpha)
		marker.Border.Circle:SetIgnoreParentAlpha(ignoreAlpha)
		marker.Border.Square:SetIgnoreParentAlpha(ignoreAlpha)

		return marker
	end

	marker = {
		WithoutColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
		WithColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
		IconMask = nameplate:CreateMaskTexture(),
		Background = {
			Circle = nameplate:CreateTexture(nil, "BACKGROUND", nil, 1),
			Square = nameplate:CreateTexture(nil, "BACKGROUND", nil, 1),
		},
		Border = {
			Circle = nameplate:CreateTexture(nil, "BACKGROUND", nil, 0),
			Square = nameplate:CreateTexture(nil, "BACKGROUND", nil, 0),
		},
	}

	DisablePixelSnapping(marker.WithoutColor)
	DisablePixelSnapping(marker.WithColor)
	DisablePixelSnapping(marker.IconMask)
	DisablePixelSnapping(marker.Background.Circle)
	DisablePixelSnapping(marker.Background.Square)
	DisablePixelSnapping(marker.Border.Circle)
	DisablePixelSnapping(marker.Border.Square)

	local bg = marker.Background

	local squareTexture = nameplate:CreateMaskTexture()
	squareTexture:SetTexture(squareShapeTexture)
	squareTexture:SetAllPoints(bg.Square)
	DisablePixelSnapping(squareTexture)

	bg.Square:AddMaskTexture(squareTexture)
	bg.Square:SetColorTexture(0, 0, 0, 1)

	-- don't use masks for circles as they don't scale properly at different sizes
	bg.Circle:SetTexture(circleShapeTexture)
	bg.Circle:SetVertexColor(0, 0, 0, 1)

	local border = marker.Border

	local borderSquareMask = nameplate:CreateMaskTexture()
	borderSquareMask:SetTexture(squareShapeTexture)
	borderSquareMask:SetAllPoints(border.Square)
	DisablePixelSnapping(borderSquareMask)

	border.Square:AddMaskTexture(borderSquareMask)
	border.Square:SetColorTexture(1, 1, 1, 1)

	border.Circle:SetTexture(circleShapeTexture)

	-- masks icon textures to the configured shape; texture changes per shape in AddMarker
	marker.IconMask:SetTexture(squareShapeTexture)
	marker.WithColor:AddMaskTexture(marker.IconMask)
	marker.WithoutColor:AddMaskTexture(marker.IconMask)

	marker.WithColor:SetIgnoreParentAlpha(ignoreAlpha)
	marker.WithoutColor:SetIgnoreParentAlpha(ignoreAlpha)
	bg.Circle:SetIgnoreParentAlpha(ignoreAlpha)
	bg.Square:SetIgnoreParentAlpha(ignoreAlpha)
	border.Circle:SetIgnoreParentAlpha(ignoreAlpha)
	border.Square:SetIgnoreParentAlpha(ignoreAlpha)

	marker.WithoutColor:Hide()
	marker.WithColor:Hide()
	border.Circle:Hide()
	border.Square:Hide()

	nameplate.Marker = marker
	return marker
end

local function HideMarkerBackground(marker)
	if not marker.Background then
		return
	end

	if marker.Background.Circle then
		marker.Background.Circle:Hide()
	end

	if marker.Background.Square then
		marker.Background.Square:Hide()
	end
end

local function HideMarkerBorder(marker)
	if not marker.Border then
		return
	end

	if marker.Border.Circle then
		marker.Border.Circle:Hide()
	end

	if marker.Border.Square then
		marker.Border.Square:Hide()
	end
end

local function ApplyShape(shapeTexture, texture, extraPadding)
	extraPadding = extraPadding or 0

	local w, h = texture:GetSize()
	local size = math.max(w, h) + extraPadding * 2
	size = math.floor(size + 0.5)

	shapeTexture:ClearAllPoints()
	shapeTexture:SetPoint("CENTER", texture, "CENTER")
	shapeTexture:SetSize(size, size)
	shapeTexture:Show()
end

local function HideMarker(nameplate)
	local marker = nameplate.Marker

	if not marker then
		return
	end

	marker.WithColor:Hide()
	marker.WithoutColor:Hide()

	HideMarkerBackground(marker)
	HideMarkerBorder(marker)
end

local function AddMarker(unit, nameplate)
	local options = GetTextureForUnit(unit)

	if not options then
		HideMarker(nameplate)
		return
	end

	local marker = GetOrCreateMarker(nameplate)

	if not marker then
		return
	end

	local texture

	if options.Color then
		texture = marker.WithColor
		marker.WithoutColor:Hide()
	else
		texture = marker.WithoutColor
		marker.WithColor:Hide()
	end

	if options.Texture then
		-- texture might be a number, in which case we need to parse it as such
		local name = tonumber(options.Texture) or options.Texture
		local isAtlas = C_Texture.GetAtlasInfo(name) ~= nil

		if isAtlas then
			texture:SetAtlas(name, false)
		else
			texture:SetTexture(name)

			if not texture:GetTexture() and options.FallbackTexture then
				texture:SetTexture(options.FallbackTexture)
			end
		end
	end

	texture:SetSize(options.Width or 20, options.Height or 20)
	texture:SetDesaturated(options.Desaturated and true or false)
	texture:SetRotation(math.rad(options.Rotation or 0))

	if options.Color then
		texture:SetVertexColor(options.Color.R, options.Color.G, options.Color.B, options.Color.A)
	end

	local anchor = GetNameplateAnchor(nameplate)
	local _, isEnemyUnit = GetUnitReaction(unit)
	local offsetX = isEnemyUnit and (tonumber(db.EnemyOffsetX) or 0) or (tonumber(db.FriendlyOffsetX) or 0)
	local offsetY = isEnemyUnit and (tonumber(db.EnemyOffsetY) or 0) or (tonumber(db.FriendlyOffsetY) or 0)
	texture:ClearAllPoints()
	texture:SetPoint("BOTTOM", anchor, "TOP", offsetX, offsetY)
	texture:Show()

	local shapeTextureFile = options.BackgroundShape == backgroundCircle and circleShapeTexture or squareShapeTexture
	marker.IconMask:SetTexture(shapeTextureFile)
	marker.IconMask:ClearAllPoints()
	marker.IconMask:SetAllPoints(texture)

	HideMarkerBackground(marker)
	HideMarkerBorder(marker)

	if options.BackgroundEnabled then
		local padding = options.BackgroundPadding or 0
		local bg

		if options.BackgroundShape == backgroundCircle then
			bg = marker.Background.Circle
		elseif options.BackgroundShape == backgroundSquare then
			bg = marker.Background.Square
		end

		if bg then
			ApplyShape(bg, texture, padding)
		end
	end

	if options.BorderEnabled and options.BorderColor then
		local padding = options.BackgroundEnabled and (options.BackgroundPadding or 0) or 0
		local border

		if options.BackgroundShape == backgroundCircle then
			border = marker.Border.Circle
			border:SetVertexColor(options.BorderColor.R, options.BorderColor.G, options.BorderColor.B, options.BorderColor.A)
		elseif options.BackgroundShape == backgroundSquare then
			border = marker.Border.Square
			border:SetColorTexture(options.BorderColor.R, options.BorderColor.G, options.BorderColor.B, options.BorderColor.A)
		end

		if border then
			ApplyShape(border, texture, padding + borderThickness)
		end
	end
end

local function UpdateAllNameplates()
	for _, nameplate in ipairs(C_NamePlate.GetNamePlates(false) or {}) do
		if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.unit then
			AddMarker(nameplate.UnitFrame.unit, nameplate)
		end
	end
end

local function ProcessEvent(event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" then
		local nameplate = unit and C_NamePlate.GetNamePlateForUnit(unit)

		if nameplate then
			AddMarker(unit, nameplate)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local nameplate = unit and C_NamePlate.GetNamePlateForUnit(unit)

		if nameplate then
			HideMarker(nameplate)
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
		UpdateAllNameplates()
	end
end

local function OnEvent(_, event, unit)
	-- delay our processing to wait for other nameplate addons to process it first
	C_Timer.After(0, function()
		ProcessEvent(event, unit)
	end)
end

local function OnFrameSortInspect()
	UpdateAllNameplates()
end

local function OnAddonLoaded()
	addon.Config:Init()

	local fs = FrameSortApi and FrameSortApi.v3

	if fs and fs.Inspector and fs.Inspector.RegisterCallback then
		fs.Inspector:RegisterCallback(OnFrameSortInspect)
	end

	db = MiniMarkersDB or {}

	eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", OnEvent)
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventsFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	eventsFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
end

function addon:Refresh()
	db = mini:GetSavedVars()
	UpdateAllNameplates()
end

if not C_NamePlate or not C_NamePlate.GetNamePlates or not C_NamePlate.GetNamePlateForUnit then
	mini:Notify("Unable to run due to missing nameplate APIs.")
	return
end

mini:WaitForAddonLoad(OnAddonLoaded)

bnCacheInvalidator = CreateFrame("Frame")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_INFO_CHANGED")
bnCacheInvalidator:RegisterEvent("FRIENDLIST_UPDATE")

bnCacheInvalidator:SetScript("OnEvent", function()
	bnCacheValid = false
end)
