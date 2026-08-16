---
--  Name ...... : Auras
--  Description : Player Buffs, Debuffs, and Weapon Enchants
--

local addonName, LUI = ...
----------------------------------------------------------------------
-- Initialize
----------------------------------------------------------------------

local module = LUI:Module("Auras")
local Media = LUI.Lib("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))

local L = LUI.L
local db, dbd
local argcheck = LUI.argcheck

local profile, group

----------------------------------------------------------------------
-- Local Variables
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Local Functions
----------------------------------------------------------------------
BuffFrame:ClearAllPoints()
BuffFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",300,-35)
BuffFrame.AuraContainer.addIconsToRight = true
BuffFrame.AuraContainer.addIconsToTop = false
BuffFrame.AuraContainer.isHorizontal = true

BuffFrame:ClearAllPoints()
BuffFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",30, 0)
BuffFrame.AuraContainer.addIconsToRight = true
BuffFrame:UpdateAuraContainerAnchor()

DebuffFrame:ClearAllPoints()
DebuffFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT",30, 0)
DebuffFrame:UpdateAuraContainerAnchor()

-- print(profile.Buffs.Anchor)
----------------------------------------------------------------------
-- Aura Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- WeaponEnchant Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Proxy Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Header Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Auras Functions
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Defaults
----------------------------------------------------------------------

module.defaults = {
	profile = {
		Buffs = {
			Anchor = "TOPLEFT",
			X = 30,
			Y = -35,
			Size = 35,
			AurasPerRow = 16,
			NumRows = 2,
			HorizontalSpacing = 12,
			VerticalSpacing = 22,
			SortMethod = "Time",
			ReverseSort = false,
			Consolidate = true,
			Count = {
				Font = "vibrocen",
				Size = 18,
				Flag = "OUTLINE",
				Color = {1, 1, 1},
			},
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Flag = "",
				Color = {1, 1, 1},
			},
		},
		Debuffs = {
			Anchor = "TOPLEFT",
			X = 30,
			Y = -160,
			Size = 35,
			AurasPerRow = 16,
			NumRows = 1,
			HorizontalSpacing = 12,
			VerticalSpacing = 22,
			SortMethod = "Time",
			ReverseSort = false,
			Count = {
				Font = "vibrocen",
				Size = 18,
				Flag = "OUTLINE",
				Color = {1, 1, 1},
			},
			Duration = {
				Font = "vibrocen",
				Size = 12,
				Flag = "",
				Color = {1, 1, 1},
			},
		},
	},
}

----------------------------------------------------------------------
-- Options
----------------------------------------------------------------------

module.getter = "GetDBVar"
module.setter = function(info, value)
	module:SetDBVar(info, value)
	headers[info[2]]:Configure()
end

function module:LoadOptions()
	local function refresh(info)
		headers[info[2]]:Configure()
	end

	local function CreateTextOptions(auraType, kind, order)
		local options = self:NewGroup(kind, order, true, {
			Font = self:NewSelect(L["Font"], L["Choose a font"], 1, true, "LSM30_Font", refresh),
			Flag = self:NewSelect(L["Flag"], L["Choose a font flag"], 2, LUI.FontFlags, false, refresh),
			Size = self:NewSlider(L["Size"], L["Choose a fontsize"], 3, 1, 40, 1, true),
			Color = self:NewColorNoAlpha(format("%s %s", auraType, kind), nil, 4, refresh),
		})

		return options
	end

	local function CreateAuraOptions(auraType, order)
		local options = self:NewGroup(auraType, order, false, InCombatLockdown, {
			header = self:NewHeader(format("Use Blizzard Edit Mode", auraType), 1),
			-- header = self:NewHeader(format(L["%s Options"], auraType), 1),
			-- Size = self:NewSlider(L["Size"], format(L["Choose the Size for your %s"], auraType), 2, 15, 65, 1, true),
			-- Anchor = self:NewSelect(L["Anchor"], format(L["Choose the corner to anchor your %s to"], auraType), 3, LUI.Corners, false, refresh),
			-- X = self:NewInputNumber(L["Horizontal Position"], format(L["Adjust the horizontal position"], auraType), 4, refresh),
			-- Y = self:NewInputNumber(L["Vertical Position"], format(L["Adjust the vertical position"], auraType), 5, refresh),
			-- NumRows = self:NewSlider(L["Number of rows"], format(L["Choose the maximum number of rows for your %s"], auraType), 6, 1, 10, 1, true),
			-- AurasPerRow = self:NewSlider(L["Number per row"], format(L["Choose the maximum number of %s for each row"], auraType), 7, 1, 40, 1, true),
			-- HorizontalSpacing = self:NewInputNumber(L["Spacing"], format(L["Choose the amount of space between each of your %s"], auraType), 8, refresh),
			-- VerticalSpacing = self:NewInputNumber(L["Row Spacing"], format(L["Choose the amount of space between each row of your %s"], auraType), 9, refresh),
			-- Consolidate = auraType == L["Buffs"] and self:NewToggle(format(L["Consolidate %s"], auraType), format(L["Choose whether you want to consolidate your %s or not"], auraType), 10, true) or nil,
			-- SortMethod = self:NewSelect(L["Sorting Order"], format(L["Choose the sorting order for your %s"], auraType), 11, sortOrders, false, refresh),
			-- ReverseSort = self:NewToggle(L["Reverse Sorting"], L["Choose whether you want to reverse the sorting order or not"], 12, true, "normal"),
			-- Count = CreateTextOptions(auraType, L["Count"], 13),
			-- Duration = CreateTextOptions(auraType, L["Duration"], 14),
		})

		return options
	end

	local options = {
		Buffs = CreateAuraOptions(L["Buffs"], 1),
		-- Debuffs = CreateAuraOptions(L["Debuffs"], 2),
	}

	return options
end

function module:Refresh()
	-- for auraType, header in pairs(headers) do
	-- 	header:Configure()
	-- 	header:Update("PLAYER_ENTERING_WORLD")
	-- end
end

local function OnAnyEvent(self, event, addon)
	for i=1, BUFF_MAX_DISPLAY do
		local buff = _G["LUI_Auras_BuffsAuraButton"..i]
		if buff then
			group:AddButton(buff)
		end
		if not buff then break end
	end
	
	for i=1, BUFF_MAX_DISPLAY do
		local debuff = _G["LUI_Auras_DebuffsAuraButton"..i]
		if debuff then
			group:AddButton(debuff)
		end
		if not debuff then break end
	end
	
	for i=1, NUM_TEMP_ENCHANT_FRAMES do
		local f = _G["TempEnchant"..i]
		if TempEnchant then
			group:AddButton(f)
		end
		_G["TempEnchant"..i.."Border"]:SetVertexColor(0.75, 0, 1)
	end
	group:ReSkin()
end

function module:SetupSkins()

	local f = CreateFrame("Frame")

	hooksecurefunc("CreateFrame", function (_, name, parent) --dont need to do this for TempEnchant enchant frames because they are hard created in xml
		if type(name) ~= "string" then return end
		if strfind(name, "LUI_Auras") then
			group:AddButton(_G[name])
			group:ReSkin() -- Needed to prevent issues with stack text appearing under the frame.
		end
	end
	)
		
	f:SetScript("OnEvent", OnAnyEvent)
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("UNIT_AURA")
end

----------------------------------------------------------------------
-- AceAddon Load Functions
----------------------------------------------------------------------

function module:DBCallback()
	profile = self.db.profile

	-- for auraType, header in pairs(headers) do
	-- 	header.settings = profile[auraType]

	-- 	if header.Proxy then
	-- 		header.Proxy.Consolidate.settings = profile[auraType]
	-- 	end
	-- end

	module:Refresh()
end

function module:OnInitialize()
	profile = LUI:Namespace(self, true, 2.0)
end

function module:OnEnable()
	-- if Masque then
	-- 	group = Masque:Group("LUI", "Buffs & Debuffs")
	-- 	self:SetupSkins()
	-- end
end

function module:OnDisable()
	-- for auraType, header in pairs(headers) do
	-- 	header:Hide()
	-- end
end
