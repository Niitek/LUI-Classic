--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: LUI_MM.lua
	Description: Micromenu Module
	Version....: 1.5
	Rev Date...: 14/03/2012

	Edits:
		v1.0: Loui
		v1.1: Loui/Thaly
		v1.2: Thaly
		v1.3: Thaly
		v1.4: Xus
		v1.5: Thaly
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Micromenu", "AceEvent-3.0", "AceHook-3.0")
local Themes = LUI:Module("Themes")
local Panels = LUI:Module("Panels")
local RaidMenu = LUI:Module("RaidMenu")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local db, dbd
local version = 1.5

local fdir = "Interface\\AddOns\\LUI\\media\\templates\\v3\\"

LUI.MicroMenu = {Buttons = {}}

local MicroMenuButtons = {
	'Bags',
	'Settings',
	'Store',
	'Pets',
	'LFG',
	'Encounter',
	'PVP',
	'Guild',
	'Quests',
	'Achievements',
	'Talents',
	'Spellbook',
	'Player',
}

local MicroMenuWidth = 595
local MicroMenuButtonsShift = 1
if LUI.isClassic then 
	MicroMenuWidth = 424
	MicroMenuButtonsShift = -1
	table.remove(MicroMenuButtons, 10)
	table.remove(MicroMenuButtons, 7)
	table.remove(MicroMenuButtons, 6)
	table.remove(MicroMenuButtons, 4)
end
	
local _, class = UnitClass("player")

function module:SetMicroMenuPosition()
	LUI.MicroMenu.Anchor:ClearAllPoints()
	LUI.MicroMenu.Anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.NaviX, db.NaviY)

	LUI.MicroMenu.Button:ClearAllPoints()
	LUI.MicroMenu.Button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", db.X, db.Y)
end

function module:SetColors()
	local r, g, b = unpack(Themes.db.profile.micromenu)
	local rb, gb, bb, ab = unpack(Themes.db.profile.micromenu_btn)
	local rc, gc, bc, ac = unpack(Themes.db.profile.micromenu_bg)
	local rd, gd, bd, ad = unpack(Themes.db.profile.micromenu_bg2)

	LUI.MicroMenu.Anchor:SetBackdropColor(rb, gb, bb, ab)
	LUI.MicroMenu.ButtonRight:SetBackdropColor(rb, gb, bb, ab)
	LUI.MicroMenu.ButtonLeft:SetBackdropColor(rb, gb, bb, ab)

	LUI.MicroMenu.Button:SetBackdropColor(rc, gc, bc, ac)
	LUI.MicroMenu.Button.BG:SetBackdropColor(rd, gd, bd, ad)

	MicroMenuButtonBags:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonSettings:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonStore:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonPets:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonLFG:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonEncounter:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonPVP:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonGuild:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonQuests:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonAchievements:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonTalents:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonSpellbook:SetBackdropColor(r, g, b, 1)
	MicroMenuButtonPlayer:SetBackdropColor(r, g, b, 1)
end

function module:SetMicroMenu()
	local micro_r, micro_g, micro_b = unpack(Themes.db.profile.micromenu)

	LUI.MicroMenu.Anchor = LUI:CreateMeAFrame("Frame", nil, UIParent, 128, 128, 1, "MEDIUM", 2, "TOPRIGHT", UIParent, "TOPRIGHT", -150, 6, 1)
	LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir..(Panels.db.profile.MicroMenu.AlwaysShow and "micro_anchor3" or "micro_anchor")})
	LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)

	--LUI.MicroMenu.Button = LUI:CreateMeAFrame("Frame", nil, UIParent, 640, 512, 1, "BACKGROUND", 1, "TOPRIGHT", UIParent, "TOPRIGHT", 0, -1, 1)
	LUI.MicroMenu.Button = LUI:CreateMeAFrame("Frame", nil, UIParent, MicroMenuWidth + 2, 512, 1, "BACKGROUND", 1, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", 0, -2, 1) --470
	LUI.MicroMenu.Button:SetBackdrop({bgFile = fdir.."micro_button"})
	LUI.MicroMenu.Button:SetBackdropColor(unpack(Themes.db.profile.micromenu_bg))
	LUI.MicroMenu.Button:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.Button.BG = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Button, MicroMenuWidth, 490, 1, "BACKGROUND", 0, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", MicroMenuButtonsShift, -2, 1)
	LUI.MicroMenu.Button.BG:SetBackdrop({bgFile = fdir.."micro_button_bg"})
	LUI.MicroMenu.Button.BG:SetBackdropColor(unpack(Themes.db.profile.micromenu_bg2))
	LUI.MicroMenu.Button.BG:SetBackdropBorderColor(0, 0, 0, 0)
	LUI.MicroMenu.Button.BG:SetFrameStrata("BACKGROUND")

	LUI.MicroMenu.Clicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.Anchor, 85, 22, 1, "MEDIUM", 2, "TOP", LUI.MicroMenu.Anchor, "TOP", -2, 0, 1)
	LUI.MicroMenu.Clicker:RegisterForClicks("AnyUp")
	LUI.MicroMenu.Clicker:SetScript("OnClick", function(self)
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.AlphaOut:Show()
			Panels.db.profile.MicroMenu.IsShown = false

			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir..(GetMouseFoci() == LUI.MicroMenu.Clicker and "micro_anchor2" or "micro_anchor")})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.AlphaIn:Show()
			Panels.db.profile.MicroMenu.IsShown = true

			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir..(GetMouseFoci() == LUI.MicroMenu.Clicker and "micro_anchor4" or "micro_anchor3")})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)
	LUI.MicroMenu.Clicker:SetScript("OnEnter", function(self)
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir.."micro_anchor4"})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir.."micro_anchor2"})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)
	LUI.MicroMenu.Clicker:SetScript("OnLeave", function(self)
		if Panels.db.profile.MicroMenu.IsShown then
			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir.."micro_anchor3"})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		else
			LUI.MicroMenu.Anchor:SetBackdrop({bgFile = fdir.."micro_anchor"})
			LUI.MicroMenu.Anchor:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
			LUI.MicroMenu.Anchor:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end)

	LUI.MicroMenu.ButtonRight = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Anchor, 128, 128, 1, "MEDIUM", 1, "RIGHT", LUI.MicroMenu.Anchor, "RIGHT", 47, -3, 1)
	LUI.MicroMenu.ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right"})
	LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.ButtonRightClicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.ButtonRight, 40, 12, 1, "MEDIUM", 2, "TOP", LUI.MicroMenu.ButtonRight, "TOP", 22, -5, 1)
	LUI.MicroMenu.ButtonRightClicker:RegisterForClicks("AnyUp")
	LUI.MicroMenu.ButtonRightClicker:SetScript("OnClick", function(self, button)
		if LUI:GetModule("Minimap"):IsEnabled() then
			if button == "RightButton" then
				ToggleFrame(WorldMapFrame)
			else
				if Minimap:GetAlpha() == 0 then
					MinimapAlphaIn:Show()
					Panels.db.profile.Minimap.IsShown = true
				else
					MinimapAlphaOut:Show()
					Panels.db.profile.Minimap.IsShown = false
				end
			end
		else
			ToggleFrame(WorldMapFrame)
		end
	end)
	LUI.MicroMenu.ButtonRightClicker:SetScript("OnEnter", function(self)
		LUI.MicroMenu.ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right_hover"})
		LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
		LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)
	end)
	LUI.MicroMenu.ButtonRightClicker:SetScript("OnLeave", function(self)
		LUI.MicroMenu.ButtonRight:SetBackdrop({bgFile = fdir.."mm_button_right"})
		LUI.MicroMenu.ButtonRight:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
		LUI.MicroMenu.ButtonRight:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.ButtonLeft = LUI:CreateMeAFrame("Frame", nil, LUI.MicroMenu.Anchor, 128, 128, 1, "MEDIUM", 1, "LEFT", LUI.MicroMenu.Anchor, "LEFT", -47, -3, 1)
	LUI.MicroMenu.ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left"})
	LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
	LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)

	LUI.MicroMenu.ButtonLeftClicker = LUI:CreateMeAFrame("Button", nil, LUI.MicroMenu.ButtonLeft, 40, 12, 1, "MEDIUM", 2, "TOP", LUI.MicroMenu.ButtonLeft, "TOP", -22, -5, 1)
	LUI.MicroMenu.ButtonLeftClicker:RegisterForClicks("AnyUp")
	LUI.MicroMenu.ButtonLeftClicker:SetScript("OnClick", function(self, button)	RaidMenu:OverlapPrevention("RM", "toggle") end)
	LUI.MicroMenu.ButtonLeftClicker:SetScript("OnEnter", function(self)
		LUI.MicroMenu.ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left_hover"})
		LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn_hover))
		LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)
	end)
	LUI.MicroMenu.ButtonLeftClicker:SetScript("OnLeave", function(self)
		LUI.MicroMenu.ButtonLeft:SetBackdrop({bgFile = fdir.."mm_button_left"})
		LUI.MicroMenu.ButtonLeft:SetBackdropColor(unpack(Themes.db.profile.micromenu_btn))
		LUI.MicroMenu.ButtonLeft:SetBackdropBorderColor(0, 0, 0, 0)
	end)

	LUI.MicroMenu.AlphaOut = CreateFrame("Frame", nil, UIParent)
	LUI.MicroMenu.AlphaOut:Hide()
	LUI.MicroMenu.AlphaOut.timer = 0
	LUI.MicroMenu.AlphaOut:SetScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer + elapsed
		if self.timer < .5 then
			LUI.MicroMenu.Button:SetAlpha(1 - self.timer / .5)
		else
			LUI.MicroMenu.Button:SetAlpha(0)
			LUI.MicroMenu.Button:Hide()
			self.timer = 0
			self:Hide()
		end
	end)

	LUI.MicroMenu.AlphaIn = CreateFrame("Frame", nil, UIParent)
	LUI.MicroMenu.AlphaIn:Hide()
	LUI.MicroMenu.AlphaIn.timer = 0
	LUI.MicroMenu.AlphaIn:SetScript("OnUpdate", function(self, elapsed)
		LUI.MicroMenu.Button:Show()
		self.timer = self.timer + elapsed
		if self.timer < .5 then
			LUI.MicroMenu.Button:SetAlpha(self.timer / .5)
		else
			LUI.MicroMenu.Button:SetAlpha(1)
			self.timer = 0
			self:Hide()
		end
	end)

	--------------------------------------
	-- MICRO MENU
	--------------------------------------

	for i = 1, #MicroMenuButtons do
		if i == 1 then
			frame = LUI:CreateMeAFrame("Frame", "MicroMenuButton"..MicroMenuButtons[i], LUI.MicroMenu.Button, 64, 64, 1, "BACKGROUND", 3, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", 2, 0, 1)
		elseif i == 2 then
			frame = LUI:CreateMeAFrame("Frame", "MicroMenuButton"..MicroMenuButtons[i], LUI.MicroMenu.Button, 64, 64, 1, "BACKGROUND", 3, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", -46, 0, 1)
		elseif i > 2 then
			frame = LUI:CreateMeAFrame("Frame", "MicroMenuButton"..MicroMenuButtons[i], LUI.MicroMenu.Button, 64, 64, 1, "BACKGROUND", 3, "TOPRIGHT", LUI.MicroMenu.Button, "TOPRIGHT", (-33*(i-2))-46, 0, 1)
		end
		frame:SetBackdrop({bgFile = fdir.."micro_"..MicroMenuButtons[i]})
		frame:SetBackdropColor(micro_r, micro_g, micro_b, 1)
	end

	local bagsFrame
	local getBagsFrame = function()
		if LUI:Module("Bags").db.profile.Enable then
			bagsFrame = LUIBags
		elseif C_AddOns.IsAddOnLoaded("Stuffing") then
			bagsFrame = StuffingFrameBags
		elseif C_AddOns.IsAddOnLoaded("Bagnon") then
			bagsFrame = BagnonFrameinventory
		elseif C_AddOns.IsAddOnLoaded("ArkInventory") then
			bagsFrame = ARKINV_Frame1
		elseif C_AddOns.IsAddOnLoaded("OneBag") then
			bagsFrame = OneBagFrame
		else
			bagsFrame = nil
		end
	end
	getBagsFrame()

	MicroMenuButtonBagsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonBags, 42, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonBags, "CENTER", -8, 0, 1)
	MicroMenuButtonBagsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonBagsClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonBagsClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonBagsClicker:SetAlpha(0)
	MicroMenuButtonBagsClicker:RegisterForClicks("AnyUp")
	MicroMenuButtonBagsClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Bags")
		GameTooltip:AddLine("Left Click: Hide/Show your Bags", 1, 1, 1)
		GameTooltip:AddLine("Right Click: Hide/Show your Keyring", 1, 1, 1)	
		GameTooltip:Show()
	end)
	MicroMenuButtonBagsClicker:SetScript("OnLeave", function(self)
		getBagsFrame()
		if bagsFrame and not bagsFrame:IsShown() then self:SetAlpha(0) end
		GameTooltip:Hide()
	end)
	MicroMenuButtonBagsClicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
		ToggleBag(-2)
		else
		ToggleAllBags()
		end
	end)
	MicroMenuButtonBagsClicker:SetScript("OnUpdate", function(self)
		local i=IsBagOpen
		if (bagsFrame and bagsFrame:IsShown()) or i(0) or i(1) or i(2) or i(3) or i(4) or self.State then
			self:SetAlpha(1)
		else
			self:SetAlpha(0)
		end
	end)

	MicroMenuButtonSettingsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonSettings, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonSettings, "CENTER", -2, 0, 1)
	MicroMenuButtonSettingsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonSettingsClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonSettingsClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonSettingsClicker:SetAlpha(0)
	MicroMenuButtonSettingsClicker:RegisterForClicks("AnyUp")
	MicroMenuButtonSettingsClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
		GameTooltip:SetText("Options")
		GameTooltip:AddLine("Left Click: LUI Option Panel", 1,1,1)
		GameTooltip:AddLine("Right Click: WoW Option Panel", 1,1,1)
		GameTooltip:Show()
	end)
	MicroMenuButtonSettingsClicker:SetScript("OnLeave", function(self)
		self:SetAlpha(0)
		GameTooltip:Hide()
	end)
	MicroMenuButtonSettingsClicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if GameMenuFrame:IsShown() then
				HideUIPanel(GameMenuFrame)
			else
				ShowUIPanel(GameMenuFrame)
			end
		else
			if not InCombatLockdown() or LUI.options then
				LUI:Open()
			else
				LUI:Print("Unable to open the options for the first time while in combat.")
			end
		end
	end)

	MicroMenuButtonStoreClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonStore, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonStore, "CENTER", -2, 0, 1)
	MicroMenuButtonStoreClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonStoreClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonStoreClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonStoreClicker:SetAlpha(0)
	MicroMenuButtonStoreClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
		GameTooltip:SetText("Blizzard Store")
		GameTooltip:AddLine("Show/Hide the Blizzard Store Frame", 1, 1, 1)
		GameTooltip:Show()
	end)
	MicroMenuButtonStoreClicker:SetScript("OnLeave", function(self)
		self:SetAlpha(0)
		GameTooltip:Hide()
	end)
	MicroMenuButtonStoreClicker:SetScript("OnClick", function(self)
		ToggleStoreUI()
	end)

	MicroMenuButtonLFGClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonLFG, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonLFG, "CENTER", -2, 0, 1)
	MicroMenuButtonLFGClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonLFGClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonLFGClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonLFGClicker:SetAlpha(0)
	MicroMenuButtonLFGClicker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	MicroMenuButtonLFGClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Looking For Group/Looking For More")
		GameTooltip:AddLine("Dungeons & Raids", 1, 1, 1)
		if UnitLevel("player") < 15 then
			GameTooltip:AddLine("Available with Level 15", 1, 0, 0)
		end
		GameTooltip:Show()
	end)
	MicroMenuButtonLFGClicker:SetScript("OnLeave", function(self)
		self:SetAlpha(0)
		self.State = nil
		GameTooltip:Hide()
	end)
	MicroMenuButtonLFGClicker:SetScript("OnClick", function(self, button)
		if LUI.isClassic then
			ToggleFrame(LFGParentFrame)
		else
			PVEFrame_ToggleFrame()
		end
	end)

	if not LUI.isClassic then	
		MicroMenuButtonPetsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonPets, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonPets, "CENTER", -2, 0, 1)
		MicroMenuButtonPetsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
		MicroMenuButtonPetsClicker:SetBackdropColor(0, 0, 0, 1)
		MicroMenuButtonPetsClicker:SetBackdropBorderColor(0, 0, 0, 0)
		MicroMenuButtonPetsClicker:SetAlpha(0)
		MicroMenuButtonPetsClicker:SetScript("OnEnter", function(self)
			self:SetAlpha(1)
			GameTooltip:SetOwner(self, "ANCHOR_NONE " ,40, -90)
			GameTooltip:SetText("Collections")
			GameTooltip:AddLine("Show/Hide the Collections UI", 1, 1, 1)
			GameTooltip:Show()
		end)
		MicroMenuButtonPetsClicker:SetScript("OnLeave", function(self)
			if not PetJournalParent or not PetJournalParent:IsShown() then
				self:SetAlpha(0)
			end
			GameTooltip:Hide()
		end)
		MicroMenuButtonPetsClicker:SetScript("OnClick", function(self)
			_G.ToggleCollectionsJournal()
		end)

		MicroMenuButtonEncounterClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonEncounter, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonEncounter, "CENTER", -2, 0, 1)
		MicroMenuButtonEncounterClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
		MicroMenuButtonEncounterClicker:SetBackdropColor(0, 0, 0, 1)
		MicroMenuButtonEncounterClicker:SetBackdropBorderColor(0, 0, 0, 0)
		MicroMenuButtonEncounterClicker:SetAlpha(0)
		MicroMenuButtonEncounterClicker:SetScript("OnEnter", function(self)
			self:SetAlpha(1)
			GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
			GameTooltip:SetText("Encounter Journal")
			GameTooltip:AddLine("Dungeon & Encounter Journal", 1, 1, 1)
			GameTooltip:Show()
		end)
		MicroMenuButtonEncounterClicker:SetScript("OnLeave", function(self)
			self:SetAlpha(0)
			self.State = nil
			GameTooltip:Hide()
		end)
		MicroMenuButtonEncounterClicker:SetScript("OnClick", function(self)
			ToggleEncounterJournal()
		end)

		MicroMenuButtonPVPClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonPVP, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonPVP, "CENTER", -2, 0, 1)
		MicroMenuButtonPVPClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
		MicroMenuButtonPVPClicker:SetBackdropColor(0, 0, 0, 1)
		MicroMenuButtonPVPClicker:SetBackdropBorderColor(0, 0, 0, 0)
		MicroMenuButtonPVPClicker:SetAlpha(0)
		MicroMenuButtonPVPClicker:SetScript("OnEnter", function(self)
			self:SetAlpha(1)
			GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
			GameTooltip:SetText("PvP")
			GameTooltip:AddLine("Arena/Battlegrounds...", 1, 1, 1)
			if UnitLevel("player") < 10 then
				GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
			end
			GameTooltip:Show()
		end)
		MicroMenuButtonPVPClicker:SetScript("OnLeave", function(self)
			self:SetAlpha(0)
			self.State = nil
			GameTooltip:Hide()
		end)
		MicroMenuButtonPVPClicker:SetScript("OnClick", function(self)
			if UnitLevel("player") >= 10 then
				TogglePVPFrame()
				-- TogglePVPUI()
			end
		end)

		MicroMenuButtonAchievementsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonAchievements, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonAchievements, "CENTER", -2, 0, 1)
		MicroMenuButtonAchievementsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
		MicroMenuButtonAchievementsClicker:SetBackdropColor(0, 0, 0, 1)
		MicroMenuButtonAchievementsClicker:SetBackdropBorderColor(0, 0, 0, 0)
		MicroMenuButtonAchievementsClicker:SetAlpha(0)
		MicroMenuButtonAchievementsClicker:SetScript("OnEnter", function(self)
			self:SetAlpha(1)
			GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
			GameTooltip:SetText("Achievements")
			GameTooltip:AddLine("Show/Hide your Achievements", 1, 1, 1)
			GameTooltip:Show()
		end)
		MicroMenuButtonAchievementsClicker:SetScript("OnLeave", function(self)
			self:SetAlpha(0)
			GameTooltip:Hide()
		end)
		MicroMenuButtonAchievementsClicker:SetScript("OnClick", function(self)
			ToggleAchievementFrame()
		end)
	end
	
	MicroMenuButtonGuildClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonGuild, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonGuild, "CENTER", -2, 0, 1)
	MicroMenuButtonGuildClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonGuildClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonGuildClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonGuildClicker:SetAlpha(0)
	MicroMenuButtonGuildClicker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	MicroMenuButtonGuildClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(MicroMenuButtonGuildClicker, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Guild/Friends")
		GameTooltip:AddLine("Left Click: Guild Frame", 1, 1, 1)
		GameTooltip:AddLine("Right Click: Friends Frame", 1, 1, 1)
		GameTooltip:Show()
	end)
	MicroMenuButtonGuildClicker:SetScript("OnLeave", function(self)
		if not FriendsFrame:IsShown() and not GuildFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)
	MicroMenuButtonGuildClicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			ToggleFriendsFrame(1)
		else
			if not CommunitiesFrame:IsShown() then
				ShowUIPanel(CommunitiesFrame)
			else
				HideUIPanel(CommunitiesFrame)
			end
		end
	end)

	MicroMenuButtonQuestsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonQuests, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonQuests, "CENTER", -2, 0, 1)
	MicroMenuButtonQuestsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonQuestsClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonQuestsClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonQuestsClicker:SetAlpha(0)
	MicroMenuButtonQuestsClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Quests Log")
		GameTooltip:AddLine("Show/Hide your Quests Log", 1, 1, 1)
		GameTooltip:Show()
	end)
	MicroMenuButtonQuestsClicker:SetScript("OnLeave", function(self)
		if not QuestLogFrame:IsShown() then self:SetAlpha(0) end
		GameTooltip:Hide()
	end)
	MicroMenuButtonQuestsClicker:SetScript("OnClick", function(self)
		if QuestLogFrame:IsShown() then
			HideUIPanel(QuestLogFrame)
		else
			ShowUIPanel(QuestLogFrame)
		end
	end)

	MicroMenuButtonTalentsClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonTalents, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonTalents, "CENTER", -2, 0, 1)
	MicroMenuButtonTalentsClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonTalentsClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonTalentsClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonTalentsClicker:SetAlpha(0)
	MicroMenuButtonTalentsClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Talents")
		GameTooltip:AddLine("Show/Hide your Talent Frame", 1, 1, 1)
		if UnitLevel("player") < 10 then
			GameTooltip:AddLine("Available with Level 10", 1, 0, 0)
		end
		GameTooltip:Show()
	end)
	MicroMenuButtonTalentsClicker:SetScript("OnLeave", function(self)
		if not PlayerTalentFrame:IsShown() then
			self:SetAlpha(0)
		end
		self.State = nil
		GameTooltip:Hide()
	end)
	MicroMenuButtonTalentsClicker:SetScript("OnClick", function(self)
		if UnitLevel("player") >= 10 then
			if PlayerTalentFrame:IsShown() then
				HideUIPanel(PlayerTalentFrame)
			else
				ShowUIPanel(PlayerTalentFrame)
			end
		end
	end)
	if not PlayerTalentFrame then
		C_AddOns.LoadAddOn("Blizzard_TalentUI")
		-- Fix for Events firing before TalentFrame is fully loaded (aka: blizz fail with patch 4.0.6)
		ShowUIPanel(PlayerTalentFrame)
		HideUIPanel(PlayerTalentFrame)
	end

	MicroMenuButtonSpellbookClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonSpellbook, 30, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonSpellbook, "CENTER", -2, 0, 1)
	MicroMenuButtonSpellbookClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonSpellbookClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonSpellbookClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonSpellbookClicker:SetAlpha(0)
	MicroMenuButtonSpellbookClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ", 40, -90)
		GameTooltip:SetText("Spellbook & Abilities")
		GameTooltip:AddLine("Show/Hide your Spellbook", 1, 1, 1)
		GameTooltip:Show()
	end)
	MicroMenuButtonSpellbookClicker:SetScript("OnLeave", function(self)
		if not SpellBookFrame:IsShown() then self:SetAlpha(0) end
		GameTooltip:Hide()
	end)
	MicroMenuButtonSpellbookClicker:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		if SpellBookFrame:IsShown() then
			HideUIPanel(SpellBookFrame)
		else
			ShowUIPanel(SpellBookFrame)
		end
	end)

	MicroMenuButtonPlayerClicker = LUI:CreateMeAFrame("Button", nil, MicroMenuButtonPlayer, 42, 25, 1, "BACKGROUND", 2, "CENTER", MicroMenuButtonPlayer, "CENTER", -8, 0, 1)
	MicroMenuButtonPlayerClicker:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	MicroMenuButtonPlayerClicker:SetBackdropColor(0, 0, 0, 1)
	MicroMenuButtonPlayerClicker:SetBackdropBorderColor(0, 0, 0, 0)
	MicroMenuButtonPlayerClicker:SetAlpha(0)
	MicroMenuButtonPlayerClicker:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		GameTooltip:SetOwner(self, "ANCHOR_NONE ",40,-90)
		GameTooltip:SetText("Character Info")
		GameTooltip:AddLine("Show/Hide your Character Pane", 1, 1, 1)
		GameTooltip:Show()
	end)
	MicroMenuButtonPlayerClicker:SetScript("OnLeave", function(self)
		if not CharacterFrame:IsShown() then self:SetAlpha(0) end
		self.State = nil
		GameTooltip:Hide()
	end)
	MicroMenuButtonPlayerClicker:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			ToggleCharacter("PetPaperDollFrame")
		else
			ToggleCharacter("PaperDollFrame")
		end
	end)

	self:SetMicroMenuPosition()

	-- Alert Frames
	-- if LUI.isMists then module:SecureHook(HelpTip, "Show", "ScanHelpTips") end
	-- if LUI.isMists and HelpTip.framePool.numActiveObjects > 0 then
	-- 	module:ScanHelpTips()
	-- end
	-- hooksecurefunc(HelpTipTemplateMixin,"Init",function(self,parent,info,relregion)
	-- 	if info.system=="MicroButtons" then
	-- 		info.targetPoint=HelpTip.Point.BottomEdgeCenter;
	-- 		self:AnchorAndRotate();
	-- 	end
	-- end);
	-- if LUI.isMists and TalentMicroButtonAlert:IsShown() then
	-- 	TalentMicroButtonAlert:ClearAllPoints()
	-- 	TalentMicroButtonAlert:SetPoint("TOP", MicroMenuButtonTalentsClicker, "TOP", 0, -50)
	-- 	TalentMicroButtonAlert.Arrow:ClearAllPoints()
	-- 	TalentMicroButtonAlert.Arrow:SetPoint("BOTTOM", TalentMicroButtonAlert, "TOP", 0, 0)
	-- 	print(TalentMicroButtonAlert.Arrow:GetRotation())
	-- end
	-- hooksecurefunc(HelpTip,"Show", 
	-- 	function(parent,info,relativeRegion)
	-- 		for frame in HelpTip.framePool:EnumerateActive() do
	-- 			if frame.info.system == "MicroButtons" then
	-- 				frame.info.targetPoint = HelpTip.Point.BottomEdgeCenter
	-- 			end
	-- 		end
	-- 	end
	-- )
end

function module:ScanHelpTips()
	for frame in HelpTip.framePool:EnumerateActive() do
		local parent = frame.relativeRegion:GetName()
		if parent == "CollectionsMicroButton" then
			module:AnchorAlertFrame(frame, MicroMenuButtonPets)
		elseif parent == "TalentMicroButton" then
			module:AnchorAlertFrame(frame, MicroMenuButtonTalents)
		elseif parent == "EJMicroButton" then
			module:AnchorAlertFrame(frame, MicroMenuButtonEncounter)
		end
	end
end

function module:AnchorAlertFrame(frame, anchor)
	frame.relativeRegion = anchor
	frame:ClearAllPoints()
	frame:SetPoint("TOP", anchor, "BOTTOM")
	frame.Arrow:ClearAllPoints()
	frame.Arrow:SetPoint("BOTTOM", frame, "TOP", 0, -30)
end

module.defaults = {
	profile = {
		X = 0,
		Y = -1,
		NaviX = -150,
		NaviY = 6,
		GuildComm = true,
	}
}

function module:LoadFrameOptions()
	local options = {
		name = "MicroMenu",
		type = "group",
		order = 6,
		args = {
			MicroMenuPosition = {
				name = "Micro Menu",
				type = "group",
				order = 1,
				guiInline = true,
				args = {
					MMX = {
						name = "X Value",
						desc = "X Value for your Micro Menu.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..dbd.profile.X,
						type = "input",
						get = function() return tostring(db.X) end,
						set = function(self,MMX)
							if MMX == nil or MMX == "" then
								MMX = 0
							end
							db.X = tonumber(MMX)

							module:SetMicroMenuPosition()
						end,
						order = 1,
					},
					MMY = {
						name = "Y Value",
						desc = "Y Value for your Micro Menu.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..dbd.profile.Y,
						type = "input",
						get = function() return tostring(db.Y) end,
						set = function(self,MMY)
							if MMY == nil or MMY == "" then
								MMY = 0
							end
							db.Y = tonumber(MMY)

							module:SetMicroMenuPosition()
						end,
						order = 2,
					},
				},
			},
			MicroMenuNaviPosition = {
				name = "Micro Menu Navigation",
				type = "group",
				order = 2,
				guiInline = true,
				args = {
					MMNaviX = {
						name = "X Value",
						desc = "X Value for your Micro Menu Navigation Panel.\n\nNote:\nPositive values = right\nNegative values = left\nDefault: "..dbd.profile.NaviX,
						type = "input",
						get = function() return tostring(db.NaviX) end,
						set = function(self, MMNaviX)
							if MMNaviX == nil or MMNaviX == "" then
								MMNaviX = 0
							end
							db.NaviX = tonumber(MMNaviX)

							module:SetMicroMenuPosition()
						end,
						order = 1,
					},
					MMNaviY = {
						name = "Y Value",
						desc = "Y Value for your Micro Menu Navigation Panel.\n\nNote:\nPositive values = up\nNegative values = down\nDefault: "..dbd.profile.NaviY,
						type = "input",
						get = function() return tostring(db.NaviY) end,
						set = function(self, MMNaviY)
							if MMNaviY == nil or MMNaviY == "" then
								MMNaviY = 0
							end
							db.NaviY = tonumber(MMNaviY)

							module:SetMicroMenuPosition()
						end,
						order = 2,
					},
					-- option to use Guild/Communities instead of Guild/Friends
					GuildComm = {
						name = "Display Communities instead of Friends on Right Click",
						desc = "Changes the Guild button's right click to show/hide Communities instead of Friends panel.",
						type = "toggle",
						width = "full",
						get = function() return db.GuildComm end,
						set = function(info, value)
							db.GuildComm = value
						end,
						order = 3,
					},
				},
			},
		},
	}

	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, nil, version)

	LUI:Module("Panels"):RegisterFrame(self)
end

function module:OnEnable()
	self:SetMicroMenu()
end
