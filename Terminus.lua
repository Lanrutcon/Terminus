local addonName, addonTable = ...;

--MainFrame
local Terminus = _G["Terminus"];

--String that will be later
local formatStr = "%s  I N C R E A S E D  T O  %s";

--Saves words index in GlobalStrings:SKILL_RANK_UP
local skillIndex, numberIndex

--Notifies player X in X levels
local threshold;


-------------------------------------
--
-- Returns the given string with spaces between each character.
-- @param #string str : the given string
-- @return #string returnStr : the given string "spaced"
--
-------------------------------------
local function addSpaces(str)
    local returnStr = "";
    for w in string.gmatch(string.upper(str), "%w") do
        returnStr = returnStr .. " "  .. w;
    end
    return string.sub(returnStr, 2, -1);
end


-------------------------------------
--
-- Receives the CHAT_MSG_SKILL result (1st arg) and gets the skill and the new level.
-- @param #string chatMessage : the 1st argument from CHAT_MSG_SKILL event
-- @return #string skill : the skill that got leveled
-- @return #integer newLevel : the new level of the skill
--
-------------------------------------
local function getSkillInfo(chatMessage)
    --"Your skill in %s has increased to %d.";
    local skill, newLevel;
	
	--"First Aid" are 2 words, so it messes up with the generic algorithm
	if(string.find(chatMessage, PROFESSIONS_FIRST_AID)) then
		skill = PROFESSIONS_FIRST_AID;
		newLevel = string.match(chatMessage, "%d+");
		return skill, newLevel;
	end
	
	
    local i = 1;
    for word in string.gmatch(chatMessage, "%w+") do
        if(i == skillIndex) then
            skill = word;
        elseif(i == numberIndex) then
            newLevel = word;
        end
        i = i + 1;
    end

    return skill, newLevel;
end


local animationFrame = CreateFrame("FRAME");
-------------------------------------
--
-- Plays animation when you level up a skill
-- @param #string skill : the leveled skill
-- @param #integer newLevel : the new level of the skill
--
-------------------------------------
local function playAnimation(skill, newLevel)

    --AnimationGroup created in Terminus.xml
    TerminusBar.animation:Play();

    local bar = TerminusBar;
    local barLevel = math.fmod(newLevel, 75);
    if(barLevel == 0) then
        barLevel = 75;
    end
    bar:SetValue(barLevel-threshold);
    bar.levelNumber:SetText(newLevel);

    local text = Terminus.text;
    text:SetText(string.format(formatStr, addSpaces(skill), addSpaces(newLevel)));
    text:SetAlpha(1);
	text:SetAlphaGradient(0,1);

    local total, totalChars = 0, string.len(skill);
    animationFrame:SetScript("OnUpdate", function(self, elapsed)
    	total = total + elapsed;

        --at 1sec: animateBar
        if(total > 1) then
            local point = barLevel-threshold*(1-(total-1)/2);
            bar:SetValue(point);

            --at 3secs (where animation of bar ends)
            if(total > 3 and not bar.backgroundHighlight.animation:IsPlaying()) then
                UIFrameFadeOut(text, 1, 1, 0);
                if(barLevel == 75) then
                    Terminus.bar.backgroundHighlight.animation:Play();
                end
                self:SetScript("OnUpdate", nil);
            end
        end

        --fontString animation
        if(total*75 > 1) then
            text:SetAlphaGradient(total*2.5*totalChars, total*75);
        else
            text:SetAlphaGradient(total*2.5*totalChars, 1);
        end
	end);
end


-------------------------------------
--
-- Shows Terminus (MainFrame) and executes animation
-- @param #string skill : the leveled skill
-- @param #integer newLevel : the new level of the skill
--
-------------------------------------
local function showTerminus(skill, newLevel)
    Terminus:Show();
    playAnimation(skill, newLevel);
end


-------------------------------------
--
-- Saves client options, i.e. gets the GlobalStrings to use later.
--
-------------------------------------
local function saveClientOptions()
    local i = 1;
    for word in string.gmatch(SKILL_RANK_UP, "%a+") do
        if(word == "s") then
            skillIndex = i;
        elseif(word == "d") then
            numberIndex = i;
        end
        i = i + 1;
    end
end


SLASH_Terminus1, SLASH_Terminus2 = "/terminus", "/tms";
-------------------------------------
--
-- Slash Command function.
-- @param #string cmd : the command that player executed
--
-------------------------------------
local function SlashCmd(cmd)
    --"level" as threshold
    if(cmd:match("level")) then
        threshold = cmd:match("%d+");
        TerminusSV[UnitName("player")] = threshold;
        print("|cffcc7777Terminus: You will now only be notified every " .. threshold .. " levels");
    else
        print("|cffcc7777Terminus Commands:");
        print("|cffcc4444           /terminus level X - if X = 5, then you will be notified every 5th level.");
    end
end

SlashCmdList["Terminus"] = SlashCmd;


-------------------------------------
--
-- Loads SavedVariables.
--
-------------------------------------
local function loadSavedVariables()
    if(not TerminusSV) then
        TerminusSV = {};
        TerminusSV[UnitName("player")] = 5;
    elseif(not TerminusSV[UnitName("player")]) then
        TerminusSV[UnitName("player")] = 5;
    end
    threshold = TerminusSV[UnitName("player")];
end


-------------------------------------
-- SCRITPS
-------------------------------------

function Terminus:PLAYER_LOGIN()
    saveClientOptions();
    loadSavedVariables();

    --disable skill gain messages
    ChatFrame1:UnregisterEvent("CHAT_MSG_SKILL");
end


function Terminus:CHAT_MSG_SKILL(message)
    local skill, newLevel = getSkillInfo(message);
    if not (skill and newLevel) then
        return;
    end
    --if newLevel can be divided by threshold or if newLevel is at max level
    if(math.fmod(newLevel, threshold) == 0 or math.fmod(newLevel, 75) == 0) then
        showTerminus(skill, newLevel)
    end
end


Terminus:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...);
end);


Terminus:RegisterEvent("CHAT_MSG_SKILL");
Terminus:RegisterEvent("PLAYER_LOGIN");
