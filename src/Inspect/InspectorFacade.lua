local _, addon = ...

---@class InspectorFacade
local M = {}
addon.InspectorFacade = M

local function GetFrameSortInspector()
	local fs = FrameSortApi and FrameSortApi.v3
	local inspector = fs and fs.Inspector

	if inspector and inspector.GetUnitSpecId then
		return inspector
	end

	return nil
end

---Arena opponents cannot be inspected, so their broadcast spec is the only source for them.
---Markers work in nameplate tokens, so those are matched back to an arena slot.
local function GetArenaSpecId(unit)
	if not GetArenaOpponentSpec then
		return nil
	end

	local index = unit:match("^arena(%d)$")

	if index then
		local specId = GetArenaOpponentSpec(tonumber(index))
		return specId and specId > 0 and specId or nil
	end

	local numOpponents = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0

	for i = 1, numOpponents do
		if UnitIsUnit(unit, "arena" .. i) then
			local specId = GetArenaOpponentSpec(i)
			return specId and specId > 0 and specId or nil
		end
	end

	return nil
end

---Returns the spec ID for a unit using a best-effort fallback chain:
---  1. FrameSort (most authoritative, real-time)
---  2. Our own inspector (tooltip + async inspect queue)
---  3. GetArenaOpponentSpec for arena opponents
---@param unit string
---@return number|nil
function M:GetUnitSpecId(unit)
	if not unit then
		return nil
	end

	local frameSort = GetFrameSortInspector()

	if frameSort then
		local specId = frameSort:GetUnitSpecId(unit)

		if specId then
			return specId
		end
	end

	local specId = addon.Inspector:GetUnitSpecId(unit)

	if specId then
		return specId
	end

	return GetArenaSpecId(unit)
end

---Registers a callback to invoke when any source learns something new about a unit's spec.
---@param callback function
function M:RegisterCallback(callback)
	local frameSort = GetFrameSortInspector()

	if frameSort and frameSort.RegisterCallback then
		frameSort:RegisterCallback(callback)
	end

	addon.Inspector:RegisterCallback(callback)
end

function M:Init()
	-- Run our own inspector even when FrameSort is present: it costs nothing while FrameSort
	-- answers first, and keeps working if FrameSort is disabled later in the session.
	addon.Inspector:Init()
end

---@class InspectorFacade
---@field Init fun(self: InspectorFacade)
---@field GetUnitSpecId fun(self: InspectorFacade, unit: string): number|nil
---@field RegisterCallback fun(self: InspectorFacade, callback: function)
