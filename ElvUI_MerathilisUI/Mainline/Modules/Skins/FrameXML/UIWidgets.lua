local MER, E, L, V, P, G = unpack(select(2, ...))
local MERS = MER:GetModule('MER_Skins')
local S = E:GetModule('Skins')

local _G = _G
local pairs, unpack = pairs, unpack

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local r, g, b = unpack(E["media"].rgbvaluecolor)

local Type_StatusBar = _G.Enum.UIWidgetVisualizationType.StatusBar
local Type_CaptureBar = _G.Enum.UIWidgetVisualizationType.CaptureBar
local Type_SpellDisplay = _G.Enum.UIWidgetVisualizationType.SpellDisplay
local Type_DoubleStatusBar = _G.Enum.UIWidgetVisualizationType.DoubleStatusBar

local atlasColors = {
	["UI-Frame-Bar-Fill-Blue"] = {.2, .6, 1},
	["UI-Frame-Bar-Fill-Red"] = {.9, .2, .2},
	["UI-Frame-Bar-Fill-Yellow"] = {1, .6, 0},
	["objectivewidget-bar-fill-left"] = {.2, .6, 1},
	["objectivewidget-bar-fill-right"] = {.9, .2, .2},
	["EmberCourtScenario-Tracker-barfill"] = {.9, .2, .2},
}

local function ReplaceWidgetBarTexture(self, atlas)
	if atlasColors[atlas] then
		self:SetStatusBarTexture(E.media.normTex)
		self:SetStatusBarColor(unpack(atlasColors[atlas]))
	end
end

local function ReskinWidgetStatusBar(bar)
	if bar and not bar.styled then
		if bar.BG then bar.BG:SetAlpha(0) end
		if bar.BGLeft then bar.BGLeft:SetAlpha(0) end
		if bar.BGRight then bar.BGRight:SetAlpha(0) end
		if bar.BGCenter then bar.BGCenter:SetAlpha(0) end
		if bar.BorderLeft then bar.BorderLeft:SetAlpha(0) end
		if bar.BorderRight then bar.BorderRight:SetAlpha(0) end
		if bar.BorderCenter then bar.BorderCenter:SetAlpha(0) end
		if bar.Spark then bar.Spark:SetAlpha(0) end
		if bar.SparkGlow then bar.SparkGlow:SetAlpha(0) end
		if bar.BorderGlow then bar.BorderGlow:SetAlpha(0) end

		bar:CreateBackdrop('Transparent')
		ReplaceWidgetBarTexture(bar, bar:GetStatusBarAtlas())
		hooksecurefunc(bar, "SetStatusBarAtlas", ReplaceWidgetBarTexture)

		bar.styled = true
	end
end

local function ReskinDoubleStatusBarWidget(self)
	if not self.styled then
		ReskinWidgetStatusBar(self.LeftBar)
		ReskinWidgetStatusBar(self.RightBar)

		self.styled = true
	end
end

local function ReskinPVPCaptureBar(self)
	self.LeftBar:SetTexture(E.media.normTex)
	self.NeutralBar:SetTexture(E.media.normTex)
	self.RightBar:SetTexture(E.media.normTex)

	self.LeftBar:SetVertexColor(.2, .6, 1)
	self.NeutralBar:SetVertexColor(.8, .8, .8)
	self.RightBar:SetVertexColor(.9, .2, .2)

	self.LeftLine:SetAlpha(0)
	self.RightLine:SetAlpha(0)
	self.BarBackground:SetAlpha(0)
	self.Glow1:SetAlpha(0)
	self.Glow2:SetAlpha(0)
	self.Glow3:SetAlpha(0)

	if not self.backdrop then
		self:CreateBackdrop('Transparent')
		self.backdrop:SetPoint("TOPLEFT", self.LeftBar, -2, 2)
		self.backdrop:SetPoint("BOTTOMRIGHT", self.RightBar, 2, -2)
	end
end

local function ReskinSpellDisplayWidget(spell)
	if not spell.backdrop then
		spell.Border:SetAlpha(0)
		spell.DebuffBorder:SetAlpha(0)
		spell.backdrop = S:HandleIcon(spell.Icon)
	end
	spell.IconMask:Hide()
end

local function LoadSkin()
	if E.private.skins.blizzard.enable ~= true then return end

	hooksecurefunc(_G.UIWidgetTopCenterContainerFrame, "UpdateWidgetLayout", function(self)
		for _, widgetFrame in pairs(self.widgetFrames) do
			local widgetType = widgetFrame.widgetType
			if widgetType == Type_DoubleStatusBar then
				ReskinDoubleStatusBarWidget(widgetFrame)
			elseif widgetType == Type_SpellDisplay then
				ReskinSpellDisplayWidget(widgetFrame.Spell)
			elseif widgetType == Type_StatusBar then
				ReskinWidgetStatusBar(widgetFrame.Bar)
			end
		end
	end)

	hooksecurefunc(_G.UIWidgetBelowMinimapContainerFrame, "UpdateWidgetLayout", function(self)
		for _, widgetFrame in pairs(self.widgetFrames) do
			if widgetFrame.widgetType == Type_CaptureBar then
				ReskinPVPCaptureBar(widgetFrame)
			end
		end
	end)

	hooksecurefunc(_G.UIWidgetPowerBarContainerFrame, "UpdateWidgetLayout", function(self)
		for _, widgetFrame in pairs(self.widgetFrames) do
			if widgetFrame.widgetType == Type_StatusBar then
				ReskinWidgetStatusBar(widgetFrame.Bar)
			end
		end
	end)

	hooksecurefunc(_G.TopScenarioWidgetContainerBlock.WidgetContainer, "UpdateWidgetLayout", function(self)
		for _, widgetFrame in pairs(self.widgetFrames) do
			if widgetFrame.widgetType == Type_StatusBar then
				ReskinWidgetStatusBar(widgetFrame.Bar)
			end
		end
	end)

	hooksecurefunc(_G.BottomScenarioWidgetContainerBlock.WidgetContainer, "UpdateWidgetLayout", function(self)
		for _, widgetFrame in pairs(self.widgetFrames) do
			if widgetFrame.widgetType == Type_SpellDisplay then
				ReskinSpellDisplayWidget(widgetFrame.Spell)
			end
		end
	end)

	hooksecurefunc(_G.UIWidgetTemplateStatusBarMixin, "Setup", function(self)
		ReskinWidgetStatusBar(self.Bar)
	end)
end

S:AddCallback("MER_WidgetFrame", LoadSkin)
