local addonName = "JoyForty"
local addonCommand = "joy40"
local author = "Chobby"

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {}
local g = _G["ADDONS"][author][addonName]

g.settingsFileLoc = string.format("../addons/%s/settings.json", string.lower(addonName))
g.padslotBoxes = {"L1R1_slot_Set1", "L1_slot_Set1", "L2_slot_Set1", "R1_slot_Set1", "R2_slot_Set1", "L1R1_slot_Set2", "L1_slot_Set2", "L2_slot_Set2", "R1_slot_Set2", "R2_slot_Set2"}

local acutil = require('acutil')

if not g.loaded then
    g.settings = {enable = true, key = "JOY_BTN_11"}
end

CHAT_SYSTEM(string.format("%s.lua is loaded", addonName))

function JOYFORTY_SAVE_SETTINGS()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end

function JOYFORTY_ON_INIT(addon, frame)
    g.addon = addon
    
    acutil.slashCommand("/" .. addonCommand, JOYFORTY_PROCESS_COMMAND)
    if not g.loaded then
        local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
        if err then
            CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName))
        else
            g.settings = t
        end
        g.loaded = true
    end
    
    JOYFORTY_SAVE_SETTINGS()
    
    if g.settings.enable then
        acutil.setupHook(JOYSTICK_QUICKSLOT_EXECUTE_HOOK, "JOYSTICK_QUICKSLOT_EXECUTE")
        acutil.setupHook(UPDATE_JOYSTICK_INPUT_HOOK, "UPDATE_JOYSTICK_INPUT")
        acutil.setupHook(JOYSTICK_QUICKSLOT_SWAP_HOOK, "JOYSTICK_QUICKSLOT_SWAP")
        acutil.setupHook(QUICKSLOT_INIT_HOOK, "QUICKSLOT_INIT")
        addon:RegisterMsg("GAME_START_3SEC", "JOYFORTY_INIT")
    end
end

function JOYFORTY_INIT()
    QUICKSLOT_INIT_HOOK()
    JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT()
end

function JOYFORTY_PROCESS_COMMAND(command)
    local cmd = ""
    
    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        CHAT_SYSTEM("/" .. addonCommand .. " [on|off] : toggle on or off")
        CHAT_SYSTEM("/" .. addonCommand .. " key [key] : set shiftkey")
    end
    
    if cmd == "on" then
        g.settings.enable = true
        CHAT_SYSTEM(string.format("[%s] is enable", addonName))
        JOYFORTY_SAVE_SETTINGS()
        return 
    elseif cmd == "off" then
        g.settings.enable = false
        CHAT_SYSTEM(string.format("[%s] is disable", addonName))
        JOYFORTY_SAVE_SETTINGS()
        return 
    elseif cmd == "key" then
        if #command > 0 then
            g.settings.key = table.remove(command, 1)
            CHAT_SYSTEM(string.format("set key %s", g.settings.key))
            JOYFORTY_SAVE_SETTINGS()
        end
        return 
    end
    
    CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName))
end

function JOYFORTY_SET_PADSLOT_SKIN(frame, activebox)
    for i, box in pairs(g.padslotBoxes) do
        local gbox = frame:GetChildRecursively(box)
        gbox:SetSkinName((box == activebox) and padslot_onskin or padslot_offskin)
    end
end

function JOYFORTY_GET_STANDARD_SLOT_INDEX(slotIndex)
    local inputL1 = joystick.IsKeyPressed("JOY_BTN_5")
    local inputR1 = joystick.IsKeyPressed("JOY_BTN_6")
    local inputShift
    if string.match(g.settings.key, "^JOY_") then
        inputShift = joystick.IsKeyPressed(g.settings.key)
    else
        inputShift = keyboard.IsKeyPressed(g.settings.key)
    end
    
    -- L1R1
    if inputL1 == 1 and inputR1 == 1 then
        if slotIndex >= 0 and slotIndex <= 3 then
            slotIndex = slotIndex + 8
        elseif slotIndex >= 12 and slotIndex <= 15 then
            slotIndex = slotIndex - 4
        end
    end
    -- Set1/2
    if inputShift == 1 then
        slotIndex = slotIndex + 20
    end
    
    return slotIndex
end

function JOYSTICK_QUICKSLOT_EXECUTE_HOOK(slotIndex)
    local qframe = ui.GetFrame('joystickquickslot')
    
    -- (。-ω-)
    local restframe = ui.GetFrame('joystickrestquickslot')
    if restframe:IsVisible() == 1 then
        REST_JOYSTICK_SLOT_USE(restframe, slotIndex)
        return 
    end
    
    slotIndex = JOYFORTY_GET_STANDARD_SLOT_INDEX(slotIndex)
    
    local slot = qframe:GetChildRecursively("slot" .. slotIndex + 1)
    QUICKSLOTNEXPBAR_SLOT_USE(qframe, slot, 'None', 0)
end

-- @Override hotkeyabilityforjoy
function JOYSTICK_QUICKSLOT_EXECUTE_EVENT(addonFrame, eventMsg)
    local slotIndex = JOYFORTY_GET_STANDARD_SLOT_INDEX(acutil.getEventArgs(eventMsg))
    local key = tostring(slotIndex + 1)
    local value = _G['ADDONS']['HOTKEYABILITYFORJOY'].setting[key]
    if not value then
        return 
    end
    
    if value[2] == 'Pose' then
        local poseCls = GetClassByType('Pose', value[1])
        if poseCls ~= nil then
            control.Pose(poseCls.ClassName)
        end
    elseif value[2] == 'Macro' then
        EXEC_CHATMACRO(tonumber(value[1]))
    elseif value[2] == 'Ability' then
        HOTKEYABILITY_TOGGLE_ABILITIY(key, value[1])
    end
end

function UPDATE_JOYSTICK_INPUT_HOOK(frame)
    if IsJoyStickMode() == 0 then
        return 
    end
    
    local inputL1 = joystick.IsKeyPressed("JOY_BTN_5")
    local inputL2 = joystick.IsKeyPressed("JOY_BTN_7")
    local inputR1 = joystick.IsKeyPressed("JOY_BTN_6")
    local inputR2 = joystick.IsKeyPressed("JOY_BTN_8")
    local inputL1L2 = joystick.IsKeyPressed("JOY_L1L2")
    local inputShift
    if string.match(g.settings.key, "^JOY_") then
        inputShift = joystick.IsKeyPressed(g.settings.key)
    else
        inputShift = keyboard.IsKeyPressed(g.settings.key)
    end
    local set1Btn = frame:GetChildRecursively("L2R2_Set1")
    local set2Btn = frame:GetChildRecursively("L2R2_Set2")
    
    if joystick.IsKeyPressed("JOY_UP") == 1 and inputL1L2 == 1 then
        ON_RIDING_VEHICLE(1)
    elseif joystick.IsKeyPressed("JOY_DOWN") == 1 and inputL1L2 == 1 then
        ON_RIDING_VEHICLE(0)
    elseif joystick.IsKeyPressed("JOY_LEFT") == 1 and inputL1L2 == 1 then
        COMPANION_INTERACTION(2)
    elseif joystick.IsKeyPressed("JOY_RIGHT") == 1 and inputL1L2 == 1 then
        COMPANION_INTERACTION(1)
    end
    
    local slot
    if inputShift == 0 then
        slot = 1
        set1Btn:SetSkinName(setButton_onSkin)
        set2Btn:SetSkinName(setButton_offSkin)
    else
        slot = 2
        set1Btn:SetSkinName(setButton_offSkin)
        set2Btn:SetSkinName(setButton_onSkin)
    end
    
    if inputL1 == 1 and inputR1 == 1 then
        -- L1R1
        JOYFORTY_SET_PADSLOT_SKIN(frame, "L1R1_slot_Set" .. slot)
    elseif inputL1 == 1 and inputL2 == 0 and inputR1 == 0 then
        -- L1 
        JOYFORTY_SET_PADSLOT_SKIN(frame, "L1_slot_Set" .. slot)
    elseif inputL2 == 1 and inputL1 == 0 and inputR2 == 0 then
        -- L2
        if SYSMENU_JOYSTICK_IS_OPENED() == 1 then
            SYSMENU_JOYSTICK_MOVE_LEFT()
        end
        JOYFORTY_SET_PADSLOT_SKIN(frame, "L2_slot_Set" .. slot)
    elseif inputR1 == 1 and inputR2 == 0 and inputL1 == 0 then
        -- R1
        JOYFORTY_SET_PADSLOT_SKIN(frame, "R1_slot_Set" .. slot)
    elseif inputR2 == 1 and inputR1 == 0 and inputL2 == 0 then
        -- R2
        if SYSMENU_JOYSTICK_IS_OPENED() == 1 then
            SYSMENU_JOYSTICK_MOVE_RIGHT()
        end
        JOYFORTY_SET_PADSLOT_SKIN(frame, "R2_slot_Set" .. slot)
    else
        JOYFORTY_SET_PADSLOT_SKIN(frame, nil)
    end
end

function JOYSTICK_QUICKSLOT_SWAP_HOOK(test)
    -- NOP
end

function QUICKSLOT_INIT_HOOK(frame, msg, argStr, argNum)
    local qframe = ui.GetFrame('joystickquickslot')
    local set1 = qframe:GetChild("Set1")
    local set2 = qframe:GetChild("Set2")
    local set1Btn = qframe:GetChildRecursively("L2R2_Set1")
    local set2Btn = qframe:GetChildRecursively("L2R2_Set2")
    local l2r2Label = qframe:GetChildRecursively("L2R2")
    
    qframe:Resize(1920, 270)
    qframe:SetOffset(0, 810)
    set2:SetOffset(0, 120)
    set1:ShowWindow(1)
    set2:ShowWindow(1)
    set1Btn:SetSkinName(setButton_onSkin)
    set2Btn:SetSkinName(setButton_onSkin)
    l2r2Label:ShowWindow(0)
    
    UPDATE_JOYSTICK_INPUT_HOOK(qframe)
    JOYSTICK_QUICKSLOT_UPDATE_ALL_SLOT()
end
