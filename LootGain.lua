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
   LootGainPrint("Player Info:");
   LootGainPrint("  Date: " .. date("%m/%d/%y %H:%M:%S"));
   LootGainPrint("  Time since epoch: " .. time());
   LootGainPrint("  GUID: " .. (UnitGUID("player") or "nil"));
   LootGainPrint("  Name: " .. UnitName("player"));
   --LootGainPrint("  Server: " .. ....
   LootGainPrint("  Level: " .. UnitLevel("player"));
   LootGainPrint("  Class: " .. UnitClass("player"));
   LootGainPrint("  In Party: " .. (UnitInParty("player") or "nil"));
   LootGainPrint("  In Raid: " .. (UnitInRaid("player") or "nil"));

   LootGainPrint("");

   local currentSpecialization = GetSpecialization(false);
   LootGainPrint("  Active specialization group: " .. GetActiveSpecGroup(false));
   LootGainPrint("  Specialization: " .. (currentSpecialization or "nil"));
   LootGainPrint("  Specialization Name: " .. (currentSpecialization and
                                                               select(2, GetSpecializationInfo(currentSpecialization))
                                                            or "None"));

   local numQuestLogLines, numQuests = GetNumQuestLogEntries();
   LootGainPrint("Quests (" .. numQuestLogLines .. "):");
   LootGainPrint("  Number of Quest log lines: " .. numQuestLogLines);
   LootGainPrint("  Number of Quests: " .. numQuests);

   local i = 1
   while GetQuestLogTitle(i) do
      local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
      if (isHeader) then
         LootGainPrint("(" .. i .. ") " .. questTitle .. ":")
      else
         LootGainPrint("(" .. i .. ")   " .. questTitle .. " [" .. level .. "] " .. questID)
      end
      i = i + 1
   end
   --LootGainPrint("  Required items: " .. (GetNumQuestItems() or "nil"));

   local numCurrencyLines = GetCurrencyListSize();
   LootGainPrint("Currencies (" .. numCurrencyLines .. "):");
   i = 1
   for i = 1, numCurrencyLines do
      local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum,
      hasWeeklyLimit, currentWeeklyAmount, unknown, itemID = GetCurrencyListInfo(i);
      if (isHeader) then
         LootGainPrint("(" .. i .. ") " .. name .. ":")
      else
         LootGainPrint("(" .. i .. ")   " .. name .. " - " .. count .. " / " .. (maximum or "None")
                                       .. " / " .. (currentWeeklyAmount or "None") .. " / " .. (hasWeeklyLimit or "None")
                                       .. " - " .. (itemID or "No Item ID") .. " (" .. (icon or "No icon") .. ")");
      end
   end

   LootGainPrint("Inventory:");
   i = 0;
   while GetBagName(i) do
      local numSlots = GetContainerNumSlots(i);
      LootGainPrint("Bag " .. i .. ": " .. GetBagName(i) .. " (" .. numSlots .. ")");
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
         LootGainPrint(outputString);
         j = j + 1;
      end
      i = i + 1;
   end
end

function LootGain_OnLoad(self)
   DEFAULT_CHAT_FRAME:AddMessage("Loot Gain 0.01 loaded.");

   JoinAddonChannel();
   PrintPlayerInfo();
end

