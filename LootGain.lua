local addonChannelName = "LootGain3940";
local addonChannelId = nil;

local function LootGainPrint(message)
   if (addonChannelId ~= nil) then
      SendChatMessage(message, "CHANNEL", nil, addonChannelId);
   else
      DEFAULT_CHAT_FRAME:AddMessage(message);
   end
end

local function JoinAddonChannel()
   local channelType, channelName = JoinChannelByName(addonChannelName);
   addonChannelId = GetChannelName(addonChannelName);

   LootGainPrint("Channel Type: " .. (channelType or "nil"));
   LootGainPrint("Channel Name: " .. (channelName or "nil"));
end

local function PrintPlayerInfo()
   DEFAULT_CHAT_FRAME:AddMessage("Player Info:");
   DEFAULT_CHAT_FRAME:AddMessage("  Date: " .. date("%m/%d/%y %H:%M:%S"));
   DEFAULT_CHAT_FRAME:AddMessage("  Time since epoch: " .. time());
   DEFAULT_CHAT_FRAME:AddMessage("  GUID: " .. (UnitGUID("player") or "nil"));
   DEFAULT_CHAT_FRAME:AddMessage("  Name: " .. UnitName("player"));
   --DEFAULT_CHAT_FRAME:AddMessage("  Server: " .. ....
   DEFAULT_CHAT_FRAME:AddMessage("  Level: " .. UnitLevel("player"));
   DEFAULT_CHAT_FRAME:AddMessage("  Class: " .. UnitClass("player"));
   DEFAULT_CHAT_FRAME:AddMessage("  In Party: " .. (UnitInParty("player") or "nil"));
   DEFAULT_CHAT_FRAME:AddMessage("  In Raid: " .. (UnitInRaid("player") or "nil"));

   DEFAULT_CHAT_FRAME:AddMessage("");

   local currentSpecialization = GetSpecialization(false);
   DEFAULT_CHAT_FRAME:AddMessage("  Active specialization group: " .. GetActiveSpecGroup(false));
   DEFAULT_CHAT_FRAME:AddMessage("  Specialization: " .. (currentSpecialization or "nil"));
   DEFAULT_CHAT_FRAME:AddMessage("  Specialization Name: " .. (currentSpecialization and
                                                               select(2, GetSpecializationInfo(currentSpecialization))
                                                            or "None"));

   local numQuestLogLines, numQuests = GetNumQuestLogEntries();
   DEFAULT_CHAT_FRAME:AddMessage("Quests (" .. numQuestLogLines .. "):");
   DEFAULT_CHAT_FRAME:AddMessage("  Number of Quest log lines: " .. numQuestLogLines);
   DEFAULT_CHAT_FRAME:AddMessage("  Number of Quests: " .. numQuests);

   local i = 1
   while GetQuestLogTitle(i) do
      local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
      if (isHeader) then
         DEFAULT_CHAT_FRAME:AddMessage("(" .. i .. ") " .. questTitle .. ":")
      else
         DEFAULT_CHAT_FRAME:AddMessage("(" .. i .. ")   " .. questTitle .. " [" .. level .. "] " .. questID)
      end
      i = i + 1
   end
   --DEFAULT_CHAT_FRAME:AddMessage("  Required items: " .. (GetNumQuestItems() or "nil"));

   local numCurrencyLines = GetCurrencyListSize();
   DEFAULT_CHAT_FRAME:AddMessage("Currencies (" .. numCurrencyLines .. "):");
   i = 1
   for i = 1, numCurrencyLines do
      local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum,
      hasWeeklyLimit, currentWeeklyAmount, unknown, itemID = GetCurrencyListInfo(i);
      if (isHeader) then
         DEFAULT_CHAT_FRAME:AddMessage("(" .. i .. ") " .. name .. ":")
      else
         DEFAULT_CHAT_FRAME:AddMessage("(" .. i .. ")   " .. name .. " - " .. count .. " / " .. (maximum or "None")
                                       .. " | " .. (currentWeeklyAmount or "None") .. " / " .. (hasWeeklyLimit or "None")
                                       .. " - " .. (itemID or "No Item ID") .. " (" .. (icon or "No icon") .. ")");
      end
   end

   DEFAULT_CHAT_FRAME:AddMessage("Inventory:");
   i = 0;
   while GetBagName(i) do
      local numSlots = GetContainerNumSlots(i);
      DEFAULT_CHAT_FRAME:AddMessage("Bag " .. i .. ": " .. GetBagName(i) .. " (" .. numSlots .. ")");
      local j = 1;
      for j = 1, numSlots do
         local itemLink = GetContainerItemLink(i, j)
         local isQuestItem, questId, isActive = GetContainerItemQuestInfo(i, j);
         local outputString = i .. ", " .. j .. ": ";
         if (itemLink) then
            outputString = outputString .. itemLink;
            if (isQuestItem) then
               outputString = outputString .. " (" .. (questId or "nil") .. " - " .. (isActive or "nil") .. ")";
            else
               outputString = outputString .. " (Not Quest Item)";
            end
         else
            outputString = outputString .. " Empty";
         end
         DEFAULT_CHAT_FRAME:AddMessage(outputString);
         j = j + 1;
      end
      i = i + 1;
   end
end

local function ChannelTest()
   local lgChannel = "LootGain3940"
   local channelType, channelName = JoinChannelByName(lgChannel);
   DEFAULT_CHAT_FRAME:AddMessage(" Channel Type: " .. (channelType or "nil"));
   DEFAULT_CHAT_FRAME:AddMessage(" Channel Name: " .. (channelName or "nil"));

   local lgChannelId = GetChannelName(lgChannel);
   --ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, lgChannel);
   --ChatFrame_AddChannel(ChatFrame1, lgChannel);

   if (lgChannelId ~= nil) then
      DEFAULT_CHAT_FRAME:AddMessage(" Attempting to send message to channel " .. lgChannel .. " with id " .. lgChannelId .. ".");
      SendChatMessage("test", "CHANNEL", nil, lgChannelId);
   else
      DEFAULT_CHAT_FRAME:AddMessage(" Chat channel is nil!");
   end
end

function LootGain_OnLoad(self)
   DEFAULT_CHAT_FRAME:AddMessage("Loot Gain 0.01 loaded.");

   JoinAddonChannel();
   PrintPlayerInfo();
end

