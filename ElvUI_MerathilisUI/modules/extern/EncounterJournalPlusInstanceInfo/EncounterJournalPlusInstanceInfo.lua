﻿--Cache global variables
--Lua functions
local _G = _G
local ipairs, pairs, type = ipairs, pairs, type
local tforeach, tinsert, tsort = table.foreach, table.insert, table.sort
local format, match = string.format, string.match
--WoW API / Variables
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceEncounterInfo = GetSavedInstanceEncounterInfo
local GetSavedInstanceInfo = GetSavedInstanceInfo
local RequestRaidInfo = RequestRaidInfo
--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: hooksecurefunc, EncounterJournal, EJ_GetInstanceInfo, EJ_GetDifficulty, EJ_GetInstanceInfo
-- GLOBALS: EncounterJournalPlus_InstanceInfo_OnLoad, EncounterJournalPlus_InstanceInfo_OnEvent

local function GetTableSize(tb)
	local size = 0

	if type(tb) == "table" then
		for i, val in pairs(tb) do
			size = size + 1
		end
	end

	return size
end

local function GetSavedInstances()
	local db = {
		["dungeons"] = {},
		["raids"] = {},
	}

	for i = 1, GetNumSavedInstances() do
		local name, id, _, difficulty, locked, extended, _, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
		local instances = isRaid and db.raids or db.dungeons

		if instances[name] == nil then
			instances[name] = {}
		end

		if locked or extended then
			tinsert(instances[name], {
				["index"] = i,
				["name"] = name,
				["difficulty"] = difficulty,
				["locked"] = locked,
				["extended"] = extended,
				["isRaid"] = isRaid,
				["maxPlayers"] = maxPlayers,
				["difficultyName"] = difficultyName,
				["numEncounters"] = numEncounters,
				["encounterProgress"] = encounterProgress,
			})

			tsort(instances[name], function(a, b)
				return a.difficulty < b.difficulty
			end)
		end
	end

	return db
end

local function GetSavedInstancesByDifficulty()
	local db = {}

	for i = 1, GetNumSavedInstances() do
		local name, id, _, difficulty, locked, extended = GetSavedInstanceInfo(i)

		if locked or extended then
			if db[name] == nil then
				db[name] = {}
			end

			db[name][difficulty] = {
				["index"] = i,
				["locked"] = locked,
				["extended"] = extended,
			}
		end
	end

	return db
end

local function GetNumSavedDBInstances(db, type)
	local size = 0

	for instanceName, instances in pairs(db[type]) do
		for difficulty, instance in pairs(instances) do
			if instance.locked or instance.extended then
				size = size + 1
			end
		end
	end

	return size
end

local function GetEncounterJournalInstanceTabs()
	if EncounterJournal ~= nil then
		return EncounterJournal.instanceSelect.dungeonsTab, EncounterJournal.instanceSelect.raidsTab
	end

	return nil, nil
end

local function GetEncounterJournalEncounterBossButtonKilledTexture(button)
	if button.killedTexture == nil then
		button.killedTexture = button:CreateTexture(nil, "OVERLAY")
		button.killedTexture:SetTexture("Interface\\EncounterJournal\\UI-EJ-HeroicTextIcon")
		button.killedTexture:SetPoint("RIGHT", -14, 0)
		button.killedTexture:SetAlpha(0.66)
	end

	button.killedTexture:Hide()

	return button.killedTexture
end

local function GetSavedInstanceBossEncounterInfo(instanceIndex)
	local info = {}

	for i = 1, 32 do
		local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo(instanceIndex, i)

		if bossName ~= nil then
			info[bossName] = isKilled
		else
			break
		end
	end

	return info
end

local function HandleEncounterJournalScrollInstances(func)
	if EncounterJournal then
		tforeach(EncounterJournal.instanceSelect.scroll.child, function(instanceButtonKey, instanceButton)
			if match(instanceButtonKey, "instance%d+") and type(instanceButton) == "table" then
				func(instanceButton)
			end
		end)
	end
end

local function ResetEncounterJournalScrollInstancesInfo()
	HandleEncounterJournalScrollInstances(function(instanceButton)
		if instanceButton.instanceInfoDifficulty == nil then
			instanceButton.instanceInfoDifficulty = instanceButton:CreateFontString(
				instanceButton:GetName() .. "InstanceInfoDifficulty",
				"OVERLAY",
				"QuestTitleFontBlackShadow"
			)
		end

		if instanceButton.instanceInfoEncounterProgress == nil then
			instanceButton.instanceInfoEncounterProgress = instanceButton:CreateFontString(
				instanceButton:GetName() .. "InstanceInfoEncounterProgress",
				"OVERLAY",
				"QuestTitleFontBlackShadow"
			)
		end

		local difficultyText = instanceButton.instanceInfoDifficulty
		local encounterProgressText = instanceButton.instanceInfoEncounterProgress
		local font = difficultyText:GetFont()

		difficultyText:SetPoint("BOTTOMLEFT", 9, 7)
		difficultyText:SetJustifyH("LEFT")
		difficultyText:SetFont(font, 12)
		difficultyText:Hide()

		encounterProgressText:SetPoint("BOTTOMRIGHT", -7, 7)
		encounterProgressText:SetJustifyH("RIGHT")
		encounterProgressText:SetFont(font, 12)
		encounterProgressText:Hide()
	end)
end

local function ResetEncounterJournalBossButtonKilledTexture()
	for i = 1, 32 do
		local button = _G["EncounterJournalBossButton" .. i]

		if button == nil then
			break
		end

		if button.killedTexture ~= nil then
			button.killedTexture:Hide()
		end
	end
end

local function RenderInstanceInfo(instanceButton, savedInstance)
	local difficultyButton = instanceButton.instanceInfoDifficulty
	local encounterProgressButton = instanceButton.instanceInfoEncounterProgress
	local difficulty = ""
	local encounterProgress = ""

	tforeach(savedInstance, function(index, instance)
		difficulty = difficulty .. "\n" .. instance.difficultyName
		encounterProgress = encounterProgress .. "\n" .. format("%s/%s", instance.encounterProgress, instance.numEncounters)
	end)

	difficultyButton:SetText(difficulty)
	difficultyButton:SetWidth(difficultyButton:GetStringWidth() * 1.25)
	difficultyButton:Show()

	encounterProgressButton:SetText(encounterProgress)
	encounterProgressButton:SetWidth(encounterProgressButton:GetStringWidth() * 1.25)
	encounterProgressButton:Show()
end

local function RenderEncounterJournalEncounterBossInfo(index)
	local info = GetSavedInstanceBossEncounterInfo(index)

	for i = 1, 32 do
		local button = _G["EncounterJournalBossButton" .. i]

		if button == nil then
			break
		end

		local texture = GetEncounterJournalEncounterBossButtonKilledTexture(button)

		if info[button:GetText()] then
			texture:Show()
		end
	end
end

local function RenderEncounterJournalEncounter(difficulty, name)
	local db = GetSavedInstancesByDifficulty()

	if db[name] ~= nil and db[name][difficulty] ~= nil then
		local info = db[name][difficulty]

		if info.locked or info.extended then
			RenderEncounterJournalEncounterBossInfo(info.index)
		end
	end
end

local function RenderEncounterJournalInstances()
	local savedDB = GetSavedInstances()
	local dungeonsTab, raidsTab = GetEncounterJournalInstanceTabs()
	local savedInstances = savedDB[(raidsTab ~= nil and not raidsTab:IsEnabled()) and "raids" or "dungeons"]

	HandleEncounterJournalScrollInstances(function(instanceButton)
		local instanceName = EJ_GetInstanceInfo(instanceButton.instanceID)
		local savedInstance = savedInstances[instanceName]

		if savedInstance ~= nil then
			RenderInstanceInfo(instanceButton, savedInstance)
		end
	end)
end

local function EncounterJournalInstanceTab_OnClick()
	for _, tab in ipairs({ "dungeonsTab", "raidsTab" }) do
		EncounterJournal.instanceSelect[tab]:HookScript("OnClick", function(self, button, down)
			ResetEncounterJournalScrollInstancesInfo()
			RequestRaidInfo()
		end)
	end
end

local function EncounterJournalTierDropdown_OnSelect()
	hooksecurefunc("EJ_SelectTier", function()
		ResetEncounterJournalScrollInstancesInfo()
		RequestRaidInfo()
	end)
end

local function EncounterJournalEncounter_OnHook()
	hooksecurefunc("EncounterJournal_DisplayInstance", function()
		local difficulty = EJ_GetDifficulty()
		local name = EJ_GetInstanceInfo(EncounterJournal.instanceID)

		ResetEncounterJournalBossButtonKilledTexture()
		RenderEncounterJournalEncounter(difficulty, name)
	end)
end

function EncounterJournalPlus_InstanceInfo_OnLoad(self)
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
end

function EncounterJournalPlus_InstanceInfo_OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Blizzard_EncounterJournal" then
		hooksecurefunc(EncounterJournal, "Show", function()
			local dungeonsTab, raidsTab = GetEncounterJournalInstanceTabs()
			local encounter = EncounterJournal.encounter

			if not dungeonsTab:IsEnabled() or not raidsTab:IsEnabled() or encounter:IsShown() then
				ResetEncounterJournalScrollInstancesInfo()
				RequestRaidInfo()
			end
		end)

		EncounterJournalEncounter_OnHook()
		EncounterJournalTierDropdown_OnSelect()
		EncounterJournalInstanceTab_OnClick()
	elseif event == "UPDATE_INSTANCE_INFO" then
		RenderEncounterJournalInstances()
	end
end