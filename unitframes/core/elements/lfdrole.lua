--[[ Element: LFD Role Icon

 Toggles visibility of the LFD role icon based upon the units current dungeon
 role.

 Widget

 LFDRole - A Texture containing the LFD role icons at specific locations. Look
           at the default LFD role icon texture for an example of this.
           Alternatively you can look at the return values of
           GetTexCoordsForRoleSmallCircle(role).

 Notes

 The default LFD role texture will be applied if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local LFDRole = self:CreateTexture(nil, "OVERLAY")
   LFDRole:SetSize(16, 16)
   LFDRole:SetPoint("LEFT", self)
   
   -- Register it with oUF
   self.LFDRole = LFDRole

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event, oufdb)
	print((self.unit))
	local lfdrole = self.LFDRole
	if(lfdrole.PreUpdate) then
		lfdrole:PreUpdate()
	end

	local class = UnitClass(self.unit)
	local name = UnitName(self.unit)
	-- local talent = NotifyInspect(self.unit)
	print(class)
	print(name)
	print(talent)

	local function setrole(self)
		local class = UnitClass(self.unit)
		local name = UnitName(self.unit)
		local talent = GetInspectSpecialization(self.unit)
		print(class)
		print(name)
		print(talent)
			if class == "DEATH KNIGHT" or class == "DEATHKNIGHT" then
				UnitSetRole(name,"DAMAGER");
			elseif class == "DRUID" then
				if talent == 1 then 
					UnitSetRole(name,"DAMAGER");
				elseif talent == 2 then
					UnitSetRole(name,"TANK");
				else
					UnitSetRole(name,"HEALER");
				end
			elseif class == "PALADIN" then
				if talent == 1 then
					UnitSetRole(name,"HEALER");
				elseif talent == 2 then
					UnitSetRole(name,"TANK");
				else
					UnitSetRole(name,"DAMAGER");
				end
			elseif class == "ROGUE" then
				UnitSetRole(name,"DAMAGER");
			elseif class == "SHAMAN" then
				if talent == 3 then
					UnitSetRole(name,"HEALER");
				else
					UnitSetRole(name,"DAMAGER");
				end
			elseif class == "MAGE" then
				UnitSetRole(name,"DAMAGER");
			elseif class == "WARLOCK" then
				UnitSetRole(name,"DAMAGER");
			elseif class == "PRIEST" then
				if talent == 3 then
					UnitSetRole(name,"DAMAGER");
				else 
					UnitSetRole(name,"HEALER");
				end
			elseif class == "WARRIOR" then
				if talent == 3 then
					UnitSetRole(name,"TANK");
				else
					UnitSetRole(name,"DAMAGER");
				end
			end

		-- talentPointsSpent(self.unit)
		-- if ( playerInfo[name].tank == 1 ) then
		-- UnitSetRole(name,"TANK");
		-- elseif ( playerInfo[name].heals == 1 ) then
		-- UnitSetRole(name,"HEALER");
		-- elseif ( playerInfo[name].mDps == 1 ) then
		-- UnitSetRole(name,"DAMAGER");
		-- elseif ( playerInfo[name].rDps == 1 ) then
		-- UnitSetRole(name,"DAMAGER");
		-- end
	end

	local role = 'NONE'
		if UnitGroupRolesAssigned then
			role = UnitGroupRolesAssigned(self.unit)
		end
	if(role == 'TANK' or role == 'HEALER' or role == 'DAMAGER') then
		lfdrole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		lfdrole:Show()
	else
		lfdrole:Hide()
	end

	if(lfdrole.PostUpdate) then
		return lfdrole:PostUpdate(role)
	end
end

local Path = function(self, ...)
	return (self.LFDRole.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self)
	local lfdrole = self.LFDRole
	if(lfdrole) then
		lfdrole.__owner = self
		lfdrole.ForceUpdate = ForceUpdate

		if(self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Path, true)
		else
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
		end

		if(lfdrole:IsObjectType"Texture" and not lfdrole:GetTexture()) then
			lfdrole:SetTexture[[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
		end

		return true
	end
end

local Disable = function(self)
	local lfdrole = self.LFDRole
	if(lfdrole) then
		lfdrole:Hide()
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Path)
	end
end

oUF:AddElement('LFDRole', Path, Enable, Disable)
