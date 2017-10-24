local MER, E, L, V, P, G = unpack(select(2, ...))
local MERS = E:GetModule("muiSkins")
local S = E:GetModule("Skins")

--Cache global variables
local _G = _G
--WoW API / Variables

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS:

local function styleGuild()
	if E.private.skins.blizzard.enable ~= true or E.private.skins.blizzard.guild ~= true or E.private.muiSkins.blizzard.guild ~= true then return end

	MERS:CreateGradient(_G["GuildFrame"])
	MERS:CreateStripes(_G["GuildFrame"])
end

S:AddCallbackForAddon("Blizzard_GuildUI", "mUIGuild", styleGuild)