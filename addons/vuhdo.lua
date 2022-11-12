--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: VuhDo.lua
	Description: VuhDo Install Script
	Version....: 1.0
]]

local addonname, LUI = ...
local L = LUI.L

LUI.Versions.vuhdo = 3300

function LUI:InstallGrid()
	if not IsAddOnLoaded("VuhDO") then return end
	if LUICONFIG.Versions.vuhdo == LUI.Versions.vudho then return end
end
