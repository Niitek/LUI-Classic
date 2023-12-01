--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: bags.lua
	Description: Bags Module
	Version....: 1.3.2
	Rev Date...: 27/04/11 [dd/mm/yy]

	Edits:
		v1.0: Loui
		-  a: Chaoslux
		v1.1: Chaoslux
		v1.2: Chaoslux
		v1.3: Chaoslux
		v1.3.1: Xolsom (Stack & Sort Function)
		v1.3.2: Xolsom (WoW 4.1 Fix)

	A featureless, 'pure' version of Stuffing.
	This version should work on absolutely everything,
	but I've removed pretty much all of the options.
]]

-- External references.
local addonname, LUI = ...
local module = LUI:Module("Bags", "AceHook-3.0", "AceEvent-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local widgetLists = AceGUIWidgetLSMlists

local db, dbd
local GetBags = {
	["Bags"] = {0, 1, 2, 3, 4},
	["Bank"] = {-1, 5, 6, 7, 8, 9, 10, 11},
	-- ["Bank"] = {5, 6, 7, 8, 9, 10, 11},
}
local isCreated = {}

--localized API
local _G = getfenv(0)
local tinsert = table.insert
local tremove = table.remove
local strlower = string.lower
local strfind = string.find
local strsub = string.sub
local format = format
local pairs, ipairs = pairs, ipairs

local MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS

local GetItemInfo = GetItemInfo
local GetKeyRingSize = GetKeyRingSize
local GetMoneyString = GetMoneyString
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local PickupContainerItem = PickupContainerItem or (C_Container and (C_Container.PickupContainerItem))
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerNumFreeSlots = GetContainerNumFreeSlots

local CreateFrame = CreateFrame
local OpenEditbox = OpenEditbox
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonDesaturated = SetItemButtonDesaturated

local BankFrameItemButton_Update = BankFrameItemButton_Update
local BankFrameItemButton_UpdateLocked = BankFrameItemButton_UpdateLocked

-- Constants. Do NOT Edit those.
local ST_NORMAL = 1	--Flagged for possible deletion
local ST_SPECIAL = 3	--Flagged for possible deletion
local bagTexSize = 30

--Wonder about new names for those. Or if their purpose is justified.
local trashButton = {}
local trashBag = {}

local LUIBags, LUIBank		-- replace self.frame and self.bankframe

--Cache tables.
local BagsInfo = {}		--replace self.bags
local ItemSlots = {}		--replace self.buttons
local BagsSlots = {}		--replace self.bagsframe_buttons

--Tooltip Frame for to scan item tooltips.
--At the moment, not sure if tooltip scanning is required.
--local LUIBagsTT = nil

--Making sure the Static Popup uses the good args.
StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT"] = {
	preferredIndex = 3,
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		PurchaseSlot();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, LUIBank.bankCost);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1,
};

--This function returns the correct variable for the bag type.
local function LUIBags_Select(bag)
	if bag == "Bank" and LUIBank then return LUIBank end
	if bag == "Bags" and LUIBags then return LUIBags end
end

local function CheckSortButton()
	if db.hideSort then
		if LUIBank then LUIBank.sortButton:Hide() end
		if LUIBags then LUIBags.sortButton:Hide() end
	else
		if LUIBank then LUIBank.sortButton:Show() end
		if LUIBags then LUIBags.sortButton:Show() end
	end
end

local function LUIBags_OnShow()
	module:PLAYERBANKSLOTS_CHANGED(nil, 29)	-- XXX: hack to force bag frame update
	module:ReloadLayout("Bags")
	module:SearchReset()

	module:RegisterEvent("BAG_UPDATE_DELAYED")
	module:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	module:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	module:RegisterEvent("BAG_CLOSED")
	module:RegisterEvent("ITEM_LOCK_CHANGED")
	module:RegisterEvent("QUEST_ACCEPTED")
	module:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	CheckSortButton()
end

local function LUIBank_OnHide()
	CloseBankFrame()
end
local function LUIBank_OnShow()
	module:PLAYERBANKSLOTS_CHANGED(nil, 29)
	CheckSortButton()
end

local function LUIBags_OnHide()  -- Close the Bank if Bags are closed.
	if LUIBank and LUIBank:IsShown() then
		LUIBank:Hide()
	end

	module:UnregisterEvent("BAG_UPDATE_DELAYED")
	module:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	module:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
	module:UnregisterEvent("BAG_CLOSED")
	module:UnregisterEvent("ITEM_LOCK_CHANGED")
	module:UnregisterEvent("QUEST_ACCEPTED")
	module:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
end

local function LUIBags_Open()
	LUIBags:Show()
end

local function LUIBags_Close()
	LUIBags:Hide()
end

local function LUIBags_Toggle(forceOpen)
	if LUIBags:IsShown() and not forceOpen then
		LUIBags:Hide()
		--LUI:Print("Closing Bags")
	else
		LUIBags:Show()
		--LUI:Print("OPening Bags")
	end
end

local function LUIBags_ToggleBag(id)
	if id == -2 then
		ToggleBag(-2)
		return
	end
	LUIBags_Toggle()
end

local function LUIBags_StartMoving(self)
	if not db.Lock then
		self:StartMoving()
	end
end

local function LUIBags_StopMoving(self)
		self:StopMovingOrSizing()
		self:SetUserPlaced(true)

		local x, y = self:GetCenter()

		-- Get rid of the "LUI" in the frame name, leaving Bags or Bank
		local bag = strsub(self:GetName(), 4)
		db[bag].CoordX = x
		db[bag].CoordY = y
	end

function module:InitSelect(bag)
	if bag == "Bank" and not LUIBank then module:InitBank() end
	if bag == "Bags" and not LUIBags then module:InitBags() end
end

function module:SlotUpdate(item)
	local itemInfo = C_Container.GetContainerItemInfo(item.bag, item.slot)
    local texture = itemInfo and itemInfo.iconFileID
    local itemCount = itemInfo and itemInfo.stackCount
    local quality = itemInfo and itemInfo.quality
    local clink = itemInfo and itemInfo.hyperlink
	local color = db.Colors.Border

	if not item.frame.lock then
		item.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)

		--Check for Profession Bag
		local bagType = module:BagType(item.bag)
		if (bagType == ST_SPECIAL) then
			local color = db.Colors.Professions
			item.frame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
		end

	end

	if item.Cooldown then
		local startTime, duration, enable = C_Container.GetContainerItemCooldown(item.bag, item.slot)
		CooldownFrame_Set(item.Cooldown, startTime, duration, enable)
	end

	-- New item code from Blizzard's ContainerFrame.lua
	local newItemTexture = item.frame.NewItemTexture
	local battlePayTexture = item.frame.BattlepayItemTexture
	local flashAnim = item.frame.flashAnim
	local newItemAnim = item.frame.newitemglowAnim
	if newItemTexture then
		if db.Bags.ShowNew and C_NewItems.IsNewItem(item.bag, item.slot) then
			if quality and NEW_ITEM_ATLAS_BY_QUALITY[quality] then
				newItemTexture:SetAtlas(NEW_ITEM_ATLAS_BY_QUALITY[quality])
			else
				newItemTexture:SetAtlas("bags-glow-white")
			end
			newItemTexture:Show()
			battlePayTexture:Hide()

			if not flashAnim:IsPlaying() and not newItemAnim:IsPlaying() then
				flashAnim:Play()
				newItemAnim:Play()
			end
		else
			newItemTexture:Hide()
			battlePayTexture:Hide()
			if flashAnim:IsPlaying() or newItemAnim:IsPlaying() then
				flashAnim:Stop()
				newItemAnim:Stop()
			end
		end
		--Make sure that the textures are the same size as the itemframe.
		battlePayTexture:SetSize(item.frame:GetSize())
		newItemTexture:SetSize(item.frame:GetSize())
	end

	if (clink) then
		local name, _, itemQuality, _, _, iType, _, _, _, _, _, classID = GetItemInfo(clink)
		item.name, item.itemQuality = name, itemQuality
		-- color slot according to item quality
		if db.Bags.Rarity and not item.frame.lock and itemQuality > 1 then
			local r, g, b, hex = GetItemQualityColor(itemQuality)
			item.frame:SetBackdropBorderColor(r, g, b)
		-- color slot according to quest item.
		elseif db.Bags.ShowQuest and not item.frame.lock and classID == 12 then
			item.frame:SetBackdropBorderColor(1,1,0)
		end
	else
		item.name, item.itemQuality = nil, nil
	end

	SetItemButtonTexture(item.frame, texture)
	SetItemButtonCount(item.frame, itemCount)
	SetItemButtonDesaturated(item.frame, locked, 0.5, 0.5, 0.5)
	if db.Bags.ShowOverlay and clink then
		--_G.SetItemButtonOverlay(item.frame, clink, quality, isBound)
	else
		item.frame.IconOverlay:Hide()
		if item.frame.IconOverlay2 then
			item.frame.IconOverlay2:Hide()
		end
	end

	item.frame:Show()
end

function module:BagSlotUpdate(bag)
	if not ItemSlots then
		return
	end

	if bag then
		for _, item in ipairs(ItemSlots) do
			if item.bag == bag then
				module:SlotUpdate(item)
			end
		end
		if (bag >= 0 and bag <= 4) then
			if LUIBags and LUIBags:IsShown() then
				module:ReloadLayout("Bags")
			end
		end
	else
		if LUIBags and LUIBags:IsShown() then
			module:ReloadLayout("Bags")
		end
		if LUIBank and LUIBank:IsShown() then
			module:ReloadLayout("Bank")
		end
	end
end

function module:BagFrameSlotNew(slot, parent, bagType)
	--Check if the slot doesnt already exist
	for _, v in ipairs(BagsSlots) do
		if v.slot == slot then
			--found the slot, return in.
			return v, false
		end
	end

	--Make a new slot.
	local ret = {}

	if bagType == "Bank" then
		ret.slot = slot
		slot = slot - 4
		ret.frame = CreateFrame("CheckButton", "LUIBank__Bag"..slot, parent, "BankItemButtonBagTemplate")
		ret.frame:SetID(slot)
		tinsert(BagsSlots, ret)

		BankFrameItemButton_Update(ret.frame)
		BankFrameItemButton_UpdateLocked(ret.frame)

		if not ret.frame.tooltipText then
			ret.frame.tooltipText = ""
		end
	else
		ret.frame = CreateFrame("checkButton", "LUIBags__Bag"..slot.."Slot", parent, "BagSlotButtonTemplate")
		ret.slot = slot
		tinsert(BagsSlots, ret)
	end

	--Fix the size of the bag buttons
	local bagBigTexSize = bagTexSize * 1.65 -- Number found through trial and error. This give the best results.
	ret.frame:SetSize(bagTexSize, bagTexSize)
	_G[ret.frame:GetName() .. "NormalTexture"]:SetSize(bagBigTexSize,bagBigTexSize)
	_G[ret.frame:GetName() .. "IconTexture"]:SetSize(bagBigTexSize,bagBigTexSize)

	return ret
end

function module:SlotNew(bag, slot)
	for _, v in ipairs(ItemSlots) do
		if v.bag == bag and v.slot == slot then
			return v, false
		end
	end

	local template = "ContainerFrameItemButtonTemplate"

	if bag == -1 then
		template = "BankItemButtonGenericTemplate"
	end

	local ret = {}

	if #trashButton > 0 then
		local f = -1
		for i, v in ipairs(trashButton) do
			local b, s = v:GetName():match("(%d+)_(%d+)")

			b = tonumber(b)
			s = tonumber(s)

			--print (b .. " " .. s)
			if b == bag and s == slot then
				f = i
				break
			end
		end

		if f ~= -1 then
			--print("found it")
			ret.frame = trashButton[f]
			table.remove(trashButton, f)
		end
	end

	if not ret.frame then
		ret.frame = CreateFrame("checkButton", "LUIBags_Item" .. bag .. "_" .. slot, BagsInfo[bag], template)
			-- Mixin(ret.frame, BackdropTemplateMixin)
		if not ret.frame.SetBackdrop then Mixin(ret.frame, BackdropTemplateMixin) end
	end

	ret.bag = bag
	ret.slot = slot
	ret.frame:SetID(slot)

	ret.Cooldown = _G[ret.frame:GetName() .. "Cooldown"]
	ret.Cooldown:Show()

	self:SlotUpdate(ret)

	return ret, true
end

function module:BagType(bag)
	local bagType = select(2, C_Container.GetContainerNumFreeSlots(bag))
	if bagType and bagType > 0 then
		return ST_SPECIAL
	end

	return ST_NORMAL
end

function module:BagNew(bag, frame)
	for _, v in pairs(BagsInfo) do
		if v:GetID() == bag then
			v.bagType = module:BagType(bag)
			return v
		end
	end

	local ret

	if #trashBag > 0 then
		local f = -1
		for i, v in pairs(trashBag) do
			if v:GetID() == bag then
				frame = i
				break
			end
		end

		if frame ~= -1 then
			--LUI:Print("found bag " .. bag)
			if type(frame) ~= "number" then frame = 1 end -- sometimes, frame ends up being a table instead of a number.
			ret = trashBag[frame]
			tremove(trashBag, frame)
			ret:Show()
			ret.bagType = module:BagType(bag)
			return ret
		end
	end

	--LUI:Print("new bag " .. bag)
	ret = CreateFrame("Frame", "LUIBag" .. bag, frame)
	ret.bagType = module:BagType(bag)

	ret:SetID(bag)
	return ret
end

function module:SearchUpdate(str)
	str = strlower(str)

	for _, b in ipairs(ItemSlots) do
		if b.frame and not b.name then
			b.frame:SetAlpha(.2)
		end
		if b.name then
			if not strfind(strlower(b.name), str) then
				SetItemButtonDesaturated(b.frame, true, 1, 1, 1)
				b.frame:SetAlpha(.2)
			else
				SetItemButtonDesaturated(b.frame, false, 1, 1, 1)
				b.frame:SetAlpha(1)
			end
		end
	end
end

function module:SearchReset()
	for _, item in ipairs(ItemSlots) do
		item.frame:SetAlpha(1)
		SetItemButtonDesaturated(item.frame, false, 1, 1, 1)
	end
end

function module:CreateBagFrame(bagType)
	local frameName = "LUI"..bagType -- LUIBags, LUIBank
	local frame = CreateFrame("Frame", frameName, UIParent)
	frame:EnableMouse(1)
	frame:SetMovable(1)
	frame:SetToplevel(1)
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(20)

	if db[bagType] and db[bagType].Locked == 0 then
		frame:SetScript("OnMouseDown", LUIBags_StartMoving)
		frame:SetScript("OnMouseUp", LUIBags_StopMoving)
	end

	local x = db[bagType] and db[bagType].CoordX or 0
	local y = db[bagType] and db[bagType].CoordY or 0
	frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

	--Close Button, no embed options anymore.
	local closeBtn = CreateFrame("Button", frameName.."_CloseButton", frame, "UIPanelCloseButton")
	closeBtn:SetWidth(LUI:Scale(32))
	closeBtn:SetHeight(LUI:Scale(32))
	closeBtn:SetPoint("TOPRIGHT", LUI:Scale(-3), LUI:Scale(-3))
	closeBtn:SetScript("OnClick", function(self, button)
		self:GetParent():Hide()
	end)
	closeBtn:RegisterForClicks("AnyUp")
	closeBtn:GetNormalTexture():SetDesaturated(1)
	frame.closeButton = closeBtn
	
	-- Bag Frame
	local bagsFrame = CreateFrame("Frame", frameName.."_BagsFrame", frame, "BackdropTemplate")
	bagsFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, LUI:Scale(2))
	bagsFrame:SetFrameStrata("HIGH")
	frame.BagsFrame = bagsFrame


	-- Sort Button
	local sortBtn = CreateFrame("Button", frameName.."_SortButton", frame, "UIPanelButtonTemplate")
	sortBtn:SetText("Stack & Sort");
	sortBtn:SetWidth(LUI:Scale(sortBtn:GetTextWidth()+20))
	sortBtn:SetHeight(LUI:Scale(sortBtn:GetTextHeight()+10))
	sortBtn:SetPoint("BOTTOMRIGHT", LUI:Scale(-3), LUI:Scale(3))
	sortBtn:SetScript("OnClick", function(self, button)
		--PlaySound("UI_BagSorting_01");
		PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
		-- Make sure we arent calling bag updates a million times
		module:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
		module:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
		module:PrepareSort(self:GetParent())
		module:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
		module:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	end)
	sortBtn:RegisterForClicks("AnyUp")
	frame.sortButton = sortBtn
	CheckSortButton()

	return frame
end

function module:InitBank()
	if LUIBank then
		return
	end

	LUIBank = self:CreateBagFrame("Bank")
	LUIBank:SetScript("OnShow", LUIBank_OnShow)
	LUIBank:SetScript("OnHide", LUIBank_OnHide)
end

local GetParent_StartMoving = function(self)
	LUIBags_StartMoving(self:GetParent())
end

local GetParent_StopMoving = function(self)
	LUIBags_StopMoving(self:GetParent())
end

function module:SetBags()
	if LUIBags then return end -- Bags are already setup.

	LUIBags = module:CreateBagFrame("Bags")
	LUIBags:SetScript("OnShow", LUIBags_OnShow)
	LUIBags:SetScript("OnHide", LUIBags_OnHide)

	-- Search Editbox
	local editbox = CreateFrame("EditBox", nil, LUIBags, "BackdropTemplate")
	editbox:Hide()
	editbox:SetAutoFocus(true)
	editbox:SetHeight(LUI:Scale(32))
	editbox:SetBackdrop( {
		bgFile = LUI.Media.blank,
		edgeFile = LUI.Media.blank,
		tile = false, edgeSize = 0,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	editbox:SetBackdropColor(0,0,0,0)
	editbox:SetBackdropBorderColor(0,0,0,0)

	local resetAndClear = function (self)
		self:GetParent().search:Show()
		self:GetParent().gold:Show()
		self:ClearFocus()
		module:SearchReset()
	end

	local updateSearch = function(self, text)
		if text == true then
			module:SearchUpdate(self:GetText())
		end
	end

	editbox:SetScript("OnEscapePressed", resetAndClear)
	editbox:SetScript("OnEnterPressed", resetAndClear)
	editbox:SetScript("OnEditFocusLost", editbox.Hide)
	editbox:SetScript("OnEditFocusGained", editbox.HighlightText)
	editbox:SetScript("OnTextChanged", updateSearch)
	editbox:SetText("Search")

	--Search text
	local search = LUIBags:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	search:SetPoint("TOPLEFT", LUIBags, LUI:Scale(db.Bags.Padding), LUI:Scale(-10))
	search:SetPoint("RIGHT", LUI:Scale(-(16 + 24)), 0)
	search:SetJustifyH("LEFT")
	search:SetText("|cff9999ff" .. "Search")
	editbox:SetAllPoints(search)

	--Gold Display, next to close button
	local gold = LUIBags:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gold:SetJustifyH("RIGHT")
	gold:SetPoint("RIGHT", LUIBags.closeButton, "LEFT", LUI:Scale(-3), 0)

	LUIBags:SetScript("OnEvent", function(self, e) -- wtf is E? Found it: Elapsed time since last call
		self.gold:SetText(GetMoneyString(GetMoney(), 12))
	end)

	LUIBags:RegisterEvent("PLAYER_MONEY")
	LUIBags:RegisterEvent("PLAYER_LOGIN")
	LUIBags:RegisterEvent("PLAYER_TRADE_MONEY")
	LUIBags:RegisterEvent("TRADE_MONEY_CHANGED")

	local OpenEditbox = function(self)
		self:GetParent().search:Hide()
		self:GetParent().gold:Hide()
		self:GetParent().editbox:Show()
		self:GetParent().editbox:HighlightText()
	end

	local button = CreateFrame("checkButton", nil, LUIBags)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetAllPoints(search)
	button:SetScript("OnClick", function(self, btn)
		if btn == "RightButton" then
			OpenEditbox(self)
		else
			if self:GetParent().editbox:IsShown() then
				self:GetParent().editbox:Hide()
				self:GetParent().editbox:ClearFocus()
				-- self:GetParent().detail:Show()
				self:GetParent().gold:Show()
				self:GetParent().search:Show()
				module:SearchReset()
			end
		end
	end)

	local tooltip_hide = function()
		GameTooltip:Hide()
	end

	local tooltip_show = function (self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:ClearLines()
		GameTooltip:SetText("Right-click to search.")
	end

	button:SetScript("OnEnter", tooltip_show)
	button:SetScript("OnLeave", tooltip_hide)

	button:SetScript("OnMouseDown", GetParent_StartMoving)
	button:SetScript("OnMouseUp", GetParent_StopMoving)

	LUIBags.editbox = editbox
	LUIBags.search = search
	LUIBags.button = button
	LUIBags.gold = gold
	LUIBags:Hide()
end

function module:Layout(bagType)
	local frame = LUIBags_Select(bagType)
	local cols = db[bagType].Cols
	local bagId = GetBags[bagType]

	local slots = 0
	local rows = 0
	local off = 28

	local padding = db[bagType].Padding
	local spacing = db[bagType].Spacing
	local borderTex = Media:Fetch("border", db[bagType].BorderTexture)
	local border_size = db[bagType].BorderSize
	local border_inset = db[bagType].BorderInset

	local color, bgcolor = db.Colors.Border, db.Colors.Background
	local border_color = { color.r, color.g, color.b, color.a }
	local background_color = { bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a }

	if not frame then
		module:InitSelect(bagType)
		frame = LUIBags_Select(bagType)
	end

	local isBank = false
	if bagType == "Bank" then
		isBank = true
	else
		frame.gold:SetText(GetMoneyString(GetMoney(), 12)) 
		frame.editbox:SetFont(Media:Fetch("font", db.Bags.Font), 12, "")
		frame.search:SetFont(Media:Fetch("font", db.Bags.Font), 12, "")
		frame.gold:SetFont(Media:Fetch("font", db.Bags.Font), 12, "")

		frame.search:ClearAllPoints()
		frame.search:SetPoint("TOPLEFT", frame, LUI:Scale(db.Bags.Padding), LUI:Scale(-1))
		frame.search:SetPoint("RIGHT", LUI:Scale(-(16 + 24)), 0)
	end

	local bagsFrame = frame.BagsFrame
	if not isCreated[bagType] then
		frame:SetClampedToScreen(1)
		Mixin(frame, BackdropTemplateMixin)
		frame:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = borderTex,
			tile = false, edgeSize = 5,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		local fColor = { color.r *1.5, color.g *1.5, color.b *1.5, color.a}
		local fbgColor = { bgcolor.r /2, bgcolor.g /2, bgcolor.b /2, bgcolor.a}
		if db.Colors.BlackFrameBG then
			frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
			frame:SetBackdropBorderColor(0.3, 0.3 ,0.3 ,1)
		else
			frame:SetBackdropColor(unpack(fbgColor))
			frame:SetBackdropBorderColor(unpack(fColor))
		end
		-- bag frame stuff

		bagsFrame:SetClampedToScreen(1)
		bagsFrame:SetBackdrop( {
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",                                             
			edgeFile = borderTex,
			tile = false, edgeSize = 5,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		bagsFrame:SetBackdropColor(unpack(background_color))
		bagsFrame:SetBackdropBorderColor(unpack(border_color))

		local width = 2*padding + (#bagId - 1)*bagTexSize + spacing*(#bagId - 2)

		bagsFrame:SetHeight(LUI:Scale(2 * padding + bagTexSize))
		bagsFrame:SetWidth(LUI:Scale(width))

		local idx = 0
		for x, id in ipairs(bagId) do
			if (not isBank and id <= 3 ) or (isBank and id ~= -1) then
				local b = module:BagFrameSlotNew(id, bagsFrame, bagType)

				local Xoffset = padding + idx*bagTexSize + idx*spacing

				local BankSlots, Full = GetNumBankSlots()
				local cost = GetBankSlotCost(BankSlots);

				if isBank and not Full then

					--Most recently bought bag.
					if x == GetNumBankSlots() + 1 then

						--Set Things back up to normal after a purchase.
						b.frame:SetAlpha(1)
						SetItemButtonTexture(b.frame,"Interface\\paperdoll\\UI-PaperDoll-Slot-Bag")

						b.frame:SetScript("OnClick", function(self)
							if ( IsModifiedClick("PICKUPACTION") ) then
								BankFrameItemButtonBag_Pickup(self);
							else
								BankFrameItemButtonBag_OnClick(self, button);
							end
						end)

						--Bag about to be purcahsed.
					elseif x == GetNumBankSlots() + 2 then

						b.frame:SetAlpha(1)
						SetItemButtonTexture(b.frame,GetCoinIcon(cost))

						-- Add the Click-To-Purchase option.
						b.frame:SetScript("OnClick", function(self)
							LUIBank.bankCost = cost
							StaticPopup_Show("CONFIRM_BUY_BANK_SLOT");
						end)

						--Unpurchased Bags.
					elseif x > GetNumBankSlots() + 2 then
						b.frame:SetAlpha(.2)
					end
				end
				if isBank and Full and LUIBank.bankCost then
					LUIBank.bankCost = nil
				end

				b.frame:ClearAllPoints()
				b.frame:SetPoint("LEFT", bagsFrame, "LEFT", LUI:Scale(Xoffset), 0)
				b.frame:Show()

				idx = idx + 1
			end
		end

		for _, id in ipairs(bagId) do
			local bagCount = C_Container.GetContainerNumSlots(id)
			if bagCount > 0 then
				if not BagsInfo[id] then
					BagsInfo[id] = module:BagNew(id, frame)
				end

				slots = slots + C_Container.GetContainerNumSlots(id)
			end
		end

		rows = floor(slots / cols)
		if (slots % cols) ~= 0 then
			rows = rows + 1
		end

		frame:SetWidth(LUI:Scale(cols * 34 + 4 + (cols - 1) * spacing + padding * 2))
		frame:SetHeight(LUI:Scale(rows * 34 + (rows - 1) * spacing + off + padding * 2) + frame.sortButton:GetHeight());

	end

	if db[bagType].BagFrame then
		bagsFrame:Show()
	else
		bagsFrame:Hide()
	end
	local idx = 0
	for _, id in ipairs(bagId) do
		local bagCount = C_Container.GetContainerNumSlots(id)

		if bagCount > 0 then
			BagsInfo[id] = module:BagNew(id, frame)
			local idBagType = BagsInfo[id].bagType

			BagsInfo[id]:Show()

			for i = 1, bagCount do
				local item, isnew = module:SlotNew(id, i)

				if isnew then
					tinsert(ItemSlots, idx + 1, item)
				end

				if not isCreated[bagType] then
					local xoff
					local yoff
					local x = (idx % cols)
					local y = floor(idx / cols)

					xoff = padding + (x * 34) + (x * spacing) + 4
					yoff = off + padding + (y * 34) + ((y - 1) * spacing) + 7
					yoff = yoff * -1

					item.frame:ClearAllPoints()
					item.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", LUI:Scale(xoff), LUI:Scale(yoff))
					item.frame:SetHeight(LUI:Scale(34))
					item.frame:SetWidth(LUI:Scale(34))
					item.frame:SetPushedTexture("")
					item.frame:SetNormalTexture("")
					item.frame:Show()

					item.frame:SetBackdrop( {
						bgFile = "Interface/Tooltips/UI-Tooltip-Background",
						edgeFile = borderTex,
						tile = false, tileSize = 0, edgeSize = 15,
						insets = { left = 5, right = 5, top = 5, bottom = 5 }
					})

					item.frame:SetBackdropColor(unpack(background_color))
					item.frame:SetBackdropBorderColor(unpack(border_color))

				end

				LUI:StyleButton(item.frame)
				module:SlotUpdate(item)

				local iconTex = _G[item.frame:GetName() .. "IconTexture"]
				iconTex:SetTexCoord(.08, .92, .08, .92)
				iconTex:SetPoint("TOPLEFT", item.frame, LUI:Scale(3), LUI:Scale(-3))
				iconTex:SetPoint("BOTTOMRIGHT", item.frame, LUI:Scale(-3), LUI:Scale(3))

				iconTex:Show()
				item.iconTex = iconTex

				idx = idx + 1
			end

		end

	end

	--adjust the size of the frames now.
	frame:SetScale(db[bagType].Scale)
	bagsFrame:SetScale(db[bagType].BagScale)

	isCreated[bagType] = true
end

function module:EnableBags()
	if db.Enable ~= true then return end
	-- 		hooking and setting key ring bag
	-- this is just a reskin of Blizzard key bag to fit LUI
	-- hooking OnShow because sometime key max slot changes.
	if not module:IsHooked(ContainerFrame1, "OnShow") then
		module:HookScript(ContainerFrame1, "OnShow", function(self)
			ContainerFrame1:SetScript("OnMouseDown", LUIBags_StartMoving)
			ContainerFrame1:SetScript("OnMouseUp", LUIBags_StopMoving)

			local keybackdrop = CreateFrame("Frame", keybackdropframe, ContainerFrame1, "ContainerFrameItemButtonTemplate" and "BackdropTemplate")
			keybackdrop:SetPoint("TOPLEFT", LUI:Scale(0), LUI:Scale(-0))
			keybackdrop:SetPoint("BOTTOMLEFT", 0, 0)
			keybackdrop:SetSize(LUI:Scale(300),LUI:Scale(190))
			keybackdrop:SetBackdrop( {
				bgFile = Media:Fetch("background", LUI.Media.empty),
				edgeFile = Media:Fetch("border", LUI.Media.empty),
				tile = false, edgeSize = 0,
				insets = { left = 0, right = 0, top = 0, bottom = 0 }
			})
			keybackdrop:SetBackdropColor(0,0,0,0)
			keybackdrop:SetBackdropBorderColor(0,0,0,0)

			ContainerFrame1CloseButton:Hide()
			ContainerFrame1Portrait:Hide()
			ContainerFrame1Name:Hide()
			ContainerFrame1BackgroundTop:SetAlpha(0)
			ContainerFrame1BackgroundMiddle1:SetAlpha(0)
			ContainerFrame1BackgroundMiddle2:SetAlpha(0)
			ContainerFrame1BackgroundBottom:SetAlpha(0)

			local bgColor, color = db.Colors.Background, db.Colors.Border -- Shorter vars for colors.
			for i=1, GetKeyRingSize() do
				local slot = _G["ContainerFrame1Item"..i]
				local t = _G["ContainerFrame1Item"..i.."IconTexture"]
				slot:SetPushedTexture("")
				slot:SetNormalTexture("")
				t:SetTexCoord(.08, .92, .08, .92)
				t:SetPoint("TOPLEFT", slot, LUI:Scale(2), LUI:Scale(-2))
				t:SetPoint("BOTTOMRIGHT", slot, LUI:Scale(-2), LUI:Scale(2))
					Mixin(slot, BackdropTemplateMixin)
				slot:SetBackdrop( {
					bgFile = Media:Fetch("background", db.Bags.BackgroundTexture),
					edgeFile = Media:Fetch("border", db.Bags.BorderTexture),
					tile = false, edgeSize = 15,
					insets = { left = 0, right = -0, top = -0, bottom = 0 }
				})
				slot:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
				slot:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
				LUI:StyleButton(slot, false)
			end

			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, "CENTER", LUI:Scale(4), LUI:Scale(5))
		end)
	end
end

function module:QUEST_ACCEPTED(event)
	module:ReloadLayout("Bags")
	module:ReloadLayout("Bank")
end

function module:UNIT_QUEST_LOG_CHANGED(event, unit)
	if unit == "player" then
		module:ReloadLayout("Bags")
		module:ReloadLayout("Bank")
	end
end

function module:PLAYERBANKBAGSLOTS_CHANGED(event, id)
	module:ReloadLayout("Bank")
end


function module:PLAYERBANKSLOTS_CHANGED(event, id)
	if id > 28 then
		for _, v in ipairs(BagsSlots) do
			if v.frame and v.frame.GetInventorySlot then
				if v.slot < GetNumBankSlots() + 5 then
					BankFrameItemButton_Update(v.frame)
					BankFrameItemButton_UpdateLocked(v.frame)
				end
				if not v.frame.tooltipText then
					v.frame.tooltipText = ""
				end
			end
		end
	end

	if LUIBank and LUIBank:IsShown() then
		for _, id in ipairs(GetBags["Bank"]) do
			module:BagSlotUpdate(id)
		end
	end
end

function module:BAG_UPDATE_DELAYED(event,id)
	module:BagSlotUpdate(id)
end

function module:ITEM_LOCK_CHANGED(event, bag, slot)
	if slot == nil then
		return
	end

	for _, v in ipairs(ItemSlots) do
		if v.bag == bag and v.slot == slot then
			module:SlotUpdate(v)
			break
		end
	end
end

function module:BANKFRAME_OPENED()
	if not LUIBank then
		module:InitBank()
	end

	module:Layout("Bank")
	for _, x in ipairs(GetBags["Bank"]) do
		module:BagSlotUpdate(x)
	end
	LUIBags_Open()
	LUIBank:Show()
	LUIBank:SetAlpha(1)
end

function module:BANKFRAME_CLOSED()
	if not LUIBank then
		return
	end

	LUIBank:Hide()
end

function module:BAG_CLOSED(event, id)
	local bagId = BagsInfo[id]
	if bagId then
		tremove(BagsInfo, id)
		bagId:Hide()
		tinsert(trashBag, #trashBag + 1, bagId)
	end

	while true do
		local changed = false

		for i, v in ipairs(ItemSlots) do
			if v.bag == id then
				v.frame:Hide()
				v.iconTex:Hide()

				tinsert(trashButton, #trashButton + 1, v.frame)
				tremove(ItemSlots, i)
				v = nil
				changed = true
			end
		end

		if not changed then
			break
		end
	end

	--Hack to get a ReloadLayout on next re-open.
	isCreated["Bags"] = false
	isCreated["Bank"] = false
end

--Copy bags options over.
function module:CopyBags()
	--Iterate through all bag types.
	for bag, _ in pairs(GetBags) do

		--Check for bag types that needs to be copied.
		if bag ~= "Bags" and db[bag].CopyBags then

			for option, value in pairs(db.Bags) do
				if db[bag][option] ~= value and option ~= "Cols" then
					db[bag][option] = value
				end
			end

			-- Force re-creation of bag frames.
			module:ReloadLayout(bag)
		end
	end
end

--Used to see if any bags have the function enabled.
function module:CheckBagsCopy()
	for bag, _ in pairs(GetBags) do
		if bag ~= "Bags" then
			if db[bag].CopyBags then
				db.CopyBags = true
				return
			end
		end
	end
	db.CopyBags = false
end

function module:ReloadLayout(bag)
	isCreated[bag] = false
	local frame = LUIBags_Select(bag)
	if frame and frame:IsShown() then
		module:Layout(bag)
	end
end

-- Note: Do not make new tables inside the Bags and Bank Options.
--       It would break the CopyBags function that dynamically copy things.
module.defaults = {
	profile = {
		Enable = true,
		CopyBags = true,
		Lock = false,
		hideSort = false,
		--Start of Bags Options
		Bags = {
			Font = "AvantGarde_LT_Medium",
			FontSize = 12,
			Cols = 12,
			Padding = 7,
			Spacing = 7,
			Scale = 1,
			BagScale = 1,
			BagFrame = true,
			Rarity = true,
			ShowNew = false,
			ShowQuest = true,
			ShowOverlay = true,
			Locked = 0,
			CoordX = 0,
			CoordY = 0,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			BorderInset = -1,
		},
		--End of Bags Options
		--Start of Bank Options
		Bank = {
			CopyBags = true,
			Cols = 14,
			Padding = 8,
			Spacing = 3,
			Scale = 1,
			BagScale = 1,
			BagFrame = true,
			ItemQuality = false,
			ShowQuest = true,
			Locked = 0,
			CoordX = 0,
			CoordY = 0,
			BackgroundTexture = "Blizzard Tooltip",
			BorderTexture = "Stripped_medium",
			BorderSize = 5,
			BorderInset = -1,
		},
		-- End of Bank Options
		-- Start of Keyring Options
		-- Keyring = {
		-- 	-- CopyBags = true,
		-- 	Cols = 14,
		-- 	Padding = 8,
		-- 	Spacing = 3,
		-- 	Scale = 1,
		-- 	BagScale = 1,
		-- 	BagFrame = true,
		-- 	ItemQuality = false,
		-- 	Locked = 0,
		-- 	CoordX = 0,
		-- 	CoordY = 0,
		-- 	BackgroundTexture = "Blizzard Tooltip",
		-- 	BorderTexture = "Stripped_medium",
		-- 	BorderSize = 5,
		-- 	BorderInset = -1,
		-- },
		--End of Keyring Options
		Colors = {
			BlackFrameBG = false,
			Border = {
				r = 0.2,
				g = 0.2,
				b = 0.2,
				a = 1,
			},
			Background = {
				r = 0.18,
				g = 0.18,
				b = 0.18,
				a = 0.8,
			},
			Professions = {
				r = 0.1,
				g = 0.5,
				b = 0.1,
				a = 1,
			},
		},
		--End of Colors Options
		Fonts = {
			General = {
				Font = "AvantGarde_LT_Medium",
				FontSize = 12,
				FontFlag = "OUTLINE",
				FontColor = {
					r = 1,
					g = 1,
					b = 1,
					a = 1,
				},
			},
		},
	},
}

function module:LoadOptions()
	local function BagOpt()
		module:ReloadLayout("Bags")
		if db.CopyBags then module:CopyBags() end
	end
	local function BankOpt()
		module:ReloadLayout("Bank")
	end
	local function DisabledCopy()
		return db.Bank.CopyBags
	end
	local function ReloadBoth()
		module:ReloadLayout("Bags")
		module:ReloadLayout("Bank")
	end

	local options = {
		Bags = {
			name = "Bags",
			type = "group",
			order = 3,
			args = {
				Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.",
					2, db.Bags, "Cols", dbd.Bags, 4, 32, 1, BagOpt),
				Lock = LUI:NewToggle("Lock Frames", "Lock the Bags and Bank frames in place", 3, db, "Lock", dbd,nil,"normal"),
				hideSort = LUI:NewToggle("Hide Sort Button", "Hide the Stack & Sort button from the bags window", 4, db, "hideSort", dbd, CheckSortButton, "normal"),
				Header = LUI:NewHeader("", 5),
				Padding = LUI:NewSlider("Bag Padding", "This sets the space between the background border and the adjacent items.",
					6, db.Bags, "Padding", dbd.Bags, 4, 24, 1, BagOpt),
				Spacing = LUI:NewSlider("Bag Spacing", "This sets the distance between items.",
					7, db.Bags, "Spacing", dbd.Bags, 1, 15, 1, BagOpt),
				Scale = LUI:NewScale("Bags Frame",8, db.Bags, "Scale", dbd.Bags, BagOpt),
				BagScale = LUI:NewScale("Bag Bar",9, db.Bags, "BagScale", dbd.Bags, BagOpt),
				BagFrame = LUI:NewToggle("Show Bag Bar", nil, 10, db.Bags, "BagFrame", dbd.Bags, BagOpt),
				Rarity = LUI:NewToggle("Show Item Quality", nil, 11, db.Bags, "Rarity", dbd.Bags, ReloadBoth),
				ShowNew = LUI:NewToggle("Show New Item Animation", nil, 12, db.Bags, "ShowNew", dbd.Bags, ReloadBoth),
				ShowQuest = LUI:NewToggle("Show Quest Highlights", nil, 13, db.Bags, "ShowQuest", dbd.Bags, ReloadBoth),
				-- ShowOverlay = LUI:NewToggle("Show Overlays", nil, 14, db.Bags, "ShowOverlay", dbd.Bags, ReloadBoth),
			},
		},
		Bank = {
			name = "Bank",
			type = "group",
			order = 4,
			args = {
				CopyBags = LUI:NewToggle("Copy Bags", "Make the Bank frame copy the bags options.", 1, db.Bank, "CopyBags", dbd.Bank,
					function()
						module:CheckBagsCopy()
						if db.Bank.CopyBags then module:CopyBags() end
					end, "normal"),
				Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.", 2,
					db.Bank, "Cols", dbd.Bank, 4, 32, 1, BankOpt),
				Header = LUI:NewHeader("", 3),
				Padding = LUI:NewSlider("Bank Padding", "This sets the space between the background border and the adjacent items.", 4,
					db.Bank, "Padding", dbd.Bank, 4, 24, 1, BankOpt, nil, DisabledCopy),
				Spacing = LUI:NewSlider("Bank Spacing", "This sets the distance between items.", 5,
					db.Bank, "Spacing", dbd.Bank, 1, 15, 1, BankOpt, nil, DisabledCopy),
				Scale = LUI:NewScale("Bank Frame",6, db.Bank, "Scale", dbd.Bank, BankOpt, nil, DisabledCopy),
				BagScale = LUI:NewScale("Bank Bag Bar",7, db.Bank, "BagScale", dbd.Bank, BankOpt, nil, DisabledCopy),
				BagFrame = LUI:NewToggle("Show Bag Bar", nil, 8, db.Bank, "BagFrame", dbd.Bank, BankOpt, nil, DisabledCopy),
			},
		},
		-- Keyring = {
		-- 	name = "Keyring",
		-- 	type = "group",
		-- 	order = 5,
		-- 	args = {
		-- 		-- CopyBags = LUI:NewToggle("Copy Bags", "Make the Keyring frame copy the bags options.", 1, db.Keyring, "CopyBags", dbd.Keyring,
		-- 		-- 	function()
		-- 		-- 		module:CheckBagsCopy()
		-- 		-- 		if db.Keyring.CopyBags then module:CopyBags() end
		-- 		-- 	end, "normal"),
		-- 		Cols = LUI:NewSlider("Items Per Row", "Select how many items will be displayed per rows in your Bags.", 2,
		-- 			db.Keyring, "Cols", dbd.Keyring, 4, 32, 1, KeyringOpt),
		-- 		Header = LUI:NewHeader("", 3),
		-- 		KeyPadding = LUI:NewSlider("Keyring Padding", "This sets the space between the background border and the adjacent items.", 4,
		-- 			db.Keyring, "KeyPadding", dbd.Keyring, 4, 24, 1, KeyringOpt),
		-- 		KeySpacing = LUI:NewSlider("Keyring Spacing", "This sets the distance between items.", 5,
		-- 			db.Keyring, "KeySpacing", dbd.Keyring, 1, 15, 1, KeyringOpt, nil, DisabledCopy),
		-- 		Scale = LUI:NewScale("Keyring Frame",6, db.Keyring, "KeyScale", dbd.Keyring, KeyringOpt, nil, DisabledCopy),
		-- 	},
		-- },
		Colors = {
			name = "Colors",
			type = "group",
			order = 6,
			args = {
				Background = module:NewColor("Background", "Bags Background", 1, ReloadBoth),
				Border = module:NewColor("Border", "Bags Border", 2, ReloadBoth),
				Professions = module:NewColor("Profession", "Profession Bags Borders", 3, ReloadBoth),
				BlackFrameBG = module:NewToggle("Black Frame Background", "This will force the Bags' Frame background to always be black.", 5, ReloadBoth),
			},
		},
		--Reminder for where to had new categories
	}

	return options
end

function module:OnInitialize()
	db, dbd = LUI:NewNamespace(self, true)
end

function module:OnEnable()

	module:RegisterEvent("BANKFRAME_OPENED")
	module:RegisterEvent("BANKFRAME_CLOSED")

	-- Add LUIBags to the "Can be closed using ESC" table.
	tinsert(UISpecialFrames,"LUIBags")
	CloseAllBags()

	--Now changes the functions to ours
	self:RawHook("ToggleBackpack", LUIBags_Toggle, true)
	self:RawHook("OpenAllBags", LUIBags_Toggle, true)
	self:RawHook("ToggleAllBags", LUIBags_Toggle, true)
	self:RawHook("OpenBackpack", LUIBags_Open, true)
	self:RawHook("CloseBackpack", LUIBags_Close, true)
	self:RawHook("CloseAllBags", LUIBags_Close, true)

	BankFrame:UnregisterAllEvents()
	BankFrame:SetAlpha(0)

	module:SetBags()
	module:EnableBags()

end

function module:OnDisable()

	--Make the bankframe works again
	BankFrame:RegisterEvent("BANKFRAME_OPENED")
	BankFrame:RegisterEvent("BANKFRAME_CLOSED")

	CloseAllBags()

	--Makes the UI functions like they were
	self:Unhook("ToggleBackpack")
	self:Unhook("OpenAllBags")
	self:Unhook("ToggleAllBags")
	self:Unhook("OpenBackpack")
	self:Unhook("CloseBackpack")
	self:Unhook("CloseAllBags")

	module:Unhook(ContainerFrame1, "OnShow")

	ContainerFrame1CloseButton:Show()
	ContainerFrame1Portrait:Show()
	ContainerFrame1Name:Show()
	ContainerFrame1BackgroundTop:SetAlpha(1)
	ContainerFrame1BackgroundMiddle1:SetAlpha(1)
	ContainerFrame1BackgroundMiddle2:SetAlpha(1)
	ContainerFrame1BackgroundBottom:SetAlpha(1)
	BankFrame:SetAlpha(1)

end

function module:PrepareSort(frame)
	if frame ~= LUIBags and frame ~= LUIBank then
		return;
	end

	if frame:GetScript("OnUpdate") then
		return;
	end

	self.sortFrame = frame;

	self.sortBags = {};
	self.sortItems = {};

	local bagOrder = {}
	if self.sortFrame == LUIBags then
		bagOrder = GetBags["Bags"];
	elseif self.sortFrame == LUIBank then
		bagOrder = GetBags["Bank"];
	end

	local specialBags = {};

	for _, v in pairs(bagOrder) do
		local maxSlots = C_Container.GetContainerNumSlots(v);

		if maxSlots > 0 then
			local bagFamily = select(2, C_Container.GetContainerNumFreeSlots(v));

			if bagFamily > 0 then
				table.insert(specialBags, {bagId = v, slot = maxSlots, maxSlots = maxSlots, bagFamily = bagFamily});
			else
				table.insert(self.sortBags, {bagId = v, slot = maxSlots, maxSlots = maxSlots, bagFamily = bagFamily});
			end
		end
	end

	for _, v in pairs(specialBags) do
		table.insert(self.sortBags, v);
	end

	for _, bag in pairs(self.sortBags) do
		for j = 1, C_Container.GetContainerNumSlots(bag.bagId) do
			local itemId = C_Container.GetContainerItemID(bag.bagId, j);
			if itemId then
				local containerInfo  = C_Container.GetContainerItemInfo(bag.bagId, j);
				local count, locked = containerInfo.stackCount, containerInfo.isLocked
				if locked then
					return;
				end

				local name, _, itemQuality, itemLevel, requiredLevel, itemType, itemSubType, stackCount, equipLocation, _, sellPrice, classID = GetItemInfo(itemId);

				local sortString = itemQuality .. itemType .. itemSubType .. requiredLevel .. itemLevel .. name .. itemId .. classID;

				local itemFamily = GetItemFamily(itemId);

				table.insert(self.sortItems, {
					sortString = sortString,
					sBag = bag.bagId,
					sSlot = j,
					itemFamily = itemFamily,
					count = count,
					stackCount = stackCount
				});
			end
		end
	end

	table.sort(self.sortItems, function(a, b)
		if a.sortString == b.sortString then
			return a.count > b.count;
		end

		return a.sortString > b.sortString;
	end);

	-- Set targets
	for i, v in pairs(self.sortItems) do
		local bagIndex = #self.sortBags;

		-- Test for special bag
		local firstNormal = -1;
		while bit.band(v.itemFamily, self.sortBags[bagIndex].bagFamily) == 0 do
			if self.sortBags[bagIndex].bagFamily == 0 and firstNormal == -1 then
				firstNormal = bagIndex;
			end

			bagIndex = bagIndex - 1;

			if not self.sortBags[bagIndex] then
				bagIndex = firstNormal;

				break;
			end
		end

		local bag = self.sortBags[bagIndex];

		-- Stacking
		local targetchange = true;
		if i > 1 and self.sortItems[i - 1].sortString == v.sortString then
			if self.sortItems[i - 1].count < v.stackCount then
				local count = self.sortItems[i - 1].count + v.count;

				v.tBag = self.sortItems[i - 1].tBag;
				v.tSlot = self.sortItems[i - 1].tSlot;

				if count - v.stackCount > 0 then
					v.count = count - v.stackCount;

					v.tBag2 = bag.bagId;
					v.tSlot2 = bag.slot;
				else
					targetchange = false;
					v.count = count;
				end
			end
		end

		if not v.tBag then
			v.tBag = bag.bagId;
			v.tSlot = bag.slot;
		end

		if targetchange then
			bag.slot = bag.slot - 1;
		end

		if bag.slot < 1 then
			table.remove(self.sortBags, bagIndex);
		end
	end

	self.sortFrame:SetScript("OnUpdate", module.Sort);
end

function module:Sort(elapsed)
	if not module.sortTime or module.sortTime > 0.5 then
		module.sortTime = 0;
	else
		module.sortTime = module.sortTime + elapsed;
		return;
	end

	if module.sorting then
		return;
	end

	module.sorting = true;

	ClearCursor();

	local changes = 1;
	local key = 1;

	while module.sortItems[key] do
		local item = module.sortItems[key];

		if not select(3, C_Container.GetContainerItemInfo(item.sBag, item.sSlot)) and not select(3, C_Container.GetContainerItemInfo(item.tBag, item.tSlot)) then
			if item.sBag ~= item.tBag or item.sSlot ~= item.tSlot then
				PickupContainerItem(item.sBag, item.sSlot);
				PickupContainerItem(item.tBag, item.tSlot);

				for i = 1, #module.sortItems do
					if module.sortItems[i].sBag == item.tBag and module.sortItems[i].sSlot == item.tSlot then
						module.sortItems[i].sBag = item.sBag;
						module.sortItems[i].sSlot = item.sSlot;
					end
				end

				changes = changes + 1;
			end

			if item.tBag2 then
				item.tBag = item.tBag2;
				item.tSlot = item.tSlot2;

				item.tBag2 = nil;
				item.tSlot2 = nil;
			else
				table.remove(module.sortItems, key);
				key = key - 1;

				if changes > 0.5 then
					module.sorting = false;

					return;
				end
			end
		end


		key = key + 1;
	end

	if not module.sortItems[1] then
		module.sortFrame:SetScript("OnUpdate", nil);
		module.sortTime = nil;
		module.sorting = nil;
		module.sortItems = nil;
		module.sortBags = nil;
		module.sortFrame = nil;
	else
		module.sorting = false;
	end
end
