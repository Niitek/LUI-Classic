local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Reputation was unable to locate oUF install')

for tag, func in pairs({
	['currep'] = function()
		local _, _, _, _, value = C_Reputation.GetWatchedFactionDataInfo()
		return value
	end,
	['maxrep'] = function()
		local _, _, _, max = C_Reputation.GetWatchedFactionDataInfo()
		return max
	end,
	['perrep'] = function()
		local _, _, _, max, value = C_Reputation.GetWatchedFactionDataInfo()
		return math.floor(value / max * 100 + 0.5)
	end,
	['standing'] = function()
		local _, standing = C_Reputation.GetWatchedFactionDataInfo()
		return standing
	end,
	['reputation'] = function()
		return C_Reputation.GetWatchedFactionDataInfo()
	end,
}) do
	oUF.Tags.Methods[tag] = func
	oUF.Tags.Events[tag] = 'UPDATE_FACTION'
end

local function Update(self, event, unit)
	local reputation = self.Reputation
	
	if(not C_Reputation.GetWatchedFactionDataInfo()) then
		return reputation:Hide()
	else
		reputation:Show()
	end

	local name, standing, min, max, value = C_Reputation.GetWatchedFactionDataInfo()
	reputation:SetMinMaxValues(min, max)
	reputation:SetValue(value)

	if(reputation.PostUpdate) then
		return reputation:PostUpdate(unit, name, standing, min, max, value)
	end
end

local function Path(self, ...)
	return (self.Reputation.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local reputation = self.Reputation
	if(reputation) then
		reputation.__owner = self
		reputation.ForceUpdate = ForceUpdate

		self:RegisterEvent('UPDATE_FACTION', Path)

		if(not reputation:GetStatusBarTexture()) then
			reputation:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		return true
	end
end

local function Disable(self)
	if(self.Reputation) then
		self:UnregisterEvent('UPDATE_FACTION', Path)
	end
end

oUF:AddElement('Reputation', Path, Enable, Disable)
