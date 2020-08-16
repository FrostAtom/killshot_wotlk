local MESSAGE = "says: Hey $name, nice dick. Killed by $spell $damagedmg. Streak #$streak!"
local ADDON_NAME = ...
local SOUNDS_PATH = "Interface\\AddOns\\"..ADDON_NAME.."\\sounds\\"
local MESSAGE_MAX_LEN = 128
local bit,math = bit,math
local COMBATLOG_FILTER_HOSTILE_PLAYER = bit.bor(COMBATLOG_OBJECT_REACTION_HOSTILE,COMBATLOG_OBJECT_TYPE_PLAYER)
local COMBATLOG_FILTER_MY_PET = COMBATLOG_FILTER_MY_PET
local COMBATLOG_FILTER_ME = COMBATLOG_FILTER_ME
local select = select
local SendChatMessage = SendChatMessage
local GetSpellLink = GetSpellLink

local frame = CreateFrame("frame")
local killstreak


function frame:Kill(unitName,spellID,damage)
    local spellLink = GetSpellLink(spellID)
    killstreak = killstreak + 1

    local message = MESSAGE
    message = message:gsub("$name",unitName or "??")
    message = message:gsub("$damage",damage or "??")
    message = message:gsub("$streak",killstreak)


    if message:find("%$spell") then
        local spell = GetSpellLink(spellID)
        if #message - #"$spell" + #spell > MESSAGE_MAX_LEN then
            spell = spell:match("(%[.+%])")
        end

        message = message:gsub("$spell",spell)
    end

    SendChatMessage(message,"EMOTE")

    PlaySoundFile(SOUNDS_PATH..math.min(killstreak,14)..".ogg")
end

function frame:Reset()
    killstreak = 0
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(_,subEvent,...)
    if subEvent:find("_DAMAGE$") then
        local _,_,srcFlags,_,dstName,dstFlags = ...
        if (bit.band(srcFlags,COMBATLOG_FILTER_ME) == COMBATLOG_FILTER_ME or bit.band(srcFlags,COMBATLOG_FILTER_MY_PET) == COMBATLOG_FILTER_MY_PET)
            and bit.band(dstFlags,COMBATLOG_FILTER_HOSTILE_PLAYER) == COMBATLOG_FILTER_HOSTILE_PLAYER then

            local spellID,_,_,damage,overkill = select(select("#",...)-11,...)
            if overkill and overkill > 0 then
                if subEvent == "SWING_DAMAGE" then spellID = 6603 end
                self:Kill(dstName,spellID,damage)
            end
        end
    end
end

frame.PLAYER_DEAD = frame.Reset
frame.PLAYER_ENTERING_WORLD = frame.Reset


function frame:OnEvent(event,...)
    self[event](self,...)
end


frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")  
frame:SetScript("OnEvent",frame.OnEvent)