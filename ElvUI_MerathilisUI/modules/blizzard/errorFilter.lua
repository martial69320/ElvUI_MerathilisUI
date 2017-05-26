local MER, E, L, V, P, G = unpack(select(2, ...))

-- Wow Lua
local _G = _G

-- Wow API
local UIErrorsFrame = _G["UIErrorsFrame"]

-- Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: SLASH_ERROR1

-- Clear UIErrorsFrame(module from Kousei by Haste)
if P.mui.error.white == true or P.mui.error.black == true then
	local MERErrors = CreateFrame("Frame")
	MERErrors:SetScript("OnEvent", function(self, event, _, text)
		if P.mui.error.white == true and P.mui.error.black == false then
			if MER.ErrorWhiteList[text] then
				UIErrorsFrame:AddMessage(text, 1, .1, .1)
			else
				L["Info"]["Errors"] = text
			end
		elseif P.mui.error.black == true and P.mui.error.white == false then
			if MER.ErrorBlackList[text] then
				L["Info"]["Errors"] = text
			else
				UIErrorsFrame:AddMessage(text, 1, .1, .1)
			end
		end
	end)

	SlashCmdList.ERROR = function()
		UIErrorsFrame:AddMessage(L["Info"]["Errors"], 1, .1, .1)
	end

	SLASH_ERROR1 = "/error"
	UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	MERErrors:RegisterEvent("UI_ERROR_MESSAGE")
end

-- Clear all UIErrors frame in combat
if P.mui.error.combat == true then
	local CombatErrors = CreateFrame("Frame")
	local OnEvent = function(self, event, ...) self[event](self, event, ...) end
	CombatErrors:SetScript("OnEvent", OnEvent)

	local function PLAYER_REGEN_DISABLED()
		UIErrorsFrame:Hide()
	end
	local function PLAYER_REGEN_ENABLED()
		UIErrorsFrame:Show()
	end

	CombatErrors:RegisterEvent("PLAYER_REGEN_DISABLED")
	CombatErrors["PLAYER_REGEN_DISABLED"] = PLAYER_REGEN_DISABLED
	CombatErrors:RegisterEvent("PLAYER_REGEN_ENABLED")
	CombatErrors["PLAYER_REGEN_ENABLED"] = PLAYER_REGEN_ENABLED
end