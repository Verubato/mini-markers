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
local texturesRoot = "Interface\\AddOns\\" .. addonName .. "\\Icons\\"

---@class Marker
---@field WithColor table
---@field WithoutColor table
---@field Background table

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

	local key = BnKey(name, realm)
	return bnFriendCache[key] == true
end

local function IsPet(unit)
	if UnitIsUnit(unit, "pet") then
		return true
	end

	if UnitIsOtherPlayersPet(unit) then
		return true
	end

	return false
end

local function CircleBackgroundPadding(width)
	return (width / 10) + 10
end

local function SquareBackgroundPadding(width)
	return (width / 10)
end

local function GetClassColor(unit)
	local _, classTag = UnitClass(unit)
	local color = classTag and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]
	return color and { R = color.r, G = color.g, B = color.b, A = 1 }
end

local function GetNameplateAnchor(nameplate)
	-- nameplate addons hide the UnitFrame but not the nameplate
	return nameplate.UnitFrame:IsVisible() and nameplate.UnitFrame or nameplate
end

local function GetTextureForUnit(unit)
	if not UnitExists(unit) then
		return nil
	end

	if UnitIsUnit(unit, "player") then
		-- prevent anchoring to the personal resource display
		return nil
	end

	local iconWidth = db.IconWidth or dbDefaults.IconWidth
	local iconHeight = db.IconHeight or dbDefaults.IconHeight

	if IsPet(unit) then
		if not db.PetsEnabled and not db.EveryoneEnabled then
			return nil
		end

		local petScale = db.PetIconScale or dbDefaults.PetIconScale
		return {
			Texture = db.PetIconTexture or dbDefaults.PetIconTexture,
			BackgroundEnabled = db.BackgroundEnabled,
			BackgroundShape = backgroundCircle,
			BackgroundPadding = CircleBackgroundPadding(iconWidth * petScale),
			Width = iconWidth * petScale,
			Height = iconHeight * petScale,
			Color = db.IconClassColors and GetClassColor(unit) or nil,
		}
	end

	if db.FriendsEnabled and IsFriend(unit) then
		return {
			Texture = db.FriendIconTexture or dbDefaults.FriendIconTexture,
			BackgroundEnabled = db.BackgroundEnabled,
			BackgroundShape = backgroundCircle,
			BackgroundPadding = CircleBackgroundPadding(iconWidth),
			Width = iconWidth,
			Height = iconHeight,
		}
	end

	if db.GuildEnabled and UnitIsInMyGuild(unit) then
		return {
			Texture = db.GuildIconTexture or dbDefaults.GuildIconTexture,
			BackgroundEnabled = db.BackgroundEnabled,
			BackgroundShape = backgroundCircle,
			BackgroundPadding = CircleBackgroundPadding(iconWidth),
			Width = iconWidth,
			Height = iconHeight,
		}
	end

	local pass = db.EveryoneEnabled

	if db.EnemiesEnabled then
		pass = pass or (UnitIsPlayer(unit) and UnitIsEnemy("player", unit))
	end

	if db.AlliesEnabled then
		pass = pass or (UnitIsPlayer(unit) and UnitIsFriend("player", unit))
	end

	if db.GroupEnabled then
		pass = pass or (UnitIsPlayer(unit) and IsUnitInMyGroup(unit))
	end

	if db.NpcsEnabled then
		pass = pass or not UnitIsPlayer(unit)
	end

	if not pass then
		return nil
	end

	-- prioritise icons in this order: spec -> role -> class -> texture
	local fs = FrameSortApi and FrameSortApi.v3
	if
		UnitIsPlayer(unit)
		and db.SpecIcons
		and GetSpecializationInfoByID
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
				BackgroundEnabled = db.BackgroundEnabled,
				BackgroundShape = backgroundSquare,
				BackgroundPadding = SquareBackgroundPadding(iconWidth),
				Width = db.IconWidth or dbDefaults.IconWidth,
				Height = db.IconHeight or dbDefaults.IconHeight,
			}
		end
	end

	if db.RoleIcons then
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
				BackgroundEnabled = db.BackgroundEnabled,
				BackgroundShape = backgroundCircle,
				BackgroundPadding = CircleBackgroundPadding(iconWidth),
				Width = iconWidth,
				Height = iconHeight,
				Color = db.IconClassColors and GetClassColor(unit) or nil,
				Desaturated = db.IconDesaturated or dbDefaults.IconDesaturated,
			}
		end
	end

	if db.ClassIcons then
		local _, classFilename = UnitClass(unit)

		if classFilename then
			return {
				Texture = texturesRoot .. "Classes\\" .. classFilename .. ".tga",
				-- force background, don't use config
				BackgroundEnabled = true,
				BackgroundShape = backgroundCircle,
				BackgroundPadding = CircleBackgroundPadding(iconWidth),
				Width = db.IconWidth or dbDefaults.IconWidth,
				Height = db.IconHeight or dbDefaults.IconHeight,
			}
		end
	end

	if db.TextureIcons then
		return {
			Texture = db.IconTexture or dbDefaults.IconTexture,
			BackgroundEnabled = db.BackgroundEnabled,
			BackgroundShape = backgroundCircle,
			BackgroundPadding = CircleBackgroundPadding(iconWidth),
			Rotation = db.IconRotation or dbDefaults.IconRotation,
			Width = db.IconWidth or dbDefaults.IconWidth,
			Height = db.IconHeight or dbDefaults.IconHeight,
			Color = db.IconClassColors and GetClassColor(unit) or nil,
			Desaturated = db.IconDesaturated or dbDefaults.IconDesaturated,
		}
	end

	return nil
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

		return marker
	end

	marker = {
		WithoutColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
		WithColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
		Background = {
			Circle = nameplate:CreateTexture(nil, "BACKGROUND"),
			Square = nameplate:CreateTexture(nil, "BACKGROUND"),
		},
	}

	local bg = marker.Background

	local squareTexture = nameplate:CreateMaskTexture()
	squareTexture:SetTexture(texturesRoot .. "Shapes\\White128x128.tga")
	squareTexture:SetAllPoints(bg.Square)

	bg.Square:AddMaskTexture(squareTexture)
	bg.Square:SetColorTexture(0, 0, 0, 1)

	-- don't use masks for circles as they don't scale properly at different sizes
	bg.Circle:SetTexture(texturesRoot .. "Shapes\\Circle128x128.tga")
	bg.Circle:SetVertexColor(0, 0, 0, 1)

	marker.WithColor:SetIgnoreParentAlpha(ignoreAlpha)
	marker.WithoutColor:SetIgnoreParentAlpha(ignoreAlpha)
	bg.Circle:SetIgnoreParentAlpha(ignoreAlpha)
	bg.Square:SetIgnoreParentAlpha(ignoreAlpha)

	marker.WithoutColor:Hide()
	marker.WithColor:Hide()

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

local function ApplyBackground(bg, texture, padding)
	padding = padding or 0

	local w, h = texture:GetSize()
	local size = math.max(w, h) + padding * 2
	size = math.floor(size + 0.5)

	bg:ClearAllPoints()
	bg:SetPoint("CENTER", texture, "CENTER")
	bg:SetSize(size, size)
	bg:Show()
end

local function HideMarker(nameplate)
	local marker = nameplate.Marker

	if not marker then
		return
	end

	marker.WithColor:Hide()
	marker.WithoutColor:Hide()

	HideMarkerBackground(marker)
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
	texture:ClearAllPoints()
	texture:SetPoint("BOTTOM", anchor, "TOP", tonumber(db.OffsetX) or 0, tonumber(db.OffsetY) or 0)
	texture:Show()

	if options.BackgroundEnabled then
		local padding = options.BackgroundPadding or 0
		local bg

		if options.BackgroundShape == backgroundCircle then
			bg = marker.Background.Circle
		elseif options.BackgroundShape == backgroundSquare then
			bg = marker.Background.Square
		end

		HideMarkerBackground(marker)

		if bg then
			ApplyBackground(bg, texture, padding)
		end
	else
		HideMarkerBackground(marker)
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
