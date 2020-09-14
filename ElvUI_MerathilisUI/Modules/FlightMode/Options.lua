local MER, E, L, V, P, G = unpack(select(2, ...))
local module = MER:GetModule("MER_FlightMode")

local format = string.format
local tinsert = table.insert

local function FlightMode()
	local ACH = E.Libs.ACH

	E.Options.args.mui.args.modules.args.cvars = {
		type = "group",
		name = E.NewSign..L["FlightMode"],
		get = function(info) return E.db.mui.flightMode[ info[#info] ] end,
		set = function(info, value) E.db.mui.flightMode[ info[#info] ] = value; E:StaticPopup_Show("PRIVATE_RL"); end,
		args = {
			header = ACH:Header(MER:cOption(L["FlightMode"]), 1),
			credits = {
				order = 2,
				type = "group",
				name = MER:cOption(L["Credits"]),
				guiInline = true,
				args = {
					tukui = ACH:Description(format("|cff00c0faBenikUI|r"), 1),
				},
			},
			enable = {
				order = 3,
				type = "toggle",
				name = L["Enable"],
			},
		},
	}
end
tinsert(MER.Config, FlightMode)
