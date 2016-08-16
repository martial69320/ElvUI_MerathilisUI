local E, L, V, P, G = unpack(ElvUI);
local MER = E:GetModule('MerathilisUI');
local S = E:GetModule('Skins');
local LSM = LibStub('LibSharedMedia-3.0');

-- Cache global variables
-- Lua functions
local pairs, tostring = pairs, tostring
local gmatch, tinsert = gmatch, table.insert
-- WoW API / Variables
local CreateFrame = CreateFrame
-- Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: UISpecialFrames, MerathilisUIChangeLog, PlaySound

local classColor = E.myclass == 'PRIEST' and E.PriestColors or (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass])
local flat = [[Interface\AddOns\ElvUI_MerathilisUI\media\textures\Flat]]

local ChangeLog = CreateFrame("frame")
local ChangeLogData = [=[|cffff7d0av2.12|r, xx.08.2016

|cffff7d0aChanges:|r
 |cffff7d0a•|r An extra frame will show up, if the GMOTD gets updated.
 |cffff7d0a•|r 
 
|cffff7d0aNotes:|r
 |cffff7d0a•|r The Heal Layout is not finished yet. Will work on it in the future.
 |cffff7d0a•|r The LocPanel can cause a lua error on profle switch. A reload fixes this. (WIP)
]=];

local frame = CreateFrame("Frame", "MerathilisUIChangeLog", E.UIParent)
frame:SetPoint("CENTER", UIParent, "BOTTOM", 0, 350)
frame:SetSize(450, 300)
frame:SetTemplate("Transparent")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
MER:CreateSoftShadow(frame)
frame:Hide()

local title = CreateFrame("Frame", nil, frame)
title:SetPoint("BOTTOM", frame, "TOP", 0, 3)
title:SetSize(450, 20)
title:SetTemplate("Transparent")
MER:CreateSoftShadow(title)

title.text = title:CreateFontString(nil, "OVERLAY")
title.text:SetPoint("CENTER", title, 0, 0)
title.text:SetFont(LSM:Fetch("font", "Merathilis Roboto-Black"), 14, "OUTLINE")
title.text:SetText("|cffff7d0aMerathilisUI|r - ChangeLog " .. MER.Version)

title.style = CreateFrame("Frame", nil, title)
title.style:SetTemplate("Default", true)
title.style:SetFrameStrata("TOOLTIP")
title.style:SetInside()
title.style:Point("TOPLEFT", title, "BOTTOMLEFT", 0, 1)
title.style:Point("BOTTOMRIGHT", title, "BOTTOMRIGHT", 0, (E.PixelMode and -4 or -7))

title.style.color = title.style:CreateTexture(nil, "OVERLAY")
title.style.color:SetVertexColor(classColor.r, classColor.g, classColor.b)
title.style.color:SetInside()
title.style.color:SetTexture(flat)

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:Point("TOPRIGHT", frame, "TOPRIGHT", 0, 26)
close:SetSize(24, 24)
close:SetScript("OnClick", function()
	frame:Hide()
end)
S:HandleCloseButton(close)

local data = frame:CreateFontString(nil, "OVERLAY")
data:SetPoint("TOP", frame, "TOP", 0, -5)
data:SetWidth(frame:GetRight() - frame:GetLeft() - 10)
data:FontTemplate(E['media'].muiFont, 11, "OUTLINE")
data:SetText(ChangeLogData)
data:SetJustifyH("LEFT")
frame:SetHeight(data:GetHeight() + 30)

function MER:ToggleChangeLog()
	if MerathilisUIChangeLog:IsShown() then
		MerathilisUIChangeLog:Hide()
	else
		MerathilisUIChangeLog:Show()
		PlaySound("igMainMenuOptionCheckBoxOff")
	end
end

function MER:OnCheckVersion(self)
	if MerathilisUIData == nil then MerathilisUIData = {} end
	if not MerathilisUIData["Version"] or (MerathilisUIData["Version"] and MerathilisUIData["Version"] ~= MER.Version) then
		MerathilisUIData["Version"] = MER.Version
		MerathilisUIChangeLog:Show()
	end
end

ChangeLog:RegisterEvent("PLAYER_ENTERING_WORLD")
ChangeLog:SetScript("OnEvent", function(self, event, ...)
	MER:OnCheckVersion()
end)