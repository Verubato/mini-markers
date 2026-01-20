local _, addon = ...
local config = addon.Config

---@class AtlasPicker
local M = {}
config.AtlasPicker = M

local function GetAtlasInfoCompat(name)
	if not name or name == "" then
		return nil
	end

	if C_Texture and C_Texture.GetAtlasInfo then
		return C_Texture.GetAtlasInfo(name)
	end

	if GetAtlasInfo then
		return GetAtlasInfo(name)
	end

	return nil
end

local function ApplyEntryToTexture(tex, name, rotationDeg, iconSize)
	tex:SetRotation(0)
	tex:SetTexCoord(0, 1, 0, 1)
	tex:SetSize(iconSize, iconSize)

	local isAtlas = GetAtlasInfoCompat(name) ~= nil

	if isAtlas and tex.SetAtlas then
		tex:SetAtlas(name, false)
	else
		tex:SetTexture(name)
	end

	tex:SetRotation(math.rad(rotationDeg))
    -- white
    tex:SetDesaturated(true)
	tex:SetVertexColor(1, 1, 1, 1)
end

---@param options AtlasPickerOptions
---@return table
function M:AtlasPicker(options)
	if not options then
		error("AtlasPicker - options must not be nil.")
	end

	if not options.Parent or not options.GetValue or not options.SetValue or not options.AtlasList then
		error("AtlasPicker - invalid options.")
	end

	local width = options.Width or 520
	local height = options.Height or 420

	local padding = 20
	local cellSize = 80
	local iconSize = 64
	local cellGap = 10

	local frame = CreateFrame("Frame", nil, options.Parent, "BackdropTemplate")
	frame:SetSize(width, height)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0, 0, 0, 0.25)
	frame:SetBackdropBorderColor(1, 1, 1, 0.12)

	local listWrap = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	listWrap:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
	listWrap:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	listWrap:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	listWrap:SetBackdropColor(0, 0, 0, 0.20)
	listWrap:SetBackdropBorderColor(1, 1, 1, 0.12)

	local scroll = CreateFrame("ScrollFrame", nil, listWrap, "FauxScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", listWrap, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", listWrap, "BOTTOMRIGHT", -26, 0)

	local content = CreateFrame("Frame", nil, listWrap)
	content:SetPoint("TOPLEFT", listWrap, "TOPLEFT", padding, -padding)
	content:SetPoint("BOTTOMRIGHT", listWrap, "BOTTOMRIGHT", -(padding + 22), padding)

	---@return AtlasPickerEntry|string|nil
	local function GetSelected()
		local v = options.GetValue()

		if type(v) == "table" then
			return v.Texture
		end

		return v
	end

	local all = options.AtlasList
	local probe = frame:CreateTexture(nil, "ARTWORK")
	probe:Hide()

	local filtered = {}

	local function IsValidEntry(texture)
		if not texture or texture == "" then
			return false
		end

		if GetAtlasInfoCompat(texture) ~= nil then
			return true
		end

		probe:SetTexture(nil)
		probe:SetTexture(texture)
		return probe:GetTexture() ~= nil
	end

	local function Refilter()
		wipe(filtered)

		for i = 1, #all do
			local entry = all[i]
			local texture = entry and entry.Texture

			if type(texture) == "string" and texture ~= "" and IsValidEntry(texture) then
				filtered[#filtered + 1] = entry
			end
		end
	end

	local function GetColumns()
		local w = content:GetWidth() or 0
		local cols = math.floor((w + cellGap) / (cellSize + cellGap))

		if cols < 1 then
			cols = 1
		end

		return cols
	end

	local function GetVisibleRows()
		local h = content:GetHeight() or 0
		local rowH = cellSize + cellGap
		local rows = math.floor((h + cellGap) / rowH)

		if rows < 1 then
			rows = 1
		end

		return rows
	end

	local cells = {}

	local function EnsureCells()
		local cols = GetColumns()
		local rows = GetVisibleRows()
		local needed = (rows + 1) * cols

		for i = #cells + 1, needed do
			local cell = CreateFrame("Button", nil, content)
			cell:SetSize(cellSize, cellSize)
			cell:RegisterForClicks("LeftButtonUp")

			cell.Select = cell:CreateTexture(nil, "ARTWORK")
			cell.Select:SetAllPoints()
			cell.Select:SetColorTexture(0.2, 0.6, 1, 0.18)
			cell.Select:Hide()

			cell.Highlight = cell:CreateTexture(nil, "HIGHLIGHT")
			cell.Highlight:SetAllPoints()
			cell.Highlight:SetColorTexture(1, 1, 1, 0.06)

			cell.Icon = cell:CreateTexture(nil, "ARTWORK")
			cell.Icon:SetPoint("CENTER")
			cell.Icon:SetSize(iconSize, iconSize)

			cells[i] = cell
		end
	end

	local function LayoutCells()
		local cols = GetColumns()
		local stepX = cellSize + cellGap
		local stepY = cellSize + cellGap

		for i = 1, #cells do
			local cell = cells[i]
			cell:ClearAllPoints()

			local idx = i - 1
			local col = idx % cols
			local row = math.floor(idx / cols)

			cell:SetPoint("TOPLEFT", content, "TOPLEFT", col * stepX, -row * stepY)
		end
	end

	local function Update()
		-- Wait until we have real dimensions
		local w = content:GetWidth() or 0
		local h = content:GetHeight() or 0
		if w <= 1 or h <= 1 then
			return
		end

		EnsureCells()
		LayoutCells()

		local cols = GetColumns()
		local visibleRows = GetVisibleRows()

		local totalRows = math.ceil(#filtered / cols)
		FauxScrollFrame_Update(scroll, totalRows, visibleRows, cellSize + cellGap)

		local rowOffset = FauxScrollFrame_GetOffset(scroll)
		local startIndex = rowOffset * cols + 1

		local selectedTexture = GetSelected()

		for i = 1, #cells do
			local entryIndex = startIndex + (i - 1)
			local cell = cells[i]
			local entry = filtered[entryIndex]

			if entry then
				cell:Show()
				---@type AtlasPickerEntry
				cell.Entry = entry

				local texture = entry.Texture
				local rotation = entry.Rotation or 0

				ApplyEntryToTexture(cell.Icon, texture, rotation, iconSize)
				cell.Select:SetShown(texture == selectedTexture)

				if not cell.Hooked then
					cell.Hooked = true
					cell:SetScript("OnClick", function(cellSelf)
						local e = cellSelf.Entry
						if not e then
							return
						end
						options.SetValue(e)
						Update()
					end)
				end
			else
				cell:Hide()
				cell.Entry = nil
				cell.Icon:SetTexture(nil)
				cell.Icon:SetRotation(0)
			end
		end
	end

	scroll:SetScript("OnVerticalScroll", function(scrollSelf, delta)
		FauxScrollFrame_OnVerticalScroll(scrollSelf, delta, cellSize + cellGap, Update)
	end)

	Refilter()

	scroll:SetScript("OnSizeChanged", function()
		Update()
	end)

	function frame.MiniRefresh()
		Update()
	end

	frame:MiniRefresh()
	return frame
end

---@class AtlasPickerEntry
---@field Texture string
---@field Rotation? number

---@class AtlasPickerOptions
---@field Parent table
---@field Height number
---@field Width number
---@field GetValue fun(): string|AtlasPickerEntry|nil
---@field SetValue fun(entry: AtlasPickerEntry)
---@field AtlasList AtlasPickerEntry[]
