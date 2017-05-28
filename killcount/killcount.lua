local author = "Chobby"
local addonName = "KillCount"
local addonNameUpper = string.upper(addonName)
local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][author] = _G["ADDONS"][author] or {}
_G["ADDONS"][author][addonNameUpper] = _G["ADDONS"][author][addonNameUpper] or {}
local g = _G["ADDONS"][author][addonNameUpper]
local acutil = require('acutil')

g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower)

if not g.loaded then
    g.settings = {position = {x = 500, y = 500}, million = false}
end

function KILLCOUNT_ON_INIT(addon, frame)
    g.addon = addon
    g.frame = frame
    
    if not g.loaded then
        local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
        if err then
            --設定ファイル読み込み失敗時処理
            CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName))
        else
            --設定ファイル読み込み成功時処理
            g.settings = t
        end
        g.loaded = true
    end

    frame:SetEventScript(ui.LBUTTONUP, "KILLCOUNT_END_DRAG")
    frame:ShowWindow(1)
    frame:Move(0, 0)
    frame:SetOffset(g.settings.position.x, g.settings.position.y)
    frame:RunUpdateScript("KILLCOUNT_TIMER", 1)
end

function KILLCOUNT_TIMER()
    local nowpoint = GetAchievePoint(GetMyPCObject(), 'MonKill')
    local text = g.frame:CreateOrGetControl("richtext", "text", 5, 10, 0, 0)
    tolua.cast(text, "ui::CRichText")
    text:SetText("{@st48}" .. nowpoint)
    
    if not g.settings.million and nowpoint >= 1000000 then
        ui.MsgBox("Congratulations!!", "", "Nope")
        g.settings.million = true
        KILLCOUNT_SAVE_SETTINGS()
    end
    
    return 1
end

function KILLCOUNT_END_DRAG()
    g.settings.position.x = g.frame:GetX()
    g.settings.position.y = g.frame:GetY()
    KILLCOUNT_SAVE_SETTINGS()
end

function KILLCOUNT_SAVE_SETTINGS()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end
