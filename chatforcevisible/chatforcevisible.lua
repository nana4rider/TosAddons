function CHATFORCEVISIBLE_ON_INIT(addon, frame)
    frame:ShowWindow(0)
    local targetframe =  ui.GetFrame('sysmenu')
    targetframe:RunUpdateScript("CHATFORCEVISIBLE_TIMER", 1)
end

function CHATFORCEVISIBLE_TIMER()
    local chatframe =  ui.GetFrame('chatframe')
    chatframe:ShowWindow(1)
    return 1
end
