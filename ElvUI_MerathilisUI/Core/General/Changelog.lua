local MER, E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

-- Cache global variables
-- Lua functions
local format, gmatch, gsub, find, sub = string.format, string.gmatch, string.gsub, string.find, string.sub
local tinsert = table.insert
local pairs, tostring = pairs, tostring
-- WoW API / Variables
local CreateFrame = CreateFrame
local SOUNDKIT = SOUNDKIT
local PlaySound = PlaySound
local CLOSE = CLOSE
local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
-- GLOBALS: MERData, UISpecialFrames, MerathilisUIChangeLog, DISABLED_FONT_COLOR

local ChangeLogData = {
	"Retail:",
		"• Update Minimap Buttons",
		"• Fix an error on the Encounter Journal Skin",
		"• Take account for the latest ElvUI changes",

	" ",
	"Classic:",
		"• Take account for the latest ElvUI changes",

	" ",
	"TBC:",
		"• Take account for the latest ElvUI changes",

	" ",
	"Notes:",
		"• As always, if you want my latest layout, do the install again",
		"• If you are getting any errors or something is not working, make sure you are now using:",
		"  '/muierrors on' and test again",

		-- "• ''",
}

local URL_PATTERNS = {
	"^(%a[%w+.-]+://%S+)",
	"%f[%S](%a[%w+.-]+://%S+)",
	"^(www%.[-%w_%%]+%.(%a%a+))",
	"%f[%S](www%.[-%w_%%]+%.(%a%a+))",
	"(%S+@[%w_.-%%]+%.(%a%a+))",
}

local function formatURL(url)
	url = "|cff".."149bfd".."|Hurl:"..url.."|h["..url.."]|h|r ";
	return url
end

local function ModifiedString(string)
	local count = find(string, ":")
	local newString = string

	if count then
		local prefix = sub(string, 0, count)
		local suffix = sub(string, count + 1)
		local subHeader = find(string, "•")

		if subHeader then
			newString = tostring("|cFFFFFF00".. prefix .. "|r" .. suffix)
		else
			newString = tostring("|cffff7d0a".. prefix .. "|r" .. suffix)
		end
	end

	for pattern in gmatch(string, "('.*')") do
		newString = newString:gsub(pattern, "|cFFFF8800" .. pattern:gsub("'", "") .. "|r")
	end

	-- find urls
	for k, v in pairs(URL_PATTERNS) do
		if find(string, v) then
			newString = gsub(string, v, formatURL("%1"))
		end
	end

	return newString
end

local function GetChangeLogInfo(i)
	for line, info in pairs(ChangeLogData) do
		if line == i then
			return info
		end
	end
end

function MER:CreateChangelog()
	local frame = CreateFrame("Frame", "MerathilisUIChangeLog", E.UIParent, 'BackdropTemplate')
	frame:Point("CENTER")
	frame:Size(600, 430)
	frame:CreateBackdrop("Transparent")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame.backdrop:Styling()

	local icon = CreateFrame("Frame", nil, frame, 'BackdropTemplate')
	icon:Point("BOTTOMLEFT", frame, "TOPLEFT", 0, 3)
	icon:Size(20, 20)
	icon:CreateBackdrop("Transparent")
	icon:Styling()

	icon.bg = icon:CreateTexture(nil, "ARTWORK")
	icon.bg:Point("TOPLEFT", 2, -2)
	icon.bg:Point("BOTTOMRIGHT", -2, 2)
	icon.bg:SetTexture(MER.LogoSmall)

	local title = CreateFrame("Frame", nil, frame, 'BackdropTemplate')
	title:Point("LEFT", icon, "RIGHT", 1, 0)
	title:Size(579, 20)
	title:CreateBackdrop("Transparent")
	title.backdrop:Styling()

	title.text = MER:CreateText(title, "OVERLAY", 15, nil, "CENTER")
	title.text:Point("CENTER", title, 0, -1)
	title.text:SetText(MER.Title.. "- ChangeLog "..format("|cff00c0fa%s|r", MER.Version))

	local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate, BackdropTemplate")
	close:Point("BOTTOM", frame, "BOTTOM", 0, 10)
	close:SetText(CLOSE)
	close:Size(80, 20)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)
	S:HandleButton(close)
	close:Disable()
	frame.close = close

	local countdown = MER:CreateText(close, "OVERLAY", 12, nil, "CENTER")
	countdown:Point("LEFT", close.Text, "RIGHT", 3, 0)
	countdown:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
	frame.countdown = countdown

	local offset = 4
	for i = 1, #ChangeLogData do
		local button = CreateFrame("Frame", "Button"..i, frame)
		button:SetSize(375, 16)
		button:Point("TOPLEFT", frame, "TOPLEFT", 5, -offset)

		if i <= #ChangeLogData then
			local string, isURL = ModifiedString(GetChangeLogInfo(i))

			button.Text = MER:CreateText(button, "OVERLAY", 11, nil, "CENTER")
			button.Text.isURL = isURL
			button.Text:SetText(string)
			button.Text:Point("LEFT", 0, 0)
		end
		offset = offset + 16
	end
end

function MER:CountDown()
	self.time = self.time - 1

	if self.time == 0 then
		MerathilisUIChangeLog.countdown:SetText("")
		MerathilisUIChangeLog.close:Enable()
		self:CancelAllTimers()
	else
		MerathilisUIChangeLog.countdown:SetText(format("(%s)", self.time))
	end
end

function MER:ToggleChangeLog()
	if not MerathilisUIChangeLog then
		self:CreateChangelog()
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857)

	local fadeInfo = {}
	fadeInfo.mode = "IN"
	fadeInfo.timeToFade = 0.5
	fadeInfo.startAlpha = 0
	fadeInfo.endAlpha = 1
	E:UIFrameFade(MerathilisUIChangeLog, fadeInfo)

	self.time = 6
	self:CancelAllTimers()
	MER:CountDown()
	self:ScheduleRepeatingTimer("CountDown", 1)
end

function MER:CheckVersion(self)
	if not MERData["Version"] or (MERData["Version"] and MERData["Version"] ~= MER.Version) then
		MERData["Version"] = MER.Version
		MER:ToggleChangeLog()
	end
end
