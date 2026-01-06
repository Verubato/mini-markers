local addonName, addon = ...
---@type Db
local db
---@type Db
local dbDefaults = addon.Config.DbDefaults
local loader
local bnCacheInvalidator
local bnFriendCache = {}
local bnCacheValid = false

---@class Marker
---@field WithColor table
---@field WithoutColor table
---@field Background table

local function IsUnitInMyGroup(unit)
	if not UnitExists(unit) then
		return false
	end

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
		return false
	end

	if db.FriendIconsEnabled and IsFriend(unit) then
		if IsFriend(unit) then
			return {
				Texture = db.FriendIconTexture or dbDefaults.FriendIconTexture,
				-- force background, don't use config
				BackgroundEnabled = true,
				BackgroundPadding = 8,
				Width = db.IconWidth or dbDefaults.IconWidth,
				Height = db.IconHeight or dbDefaults.IconHeight,
			}
		end
	end

	if db.GuildEnabled and UnitIsInMyGuild(unit) then
		return {
			Texture = db.GuildIconTexture or dbDefaults.GuildIconTexture,
			-- force background, don't use config
			BackgroundEnabled = true,
			BackgroundPadding = 8,
			Width = db.IconWidth or dbDefaults.IconWidth,
			Height = db.IconHeight or dbDefaults.IconHeight,
		}
	end

	local pass = db.EveryoneEnabled

	if UnitIsEnemy("player", unit) then
		pass = pass or db.EnemiesEnabled
	end

	if UnitIsFriend("player", unit) then
		pass = pass or db.AlliesEnabled
	end

	if not UnitIsPlayer(unit) then
		pass = pass or db.NpcsEnabled
	end

	if not pass and db.GroupEnabled then
		pass = pass or IsUnitInMyGroup(unit)
	end

	if not pass then
		return nil
	end

	if db.ClassIcons then
		local _, classFilename = UnitClass(unit)

		if classFilename then
			return {
				Texture = "Interface\\AddOns\\" .. addonName .. "\\Icons\\Classes\\" .. classFilename .. ".tga",
				-- force background, don't use config
				BackgroundEnabled = true,
				BackgroundPadding = 8,
				Width = db.IconWidth or dbDefaults.IconWidth,
				Height = db.IconHeight or dbDefaults.IconHeight,
			}
		end
	end

	return {
		Texture = db.IconTexture or dbDefaults.IconTexture,
		BackgroundEnabled = db.BackgroundEnabled,
		Rotation = db.IconRotation or dbDefaults.IconRotation,
		Color = db.IconClassColors and GetClassColor(unit) or nil,
		Desaturated = db.IconDesaturated or dbDefaults.IconDesaturated,
		Width = db.IconWidth or dbDefaults.IconWidth,
		Height = db.IconHeight or dbDefaults.IconHeight,
	}
end

---@return Marker
local function GetOrCreateMarker(nameplate)
	local marker = nameplate.Marker

	if marker then
		return marker
	end

	marker = {
		WithoutColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
		WithColor = nameplate:CreateTexture(nil, "OVERLAY", nil, 7),
	}

	marker.WithoutColor:Hide()
	marker.WithColor:Hide()

	nameplate.Marker = marker
	return marker
end

local function HideMarker(nameplate)
	local marker = nameplate.Marker

	if not marker then
		return
	end

	marker.WithColor:Hide()
	marker.WithoutColor:Hide()

	if marker.Background then
		marker.Background:Hide()
	end
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
		end
	end

	texture:SetSize(options.Width or 20, options.Height or 20)
	texture:SetDesaturated(options.Desaturated and true or false)
	texture:SetRotation(math.rad(options.Rotation or 0))

	if options.Color then
		texture:SetVertexColor(options.Color.R, options.Color.G, options.Color.B, options.Color.A)
	end

	if options.BackgroundEnabled then
		if not marker.Background then
			local bg = nameplate:CreateTexture(nil, "BACKGROUND")
			marker.Background = bg

			bg:SetColorTexture(0, 0, 0, 1)

			-- Circular mask
			local mask = nameplate:CreateMaskTexture()
			mask:SetTexture("Interface\\Minimap\\UI-Minimap-Background", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			mask:SetAllPoints(bg)
			bg:AddMaskTexture(mask)
			bg.Mask = mask
		end

		local padding = options.BackgroundPadding or 0

		marker.Background:ClearAllPoints()
		marker.Background:SetPoint("TOPLEFT", texture, "TOPLEFT", -padding, padding)
		marker.Background:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", padding, -padding)
		marker.Background:Show()
	elseif marker.Background then
		marker.Background:Hide()
	end

	local anchor = GetNameplateAnchor(nameplate)

	texture:ClearAllPoints()
	texture:SetPoint("BOTTOM", anchor, "TOP", tonumber(db.OffsetX) or 0, tonumber(db.OffsetY) or 0)
	texture:Show()
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

local function OnAddonLoaded(_, _, name)
	if name ~= addonName then
		return
	end

	addon.Config:Init()

	db = MiniMarkersDB or {}

	loader:UnregisterEvent("ADDON_LOADED")

	loader:SetScript("OnEvent", OnEvent)
	loader:RegisterEvent("PLAYER_ENTERING_WORLD")
	loader:RegisterEvent("GROUP_ROSTER_UPDATE")
	loader:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	loader:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
end

function addon:Refresh()
	db = MiniMarkersDB or {}
	UpdateAllNameplates()
end

function addon:Notify(msg)
	local formatted = string.format("%s - %s", addonName, msg)
	print(formatted)
end

if not C_NamePlate or not C_NamePlate.GetNamePlates or not C_NamePlate.GetNamePlateForUnit then
	print(string.format("%s is unable to run due to missing nameplate APIs.", addonName))
	return
end

loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", OnAddonLoaded)

bnCacheInvalidator = CreateFrame("Frame")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")
bnCacheInvalidator:RegisterEvent("BN_FRIEND_INFO_CHANGED")
bnCacheInvalidator:RegisterEvent("FRIENDLIST_UPDATE")

bnCacheInvalidator:SetScript("OnEvent", function()
	bnCacheValid = false
end)
