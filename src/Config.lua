local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local verticalSpacing = 20
local horizontalSpacing = 40
local checkboxWidth = 100
---@type Db
local db
---@class Db
local dbDefaults = {
	Version = 2,

	EveryoneEnabled = false,
	GroupEnabled = true,
	AlliesEnabled = true,
	EnemiesEnabled = false,
	GuildEnabled = true,
	NpcsEnabled = false,
	PetsEnabled = false,

	ClassIcons = true,
	TextureIcons = false,
	RoleIcons = false,

	EnableDistanceFading = false,

	OffsetX = 0,
	OffsetY = 0,

	IconTexture = "covenantsanctum-renown-doublearrow-depressed",
	IconWidth = 32,
	IconHeight = 32,
	IconRotation = 90,
	IconClassColors = true,
	IconDesaturated = true,
	BackgroundEnabled = false,
	BackgroundPadding = 10,

	FriendIconsEnabled = true,
	FriendIconTexture = "Interface\\AddOns\\" .. addonName .. "\\Icons\\Friend.tga",
	GuildIconTexture = "Interface\\AddOns\\" .. addonName .. "\\Icons\\Guild.tga",
}

local M = {
	DbDefaults = dbDefaults,
}
addon.Config = M

local function GetAndUpgradeDb()
	local vars = mini:GetSavedVars(dbDefaults)

	if not vars.Version or vars.Version == 1 then
		-- sorry folks, you'll have to reconfigure
		-- made some breaking changes from v1 to 2
		vars = mini:ResetSavedVars(dbDefaults)
	end

	return vars
end

function M:Init()
	db = GetAndUpgradeDb()

	local panel = CreateFrame("Frame")
	panel.name = addonName

	local category = mini:AddCategory(panel)

	if not category then
		return
	end

	local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, -verticalSpacing)
	title:SetText(string.format("%s - %s", addonName, version))

	local description = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
	description:SetPoint("TOPLEFT", title, 0, -verticalSpacing)
	description:SetText("Show markers above nameplates.")

	local everyoneChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Everyone",
		Tooltip = "Show markers for everyone.",
		Enabled = function()
			return db.EveryoneEnabled
		end,
		OnChanged = function(enabled)
			db.EveryoneEnabled = enabled
			addon:Refresh()
		end,
	})

	everyoneChkBox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)

	local groupChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Group",
		Tooltip = "Show markers for group members.",
		Enabled = function()
			return db.GroupEnabled
		end,
		OnChanged = function(enabled)
			db.GroupEnabled = enabled
			addon:Refresh()
		end,
	})

	groupChkBox:SetPoint("LEFT", everyoneChkBox, "RIGHT", checkboxWidth, 0)

	local alliesChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Allies",
		Tooltip = "Show markers for friendly players.",
		Enabled = function()
			return db.AlliesEnabled
		end,
		OnChanged = function(enabled)
			db.AlliesEnabled = enabled
			addon:Refresh()
		end,
	})

	alliesChkBox:SetPoint("LEFT", groupChkBox, "RIGHT", checkboxWidth, 0)

	local enemiesChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Enemies",
		Tooltip = "Show markers for enemy players.",
		Enabled = function()
			return db.EnemiesEnabled
		end,
		OnChanged = function(enabled)
			db.EnemiesEnabled = enabled
			addon:Refresh()
		end,
	})

	enemiesChkBox:SetPoint("LEFT", alliesChkBox, "RIGHT", checkboxWidth, 0)

	local friendsChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Friends",
		Tooltip = "Use a special icon for btag friends.",
		Enabled = function()
			return db.FriendIconsEnabled
		end,
		OnChanged = function(enabled)
			db.FriendIconsEnabled = enabled
			addon:Refresh()
		end,
	})

	friendsChkBox:SetPoint("TOPLEFT", everyoneChkBox, "BOTTOMLEFT", 0, -8)

	local guildChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Guild",
		Tooltip = "Use a special icon for guild members.",
		Enabled = function()
			return db.GuildEnabled
		end,
		OnChanged = function(enabled)
			db.GuildEnabled = enabled
			addon:Refresh()
		end,
	})

	guildChkBox:SetPoint("LEFT", friendsChkBox, "RIGHT", checkboxWidth, 0)

	local npcsChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "NPCs",
		Tooltip = "Show markers for NPCs.",
		Enabled = function()
			return db.NpcsEnabled
		end,
		OnChanged = function(enabled)
			db.NpcsEnabled = enabled
			addon:Refresh()
		end,
	})

	npcsChkBox:SetPoint("LEFT", guildChkBox, "RIGHT", checkboxWidth, 0)

	local classIconsChkBox
	local textureIconsChkBox

	classIconsChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Class Icons",
		Tooltip = "Use special high quality class icons.",
		Enabled = function()
			return db.ClassIcons
		end,
		OnChanged = function(enabled)
			db.ClassIcons = enabled
			db.TextureIcons = not enabled

			textureIconsChkBox:MiniRefresh()
			addon:Refresh()
		end,
	})

	classIconsChkBox:SetPoint("TOPLEFT", friendsChkBox, "BOTTOMLEFT", 0, -8)

	textureIconsChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Texture Icons",
		Tooltip = "Use the specified texture for icons.",
		Enabled = function()
			return db.TextureIcons
		end,
		OnChanged = function(enabled)
			db.TextureIcons = enabled
			db.ClassIcons = not enabled

			classIconsChkBox:MiniRefresh()
			addon:Refresh()
		end,
	})

	textureIconsChkBox:SetPoint("LEFT", classIconsChkBox, "RIGHT", checkboxWidth, 0)

	local roleIconsChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Role Icons",
		Tooltip = "Use tank/healer/dps role icons.",
		Enabled = function()
			return db.RoleIcons
		end,
		OnChanged = function(enabled)
			db.RoleIcons = enabled
			addon:Refresh()
		end,
	})

	roleIconsChkBox:SetPoint("LEFT", textureIconsChkBox, "RIGHT", checkboxWidth, 0)

	local textureLbl, textureBox = mini:CreateEditBox(panel, false, "Texture", 400, function()
		return db.IconTexture
	end, function(value)
		if db.IconTexture == value then
			return
		end

		db.IconTexture = value
		addon:Refresh()
	end)

	textureLbl:SetPoint("TOPLEFT", classIconsChkBox, "BOTTOMLEFT", 0, -verticalSpacing)
	textureBox:SetPoint("TOPLEFT", textureLbl, "BOTTOMLEFT", 4, -8)

	local textureWidthLbl, textureWidthBox = mini:CreateEditBox(panel, true, "Width", 50, function()
		return tonumber(db.IconWidth)
	end, function(value)
		if db.IconWidth == value then
			return
		end

		db.IconWidth = mini:ClampInt(value, 1, 500, dbDefaults.IconWidth)
		addon:Refresh()
	end)

	textureWidthLbl:SetPoint("TOPLEFT", textureBox, "BOTTOMLEFT", -4, -verticalSpacing)
	textureWidthBox:SetPoint("TOPLEFT", textureWidthLbl, "BOTTOMLEFT", 4, -8)

	local textureHeightLbl, textureHeightBox = mini:CreateEditBox(panel, true, "Height", 50, function()
		return tonumber(db.IconHeight)
	end, function(value)
		if db.IconHeight == value then
			return
		end

		db.IconHeight = mini:ClampInt(value, 1, 500, dbDefaults.IconHeight)
		addon:Refresh()
	end)

	textureHeightLbl:SetPoint("LEFT", textureWidthBox, "RIGHT", horizontalSpacing, textureWidthBox:GetHeight() + 4)
	textureHeightBox:SetPoint("TOPLEFT", textureHeightLbl, "BOTTOMLEFT", 4, -8)

	local textureRotLbl, textureRotBox = mini:CreateEditBox(panel, true, "Rotation (degrees)", 50, function()
		return tonumber(db.IconRotation)
	end, function(value)
		if db.IconRotation == value then
			return
		end

		db.IconRotation = mini:ClampInt(value, 0, 360, 0)
		addon:Refresh()
	end)

	textureRotLbl:SetPoint("LEFT", textureHeightBox, "RIGHT", horizontalSpacing, textureHeightBox:GetHeight() + 4)
	textureRotBox:SetPoint("TOPLEFT", textureRotLbl, "BOTTOMLEFT", 4, -8)

	local offsetXLbl, offsetXBox = mini:CreateEditBox(panel, true, "X Offset", 50, function()
		return tonumber(db.OffsetX)
	end, function(value)
		if db.OffsetX == value then
			return
		end

		db.OffsetX = mini:ClampInt(value, -200, 200, 0)
		addon:Refresh()
	end)

	offsetXLbl:SetPoint("TOPLEFT", textureWidthBox, "BOTTOMLEFT", -4, -verticalSpacing)
	offsetXBox:SetPoint("TOPLEFT", offsetXLbl, "BOTTOMLEFT", 4, -8)

	local offsetYLbl, offsetYBox = mini:CreateEditBox(panel, true, "Y Offset", 50, function()
		return tonumber(db.OffsetY)
	end, function(value)
		if db.OffsetY == value then
			return
		end

		db.OffsetY = mini:ClampInt(value, -200, 200, 0)
		addon:Refresh()
	end)

	offsetYLbl:SetPoint("LEFT", offsetXBox, "RIGHT", horizontalSpacing, offsetXBox:GetHeight() + 4)
	offsetYBox:SetPoint("TOPLEFT", offsetYLbl, "BOTTOMLEFT", 4, -8)

	local backgroundChkBox = mini:CreateSettingCheckbox(panel, {
		Name = "Background",
		Tooltip = "Add a background behind the icons. Only used for non-class icons.",
		Enabled = function()
			return db.BackgroundEnabled
		end,
		OnChanged = function(enabled)
			db.BackgroundEnabled = enabled
			addon:Refresh()
		end,
	})

	backgroundChkBox:SetPoint("TOPLEFT", offsetXBox, "BOTTOMLEFT", -8, -verticalSpacing)

	mini:WireTabNavigation({
		textureBox,
		textureWidthBox,
		textureHeightBox,
		textureRotBox,
		offsetXBox,
		offsetYBox,
	})

	local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(120, 26)
	resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 16)
	resetBtn:SetText("Reset")
	resetBtn:SetScript("OnClick", function()
		if InCombatLockdown() then
			mini:NotifyCombatLockdown()
			return
		end

		db = mini:ResetSavedVars(dbDefaults)

		panel:MiniRefresh()
		addon:Refresh()
		mini:Notify("Settings reset to default.")
	end)

	SLASH_MINIMARKERS1 = "/minimarkers"
	SLASH_MINIMARKERS2 = "/minim"
	SLASH_MINIMARKERS3 = "/mm"

	mini:RegisterSlashCommand(category, panel)
end
