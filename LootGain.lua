LootGain = { };
LootGain.version = "0.01";
LootGain.dataVersion = 1;

LootGain.numRecentMouseoverUnits = 0;
LootGain.recentMouseoverUnits = { };

-- Global data
LootGain_Data = LootGain_Data or {
   sources = { }
};

-- Character-specific data
LootGain_CharacterData = LootGain_CharacterData or {
   recentUnits = { }
};


local addonChannelName = "LootGain3950";
local addonChannelId = nil;

local INVENTORY_SLOT_IDS = { };
local INVENTORY_SLOTS = {
   "HeadSlot",
   "NeckSlot",
   "ShoulderSlot",
   "BackSlot",
   "ChestSlot",
   "ShirtSlot",
   "TabardSlot",
   "WristSlot",
   "HandsSlot",
   "WaistSlot",
   "LegsSlot",
   "FeetSlot",
   "Finger0Slot",
   "Finger1Slot",
   "Trinket0Slot",
   "Trinket1Slot",
   "MainHandSlot",
   "SecondaryHandSlot",
   --"RangedSlot",
   --"AmmoSlot"
   "Bag0Slot",
   "Bag1Slot",
   "Bag2Slot",
   "Bag3Slot",
}

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

local function GetInventorySlotIds(inventorySlots, inventorySlotIds)
   for k, v in pairs(inventorySlots) do
      local slotId, textureName = GetInventorySlotInfo(v);
      inventorySlotIds[v] = slotId;
   end
end

local function JoinAddonChannel()
   local channelType, channelName = JoinChannelByName(addonChannelName);
   addonChannelId = GetChannelName(addonChannelName);

   LootGainPrint("Channel Type: " .. (channelType or "nil"));
   LootGainPrint("Channel Name: " .. (channelName or "nil"));
end

local function GetStaticPlayerInfo(player)
   player.loginTime = time();
   player.name = UnitName("player");
   player.server = GetRealmName();
   player.class = UnitClass("player");
   player.race = UnitRace("player");
   player.sex = UnitSex("player");
end

local function GetVariablePlayerInfo(player)
   player.guid = UnitGUID("player");
   player.level = UnitLevel("player");
   player.inParty = UnitInParty("player");
   player.inRaid = UnitInRaid("player");

   -- location
   player.location = { };
   player.location.zone = GetRealZoneText();
   player.location.subZone = GetSubZoneText();
   player.location.positionX, player.location.positionY = GetPlayerMapPosition("player");
   LootGainPrint("Location: " .. (player.location.zone or "No Zone") .. " - " .. (player.location.subZone or "No Sub Zone") .. " (" ..
              player.location.positionX .. ", " .. player.location.positionY .. ")");

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

   -- items
   player.items = { };
   local currentBagNum = 0;
   local maxBagNum = 4;
   for currentBagNum = 0, maxBagNum do
      local bagName = GetBagName(currentBagNum);
      if (bagName) then
         local numSlots = GetContainerNumSlots(currentBagNum);
         for currentSlotNum = 1, numSlots do
            local itemLink = GetContainerItemLink(currentBagNum, currentSlotNum);

            if itemLink ~= nil then
               local texture, itemCount, locked, quality, readable = GetContainerItemInfo(currentBagNum, currentSlotNum);
               local isQuestItem, questId, isActive = GetContainerItemQuestInfo(currentBagNum, currentSlotNum);

               player.items[itemLink] = player.items[itemLink] or { count = 0 };
               local curr = player.items[itemLink];

               curr.itemLink = itemLink;
               curr.texture = texture;
               curr.quality = quality;
               curr.isQuestItem = isQuestItem;
               curr.questId = questId;
               curr.isActive = isActive;

               curr.count = curr.count + itemCount;
            end
         end
      end

      currentBagNum = currentBagNum + 1;
   end

   -- inventory
   for k, v in pairs(INVENTORY_SLOT_IDS) do
      local itemLink = GetInventoryItemLink("player", v);
      if itemLink ~= nil then
         player.items[itemLink] = player.items[itemLink] or { count = 0 };
         player.items[itemLink].itemLink = itemLink;
         player.items[itemLink].count = player.items[itemLink].count + 1;
      end
   end

   -- todo: Record bank items.  Note that this info should be cached between
   --       sessions and between calls, as that information is not always
   --       available.

   -- professions
   player.professions = { };
   local professionIndexes = { GetProfessions() };
   for k, v in pairs(professionIndexes) do
      if (v ~= nil) then
         local name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier = GetProfessionInfo(v);
         player.professions[name] = { name = name, icon = icon, skillLevel = skillLevel,
                                      maxSkillLevel = maxSkillLevel, skillModifier = skillModifier };
      end
   end

   --[[
   for k, v in pairs(player.items) do
      LootGainPrint("Item: " .. v.itemLink .. " - " .. gsub(v.itemLink, "\124", "\124\124") .. " - " .. v.count);
   end

   for k, v in pairs(player.quests) do
      LootGainPrint("Quest " .. k .. ": " .. v.name .. " - " .. (v.header or "None"));
   end

   for k, v in pairs(player.currencies) do
      LootGainPrint("Currency " .. k .. ": " .. v.name .. " - " .. (v.header or "None"));
   end

   for k, v in pairs(player.professions) do
      LootGainPrint("Profession: " .. v.name .. " - " .. v.skillLevel .. "(+" .. v.skillModifier .. ")/" .. v.maxSkillLevel);
   end
   --]]
end

local function GetLootInformation()
   local numItems = GetNumLootItems();
   LootGainPrint("Getting information (" .. numItems .. " item(s)).");

   local sources = { };
   for i = 1, numItems do
      local isCoin = false;
      -- determine and record how many of each item came from each source
      local lootSlotInfo = { GetLootSourceInfo(i) };
      local numItemSources = #lootSlotInfo / 2;

      local itemLink = GetLootSlotLink(i);
      local lootIcon, lootName, lootQuantity, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i)
      if (lootQuantity == 0) then
         isCoin = true;
      end

      for j = 0, numItemSources - 1 do
         local itemSourceGuid = lootSlotInfo[2 * j + 1];
         local itemSourceCount = lootSlotInfo[2 * j + 2];

         if (not sources[itemSourceGuid]) then
            sources[itemSourceGuid] = {
               guid = itemSourceGuid,
               slots = { },
               items = { },
            };
         end

         if (isCoin) then
            -- fill in the items table
            if (not sources[itemSourceGuid].items.coins) then
               sources[itemSourceGuid].items.coins = {
                  isCoin = true,
                  looted = false,
               };
               --sources[itemSourceGuid].coins = 0;
            end
            if (not sources[itemSourceGuid].items.coins[i]) then
               sources[itemSourceGuid].items.coins[i] = 0;
            end
            sources[itemSourceGuid].items.coins[i] = sources[itemSourceGuid].items.coins[i] + itemSourceCount;

            -- fill in the slots table
            if (not sources[itemSourceGuid].slots[i]) then
               sources[itemSourceGuid].slots[i] = {
                  isCoin = true,
                  looted = false,
                  quantity = 0,
               };
            end
            sources[itemSourceGuid].slots[i].quantity = sources[itemSourceGuid].slots[i].quantity + itemSourceCount;
         else
            -- fill in the items table
            -- initialize the information about the item
            if (not sources[itemSourceGuid].items[itemLink]) then
               sources[itemSourceGuid].items[itemLink] = {
                  isCoin = false,
                  looted = false,
               };
            end
            -- initialize the information about the item in that slot
            if (not sources[itemSourceGuid].items[itemLink][i]) then
               sources[itemSourceGuid].items[itemLink][i] = 0;
            end
            sources[itemSourceGuid].items[itemLink][i] = sources[itemSourceGuid].items[itemLink][i] + itemSourceCount;

            -- fill in the slots table
            if (not sources[itemSourceGuid].slots[i]) then
               sources[itemSourceGuid].slots[i] = {
                  isCoin = false,
                  looted = false,
                  itemLink = itemLink,
                  quantity = 0,
               };
            end
            sources[itemSourceGuid].slots[i].quantity = sources[itemSourceGuid].slots[i].quantity + itemSourceCount;
         end
      end
      for k, v in pairs (lootSlotInfo) do
         LootGainPrint("Loot: " .. k .. " - " .. v);
      end
   end

   for k, v in pairs (sources) do
      local mousedOverTime = LootGain.recentMouseoverUnits[v.guid];
      LootGainPrint("Source: " .. v.guid .. " (" .. (mousedOverTime or "Never") .. ")");
      for k2, v2 in pairs (v.slots) do
         LootGainPrint("  Slot: " .. (k2 or "nil") .. ": " .. (v2.itemLink or "Coins") .. " - " .. v2.quantity);
      end

      for itemLink, itemInfo in pairs (v.items) do
         local outputString = "";
         for j = 1, table.maxn(itemInfo) do
            if itemInfo[j] then
               outputString = outputString .. j .. " - " .. itemInfo[j] .. ", ";
            end
         end
         LootGainPrint("  Item: " .. (itemLink or "nil") .. ": " .. (outputString or "nil"));
      end
   end
end

function LootGain_OnEvent(self, event, ...)
   if event == "UPDATE_MOUSEOVER_UNIT" then
      local mouseoverGuid = UnitGUID("mouseover");
      --LootGainPrint("Mouseover GUID: " .. (UnitGUID("mouseover") or "nil"));

      if (not LootGain.recentMouseoverUnits[mouseoverGuid]) then
         LootGain.recentMouseoverUnits[mouseoverGuid] = {
            lastMouseoverTime = nil,
            recorded = false,
            info = {
               name = UnitName("mouseover"),
               level = UnitLevel("mouseover"),
               class = UnitClass("mouseover"),
               race = UnitRace("mouseover"),
               sex = UnitSex("mouseover"),
               classification = UnitClassification("mouseover"),
               creatureFamily = UnitCreatureFamily("mouseover"),
               creatureType = UnitCreatureType("mouseover"),
               isPlayer = UnitIsPlayer("mouseover"),
            },
         };

         LootGain.numRecentMouseoverUnits = LootGain.numRecentMouseoverUnits + 1;

         --for k, v in pairs(LootGain.recentMouseoverUnits[mouseoverGuid].info) do
         --   LootGainPrint("  " .. k .. ": " .. (v or "nil"));
         --end
      end
      LootGain.recentMouseoverUnits[mouseoverGuid].lastMouseoverTime = time();

      --LootGainPrint("Mouseover list (" .. LootGain.numRecentMouseoverUnits .. ")");
      --for k, v in pairs(LootGain.recentMouseoverUnits) do
      --   LootGainPrint("Mouseover: " .. k .. " - " .. date("%m/%d/%y %H:%M:%S", v));
      --end
   elseif event == "LOOT_OPENED" then
      GetLootInformation();
   end
end

local function RegisterEvents(self)
   --this:RegisterEvent("PLAYER_ENTERING_WORLD");
   self:RegisterEvent("LOOT_OPENED");
   --this:RegisterEvent("LOOT_CLOSED");
   --this:RegisterEvent("LOOT_SLOT_CLEARED");
   --this:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF");
   self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
end

function LootGain_OnLoad(self)
   DEFAULT_CHAT_FRAME:AddMessage("Loot Gain 0.01 loaded.");

   GetInventorySlotIds(INVENTORY_SLOTS, INVENTORY_SLOT_IDS);

   JoinAddonChannel();

   LootGain.player = { };
   GetStaticPlayerInfo(LootGain.player);
   GetVariablePlayerInfo(LootGain.player);

   RegisterEvents(self);
end

