local addonName = ...
local frame = CreateFrame("Frame")
local overlays = {}
local maxButtonsCount = 12
local prefixes = {
	"ActionButton",
	"MultiBarBottomLeftButton",
	"MultiBarBottomRightButton",
	"MultiBarRightButton",
	"MultiBarLeftButton",
	"MultiBar5Button",
	"MultiBar6Button",
	"MultiBar7Button",
	"PetActionButton",
	"ShapeshiftButton",
	"BonusActionButton",
	"PossessButton",
}

local function HideTooltip()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

---Returns the action slot for the specified secure button.
---@return number|nil
local function GetActionForButton(button)
	local action = button.action

	if type(action) == "number" then
		return action
	end

	action = button:GetAttribute("action")

	if type(action) == "number" then
		return action
	end

	return nil
end

---Shows the gametooltip for the spell/action of the secure button.
---@param overlay any
local function ShowTooltip(overlay)
	if not GameTooltip then
		return
	end

	if GameTooltip_SetDefaultAnchor then
		-- use the default anchor position where possible
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	else
		GameTooltip:SetOwner(overlay, "ANCHOR_RIGHT")
	end

	local prefix = overlay.Prefix
	local id = overlay.Id
	local button = overlay.Button

	if prefix == "PetActionButton" then
		GameTooltip:SetPetAction(id)
		GameTooltip:Show()
		return
	end

	if prefix == "ShapeshiftButton" then
		GameTooltip:SetShapeshift(id)
		GameTooltip:Show()
		return
	end

	if prefix == "PossessButton" then
		if GameTooltip.SetPossession then
			GameTooltip:SetPossession(id)
			GameTooltip:Show()
			return
		end
	end

	local actionSlot = GetActionForButton(button)

	if actionSlot then
		GameTooltip:SetAction(actionSlot)
		GameTooltip:Show()
		return
	end

	GameTooltip:Hide()
end

local function ApplyHoverVisuals(button, isOver)
	if button.LockHighlight and button.UnlockHighlight then
		if isOver then
			button:LockHighlight()
		else
			button:UnlockHighlight()
		end
	end

	local hl = button.GetHighlightTexture and button:GetHighlightTexture()
	if hl then
		if isOver then
			hl:Show()
		else
			hl:Hide()
		end
	end

	if button.hoverTexture then
		if isOver then
			button.hoverTexture:Show()
		else
			button.hoverTexture:Hide()
		end
	end
end

---Creates the overlay button ontop of the existing button.
---@param button table
---@param prefix string
---@param id number
---@return table|nil
local function EnsureOverlay(button, prefix, id)
	local existing = overlays[button]

	if existing then
		return existing
	end

	local name = button:GetName()
	if not name then
		return nil
	end

	local overlay = CreateFrame("Button", name .. "MouseDownOverlay", button, "SecureActionButtonTemplate")
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 10)
	overlay:EnableMouse(true)
	overlay:RegisterForClicks("AnyDown")
	overlay:SetAttribute("type", "click")
	overlay:SetAttribute("clickbutton", button)
	overlay:Show()

	overlay.Button = button
	overlay.Prefix = prefix
	overlay.Id = id

	overlay:SetScript("OnEnter", function()
		ApplyHoverVisuals(button, true)
		ShowTooltip(overlay)
	end)

	overlay:SetScript("OnLeave", function()
		ApplyHoverVisuals(button, false)
		HideTooltip()
	end)

	overlays[button] = overlay
	return overlay
end

local function Run()
	for _, prefix in ipairs(prefixes) do
		for i = 1, maxButtonsCount do
			local btn = _G[prefix .. i]

			if btn then
				EnsureOverlay(btn, prefix, i)
			end
		end
	end
end

local function OnEvent(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= addonName then
			return
		end

		-- Wait until the UI has fully built the action bars
		frame:RegisterEvent("PLAYER_LOGIN")
		return
	end

	if event == "PLAYER_LOGIN" then
		Run()
		return
	end

	if event == "PLAYER_REGEN_ENABLED" then
		frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
		Run()
		return
	end

	if InCombatLockdown() then
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	Run()
end

frame:RegisterEvent("ADDON_LOADED")

-- Bar change events
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
frame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("UPDATE_POSSESS_BAR")
frame:RegisterEvent("PET_BAR_UPDATE")
frame:RegisterEvent("UNIT_PET")

frame:SetScript("OnEvent", OnEvent)
