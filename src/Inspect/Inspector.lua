-- Lightweight spec inspector adapted from FrameSort's Inspector module.
-- Used as a fallback when FrameSortApi is unavailable.
-- Resolves friendly unit spec IDs via NotifyInspect / INSPECT_READY, with a GUID-keyed
-- cache in saved variables and a simple run loop.
--
-- Init runs once from MiniMarkers.lua. Without it GetUnitSpecId still answers, but only from
-- its synchronous paths (player spec, tooltip scan): the async inspect queue never drains and
-- the saved GUID->spec cache is never loaded.
local _, addon = ...
---@type MiniFramework
local mini = addon.Framework

local INSPECT_INTERVAL = 0.5
local INSPECT_TIMEOUT = 10
local CACHE_TIMEOUT = 60
local CACHE_EXPIRY = 60 * 60 * 24 * 3
-- A crowded battleground can ask about more units than the queue could ever work through,
-- so the oldest requests are dropped rather than queued behind a hundred others.
local PRIORITY_MAX = 10

local unitGuidToSpec = {}
-- Scratch list of group unit tokens, refilled by each pass of the run loop.
local friendlyUnits = {}
-- Unit tokens by prefix and index, built as they are first asked for. The run loop walks the
-- group twice a second and the tokens never change.
local unitTokens = { raid = {}, party = {} }
local priorityStack = {}
local priorityQueued = {}
local requestedUnit = nil
local currentInspectUnit = nil
local isOurInspect = false
local needUpdate = true
local initialised = false
local inspectStarted = nil
-- Whether a RunLoop tick is scheduled. The loop only runs while an inspect is in flight or a
-- spec is missing; ArmLoop wakes it, and an idle tick simply does not reschedule.
local loopArmed = false
local callbacks = {}
-- Lazily built spec name lookups for tooltip matching, e.g. "Discipline Priest" -> 256.
local tooltipSpecs = nil

---@class Inspector
local M = {}
addon.Inspector = M

---Monotonic within a session only, for timing an inspect that is in flight.
local function Now()
	return GetTimePreciseSec and GetTimePreciseSec() or GetTime()
end

---Wall clock, for the cache stamps that outlive the session. GetTime restarts at zero every
---login, so a stamp taken from it would make every saved entry look like it came from the
---future and nothing would ever expire.
local function Timestamp()
	return time()
end

---Whether an inspect of this unit could actually answer. Enemies can never be inspected, and
---asking anyway wastes the full INSPECT_TIMEOUT waiting for a reply that is not coming.
local function CanQueueInspect(unit)
	return UnitExists(unit)
		and UnitIsPlayer(unit)
		and UnitIsFriend(unit, "player")
		and UnitIsConnected(unit)
		and CanInspect(unit)
end

local function UnitToken(prefix, index)
	local byIndex = unitTokens[prefix]
	local token = byIndex[index]

	if not token then
		token = prefix .. index
		byIndex[index] = token
	end

	return token
end

---Fills `units` with the player and everyone grouped with them. Reuses the table it is given:
---this is called on every pass of the run loop.
---@param units string[]
---@return string[] units
local function GetFriendlyUnits(units)
	wipe(units)

	units[1] = "player"

	local numGroup = GetNumGroupMembers()
	local prefix = IsInRaid() and "raid" or "party"

	for i = 1, numGroup do
		units[#units + 1] = UnitToken(prefix, i)
	end

	return units
end

local function OnSpecInformationChanged()
	for _, callback in ipairs(callbacks) do
		pcall(callback)
	end
end

local function GetTooltipSpecs()
	if tooltipSpecs then
		return tooltipSpecs
	end

	tooltipSpecs = { ByPhrase = {}, ByClass = {} }

	if not (GetNumClasses and GetClassInfo and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID) then
		return tooltipSpecs
	end

	for classIdx = 1, GetNumClasses() do
		local className, classFile, classId = GetClassInfo(classIdx)

		if className and classFile and classId then
			for specIdx = 1, GetNumSpecializationsForClassID(classId) do
				local specId, specName = GetSpecializationInfoForClassID(classId, specIdx)

				if specId and specName then
					local phrase = specName .. " " .. className
					local byClass = tooltipSpecs.ByClass[classFile] or {}

					tooltipSpecs.ByPhrase[phrase] = specId
					byClass[#byClass + 1] = { Phrase = phrase, SpecId = specId }
					tooltipSpecs.ByClass[classFile] = byClass
				end
			end
		end
	end

	return tooltipSpecs
end

---Returns a spec ID by reading the unit's tooltip, or nil if unrecognised.
---A synchronous fast path that avoids queuing an async NotifyInspect, and the only path that
---can ever answer for an enemy, who cannot be inspected.
---@param unit string
---@return number|nil
local function SpecFromTooltip(unit)
	if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then
		return nil
	end

	local tooltipData = C_TooltipInfo.GetUnit(unit)

	if not tooltipData or not tooltipData.lines then
		return nil
	end

	local specs = GetTooltipSpecs()
	local _, classFile = UnitClass(unit)
	local classSpecs = classFile and not mini:IsSecret(classFile) and specs.ByClass[classFile] or nil

	for _, line in ipairs(tooltipData.lines) do
		local text = line and line.leftText

		if text and not mini:IsSecret(text) then
			local specId = specs.ByPhrase[text]

			if specId then
				return specId
			end

			-- The spec is usually folded into the level line ("Level 80 Discipline Priest"),
			-- so match the tail of the line against this unit's own specs.
			if classSpecs then
				for _, candidate in ipairs(classSpecs) do
					if #text > #candidate.Phrase and text:sub(-#candidate.Phrase) == candidate.Phrase then
						return candidate.SpecId
					end
				end
			end
		end
	end

	return nil
end

-- UnitGUID throws "Player/pet name are not valid arguments for this call" when called
-- on an enemy unit by name. The error message is misleading since UnitGUID does accept
-- unit names in general -- pcall is the only way to handle this gracefully.
local function SafeUnitGUID(unit)
	local ok, guid = pcall(UnitGUID, unit)
	return ok and guid or nil
end

local function PurgeOldEntries()
	local now = Timestamp()

	for guid, entry in pairs(unitGuidToSpec) do
		if not entry or type(entry) ~= "table" or not entry.LastSeen or (now - entry.LastSeen) > CACHE_EXPIRY then
			unitGuidToSpec[guid] = nil
		end
	end
end

local function EnsureCacheEntry(unit)
	local guid = SafeUnitGUID(unit)

	if not guid or mini:IsSecret(guid) then
		return nil
	end

	if not unitGuidToSpec[guid] then
		unitGuidToSpec[guid] = {}
	end

	return unitGuidToSpec[guid]
end

local function Inspect(unit)
	local specId = GetInspectSpecialization and GetInspectSpecialization(unit)
	-- A unit the client will not let an addon identify answers with a secret spec, and a
	-- mouseover of a stranger is the everyday way to get one. Nothing here can use it: comparing
	-- it errors, and caching it only moves that error to whoever reads the cache.
	if specId and not mini:IsSecret(specId) and specId > 0 then
		local cacheEntry = EnsureCacheEntry(unit)

		if cacheEntry then
			local before = cacheEntry.SpecId

			cacheEntry.SpecId = specId
			cacheEntry.LastSeen = Timestamp()

			if before ~= specId then
				OnSpecInformationChanged()
			end
		end
	end

	if isOurInspect then
		currentInspectUnit = nil
		requestedUnit = nil
		isOurInspect = false
		ClearInspectPlayer()
	end
end

local function InvalidateEntry(unit)
	local guid = SafeUnitGUID(unit)

	if not guid or mini:IsSecret(guid) then
		return
	end

	unitGuidToSpec[guid] = nil
	needUpdate = true
end

local function OnClearInspect()
	requestedUnit = nil
end

local function OnNotifyInspect(unit)
	local guid = SafeUnitGUID(unit)

	if not guid or mini:IsSecret(guid) then
		return
	end

	-- Ignore inspects of non-friendly units (e.g. enemy players inspected by other addons).
	if not UnitIsFriend(unit, "player") then
		return
	end

	if currentInspectUnit and unit ~= currentInspectUnit then
		currentInspectUnit = nil
	end

	requestedUnit = unit
	inspectStarted = Now()
	isOurInspect = false
end

local function GetNextTarget()
	-- process priority stack first (LIFO)
	while #priorityStack > 0 do
		local entry = priorityStack[#priorityStack]
		priorityStack[#priorityStack] = nil
		priorityQueued[entry.Guid] = nil

		-- A nameplate token gets recycled onto another unit, so check it still means who it
		-- meant when it was queued.
		if SafeUnitGUID(entry.Unit) == entry.Guid and CanQueueInspect(entry.Unit) then
			return entry.Unit
		end
	end

	local units = GetFriendlyUnits(friendlyUnits)
	local now = Timestamp()

	-- first pass: units with no cache entry. These are group tokens, never names, so they
	-- cannot provoke the error SafeUnitGUID exists to swallow.
	for _, unit in ipairs(units) do
		if not UnitIsUnit(unit, "player") then
			local guid = UnitGUID(unit)

			if guid and not mini:IsSecret(guid) then
				local cacheEntry = unitGuidToSpec[guid]

				if not cacheEntry and CanInspect(unit) and UnitIsConnected(unit) then
					return unit
				end
			end
		end
	end

	-- second pass: units with stale or missing spec
	for _, unit in ipairs(units) do
		if not UnitIsUnit(unit, "player") then
			local guid = UnitGUID(unit)

			if guid and not mini:IsSecret(guid) then
				local cacheEntry = unitGuidToSpec[guid]

				if
					cacheEntry
					and (not cacheEntry.SpecId or cacheEntry.SpecId == 0)
					and CanInspect(unit)
					and UnitIsConnected(unit)
					and (not cacheEntry.LastAttempt or (now - cacheEntry.LastAttempt > CACHE_TIMEOUT))
				then
					return unit
				end
			end
		end
	end

	return nil
end

---One pass of the inspect loop. Returns whether another tick is needed: an inspect is in
---flight or queued work remains. Idle passes return false, and the loop sleeps until ArmLoop.
local function Step()
	local now = Now()
	local timeSinceLastInspect = inspectStarted and (now - inspectStarted)

	if requestedUnit ~= nil and timeSinceLastInspect and timeSinceLastInspect < INSPECT_TIMEOUT then
		-- An inspect is in flight; stay scheduled to time it out if INSPECT_READY never comes.
		return true
	end

	if requestedUnit ~= nil then
		-- timeout: give up and move on
		if isOurInspect then
			ClearInspectPlayer()
		end

		requestedUnit = nil
		currentInspectUnit = nil
		isOurInspect = false
	end

	if not needUpdate then
		return false
	end

	local unit = GetNextTarget()

	if not unit then
		needUpdate = false
		return false
	end

	local cacheEntry = EnsureCacheEntry(unit)

	if not cacheEntry then
		-- The unit's GUID would not resolve just now; try again next tick.
		return true
	end

	cacheEntry.LastAttempt = Timestamp()
	ClearInspectPlayer()
	NotifyInspect(unit)
	isOurInspect = true
	inspectStarted = now
	requestedUnit = unit
	currentInspectUnit = unit

	-- Stay scheduled as the watchdog for the inspect just started.
	return true
end

local function RunLoop()
	loopArmed = false

	if Step() then
		loopArmed = true
		C_Timer.After(INSPECT_INTERVAL, RunLoop)
	end
end

---Wakes the run loop when something queues work for it; a no-op while a tick is already
---scheduled, so callers never stack timers.
local function ArmLoop()
	if not initialised or loopArmed then
		return
	end

	loopArmed = true
	C_Timer.After(INSPECT_INTERVAL, RunLoop)
end

---Returns the specialization ID for the given unit, or nil if unknown.
---@param unit string
---@return number|nil
function M:GetUnitSpecId(unit)
	if not unit then
		return nil
	end

	if UnitIsUnit(unit, "player") then
		if GetSpecialization and GetSpecializationInfo then
			local index = GetSpecialization()

			if index then
				return (GetSpecializationInfo(index))
			end
		end

		return nil
	end

	local guid = SafeUnitGUID(unit)

	if not guid or mini:IsSecret(guid) then
		return nil
	end

	local cacheEntry = unitGuidToSpec[guid]

	if cacheEntry and cacheEntry.SpecId and cacheEntry.SpecId > 0 then
		return cacheEntry.SpecId
	end

	-- Try the tooltip as a synchronous fast path before falling back to async inspect.
	-- Intentionally does not call OnSpecInformationChanged to avoid re-entrancy issues.
	local specId = SpecFromTooltip(unit)

	if specId then
		cacheEntry = EnsureCacheEntry(unit)

		if cacheEntry then
			cacheEntry.SpecId = specId
			cacheEntry.LastSeen = Timestamp()
		end

		return specId
	end

	-- Queue for async inspection on the next run loop tick, but only once Init has run: nothing
	-- drains the stack before then, so it would grow for the whole session.
	local queueable = initialised and CanQueueInspect(unit)

	if queueable and not cacheEntry and not priorityQueued[guid] then
		if #priorityStack >= PRIORITY_MAX then
			local dropped = table.remove(priorityStack, 1)
			priorityQueued[dropped.Guid] = nil
		end

		priorityStack[#priorityStack + 1] = { Unit = unit, Guid = guid }
		priorityQueued[guid] = true
	end

	-- Any miss arms the loop, not just a first sight: an entry whose inspect timed out is only
	-- retried by the scan once its CACHE_TIMEOUT passes, and someone asking is what wakes the
	-- loop to get there.
	if queueable and (not cacheEntry or not cacheEntry.SpecId or cacheEntry.SpecId == 0) then
		needUpdate = true
		ArmLoop()
	end

	return cacheEntry and cacheEntry.SpecId
end

---Registers a callback to invoke when spec information changes.
---@param callback function
function M:RegisterCallback(callback)
	callbacks[#callbacks + 1] = callback
end

function M:Init()
	if not (CanInspect and NotifyInspect and ClearInspectPlayer and GetInspectSpecialization) then
		return
	end

	-- Persist the GUID->spec cache in saved variables so it survives reloads.
	local db = mini:GetSavedVars()
	db.SpecCache = db.SpecCache or {}
	unitGuidToSpec = db.SpecCache

	PurgeOldEntries()

	hooksecurefunc("NotifyInspect", OnNotifyInspect)
	hooksecurefunc("ClearInspectPlayer", OnClearInspect)

	local eventsFrame = CreateFrame("Frame")
	eventsFrame:SetScript("OnEvent", function(_, event, ...)
		if event == "INSPECT_READY" then
			if requestedUnit then
				Inspect(requestedUnit)
			end
		elseif event == "GROUP_ROSTER_UPDATE" then
			needUpdate = true
			ArmLoop()
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
			local unit = ...
			InvalidateEntry(unit)
			ArmLoop()
		elseif event == "PLAYER_ENTERING_WORLD" then
			priorityStack = {}
			priorityQueued = {}
		end
	end)
	eventsFrame:RegisterEvent("INSPECT_READY")
	eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	eventsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

	initialised = true
	ArmLoop()
end

---@class Inspector
---@field Init fun(self: Inspector)
---@field GetUnitSpecId fun(self: Inspector, unit: string): number|nil
---@field RegisterCallback fun(self: Inspector, callback: function)
