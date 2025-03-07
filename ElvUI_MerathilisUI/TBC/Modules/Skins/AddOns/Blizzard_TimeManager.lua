local MER, E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule('Skins')

--Cache global variables
local _G = _G
--WoW API / Variables
-- GLOBALS:

local function LoadSkin()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.timemanager) or E.private.muiSkins.blizzard.timemanager ~= true then return end

	local TimeManagerFrame = _G.TimeManagerFrame
	TimeManagerFrame.backdrop:Styling()
	MER:CreateBackdropShadow(TimeManagerFrame)

	local StopwatchFrame = _G.StopwatchFrame
	StopwatchFrame.backdrop:Styling()
	MER:CreateBackdropShadow(StopwatchFrame)
end

S:AddCallbackForAddon("Blizzard_TimeManager", "mUITimeManager", LoadSkin)
