if not C_NamePlate or not C_NamePlate.GetNamePlates or not C_NamePlate.GetNamePlateForUnit then
	print("MiniPartyMarkers is unable to run due to missing nameplate APIs.")
	return
end

local textureName = "covenantsanctum-renown-doublearrow-depressed"
local yOffset = 0

local function IsPartyUnit(unit)
	for i = 1, MAX_PARTY_MEMBERS or 4 do
		local partyUnit = "party" .. i

		if UnitExists(partyUnit) and UnitIsUnit(partyUnit, unit) then
			return true
		end
	end

	return false
end

local function ApplyClassColor(texture, unit)
	local _, classTag = UnitClass(unit)

	if not classTag then
		texture:SetVertexColor(1, 1, 1, 1)
		return
	end

	local colour = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]

	if colour then
		texture:SetVertexColor(colour.r, colour.g, colour.b, 1)
	else
		texture:SetVertexColor(1, 1, 1, 1)
	end
end

local function GetOrCreateArrow(unitFrame)
	local arrow = unitFrame.ArrowTexture

	if arrow then
		return arrow
	end

	arrow = unitFrame:CreateTexture(nil, "OVERLAY", nil, 7)
	arrow:SetDesaturated(true)
	arrow:SetAtlas(textureName, true)
	arrow:SetRotation(math.rad(90))
	arrow:Hide()

	unitFrame.ArrowTexture = arrow
	return arrow
end

local function PositionArrow(unitFrame, arrow)
	arrow:ClearAllPoints()
	arrow:SetPoint("BOTTOM", unitFrame, "TOP", 0, yOffset)
end

local function AddArrow(unit, unitFrame)
	local shouldShow = IsPartyUnit(unit)

	if not shouldShow then
		if unitFrame.ArrowTexture then
			unitFrame.ArrowTexture:Hide()
		end

		return
	end

	local arrow = GetOrCreateArrow(unitFrame)

	PositionArrow(unitFrame, arrow)
	ApplyClassColor(arrow, unit)

	arrow:Show()
end

local function HideArrow(unitFrame)
	if unitFrame.ArrowTexture then
		unitFrame.ArrowTexture:Hide()
	end
end

local function UpdateAllNameplates()
	for _, nameplate in ipairs(C_NamePlate.GetNamePlates(false) or {}) do
		if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.unit then
			AddArrow(nameplate.UnitFrame.unit, nameplate.UnitFrame)
		end
	end
end

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
	if event == "NAME_PLATE_UNIT_ADDED" then
		local unit = ...
		local nameplate = unit and C_NamePlate.GetNamePlateForUnit(unit)
		local unitFrame = nameplate and nameplate.UnitFrame

		if unitFrame then
			AddArrow(unit, unitFrame)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		local unit = ...
		local nameplate = unit and C_NamePlate.GetNamePlateForUnit(unit)
		local unitFrame = nameplate and nameplate.UnitFrame

		if unitFrame then
			HideArrow(unitFrame)
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
		UpdateAllNameplates()
	end
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
