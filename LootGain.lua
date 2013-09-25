LootGain = { };
LootGain.version = "0.01";
LootGain.dataVersion = 1;

local addonChannelName = "LootGain3940";
local addonChannelId = nil;

local function LootGainPrint(message)
-- See the SendAddonMessage function for non-human-readable messages that have
-- fewer limitations than SendChatMessage.  Also see
-- RegisterAddonMessagePrefix.
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

local function GetStaticPlayerInfo(player)
   player.loginTime = time();
   player.name = UnitName("player");
   --player.server = ...;
   player.class = UnitClass("player");
   player.race = UnitRace("player");
end

local function GetVariablePlayerInfo(player)
   player.guid = UnitGUID("player");
   player.level = UnitLevel("player");
   player.inParty = UnitInParty("player");
   player.inRaid = UnitInRaid("player");

   -- specializations
   player.numSpecializations = GetNumSpecializations(false, false);
   player.specializations = { };
   for i = 1, player.numSpecializations do
      player.specializations[i] = { };

      local curr = player.specializations[i];
      curr.id, curr.name, _, curr.icon, _, curr.role = GetSpecializationInfo(i, false, false);
   end
   player.activeSpecialization = GetActiveSpecGroup(false);
   player.currentSpecialization = player.specializations[player.activeSpecialization];

   -- quests
   local numQuestLogLines, numQuests = GetNumQuestLogEntries();
   player.numQuests = numQuests;
   player.quests = { };

   local currentQuestHeader;
   for i = 1, numQuestLogLines do
      local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
      if (isHeader) then
         currentQuestHeader = questTitle;
      else
         player.quests[questID] = { name = questTitle, level = level, questTag = questTag,
                                    isDaily = isDaily, id = questID, header = currentQuestHeader };
      end
   end

   -- currencies
   local numCurrencyLines = GetCurrencyListSize();
   player.currencies = { };

   local numCurrencies = 0;
   local currentCurrencyHeader;
   for i = 1, numCurrencyLines do
      local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum,
      hasWeeklyLimit, currentWeeklyAmount, unknown, itemID = GetCurrencyListInfo(i);
      if (isHeader) then
         currentCurrencyHeader = name;
      else
         numCurrencies = numCurrencies + 1;
         player.currencies[i] = { name = name, count = count, weeklyLimit = currentWeeklyAmount,
                                  itemID = itemID, icon = icon, header = currentCurrencyHeader };
      end
   end
   player.numCurrencies = numCurrencies;

   -- inventory
   player.inventory = { };
   local currentBagNum = 0;
   while GetBagName(currentBagNum) do
      local numSlots = GetContainerNumSlots(currentBagNum);
      for currentSlotNum = 1, numSlots do
         local itemLink = GetContainerItemLink(currentBagNum, currentSlotNum);
         local texture, itemCount, locked, quality, readable = GetContainerItemInfo(currentBagNum, currentSlotNum);
         local isQuestItem, questId, isActive = GetContainerItemQuestInfo(currentBagNum, currentSlotNum);

         if itemLink ~= nil then
            player.inventory[itemLink] = player.inventory[itemLink] or { count = 0 };
            local curr = player.inventory[itemLink];

            curr.itemLink = itemLink;
            curr.texture = texture;
            curr.quality = quality;
            curr.isQuestItem = isQuestItem;
            curr.questId = questId;
            curr.isActive = isActive;

            curr.count = curr.count + itemCount;
         end
      end

      currentBagNum = currentBagNum + 1;
   end
end

function LootGain_OnLoad(self)
   DEFAULT_CHAT_FRAME:AddMessage("Loot Gain 0.01 loaded.");

   JoinAddonChannel();
   --PrintPlayerInfo();

   LootGain.player = { };
   GetStaticPlayerInfo(LootGain.player);
   GetVariablePlayerInfo(LootGain.player);
end

