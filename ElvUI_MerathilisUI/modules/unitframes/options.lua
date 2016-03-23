local E, L, V, P, G = unpack(ElvUI);
local MER = E:GetModule('MerathilisUI');
local MUF = E:GetModule('MuiUnits');
local UF = E:GetModule('UnitFrames');

-- Cache global variables
-- Lua functions
local _G = _G
local tonumber = tonumber
local tinsert = table.insert
-- WoW API / Variables
local GetAddOnMetadata = GetAddOnMetadata

local function UnitFrames()
	E.Options.args.mui.args.unitframes = {
		order = 16,
		type = 'group',
		name = L['UnitFrames'],
		disabled = function() return not E.private.unitframe.enable end,
		args = {
			name = {
				order = 1,
				type = 'header',
				name = MER:cOption(L['UnitFrames']),
			},
			player = {
				order = 2,
				type = "group",
				name = L["Player Frame"],
				guiInline = true,
				disabled = function() return tonumber(GetAddOnMetadata("ElvUI_SLE", "Version")) >= 3.00 end,
				args = {
					rested = {
						order = 2,
						type = "group",
						name = L["Rest Icon"],
						guiInline = true,
						get = function(info) return E.db['mui']['unitframes']['unit']['player']['rested'][ info[#info] ] end,
						set = function(info, value) E.db['mui']['unitframes']['unit']['player']['rested'][ info[#info] ] = value; UF:Configure_RestingIndicator(_G["ElvUF_Player"]); E:StaticPopup_Show("PRIVATE_RL") end,
						args = {
							xoffset = { order = 1, type = 'range', name = L["X-Offset"], min = -300, max = 300, step = 1 },
							yoffset = { order = 2, type = 'range', name = L["Y-Offset"], min = -150, max = 150, step = 1 },
							size = { order = 3, type = 'range', name = L["Size"], min = 10, max = 60, step = 1 },
							texture = {
								order = 5,
								type = "select",
								name = L["Texture"],
								values = {
									["DEFAULT"] = L["Default"],
									["SVUI"] = "Supervillian UI",
								},
							},
						},
					},
				},
			},
		},
	}
end
tinsert(MER.Config, UnitFrames)