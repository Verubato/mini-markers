local _, addon = ...
---@type MiniFramework
local mini = addon.Framework
local verticalSpacing = 14
local horizontalSpacing = 20
---@class Db
local dbDefaults = {
	Version = 6,

	EveryoneEnabled = false,
	GroupEnabled = true,
	AlliesEnabled = true,
	EnemiesEnabled = false,
	GuildEnabled = true,
	NpcsEnabled = false,
	PetsEnabled = false,
	FriendsEnabled = true,

	FriendlyTankEnabled = true,
	FriendlyHealerEnabled = true,
	FriendlyDpsEnabled = true,

	EnemyTankEnabled = true,
	EnemyHealerEnabled = true,
	EnemyDpsEnabled = true,

	FriendlyClassIcons = true,
	FriendlySpecIcons = false,
	FriendlyTextureIcons = false,
	FriendlyRoleIcons = false,

	EnemyClassIcons = false,
	EnemySpecIcons = false,
	EnemyTextureIcons = false,
	EnemyRoleIcons = true,

	EnemyRedEnabled = true,

	EnableDistanceFading = false,

	OffsetX = 0,
	OffsetY = 20,

	BackgroundPadding = 10,

	IconTexture = "covenantsanctum-renown-doublearrow-depressed",
	IconWidth = 50,
	IconHeight = 50,
	IconRotation = 90,

	IconClassColors = true,
	IconDesaturated = true,
	BackgroundEnabled = true,

	PetIconScale = 0.5,
}

local M = {
	DbDefaults = dbDefaults,
	VerticalSpacing = verticalSpacing,
	HorizontalSpacing = horizontalSpacing,
	LeftInset = horizontalSpacing,
	RightInset = horizontalSpacing,
	Panels = {}
}
addon.Config = M

local function GetAndUpgradeDb()
	local vars = mini:GetSavedVars(dbDefaults)
	while vars.Version ~= dbDefaults.Version do
		if not vars.Version or vars.Version == 1 then
			-- sorry folks, you'll have to reconfigure
			-- made some breaking changes from v1 to 2
			vars = mini:ResetSavedVars(dbDefaults)
			vars.Version = 2
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
		elseif vars.Version == 5 then
			vars.FriendlyClassIcons = vars.ClassIcons
			vars.FriendlySpecIcons = vars.SpecIcons
			vars.FriendlyTextureIcons = vars.TextureIcons
			vars.FriendlyRoleIcons = vars.RoleIcons

			vars.EnemyClassIcons = vars.ClassIcons
			vars.EnemySpecIcons = vars.SpecIcons
			vars.EnemyTextureIcons = vars.TextureIcons
			vars.EnemyRoleIcons = vars.RoleIcons

			vars.ClassIcons = nil
			vars.SpecIcons = nil
			vars.TextureIcons = nil
			vars.RoleIcons = nil

			vars.Version = 6
		end
	end

	return vars
end

function M:Init()
	addon.DB = GetAndUpgradeDb()

	local mainPanel = M.Panels.Main:Build()
	local category = mini:AddCategory(mainPanel)

	if not category then
		return
	end

	local rolesPanel = M.Panels.Roles:Build()
	mini:AddSubCategory(category, rolesPanel)

	local texturePanel = M.Panels.CustomTexture:Build()
	mini:AddSubCategory(category, texturePanel)

	local specialPanel = M.Panels.SpecialIcons:Build()
	mini:AddSubCategory(category, specialPanel)

	SLASH_MINIMARKERS1 = "/minimarkers"
	SLASH_MINIMARKERS2 = "/minim"
	SLASH_MINIMARKERS3 = "/mm"

	mini:RegisterSlashCommand(category, mainPanel)
end
