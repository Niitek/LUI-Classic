--[[ Element: Heal Prediction Bar
 Handle updating and visibility of the heal prediction status bars.

 Widget

 HealPrediction - A table containing `myBar` and `otherBar`.

 Sub-Widgets

 myBar    - A StatusBar used to represent your incoming heals.
 otherBar - A StatusBar used to represent other peoples incoming heals.

 Notes

 The default StatusBar texture will be applied if the UI widget doesn't have a
 status bar texture or color defined.

 Options

 .maxOverflow     - Defines the maximum amount of overflow past the end of the
                    health bar.
 .frequentUpdates - Update on UNIT_HEALTH_FREQUENT instead of UNIT_HEALTH. Use
                    this if .frequentUpdates is also set on the Health element.

 Examples

   -- Position and size
   local myBar = CreateFrame('StatusBar', nil, self.Health)
   myBar:SetPoint('TOP')
   myBar:SetPoint('BOTTOM')
   myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
   myBar:SetWidth(200)
   
   local otherBar = CreateFrame('StatusBar', nil, self.Health)
   otherBar:SetPoint('TOP')
   otherBar:SetPoint('BOTTOM')
   otherBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
   otherBar:SetWidth(200)

   -- Register with oUF
   self.HealPrediction = {
      myBar = myBar,
      otherBar = otherBar,
      maxOverflow = 1.05,
      frequentUpdates = true,
   }

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local _, ns = ...
local oUF = ns.oUF

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local hp = self.HealPrediction
	if(hp.PreUpdate) then hp:PreUpdate(unit) end

	local myIncomingHeal = UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

	if (health + allIncomingHeal > maxHealth * hp.maxOverflow) then
		allIncomingHeal = maxHealth * hp.maxOverflow - health
	end

	local otherIncomingHeal = 0
	if(allIncomingHeal < myIncomingHeal) then
		myIncomingHeal = allIncomingHeal
	else
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	end

	if(hp.myBar) then
		hp.myBar:SetMinMaxValues(0, maxHealth)
		hp.myBar:SetValue(myIncomingHeal)
		hp.myBar:Show()
	end

	if(hp.otherBar) then
		hp.otherBar:SetMinMaxValues(0, maxHealth)
		hp.otherBar:SetValue(otherIncomingHeal)
		hp.otherBar:Show()
	end
	if(hp.PostUpdate) then
		return hp:PostUpdate(unit)
	end
end

local function Path(self, ...)
	return (self.HealPrediction.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local hp = self.HealPrediction
	if(hp) then
		hp.__owner = self
		hp.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:RegisterEvent('UNIT_MAXHEALTH', Path)
		if(hp.frequentUpdates) then
			self:RegisterEvent('UNIT_HEALTH_FREQUENT', Path)
		else
			self:RegisterEvent('UNIT_HEALTH', Path)
		end
		if(not hp.maxOverflow) then
			hp.maxOverflow = 1.05
		end

		if(hp.myBar) then
			if(hp.myBar:IsObjectType'StatusBar' and not hp.myBar:GetStatusBarTexture()) then
				hp.myBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			hp.myBar:Show()
		end
		if(hp.otherBar) then
			if(hp.otherBar:IsObjectType'StatusBar' and not hp.otherBar:GetStatusBarTexture()) then
				hp.otherBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			hp.otherBar:Show()
		end

		return true
	end
end

local function Disable(self)
	local hp = self.HealPrediction
	if(hp) then
		if(hp.myBar) then
			hp.myBar:Hide()
		end
		if(hp.otherBar) then
			hp.otherBar:Hide()
		end

		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_HEALTH', Path)
		self:UnregisterEvent('UNIT_HEALTH_FREQUENT', Path)
	end
end

oUF:AddElement('HealPrediction', Path, Enable, Disable)
