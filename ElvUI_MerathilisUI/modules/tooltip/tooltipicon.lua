local MER, E, L, V, P, G = unpack(select(2, ...))
local MERS = E:GetModule("muiSkins")

-- Cache global variables
-- Lua functions
local _G = _G
local pairs, tonumber, type, unpack = pairs, tonumber, type, unpack
local format = format
local strlower = string.lower
local strmatch = string.match
local strfind = string.find
local strsub = string.sub
local strsplit = strsplit
local pi = math.pi
local next = next

-- WoW API / Variables
local CreateFrame = CreateFrame
local GetCurrencyInfo = GetCurrencyInfo
local GetCurrencyListInfo = GetCurrencyListInfo
local GetMerchantItemInfo = GetMerchantItemInfo
local GetMerchantItemCostItem = GetMerchantItemCostItem
local GetMerchantItemLink = GetMerchantItemLink
local GetMouseFocus = GetMouseFocus
local GetItemIcon = GetItemIcon
local GetSpellInfo = GetSpellInfo
local GetAchievementInfo = GetAchievementInfo
local C_ToyBox = C_ToyBox
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitIsBattlePet = UnitIsBattlePet
local UnitBattlePetType = UnitBattlePetType
local UnitBattlePetSpeciesID = UnitBattlePetSpeciesID
local UnitIsVisible = UnitIsVisible
local UnitFactionGroup = UnitFactionGroup

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: TooltipItemIcon_HookFrame, TooltipItemIcon_DisplayIcon, TooltipItemIcon_Saved, DEFAULT_CHAT_FRAME
-- GLOBALS: GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3, ItemRefTooltip
-- GLOBALS: ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, LinkWrangler
-- GLOBALS: ComparisonTooltip1, ComparisonTooltip2, AtlasLootTooltip, SLASH_TOOLTIPITEMICON1, SLASH_TOOLTIPITEMICON2
-- GLOBALS: SlashCmdList, hooksecurefunc, GameTooltipTextLeft1,  BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT

-- Author: brykrys
-- Previous Authors: Alason, Freddy, Amavana
-- Additional coding and thanks: Resike

-- See end of file for global exports
-- Documentation can be found in commands.txt and developer.txt

local version = 1.73
-- release

--------------------------------------------------------------------------------
-- VARIABLES
--------------------------------------------------------------------------------

local IconDataTable = {}
local LocationTable = {
	lefttop = {"TOPRIGHT", "TOPLEFT", 0, -3},
	righttop = {"TOPLEFT", "TOPRIGHT", 0, -3},
	topleft = {"BOTTOMLEFT", "TOPLEFT", 3, 0},
	topright = {"BOTTOMRIGHT", "TOPRIGHT", -3, 0},
	topcenter = {"BOTTOM", "TOP", 0, 0},
	bottomleft = {"TOPLEFT", "BOTTOMLEFT", 3, 0},
	bottomright = {"TOPRIGHT", "BOTTOMRIGHT", -3, 0},
	bottomcenter = {"TOP", "BOTTOM", 0, 0},
}
local DisplayIconTable = {}
local HideIconTable = {}
local SetFunctionTable = {}

-- locals to hold subtables or settings, for access speed
local saved, options, texticonsize

local DisplayIconCurrent = function() end -- temp dummy function; overloaded when TTII fully loaded
local HideIconCurrent = DisplayIconCurrent

--------------------------------------------------------------------------------
-- VARIABLE HANDLING FUNCTIONS
--------------------------------------------------------------------------------

local function DefaultSavedVariables()
	return {
		version = version,
		mode = "inside",
		options = {
			item = true,
			equipmentset = true,
			spell = true,
			toy = true,
			achievement = true,
			token = true,
		},
		tooltips = {
			compare = true,
		},
		frame = {
			size = 39,
			alpha = 1,
		},
		inside = {size = 26},
		background = {
			alpha = .9,
			tintr = .4,
			tintg = .4,
			tintb = .4,
		},
		title = {size = 24},
		exact = {},
		template = {},
	}
end

local function SetLocalVariables()
	-- Sync locals with SavedVariables
	saved = TooltipItemIcon_Saved
	DisplayIconCurrent = DisplayIconTable[saved.mode]
	HideIconCurrent = HideIconTable[saved.mode]
	options = saved.options
	if saved.mode == "inside" then
		texticonsize = saved.inside.size
	elseif saved.mode == "title" then
		texticonsize = saved.title.size
	else
		texticonsize = nil
	end
end

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local function Print(msg, ...)
	DEFAULT_CHAT_FRAME:AddMessage("TTII: "..format(msg, ...), .9, .9, .9)
end

--------------------------------------------------------------------------------
-- CORE FUNCTIONS
--------------------------------------------------------------------------------

-- dispatch to the appropriate show or hide function for current mode
-- NO other function should call DisplayIconCurrent or HideIconCurrent
-- NO other function should _change_ data.shown (though they may read it)
-- this is the key function that everything else revolves around!
local function DisplayIconDispatch(data, iconpath)
	if iconpath then
		data.shown = DisplayIconCurrent(data, iconpath)
	elseif data.shown then
		data.shown = false
		HideIconCurrent(data)
	end
end

-- get internal data table for this parent tooltip
-- most other functions will use this data table
local function GetTooltipData(parent, location, compare)
	-- get data for this parent frame
	local data = IconDataTable[parent]
	if not data then -- new frame: create data and do all first-time processing
		data = {}
		data.parent = parent
		IconDataTable[parent] = data
		if compare then
			data.compare = true
			if not saved.tooltips.compare then
				data.disable = true
			end
		end
		data.defaultlocation = LocationTable[location]

		local name, savedtable
		name = parent:GetName()
		savedtable = saved.exact[name]
		if savedtable then
			-- code to clean out empty tables
			if next(savedtable) == nil then
				savedtable = nil
				saved.exact[name] = nil
			end
		else
			name = strmatch(name, "^(%D+)")
			savedtable = saved.template[name]
			if savedtable and next(savedtable) == nil then
				savedtable = nil
				saved.template[name] = nil
			end
		end
		if savedtable then
			data.location = LocationTable[savedtable.location]
			if savedtable.disable then
				data.disable = true
				data.saveddisable = true
			end
		end
	end
	return data
end

--------------------------------------------------------------------------------
-- GENERAL SUPPORT FUNCTIONS
--------------------------------------------------------------------------------

-- function to set location of icon frame relative to parent
-- NO other function should relocate the icon frame
local function SetFrameLocation(data)
	local frame = data.frame
	if not frame then
		return
	end
	local parent = data.parent
	local location = data.location or data.defaultlocation or LocationTable.lefttop
	frame:ClearAllPoints()
	frame:SetPoint(location[1], parent, location[2], location[3], location[4])
	data.location = nil -- no longer needed
	-- data.defaultlocation is preserved in case we need it again
end

-- function which takes a 'link' string and tries to find a texture from it
local function GetTextureFromLink(link)
	if not link then return end

	local header, id = strsplit(":", link)
	id = tonumber(id)
	if id then -- looks like a valid link
		local _, linkType = strsplit("H", header)
		if not linkType then linkType = header end -- non-hyperlink, missing |H marker, header was just linkType

		if linkType == "item" then
			if options.item then
				return GetItemIcon(link)
			end
			return
		elseif linkType == "spell" or linkType == "enchant" then
			if options.spell then
				local _, _, tpath = GetSpellInfo(id)
				return tpath
			end
			return
		elseif linkType == "toy" then
			if options.toy then
				local _, _, tpath = C_ToyBox.GetToyInfo(id)
				return tpath
			end
			return
		elseif linkType == "achievement" then
			if options.achievement then
				local _, _, _, _, _, _, _, _, _, tpath = GetAchievementInfo(id)
				return tpath
			end
			return
		elseif linkType == "currency" then
			if options.token then
				local _, _, tpath = GetCurrencyInfo(id)
				if tpath then
					return tpath
				end
			end
			return
		end
	end

	-- Test for raw texture
	-- For now, only checks that it appears to be a file path, i.e. starts with "Interface/" or "Interface\"
	if strfind(link, "^Interface[/\\]") then
		--Print ("Debug: raw texture detected "..link)
		return link
	end
end

--------------------------------------------------------------------------------
-- MODE-SELECTED FUNCTIONS
--------------------------------------------------------------------------------

HideIconTable.frame = function(data)
	if data.frame then
		data.frame:Hide()
	end
end

HideIconTable.background = function(data)
	local icon = data.backgroundicon
	if icon and icon:IsShown() then
		icon:Hide()
	end
	if data.background_oldr then
		data.parent:SetBackdropColor(data.background_oldr, data.background_oldg, data.background_oldb, data.background_olda)
		data.background_oldr, data.background_oldg, data.background_oldb, data.background_olda = false, false, false, false
	end
end

HideIconTable.inside = function(data)
	local icon = data.insideicon
	if icon and icon:IsShown() then
		icon:Hide()
	end
	if data.insideresetheight then
		data.titlefield:SetHeight(0) -- height 0 removes explicit height setting
		data.insideresetheight = nil
	end
	data.insideoldtext = nil
end

HideIconTable.title = function(data)
	local icon = data.titlefield
	local old = data.titleoldtext
	if icon and old and icon:IsVisible() then
		local check = icon:GetText()
		if check and check ~= "" then
			icon:SetText(old)
		end
	end
	data.titleoldtext = nil
end


DisplayIconTable.frame = function(data, iconpath)
	local iconframe = data.frame
	-- check/create icon frame
	if not iconframe then
		-- create new icon frame
		iconframe = CreateFrame("Frame", nil, data.parent)
		iconframe:SetWidth(saved.frame.size)
		iconframe:SetHeight(saved.frame.size)
		data.frame = iconframe
		-- create texture and attach to frame
		data.frameicon = iconframe:CreateTexture(nil, "ARTWORK")
		data.frameicon:SetAllPoints(iconframe)
		data.frameicon:SetAlpha(saved.frame.alpha)
		-- set anchor position
		SetFrameLocation(data)
	end
	-- show the icon
	data.frameicon:SetTexture(iconpath)
	iconframe:Show()
	return iconpath
end

DisplayIconTable.background = function(data, iconpath)
	local icon = data.backgroundicon
	local parent = data.parent
	-- check/create background texture
	if not icon then
		icon = data.parent:CreateTexture(nil, "BACKGROUND", nil, 7)
		local sb = saved.background
		icon:SetAlpha(sb.alpha)
		icon:SetVertexColor(sb.tintr, sb.tintg, sb.tintb)
		icon:SetAllPoints(parent)
		data.backgroundicon = icon
	end
	-- adjust backdrop
	data.background_oldr, data.background_oldg, data.background_oldb, data.background_olda = parent:GetBackdropColor()
	parent:SetBackdropColor(0, 0, 0, 0)
	-- show the icon
	icon:SetTexture (iconpath)
	icon:Show()
	return iconpath
end

DisplayIconTable.inside = function(data, iconpath)
	local icon = data.insideicon
	local control = data.titlefield
	-- Find the text field
	if not icon then
		icon = _G[data.parent:GetName().."TextRight1"]
		data.insideicon = icon
	end
	if not control then
		control = _G[data.parent:GetName().."TextLeft1"]
		data.titlefield = control
	end

	data.parent:Show() -- required for ShoppingTooltips

	local oldtext = icon:GetText() or ""
	data.insideoldtext = oldtext

	-- show the icon
	icon:SetFormattedText("%s |T%s:%d|t", oldtext, iconpath, texticonsize)
	icon:Show()

	-- adjust height of title if icon size is large - this controls height of whole top line
	local cheight, iheight = control:GetHeight(), icon:GetHeight() * .8 -- adjustment factor found by trial and error
	if cheight < iheight then
		control:SetHeight(iheight)
		data.insideresetheight = cheight
	end

	data.parent:Show() -- required to reformat layout correctly

	return iconpath
end

DisplayIconTable.title = function(data, iconpath)
	local icon = data.titlefield
	-- Find the text field
	if not icon then
		icon = _G[data.parent:GetName().."TextLeft1"]
		data.titlefield = icon
	end

	--data.parent:Show() -- required for ShoppingTooltips -- todo: test if needed here

	local oldtext = icon:GetText() or ""
	data.titleoldtext = oldtext

	-- show the icon
	icon:SetFormattedText("|T%s:%d|t %s", iconpath, texticonsize, oldtext)
	icon:Show()
	data.parent:Show() -- required to reformat layout correctly

	return iconpath
end

--------------------------------------------------------------------------------
-- HOOKING FUNCTIONS
--------------------------------------------------------------------------------

-- Multipurpose hook
-- Takes extra parameters to initialize default location and compare status
-- Does NOT check if the icon is already shown, i.e. forces icon based on whatever link is passed
local function HookMultiplex(parent, link, location, compare)
	local data = GetTooltipData(parent, location, compare)
	if not data.disable then
		DisplayIconDispatch(data, GetTextureFromLink (link))
	end
end
-- Indirect multipurpose hook, for when we want to trim any extra parameters from the caller
-- (Currently only LinkWrangler hook)
local function HookLink(frame, link)
	return HookMultiplex(frame, link)
end
-- Indirect hook, plus passes compare=true
-- (Currently only LinkWrangler Compare tooltips hook)
local function HookLinkComp(frame, link)
	return HookMultiplex(frame, link, nil, true)
end

-- Hook for when we know the frame contains an item
-- (OnTooltipSetItem)
local function HookItem(frame)
	if not options.item then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local _, text = frame:GetItem()
	if text then
		text = GetItemIcon(text)
		if text then
			DisplayIconDispatch(data, text)
		end
	end
end

-- Hook for when we know the frame contains an equipemnt set
-- (OnTooltipSetEquipmentSet)
local function HookEquipmentSet(frame)
	if not options.equipmentset then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	for i = 1, 8 do
		if GameTooltipTextLeft1:GetText() == _G["PaperDollEquipmentManagerPaneButton"..i.."Text"]:GetText() then
			DisplayIconDispatch(data, _G["PaperDollEquipmentManagerPaneButton"..i.."Icon"]:GetTexture())

			return
		end
	end
end

-- Hook for when we know the frame contains a toy
-- (SetToyByItemID)
local function HookToy(frame, id)
	if not options.toy then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local _, text, icon = C_ToyBox.GetToyInfo(id)
	if text and icon then
		DisplayIconDispatch(data, icon)
	end
end

-- Hook for when we know the frame contains a spell
-- (OnTooltipSetSpell)
local function HookSpell(frame)
	if not options.spell then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local name, rank, spellID = frame:GetSpell()
	if name then
		local _, _, text = GetSpellInfo(spellID)
		if text then
			DisplayIconDispatch(data, text)
		end
	end
end

-- Hook for frame:SetCurrencyToken
local function HookCurrencyToken(frame, currency)
	if not options.token then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	-- here currency is an index into your own currency list
	local _,_,_,_,_,_,tpath = GetCurrencyListInfo(currency)
	DisplayIconDispatch(data, tpath)
end

-- Hook for frame:SetCurrencyByID
local function HookCurrencyByID(frame, currencyID)
	if not options.token then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local _,_,tpath = GetCurrencyInfo(currencyID)
	if tpath then
		DisplayIconDispatch(data, tpath)
	end
end

-- Hook for frame:SetMerchantCostItem
-- yet another hook needed to handle currency...
local function HookMerchantCostItem(frame, index, item)
	if not options.token then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local tpath = GetMerchantItemCostItem(index, item)
	DisplayIconDispatch(data, tpath)
end

-- Hook for frame:SetMerchantItem
-- Special handling for when Merchant is selling a currency token
-- (actual items are handled by the generic HookItem hook)
local function HookMerchantItem(frame, index)
	if not options.token then
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	local link = GetMerchantItemLink(index)
	if link then
		-- currency tokens appear to return a nil link
		-- if we find that something else also returns nil here, we may need additional testing
		return
	end
	local _, tpath = GetMerchantItemInfo(index)
	DisplayIconDispatch(data, tpath)
end

-- Hook for frame:SetHyperlink
local function HookHyperlink(frame, link)
	if not frame:IsVisible() then -- check if SetHyperlink caused the frame to close
		return
	end
	local data = GetTooltipData(frame)
	if data.disable or data.shown then
		return
	end
	DisplayIconDispatch(data, GetTextureFromLink(link))
end

--Hook for OnTooltipCleared - this gets called when the tooltip is hidden OR
--when another link is posted into the tooltip.
--Hides the icon by passing a nil texture
local function HookHide (frame)
	local data = GetTooltipData (frame)
	if data.disable then
		return
	end
	DisplayIconDispatch(data)
end

--------------------------------------------------------------------------------
-- SLASH COMMAND HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- saves configuration values specific to individual tooltips/frames
-- key is the name of the variable being saved; if key is nil all saved variables for this frame will be deleted
-- value is the value of the variable being saved; if value is nil then that variable will be deleted
local function SetSavedValue(frame, key, value)
	local exactname, templatename
	exactname = frame:GetName()
	templatename = strmatch(exactname, "^(%D+)")
	if exactname == templatename or not templatename then -- decide where to store this frame
		if not key then
			saved.exact[exactname] = nil
			return
		end
		if not saved.exact[exactname] then
			saved.exact[exactname] = {}
		end
		saved.exact[exactname][key] = value
	else
		if not key then
			saved.template[templatename] = nil
			return
		end
		if not saved.template[templatename] then
			saved.template[templatename] = {}
		end
		saved.template[templatename][key] = value
	end
end

-- called when global compare setting is changed
-- to recalculate the new disable setting for all tooltips
local function SyncDisableStatus ()
	local globalcomp = not saved.tooltips.compare
	for _, data in pairs (IconDataTable) do
		data.disable = data.saveddisable or (data.compare and globalcomp)
		if data.disable then
			DisplayIconDispatch (data)
		end
	end
end

-- called when mode has been changed, either from explicit mode change
-- or from resetting saved variables
-- local variables should not have been reset yet
local function SyncModeChange ()
	for _, data in pairs (IconDataTable) do
		data.wasshown = data.shown
		DisplayIconDispatch (data) -- hide icon in old mode
	end

	SetLocalVariables () -- completes the mode change

	for _, data in pairs (IconDataTable) do
		if data.wasshown then -- decide whether to show icon in new mode
			DisplayIconDispatch (data, data.wasshown)
			data.wasshown = nil
		end
	end
end

-- Called when the save data from all tooltips is purged
-- wipes all user-saved locations or disables
local function SyncTooltipPurge ()
	for _, data in pairs (IconDataTable) do
		data.saveddisable = nil
		data.disable = data.compare and not saved.tooltips.compare
		data.location = nil
		SetFrameLocation (data)
	end
end

SetFunctionTable.on = function (frame, data)
	data.saveddisable = nil
	data.disable = data.compare and not saved.tooltips.compare
	SetSavedValue (frame, "disable", nil)
end

SetFunctionTable.off = function (frame, data)
	data.disable = true
	data.saveddisable = true
	DisplayIconDispatch (data)
	SetSavedValue (frame, "disable", true)
end

-- changes location of frame-mode icon to the location specified
-- todo: consider reducing number of params as newpos can be generated from poscode
SetFunctionTable.location = function (frame, data, newpos, poscode)
	data.location = newpos
	SetFrameLocation (data)
	SetSavedValue (frame, "location", poscode)
end

-- clears saved location
-- moves frame-mode icon to default location (if applicable)
SetFunctionTable.default = function (frame, data)
	data.location = nil
	SetFrameLocation (data)
	SetSavedValue (frame, "location", nil)
end

-- clears all saved values for this frame
-- combination of 'default' and 'on'
SetFunctionTable.reset = function (frame, data)
	data.location = nil
	SetFrameLocation (data)

	data.saveddisable = nil
	data.disable = data.compare and not saved.tooltips.compare

	SetSavedValue (frame, nil)
end

--------------------------------------------------------------------------------
-- SLASH COMMAND FUNCTIONS
--------------------------------------------------------------------------------

-- Settings or other actions perfomed on one or more tooltips
-- name = code representing multiple tooltips OR name of tooltip (possibly preceded by ':')
local function SlashTooltipActions (name, action)
	-- decode action first:
	local value1, value2, setfunc
	value1 = LocationTable[action]
	if value1 then
		if saved.mode ~= "frame" then
			Print "Error: command not valid in this mode"
			return
		end
		value2 = action
		action = "location"
	end
	setfunc = SetFunctionTable[action]
	if not setfunc then
		return true -- error
	end

	-- decode name
	if name == "all" then
		Print ("Applying %s action to %s", action, "all tooltips")
		if action == "reset" then
			-- special case: clean out saved tables for all tooltips
			saved.exact = {}
			saved.template = {}
			SyncTooltipPurge ()
			return
		end
		for key, value in pairs (IconDataTable) do
			setfunc (key, value, value1, value2)
		end
		return
	elseif name == "screen" then
		Print ("Applying %s action to %s", action, "visible tooltips")
		for key, value in pairs (IconDataTable) do
			if key:IsVisible() then
				setfunc (key, value, value1, value2)
			end
		end
		return
	elseif name == "compare" then
		-- works differently to the others
		-- 'on' and 'off' should not be saved for individual tooltips
		-- instead they set the global 'compare' option
		if action == "on" then
			saved.tooltips.compare = true
			SyncDisableStatus ()
			Print ("Compare tooltips %s", "enabled")
		elseif action == "off" then
			saved.tooltips.compare = false
			SyncDisableStatus ()
			Print ("Compare tooltips %s", "disabled")
		else -- actions other than 'on' or 'off'
			Print ("Applying %s action to %s", action, "comparison tooltips")
			for key, value in pairs (IconDataTable) do
				if value.compare then
					setfunc (key, value, value1, value2)
				end
			end
		end
		return
	end

	-- explicit tooltip name marked by a starting ':' symbol; strip it out
	if strsub(name, 1, 1) == ":" then
		name = strsub(name, 2) or ""
	end
	if name == "" then
		return true
	end
	Print("Applying %s action to %s", action, name)

	-- look for a frame whose name matches the user-input string
	-- note the string will be in lower case
	local err = true
	for frame, data in pairs(IconDataTable) do
		local exactname, templatename
		exactname = strlower(frame:GetName())
		templatename = strmatch(exactname, "^(%D+)")
		if name == exactname or name == templatename then
			setfunc(frame, data, value1, value2)
			err = nil
		end
	end

	-- todo: search saved tables for frame name, in case we have seen it in a previous session
	return err
end

local function SlashGlobalActions (command, extra)
	if command == "reset" then
		TooltipItemIcon_Saved = DefaultSavedVariables()
		SyncTooltipPurge ()
		SyncModeChange ()
		Print "Saved variables reset to default values"
	elseif command == "size" then
		local extranumber = tonumber (extra)
		if not extranumber or extranumber < 1 or extranumber > 999 then
			Print "Error: number is out of range"
		elseif saved.mode == "frame" then
			saved.frame.size = extranumber
			for _,data in pairs (IconDataTable) do
				if data.frame then
					data.frame:SetWidth (extranumber)
					data.frame:SetHeight (extranumber)
				end
			end
			Print ("Icon size set to %d", extranumber)
		elseif saved.mode == "inside" then
			saved.inside.size = extranumber
			SetLocalVariables ()
			Print ("Icon size set to %d", extranumber)
		elseif saved.mode == "title" then
			saved.title.size = extranumber
			SetLocalVariables ()
			Print ("Icon size set to %d", extranumber)
		else
			Print "Error: command not valid in this mode"
		end
	elseif command == "fade" then
		local extranumber = tonumber (extra)
		if not extranumber or extranumber < 0 or extranumber > 1 then
			Print ("Error: number is out of range")
		elseif saved.mode == "background" then
			saved.background.tintr, saved.background.tintg, saved.background.tintb = extranumber, extranumber, extranumber
			for _,data in pairs (IconDataTable) do
				if data.backgroundicon then
					data.backgroundicon:SetVertexColor(extranumber, extranumber, extranumber)
				end
			end
			Print ("Background fade set to %g", extranumber)
		else
			Print "Error: command not valid in this mode"
		end
	elseif command == "alpha" then
		local extranumber = tonumber (extra)
		if not extranumber or extranumber < 0 or extranumber > 1 then
			Print ("Error: number is out of range")
		elseif saved.mode == "background" then
			saved.background.alpha = extranumber
			for _,data in pairs (IconDataTable) do
				if data.backgroundicon then
					data.backgroundicon:SetAlpha (extranumber)
				end
			end
			Print ("Background alpha set to %g", extranumber)
		elseif saved.mode == "frame" then
			saved.frame.alpha = extranumber
			for _,data in pairs (IconDataTable) do
				if data.frameicon then
					data.frameicon:SetAlpha (extranumber)
				end
			end
			Print ("Frame alpha set to %g", extranumber)
		else
			Print "Error: command not valid in this mode"
		end
	elseif DisplayIconTable[command] then
		saved.mode = command
		SyncModeChange ()
		Print ("Changing to %s mode", command)
	elseif type (options[command]) == "boolean" then
		if extra == "on" then
			options[command] = true
		elseif extra == "off" then
			options[command] = false
		else
			-- ignore erroneous extra text for now
		end
		Print ("Option %s is now %s", command, options[command] and "enabled" or "disabled")
	else
		return true -- signal that further processing is required
	end
end

local function SlashCommand (cmd)
	-- extract data from command string
	cmd = strlower (cmd)
	local _, pos, command, extra
	_,pos,command = strfind (cmd, "(%S+)")
	if pos then
		_,_,extra = strfind (cmd, "%s+(.+)", pos+1)
	else
		Print ("TooltipItemIcon version %g. Mode %s", version, saved.mode)
		return
	end
	extra = extra or ""

	-- call the slash processing functions to do the work
	-- note: each function returns true if it did not recognize the command, i.e. further processing is required
	if SlashGlobalActions (command, extra) and SlashTooltipActions (command, extra) then
		Print "Error: unrecognised TooltipItemIcon command"
	end
end

--------------------------------------------------------------------------------
-- STARTUP FUNCTIONS
--------------------------------------------------------------------------------

-- function called at startup, then deleted
local function CheckSavedVariables ()
	local oldtable = TooltipItemIcon_Saved
	if type (oldtable) ~= "table" then -- ensure it's a table
		TooltipItemIcon_Saved = DefaultSavedVariables ()
		return
	end
	local oldversion = oldtable.version
	if oldversion == version then -- only check once when a new version is installed
		return
	end
	Print "New version detected; checking saved variables"

	-- Create a new default table to use as our saved variables
	-- then copy over keys from the old table that match the types of keys in the default table
	-- this eliminates any obsolete or corrupted keys
	local newtable = DefaultSavedVariables ()
	-- options: always boolean
	if type(oldtable.options) == "table" then
		for key, _ in pairs (newtable.options) do
			if type(oldtable.options[key]) == "boolean" then
				newtable.options[key] = oldtable.options[key]
			end
		end
	end
	-- Conversion: options.compare -> tooltips.compare
	if oldtable.options and type(oldtable.options.compare) == "boolean" then
		newtable.tooltips.compare = oldtable.options.compare
	end
	-- tooltips settings
	if type(oldtable.tooltips) == "table" then
		for key, value in pairs (newtable.tooltips) do
			if type(oldtable.tooltips[key]) == type(value) then
				newtable.tooltips[key] = oldtable.tooltips[key]
			end
		end
	end
	-- mode
	if oldtable.mode == "frame" or oldtable.mode == "inside" or oldtable.mode == "background" or oldtable.mode == "title" then
		newtable.mode = oldtable.mode
	end
	-- inside settings
	if type(oldtable.inside) == "table" and type(oldtable.inside.size) == "number" then
		newtable.inside.size = oldtable.inside.size
	end
	if type(oldtable.title) == "table" and type(oldtable.title.size) == "number" then
		newtable.title.size = oldtable.title.size
	end
	-- background settings
	if type (oldtable.background) == "table" and type (oldtable.background.alpha) == "number" then
		newtable.background.alpha = oldtable.background.alpha
	end
	-- conversion: old background alpha -> new tint setting
	if oldversion < 1.535 then
		-- old-style alpha setting will have been copied over
		local fade = newtable.background.alpha * (.4/.45)
		newtable.background.alpha = .9
		newtable.background.tintr, newtable.background.tintg, newtable.background.tintb = fade, fade, fade
	end
	-- frame settings
	if type (oldtable.frame) == "table" then
		if type (oldtable.frame.size) == "number" then
			newtable.frame.size = oldtable.frame.size
		end
		if type (oldtable.frame.alpha) == "number" then
			newtable.frame.alpha = oldtable.frame.alpha
		end
	end
	-- settings for individual tooltips
	-- exact name matches
	if type(oldtable.exact) == "table" then
		for key, value in pairs(oldtable.exact) do
			if type(value) == "table" then
				local flag
				local tooltiptable = {}
				if value.disable == true then
					tooltiptable.disable = true
					flag = true
				end
				if LocationTable[value.location] then
					tooltiptable.location = value.location
					flag = true
				end
				if flag then
					newtable.exact[key] = tooltiptable
				end
			end
		end
	end
	-- template name matches
	if type(oldtable.template) == "table" then
		for key, value in pairs(oldtable.template) do
			if type(value) == "table" then
				local flag
				local tooltiptable = {}
				if value.disable == true then
					tooltiptable.disable = true
					flag = true
				end
				if LocationTable[value.location] then
					tooltiptable.location = value.location
					flag = true
				end
				if flag then
					newtable.template[key] = tooltiptable
				end
			end
		end
	end

	TooltipItemIcon_Saved = newtable
end

local function OnEvent(frame) -- only event is VARIABLES_LOADED
	-- saved Variables
	CheckSavedVariables()
	SetLocalVariables()
	-- Blizzard tooltips
	TooltipItemIcon_HookFrame(GameTooltip, "topleft")
	TooltipItemIcon_HookFrame(ShoppingTooltip1, "topleft", true)
	TooltipItemIcon_HookFrame(ShoppingTooltip2, "topleft", true)
	TooltipItemIcon_HookFrame(ShoppingTooltip3, "topleft", true)
	TooltipItemIcon_HookFrame(ItemRefTooltip, "topleft")
	TooltipItemIcon_HookFrame(ItemRefShoppingTooltip1, "topleft", true)
	TooltipItemIcon_HookFrame(ItemRefShoppingTooltip2, "topleft", true)
	TooltipItemIcon_HookFrame(ItemRefShoppingTooltip3, "topleft", true)
	-- LinkWrangler hooks
	if LinkWrangler then
		LinkWrangler.RegisterCallback("TooltipItemIcon", HookLink, "refresh")
		LinkWrangler.RegisterCallback("TooltipItemIcon", HookHide, "minimize", "hide", "hidecomp")
		LinkWrangler.RegisterCallback("TooltipItemIcon", HookLinkComp, "refreshcomp")
	end
	-- EquipCompare hooks
	if ComparisonTooltip1 then
		TooltipItemIcon_HookFrame(ComparisonTooltip1, "topleft", true)
	end
	if ComparisonTooltip2 then
		TooltipItemIcon_HookFrame(ComparisonTooltip2, "topleft", true)
	end
	-- AtlasLoot
	if AtlasLootTooltip then
		TooltipItemIcon_HookFrame(AtlasLootTooltip)
	end

	-- slash commands
	SLASH_TOOLTIPITEMICON1 = "/tooltipitemicon"
	SLASH_TOOLTIPITEMICON2 = "/ttii"
	SlashCmdList["TOOLTIPITEMICON"] = SlashCommand
	-- unregister unneeded functions to free up memory
	frame:UnregisterEvent("VARIABLES_LOADED")
	frame:SetScript("OnEvent", nil)
end

local eventframe = CreateFrame("Frame")
eventframe:SetScript("OnEvent", OnEvent)
eventframe:RegisterEvent("VARIABLES_LOADED")

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
--Refer to developer.txt for documentation

-- TooltipItemIcon_DisplayIcon (ParentFrame, [Link, [Location, [Compare]]])
-- Multi-purpose function used to explicitly attach an icon to your frame
-- Will work in more cases than TooltipItemIcon_HookFrame,
-- but requires the other AddOn to do more work
TooltipItemIcon_DisplayIcon = HookMultiplex

--Alternative hooking Export:
--TooltipItemIcon_HookFrame (frame, location, compare)
--call this function to automatically hook TTII to your frame
function TooltipItemIcon_HookFrame(frame, location, compare)
	if type(frame) == "table" and frame.IsObjectType and frame:IsObjectType("GameTooltip") then
		frame:HookScript("OnTooltipSetItem", HookItem)
		frame:HookScript("OnTooltipSetEquipmentSet", HookEquipmentSet)
		frame:HookScript("OnTooltipSetSpell", HookSpell)
		frame:HookScript("OnTooltipCleared", HookHide)
		hooksecurefunc(frame, "SetHyperlink", HookHyperlink)
		hooksecurefunc(frame, "SetCurrencyToken", HookCurrencyToken)
		hooksecurefunc(frame, "SetCurrencyByID", HookCurrencyByID)
		hooksecurefunc(frame, "SetMerchantCostItem", HookMerchantCostItem)
		hooksecurefunc(frame, "SetMerchantItem", HookMerchantItem)
		hooksecurefunc(frame, "SetToyByItemID", HookToy)
		GetTooltipData(frame, location, compare) -- save location/compare settings
	end
end

-- Model Frame
local function InsertModelFrame(self, unit)
	if not self.modelFrame then
		local f = CreateFrame("PlayerModel", nil)
		f:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 10, -10)
		self.modelFrame = f
	end
	self.modelFrame:SetSize(90 , 90)
	self.modelFrame:SetFacing(-0.25)
	self.modelFrame:SetParent(_G["GameTooltip"])

	if not UnitIsVisible(unit) then return end
	if UnitIsPlayer(unit) then
		self.modelFrame:SetUnit(unit)
		self.modelFrame:Show()
		self.modelFrame:SetScript("OnUpdate", function(self, elapsed)
			if (IsControlKeyDown() or IsAltKeyDown()) then
				self:SetFacing(self:GetFacing() + pi * elapsed)
			end
		end)
	else
		self.modelFrame:ClearModel()
		self.modelFrame:Hide()
	end
end

-- Add a faction badge
local function InsertFactionFrame(self, faction)
	if not self.factionFrame then
		local f = self:CreateTexture(nil, "OVERLAY")
		f:SetPoint("TOPRIGHT", 0, -5)
		f:SetBlendMode("ADD")
		self.factionFrame = f
	end
	self.factionFrame:SetTexture("Interface\\FriendsFrame\\PlusManz-"..faction)
	self.factionFrame:SetAlpha(.5)
	self.factionFrame:SetSize(35, 35)
end

-- Pet icon
local function InsertPetIcon(self, petType)
	if not self.petIcon then
		local f = self:CreateTexture(nil, "OVERLAY")
		f:SetPoint("TOPRIGHT", -5, -5)
		f:SetSize(35, 35)
		f:SetBlendMode("ADD")
		self.petIcon = f
	end
	self.petIcon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
	self.petIcon:SetTexCoord(.188, .883, 0, .348)
	self.petIcon:SetAlpha(1)
end

MER:SecureHookScript(GameTooltip, "OnTooltipCleared", function(self)
	if GameTooltip:IsForbidden() then return; end
	if self.modelFrame and self.modelFrame:GetAlpha() ~= 0 then
		self.modelFrame:Hide()
		self.modelFrame:ClearModel()
	end
	if self.factionFrame and self.factionFrame:GetAlpha() ~= 0 then
		self.factionFrame:SetAlpha(0)
	end
	if self.petIcon and self.petIcon:GetAlpha() ~= 0 then
		self.petIcon:SetAlpha(0)
	end
end)


local function getUnit(self)
	local _, unit = self and self:GetUnit()
	if(not unit) then
		local mFocus = GetMouseFocus()
		unit = mFocus and (mFocus.unit or (mFocus.GetAttribute and mFocus:GetAttribute("unit"))) or "mouseover"
	end
	return unit
end

MER:SecureHookScript(GameTooltip, "OnTooltipSetUnit", function(self)
	if GameTooltip:IsForbidden() then return; end
	local unit = getUnit(self)

	if UnitExists(unit) then

		if UnitIsPlayer(unit) then
			if E.db.mui.tooltip.modelIcon then
				InsertModelFrame(self, unit)
			end
		end

		if UnitIsPlayer(unit) then
			if E.db.mui.tooltip.factionIcon then
				local faction = UnitFactionGroup(unit)
				if faction and faction ~= "Neutral" then
					InsertFactionFrame(self, faction)
				end
			end
		end

		if UnitIsBattlePet(unit) then
			if E.db.mui.tooltip.petIcon then
				local _, unit = self:GetUnit()
				InsertPetIcon(self, UnitBattlePetType(unit))

				-- Pet ID
				local speciesID = UnitBattlePetSpeciesID(unit)
				self:AddDoubleLine(PET..ID..":", ((MER.InfoColor..speciesID.."|r") or (MER.GreyColor..UNKNOWN.."|r")))

				-- Pet Species icon
				InsertPetIcon(self, UnitBattlePetType(unit))
			end
		end
	end
end)