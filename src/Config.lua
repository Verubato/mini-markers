local addonName, addon = ...
---@type MiniFramework
local mini = addon.Framework
local verticalSpacing = 20
local horizontalSpacing = 20
local checkboxWidth = 100
---@type Db
local db
---@class Db
local dbDefaults = {
	Version = 5,

	EveryoneEnabled = false,
	GroupEnabled = true,
	AlliesEnabled = true,
	EnemiesEnabled = false,
	GuildEnabled = true,
	NpcsEnabled = false,
	PetsEnabled = false,
	FriendsEnabled = true,

	ClassIcons = true,
	SpecIcons = false,
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
	BackgroundEnabled = true,

	PetIconScale = 0.5,
}

local M = {
	DbDefaults = dbDefaults,
}
addon.Config = M

local function GetAndUpgradeDb()
	local vars = mini:GetSavedVars(dbDefaults)
	while vars.Version ~= dbDefaults.Version do
		if not vars.Version or vars.Version == 1 then
			-- sorry folks, you'll have to reconfigure
			-- made some breaking changes from v1 to 2
			vars = mini:ResetSavedVars(dbDefaults)
		elseif vars.Version == 2 then
			vars.BackgroundPadding = nil
			vars.Version = 3
		elseif vars.Version == 3 then
			vars.FriendsEnabled = vars.FriendIconsEnabled
			vars.FriendIconsEnabled = nil
			vars.Version = 4
		elseif vars.Version == 4 then
			vars.FriendIconTexture = nil
			vars.GuildIconTexture = nil
			vars.PetIconTexture = nil
			vars.Version = 5
		end
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

	local everyoneChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Everyone",
		Tooltip = "Show markers for everyone.",
		GetValue = function()
			return db.EveryoneEnabled
		end,
		SetValue = function(enabled)
			db.EveryoneEnabled = enabled
			addon:Refresh()
		end,
	})

	everyoneChkBox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -verticalSpacing)

	local groupChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Group",
		Tooltip = "Show markers for group members.",
		GetValue = function()
			return db.GroupEnabled
		end,
		SetValue = function(enabled)
			db.GroupEnabled = enabled
			addon:Refresh()
		end,
	})

	groupChkBox:SetPoint("LEFT", everyoneChkBox, "RIGHT", checkboxWidth, 0)

	local alliesChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Allies",
		Tooltip = "Show markers for friendly players.",
		GetValue = function()
			return db.AlliesEnabled
		end,
		SetValue = function(enabled)
			db.AlliesEnabled = enabled
			addon:Refresh()
		end,
	})

	alliesChkBox:SetPoint("LEFT", groupChkBox, "RIGHT", checkboxWidth, 0)

	local enemiesChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Enemies",
		Tooltip = "Show markers for enemy players.",
		GetValue = function()
			return db.EnemiesEnabled
		end,
		SetValue = function(enabled)
			db.EnemiesEnabled = enabled
			addon:Refresh()
		end,
	})

	enemiesChkBox:SetPoint("LEFT", alliesChkBox, "RIGHT", checkboxWidth, 0)

	local friendsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Friends",
		Tooltip = "Use a special icon for btag friends.",
		GetValue = function()
			return db.FriendsEnabled
		end,
		SetValue = function(enabled)
			db.FriendsEnabled = enabled
			addon:Refresh()
		end,
	})

	friendsChkBox:SetPoint("TOPLEFT", everyoneChkBox, "BOTTOMLEFT", 0, -8)

	local guildChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Guild",
		Tooltip = "Use a special icon for guild members.",
		GetValue = function()
			return db.GuildEnabled
		end,
		SetValue = function(enabled)
			db.GuildEnabled = enabled
			addon:Refresh()
		end,
	})

	guildChkBox:SetPoint("LEFT", friendsChkBox, "RIGHT", checkboxWidth, 0)

	local npcsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "NPCs",
		Tooltip = "Show markers for NPCs.",
		GetValue = function()
			return db.NpcsEnabled
		end,
		SetValue = function(enabled)
			db.NpcsEnabled = enabled
			addon:Refresh()
		end,
	})

	npcsChkBox:SetPoint("LEFT", guildChkBox, "RIGHT", checkboxWidth, 0)

	local petsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Pets",
		Tooltip = "Show markers for pets.",
		GetValue = function()
			return db.PetsEnabled
		end,
		SetValue = function(enabled)
			db.PetsEnabled = enabled
			addon:Refresh()
		end,
	})

	petsChkBox:SetPoint("LEFT", npcsChkBox, "RIGHT", checkboxWidth, 0)

	local typeIcons

	function RefreshTypes()
		for _, type in ipairs(typeIcons) do
			type:MiniRefresh()
		end
	end

	local classIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Class Icons",
		Tooltip = "Use special high quality class icons.",
		GetValue = function()
			return db.ClassIcons
		end,
		SetValue = function(enabled)
			db.ClassIcons = enabled
			RefreshTypes()
			addon:Refresh()
		end,
	})

	classIconsChkBox:SetPoint("TOPLEFT", friendsChkBox, "BOTTOMLEFT", 0, -8)

	local specIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Spec Icons",
		Tooltip = "Use spec icons. Requires FrameSort for this to work.",
		GetValue = function()
			return db.SpecIcons
		end,
		SetValue = function(enabled)
			if enabled and not (FrameSortApi and FrameSortApi.v3 and FrameSortApi.v3.Inspector) then
				mini:ShowDialog("Spec icons requires FrameSort 7.8.1+ to function.")
				RefreshTypes()
				return
			end

			db.SpecIcons = enabled
			RefreshTypes()
			addon:Refresh()
		end,
	})

	specIconsChkBox:SetPoint("LEFT", classIconsChkBox, "RIGHT", checkboxWidth, 0)

	local roleIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Role Icons",
		Tooltip = "Use tank/healer/dps role icons.",
		GetValue = function()
			return db.RoleIcons
		end,
		SetValue = function(enabled)
			db.RoleIcons = enabled
			addon:Refresh()
		end,
	})

	roleIconsChkBox:SetPoint("LEFT", specIconsChkBox, "RIGHT", checkboxWidth, 0)

	local textureIconsChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Texture Icons",
		Tooltip = "Use the specified texture for icons.",
		GetValue = function()
			return db.TextureIcons
		end,
		SetValue = function(enabled)
			db.TextureIcons = enabled
			RefreshTypes()
			addon:Refresh()
		end,
	})

	textureIconsChkBox:SetPoint("LEFT", roleIconsChkBox, "RIGHT", checkboxWidth, 0)

	typeIcons = {
		classIconsChkBox,
		specIconsChkBox,
		roleIconsChkBox,
		textureIconsChkBox,
	}

	local textureBox, textureLbl = mini:CreateEditBox({
		Parent = panel,
		LabelText = "Texture",
		-- same width as 2 sliders plus gap
		Width = 200 * 2 + horizontalSpacing,
		GetValue = function()
			return db.IconTexture
		end,
		SetValue = function(value)
			if db.IconTexture == value then
				return
			end

			db.IconTexture = value
			addon:Refresh()
		end,
	})

	textureLbl:SetPoint("TOPLEFT", classIconsChkBox, "BOTTOMLEFT", 4, -verticalSpacing)
	textureBox:SetPoint("TOPLEFT", textureLbl, "BOTTOMLEFT", 0, -8)

	local textureWidthSlider, textureWidthBox = mini:CreateSlider({
		Parent = panel,
		LabelText = "Width",
		Min = 10,
		Max = 200,
		Step = 5,
		Width = 200,
		GetValue = function()
			return tonumber(db.IconWidth) or dbDefaults.IconWidth
		end,
		SetValue = function(value)
			if db.IconWidth == value then
				return
			end

			db.IconWidth = mini:ClampInt(value, 10, 200, dbDefaults.IconWidth)
			addon:Refresh()
		end,
	})

	textureWidthSlider:SetPoint("TOPLEFT", textureBox, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local textureHeightSlider, textureHeightBox = mini:CreateSlider({
		Parent = panel,
		LabelText = "Height",
		Min = 10,
		Max = 200,
		Step = 5,
		Width = 200,
		GetValue = function()
			return tonumber(db.IconHeight) or dbDefaults.IconHeight
		end,
		SetValue = function(value)
			if db.IconHeight == value then
				return
			end

			db.IconHeight = mini:ClampInt(value, 10, 200, dbDefaults.IconHeight)
			addon:Refresh()
		end,
	})

	textureHeightSlider:SetPoint("LEFT", textureWidthSlider, "RIGHT", horizontalSpacing, 0)

	local offsetXSlider, offsetXBox = mini:CreateSlider({
		LabelText = "X Offset",
		Parent = panel,
		Min = -200,
		Max = 200,
		Step = 5,
		Width = 200,
		GetValue = function()
			return tonumber(db.OffsetX) or dbDefaults.OffsetX
		end,
		SetValue = function(value)
			if db.OffsetX == value then
				return
			end

			db.OffsetX = mini:ClampInt(value, -200, 200, 0)
			addon:Refresh()
		end,
	})

	offsetXSlider:SetPoint("TOPLEFT", textureWidthSlider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local offsetYSlider, offsetYBox = mini:CreateSlider({
		Parent = panel,
		Min = -200,
		Max = 200,
		Step = 5,
		Width = 200,
		LabelText = "Y Offset",
		GetValue = function()
			return tonumber(db.OffsetY) or dbDefaults.OffsetY
		end,
		SetValue = function(value)
			if db.OffsetY == value then
				return
			end

			db.OffsetY = mini:ClampInt(value, -200, 200, 0)
			addon:Refresh()
		end,
	})

	offsetYSlider:SetPoint("LEFT", offsetXSlider, "RIGHT", horizontalSpacing, 0)

	local textureRotSlider, textureRotBox = mini:CreateSlider({
		Parent = panel,
		Min = 0,
		Max = 360,
		Step = 15,
		Width = 200,
		LabelText = "Rotation",
		GetValue = function()
			return tonumber(db.IconRotation) or dbDefaults.IconRotation
		end,
		SetValue = function(value)
			if db.IconRotation == value then
				return
			end

			db.IconRotation = mini:ClampInt(value, 0, 360, 0)
			addon:Refresh()
		end,
	})

	textureRotSlider:SetPoint("TOPLEFT", offsetXSlider, "BOTTOMLEFT", 0, -verticalSpacing * 3)

	local backgroundChkBox = mini:CreateSettingCheckbox({
		Parent = panel,
		LabelText = "Background",
		Tooltip = "Add a background behind the icons. Doesn't apply for class icons.",
		GetValue = function()
			return db.BackgroundEnabled
		end,
		SetValue = function(enabled)
			db.BackgroundEnabled = enabled
			addon:Refresh()
		end,
	})

	backgroundChkBox:SetPoint("TOPLEFT", textureRotSlider, "BOTTOMLEFT", 0, -verticalSpacing)

	mini:WireTabNavigation({
		textureBox,
		textureWidthBox,
		textureHeightBox,
		offsetXBox,
		offsetYBox,
		textureRotBox,
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
