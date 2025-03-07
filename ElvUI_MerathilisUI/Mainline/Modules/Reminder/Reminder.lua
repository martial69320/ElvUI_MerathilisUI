local MER, E, L, V, P, G = unpack(select(2, ...))
local module = MER:GetModule('MER_Reminder')
local LCG = LibStub('LibCustomGlow-1.0')
local UF = E:GetModule('UnitFrames')
local S = E:GetModule('Skins')

local _G = _G
local pairs, select, type, unpack= pairs, select, type, unpack

local AuraUtil_FindAuraByName = AuraUtil.FindAuraByName
local C_PaperDollInfo_OffhandHasWeapon = C_PaperDollInfo.OffhandHasWeapon
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local GetSpecialization = GetSpecialization
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsUsableSpell = IsUsableSpell
local UnitInVehicle = UnitInVehicle
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitLevel = UnitLevel

_Reminder = module
_CreatedReminders = {}

function module:PlayerHasFilteredBuff(frame, db, checkPersonal)
	for buff, value in pairs(db) do
		if value == true then
			local name = GetSpellInfo(buff)
			local _, icon, _, _, _, _, unitCaster, _, _, _ = AuraUtil_FindAuraByName(name, "player", "HELPFUL")

			if checkPersonal then
				if (name and icon and unitCaster == "player") then
					return true
				end
			else
				if (name and icon) then
					return true
				end
			end
		end
	end
	return false
end

function module:PlayerHasFilteredDebuff(frame, db)
	for debuff, value in pairs(db) do
		if value == true then
			local name = GetSpellInfo(debuff)
			local _, icon, _, _, _, _, unitCaster, _, _, _ = AuraUtil_FindAuraByName(name, "player", "HARMFUL")

			if (name and icon) then
				return true
			end
		end
	end
	return false
end

function module:CanSpellBeUsed(id)
	local name = GetSpellInfo(id)
	local start, duration, enabled = GetSpellCooldown(name)
	if enabled == 0 or start == nil or duration == nil then
		return false
	elseif start > 0 and duration > 1.5 then	--On Cooldown
		return false
	else --Off Cooldown
		return true
	end
end

function module:ReminderIcon_OnUpdate(elapsed)
	if self.ForceShow and self.icon:GetTexture() then return; end
	if(self.elapsed and self.elapsed > 0.2) then
		local db = MER.ReminderList[E.myclass][self.groupName]
		if not db or not db.enable or UnitIsDeadOrGhost("player") then return; end
		if db.CDSpell then
			local filterCheck = module:FilterCheck(self)
			local name = GetSpellInfo(db.CDSpell)
			local start, duration, enabled = GetSpellCooldown(name)
			if(duration and duration > 0) then
				self.cooldown:SetCooldown(start, duration)
				self.cooldown:Show()
			else
				self.cooldown:Hide()
			end

			if module:CanSpellBeUsed(db.CDSpell) and filterCheck then
				if db.OnCooldown == "HIDE" then
					module:UpdateColors(self, db.CDSpell)
					module.ReminderIcon_OnEvent(self)
				else
					self:SetAlpha(db.cdFade or 0)
				end
			elseif filterCheck then
				if db.OnCooldown == "HIDE" then
					self:SetAlpha(db.cdFade or 0)
				else
					module:UpdateColors(self, db.CDSpell)
					module.ReminderIcon_OnEvent(self)
				end
			else
				self:SetAlpha(0)
			end

			self.elapsed = 0
			return
		end

		if db.spellGroup then
			for buff, value in pairs(db.spellGroup) do
				if value == true and module:CanSpellBeUsed(buff) then
					self:SetScript("OnUpdate", nil)
					module.ReminderIcon_OnEvent(self)
				end
			end
		end

		self.elapsed = 0
	else
		self.elapsed = (self.elapsed or 0) + elapsed
	end
end

function module:FilterCheck(frame, isReverse)
	local _, instanceType = IsInInstance()
	local roleCheck, treeCheck, combatCheck, instanceCheck, PVPCheck, talentCheck

	local db = MER.ReminderList[E.myclass][frame.groupName]

	if db.role then
		if db.role == E:GetPlayerRole() or db.role == "ANY" then
			roleCheck = true
		else
			roleCheck = nil
		end
	else
		roleCheck = true
	end

	if db.tree then
		if db.tree == GetSpecialization() or db.tree == "ANY" then
			treeCheck = true
		else
			treeCheck = nil
		end
	else
		treeCheck = true
	end

	if db.combat then
		if InCombatLockdown() then
			combatCheck = true
		else
			combatCheck = nil
		end
	else
		combatCheck = true
	end

	if db.instance and (instanceType == "party" or instanceType == "raid") then
		instanceCheck = true
	else
		instanceCheck = nil
	end

	if db.pvp and (instanceType == "arena" or instanceType == "pvp") then
		PVPCheck = true
	else
		PVPCheck = nil
	end

	if not db.pvp and not db.instance then
		PVPCheck = true
		instanceCheck = true
	end

	if isReverse and (combatCheck or instanceCheck or PVPCheck) then
		return true
	elseif roleCheck and treeCheck and (combatCheck or instanceCheck or PVPCheck) then
		return true
	else
		return false
	end
end

function module:ReminderIcon_OnEvent(event, unit)
	if (event == "UNIT_AURA" and unit ~= "player") then return end

	local db = MER.ReminderList[E.myclass][self.groupName]

	self.cooldown:Hide()
	self:SetAlpha(0)
	self.icon:SetTexture(nil)

	if not db or not db.enable or (not db.spellGroup and not db.weaponCheck and not db.CDSpell) or UnitIsDeadOrGhost("player") then
		self:SetScript("OnUpdate", nil)
		self:SetAlpha(0)
		self.icon:SetTexture(nil)

		if not db then
			_CreatedReminders[self.groupName] = nil
		end
		return
	end

	--Level Check
	if db.level and UnitLevel("player") < db.level and not self.ForceShow then return end

	--Negate Spells Check
	if db.negateGroup and module:PlayerHasFilteredBuff(self, db.negateGroup) and not self.ForceShow then return end

	local hasOffhandWeapon = C_PaperDollInfo_OffhandHasWeapon()
	local hasMainHandEnchant, _, _, hasOffHandEnchant, _, _ = GetWeaponEnchantInfo()
	local hasBuff, hasDebuff
	if db.spellGroup and not db.CDSpell then
		for buff, value in pairs(db.spellGroup) do
			if value == true then
				local name = GetSpellInfo(buff)
				local usable, nomana = IsUsableSpell(name)
				if usable and not module:CanSpellBeUsed(buff) then
					self:SetScript("OnUpdate", module.ReminderIcon_OnUpdate)
					return
				end

				if (usable or nomana) or not db.strictFilter or self.ForceShow then
					self.icon:SetTexture(select(3, GetSpellInfo(db.spellGroup.defaultIcon)))
					break
				end
			end
		end

		if (not self.icon:GetTexture() and event == "PLAYER_ENTERING_WORLD") then
			self:UnregisterAllEvents()
			self:RegisterEvent("UNIT_AURA")
			self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
			if E.Retail then
				self:RegisterEvent("PLAYER_TALENT_UPDATE")
			end
			if db.combat then
				self:RegisterEvent("PLAYER_REGEN_ENABLED")
				self:RegisterEvent("PLAYER_REGEN_DISABLED")
			end

			if db.instance or db.pvp then
				self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			end

			if db.role then
				self:RegisterEvent("UNIT_INVENTORY_CHANGED")
			end
			return
		end

		hasBuff, hasDebuff = module:PlayerHasFilteredBuff(self, db.spellGroup, db.personal), module:PlayerHasFilteredDebuff(self, db.spellGroup)
	end

	if db.weaponCheck then
		self:UnregisterAllEvents()
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")

		if not hasOffhandWeapon and hasMainHandEnchant then
			self.icon:SetTexture(GetInventoryItemTexture("player", 16))
		else
			if not hasOffHandEnchant then
				self.icon:SetTexture(GetInventoryItemTexture("player", 17))
			end

			if not hasMainHandEnchant then
				self.icon:SetTexture(GetInventoryItemTexture("player", 16))
			end
		end

		if db.combat then
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
		end

		if db.instance or db.pvp then
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		end

		if db.role then
			self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end
	end

	if db.CDSpell then
		if type(db.CDSpell) == "boolean" then return end
		local name = GetSpellInfo(db.CDSpell)
		local usable, nomana = IsUsableSpell(name)
		if not usable then return end

		self:SetScript("OnUpdate", module.ReminderIcon_OnUpdate)

		self.icon:SetTexture(select(3, GetSpellInfo(db.CDSpell)))

		self:UnregisterAllEvents()
	end

	if self.ForceShow and self.icon:GetTexture() then
		self:SetAlpha(1)
		return
	elseif self.ForceShow then
		MER:Print("Attempted to show a reminder icon that does not have any spells. You must add a spell first.")
		return
	end

	if E.Retail then
		if not self.icon:GetTexture() or UnitInVehicle("player") then
			return
		end
	end

	local filterCheck = module:FilterCheck(self)
	local reverseCheck = module:FilterCheck(self, true)

	if db.CDSpell then
		if filterCheck then
			self:SetAlpha(1)
		end
		return
	end

	local activeTree = E.Retail and GetSpecialization()
	if db.spellGroup and not db.weaponCheck then
		if filterCheck and ((not hasBuff) and (not hasDebuff)) and not db.reverseCheck then
			self:SetAlpha(1)
		elseif reverseCheck and db.reverseCheck and (hasBuff or hasDebuff) and not (db.talentTreeException == activeTree) then
			self:SetAlpha(1)
		elseif reverseCheck and db.reverseCheck and ((not hasBuff) and (not hasDebuff)) and (db.talentTreeException == activeTree) then
			self:SetAlpha(1)
		end
	elseif db.weaponCheck then
		if filterCheck then
			if not hasOffhandWeapon and not hasMainHandEnchant then
				self:SetAlpha(1)
				self.icon:SetTexture(GetInventoryItemTexture("player", 16))
			elseif hasOffhandWeapon and (not hasMainHandEnchant or not hasOffHandEnchant) then
				if not hasMainHandEnchant then
					self.icon:SetTexture(GetInventoryItemTexture("player", 16))
				else
					self.icon:SetTexture(GetInventoryItemTexture("player", 17))
				end
				self:SetAlpha(1)
			end
		end
	end

	local r, g, b = unpack(E["media"].rgbvaluecolor)
	local color = {r, g, b, 1}
	if self:GetAlpha() == 1 then
		LCG.PixelGlow_Start(self.overlay, color, nil, 0.25, nil, 1)
	else
		LCG.PixelGlow_Stop(self.overlay)
	end
end

function module:CreateReminder(name, index)
	if _CreatedReminders[name] or not E.db.unitframe.units.player.enable then return end

	local size = module.db.size or 30
	local ElvFrame = _G.ElvUF_Player

	local frame = CreateFrame("Button", "MER_ReminderIcon"..index, E.UIParent)
	frame:Size(size or (ElvFrame:GetHeight() -4))
	frame:SetPoint("RIGHT", ElvFrame, "LEFT", -3, 0)
	frame:SetFrameStrata(ElvFrame:GetFrameStrata())
	frame.groupName = name

	E:CreateMover(frame, "MER_ReminderMover", L["Reminders"], nil, nil, nil, "ALL,SOLO,MERATHILISUI", nil, 'mui,modules,reminder')

	frame.icon = frame:CreateTexture(nil, "OVERLAY")
	frame.icon:SetAllPoints()
	S:HandleIcon(frame.icon)
	frame:EnableMouse(false)
	frame:SetAlpha(0)

	-- Used for Glow
	frame.overlay = CreateFrame("Button", nil, frame)
	frame.overlay:SetOutside(frame, 2, 2)

	local cd = CreateFrame("Cooldown", nil, frame)
	cd:SetAllPoints(frame.icon)
	E:RegisterCooldown(cd)
	frame.cooldown = cd

	frame:RegisterUnitEvent("UNIT_AURA", "player")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", module.ReminderIcon_OnEvent)

	_CreatedReminders[name] = frame
end

function module:CheckForNewReminders()
	local db = MER.ReminderList[E.myclass]
	if not db then return end

	local index = 0
	for groupName, _ in pairs(db) do
		index = index + 1
		module:CreateReminder(groupName, index)
	end
end

function module:Initialize()
	module.db = E.db.mui.reminder
	MER:RegisterDB(module, "reminder")
	if module.db.enable ~= true then return; end

	hooksecurefunc(UF, 'LoadUnits', module.CheckForNewReminders)

	module.initialized = true
end

MER:RegisterModule(module:GetName())
