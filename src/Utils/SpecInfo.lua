local _, addon = ...

---@class SpecInfo
local M = {}
addon.SpecInfo = M

-- 12.1 moved the specialization functions onto C_SpecializationInfo and the globals stopped
-- answering, which silently emptied every spec lookup in the addon. The classic clients this
-- addon also supports only ever had the globals. Resolved per call rather than bound once,
-- because this file loads before the client has finished filling either shape in.
local function SpecFunction(name)
	local namespaced = C_SpecializationInfo and C_SpecializationInfo[name]

	if namespaced then
		return namespaced
	end

	return _G[name]
end

---Whether this client can answer spec questions at all. Classic Era has no specs.
---@return boolean
function M:IsSupported()
	return SpecFunction("GetSpecializationInfoByID") ~= nil
end

---The player's own specialization id, or nil when the client will not say.
---@return number?
function M:GetPlayerSpecId()
	local index = SpecFunction("GetSpecialization")
	local info = SpecFunction("GetSpecializationInfo")

	if not index or not info then
		return nil
	end

	local specIndex = index()

	if not specIndex then
		return nil
	end

	local specId = info(specIndex)

	if type(specId) ~= "number" or specId <= 0 then
		return nil
	end

	return specId
end

---@param specId number
---@return number? id
---@return string? name
---@return string? description
---@return number? icon
---@return string? role
function M:GetSpecializationInfoByID(specId)
	local fn = SpecFunction("GetSpecializationInfoByID")

	if not fn or not specId then
		return nil
	end

	return fn(specId)
end

---@param classId number
---@return number
function M:GetNumSpecializationsForClassID(classId)
	local fn = SpecFunction("GetNumSpecializationsForClassID")

	if not fn then
		return 0
	end

	return fn(classId) or 0
end

---@param classId number
---@param specIndex number
---@return number? specId
---@return string? specName
function M:GetSpecializationInfoForClassID(classId, specIndex)
	local fn = SpecFunction("GetSpecializationInfoForClassID")

	if not fn then
		return nil
	end

	return fn(classId, specIndex)
end
