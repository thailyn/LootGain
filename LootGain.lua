LootGain = { };
LootGain.version = "0.02";
LootGain.dataVersion = 6;
LootGain.initialized = false;

LootGain.numRecentMouseoverUnits = 0;

LootGain.recentLootActions = { };

LootGain.channel = {
   name = "LootGain3940",
   id = nil,
}

LootGain.settings = {
   unitTimeout = 60 * 20; -- 20 minutes
   verbose = false;
};

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

local LOOT_TYPES = {
   "LOOTING",
   "MINING",
   "HERB GATHERING",
   "SKINNING",
   "PICK POCKETING",
   "OPENING",
   "DISENCHANTING",
   "MILLING",
   "PROSPECTING",
   "FISHING",
   "UNKNOWN",
};

local function LootGainPrint(message)
-- See the SendAddonMessage function for non-human-readable messages that have
-- fewer limitations than SendChatMessage.  Also see
-- RegisterAddonMessagePrefix.

   if (LootGain_CharacterData.settings and not LootGain_CharacterData.settings.verbose) then
      return;
   end

   if (LootGain.channel.id ~= nil) then
      SendChatMessage(message, "CHANNEL", nil, LootGain.channel.id);
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
   local channelType, channelName = JoinChannelByName(LootGain.channel.name);
   LootGain.channel.id = GetChannelName(LootGain.channel.name);
end

local function LootGain_PrintGlobalDataKey(key, value, indent)
   if (type(value) == "table") then
      LootGainPrint(indent .. key .. " - " .. "(table)");
      local nextIndent = indent .. "  ";
      for k, v in pairs (value) do
         LootGain_PrintGlobalDataKey(k, v, nextIndent);
      end
   elseif (type(value) == "boolean") then
      LootGainPrint(indent .. key .. " - " .. (value and "true" or "false"));
   elseif (type(value) == "nil") then
      LootGainPrint(indent .. key .. " - " .. "nil");
   else
      LootGainPrint(indent .. key .. " - " .. value);
   end
end

function LootGain_PrintGlobalData()
   LootGainPrint(#LootGain_Data.sources .. " sources.");
   for k, source in ipairs (LootGain_Data.sources) do
      LootGainPrint(k .. ": ");
      for k2, v2 in pairs (source) do
         LootGain_PrintGlobalDataKey(k2, v2, "  ");
      end
   end
end

function LootGain_PrintGlobalDataShort()
   LootGainPrint(#LootGain_Data.sources .. " sources.");
   for k, source in ipairs (LootGain_Data.sources) do
      LootGainPrint(k .. ": " .. (source[20] or "nil") .. " at " .. date("%m/%d/%y %H:%M:%S", source[3]));
   end
end

local function GetStaticPlayerInfo(player)
   player.loginTime = time();
   player.name = UnitName("player");
   player.server = GetRealmName();
   player.class = UnitClass("player");
   player.race = UnitRace("player");
   player.sex = UnitSex("player");

   player.system = { };
   player.system.version, player.system.build, player.system.date, player.system.tocVersion = GetBuildInfo();
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
   --LootGainPrint("Location: " .. (player.location.zone or "No Zone") .. " - " .. (player.location.subZone or "No Sub Zone") .. " (" ..
   --           player.location.positionX .. ", " .. player.location.positionY .. ")");

   -- guild information
   player.guildName = GetGuildInfo("player");
   player.guildLevel = GetGuildLevel("player");

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

   -- auras
   player.auras = { };
   local i = 1;
   local auraName, auraRank, auraIcon, auraCount, auraDebuffType, _, _, auraUnitCaster, _, _, auraSpellId  = UnitAura("player", i);
   while auraName do
      player.auras[i] = {
         name = auraName,
         rank = auraRank,
         icon = auraIcon,
         count = auraCount,
         debuffType = auraDebuffType,
         unitCaster = auraUnitCaster,
         spellId = auraSpellId,
      };
      i = i + 1;
      auraName, auraRank, auraIcon, auraCount, auraDebuffType, _, _, auraUnitCaster, _, _, auraSpellId  = UnitAura("player", i);
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

local function DetermineLootSourceTypes(recentLootActions, sources)
   for k, v in pairs (sources) do
      if (IsFishingLoot()) then
         v.lootType = "FISHING";
      else
         v.lootType = "UNKNOWN";
      end
   end
end

local function AssignSourcesToUnitsList(units, sources)
   local currentTime = time();
   local openingLootTimeout = 15;

   for k, source in pairs (sources) do
      local isOpeningLoot = false;
      local isFishingLoot = false;
      local sourceGuid = source.guid;

      if (not units[sourceGuid]) then
         units[sourceGuid] = {
            loot = { },
         };
         -- increment mouseover units, too
      end

      -- The assumption used here for now is that, if we performed some
      -- gathering action (e.g., Mining), the next loot window will contain
      -- sources *only* associated with that source.  It seems to be true for
      -- normal situations, but not all situations have been tested.
      if (IsFishingLoot()) then
         source.lootType = "FISHING";
         isFishingLoot = true;
      elseif (LootGain.recentLootActions.type ~= nil and currentTime - LootGain.recentLootActions.time < openingLootTimeout) then
         source.lootType = LootGain.recentLootActions.type;
         isOpeningLoot = true;
      else
         source.lootType = "LOOTING";
      end

      if (not units[sourceGuid].loot[source.lootType]) then
         units[sourceGuid].loot[source.lootType] = {
            recorded = false,
            recordedTime = nil,
            slots = source.slots,
         };

         if (isOpeningLoot) then
            units[sourceGuid].info = units[sourceGuid].info or { };

            -- only set the name now if it has not been set before
            units[sourceGuid].info.name = units[sourceGuid].info.name or LootGain.recentLootActions.target;
            units[sourceGuid].info.guid = units[sourceGuid].info.guid or sourceGuid;
            units[sourceGuid].info.hasOpeningLoot = true;
            units[sourceGuid].lastMouseoverTime = currentTime; -- fake this value so the unit is eventually removed
         end

         if (isFishingLoot) then
            units[sourceGuid].info = units[sourceGuid].info or { };

            -- only set the name now if it has not been set before
            units[sourceGuid].info.name = units[sourceGuid].info.name or "Fishing";
            units[sourceGuid].info.guid = units[sourceGuid].info.guid or sourceGuid;
            units[sourceGuid].info.hasFishingLoot = true;
            units[sourceGuid].lastMouseoverTime = currentTime; -- fake this value so the unit is eventually removed
         end
      end
      source.unitReference = units[sourceGuid];
   end
end

-- Record a unit source for a certain type of loot.
-- This is created when mousing over a unit.
local function RecordNewUnitSource(source, lootType)
   if (not source.info) then
      LootGainPrint("ERROR: Attempt to record unit source without info.");
   elseif (not source.info.name) then
      LootGainPrint("ERROR: Attempt to record unit source without name in info.");
   elseif (source.loot[lootType].recorded) then
      LootGainPrint("Skipping source " .. source.info.guid .. " - " .. lootType
                    .. ": already recorded at " .. source.loot[lootType].recordedTime);
   else
      local sourceNum = #LootGain_Data.sources + 1;
      LootGainPrint("Recording source " .. source.info.guid .. " - " .. source.info.name .. " - " .. lootType .. " as source " .. sourceNum);

      -- get player info needed for logging
      -- (todo: currencies)
      local player = LootGain.player;
      local quests = { };
      for k, v in pairs (player.quests) do
         quests[#quests + 1] = v.id
      end

      local items = { };
      for k, v in pairs (player.items) do
         if (v.isQuestItem) then
            items[#items + 1] = {
               v.itemLink,
               v.questId,
               v.count,
            };
         end
      end

      local professions = { };
      for k, v in pairs (player.professions) do
         professions[#professions + 1] = {
            v.name,
            v.skillLevel,
            v.maxSkillLevel,
            v.skillModifier,
         }
      end

      local auras = { };
      for k, v in pairs (player.auras) do
         auras[#auras + 1] = {
            v.name,
            v.rank,
            v.count,
            v.spellId,
            v.unitCaster,
         };
      end
      LootGain_Data.sources[sourceNum] = {
         LootGain.dataVersion, -- [1]
         player.system.build, -- [2]
         time(), -- [3]
         player.name, -- [4]
         player.server, -- [5]
         player.race, -- [6]
         player.sex, -- [7]
         player.class, -- [8]
         player.level, -- [9]
         player.inParty or false, -- [10]
         player.inRaid or false, -- [11]
         player.location.zone, -- [12]
         player.location.subZone, -- [13]
         (player.currentSpecialization and player.currentSpecialization.id or false), -- [14]
         player.guildName, -- [15]
         player.guildLevel, -- [16]
         quests, -- quests, [17]
         { }, -- currencies (do this later) -- [18]
         items, -- items, [19]
         professions, -- professions, [20]
         auras, --auras, [21]

         source.info.guid, -- [22]
         --source.info.type,
         --source.info.id,
         source.info.name, -- [23]
         source.info.level, -- [24]
         source.info.class, -- [25]
         source.info.race, -- [26]
         source.info.sex, -- [27]
         source.info.classification, -- [28]
         source.info.creatureFamily, -- [29]
         source.info.creatureType, -- [30]
         source.isPlayer, -- [31]
         lootType, -- [32]
         source.loot[lootType].slots, -- loot, [33]
      };
      source.loot[lootType].recordedTime = time();
      source.loot[lootType].recorded = true;
   end
end

-- Record a single loot source.
local function RecordNewLootSource(source)
   local lootType = source.lootType;
   local unitReference = source.unitReference;

   if (unitReference.info) then
      RecordNewUnitSource(unitReference, lootType);
   else
      LootGainPrint("Skipping source " .. source.guid .. " - " .. lootType
                    .. ": No unit information available (probably never moused over or targeted).");
   end
end

-- Record a list of loot sources
-- A loot source is created from the sources referenced in the loot window.
-- This should reference a unit source (assuming the source has been moused
-- over previously).  If the unit source does not exist or does not have
-- sufficient information, the recording will be skipped.
local function RecordNewLootSources(sources)
   for k, source in pairs (sources) do
      RecordNewLootSource(source);
   end
end

local function GetLootInformation()
   local numItems = GetNumLootItems();
   --LootGainPrint("Getting information (" .. numItems .. " item(s)).");

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
      --for k, v in pairs (lootSlotInfo) do
      --   LootGainPrint("Loot: " .. k .. " - " .. v);
      --end
   end

   GetVariablePlayerInfo(LootGain.player);

   DetermineLootSourceTypes(LootGain.recentLootActions, sources);
   AssignSourcesToUnitsList(LootGain.recentMouseoverUnits, sources);
   RecordNewLootSources(sources);

   for k, v in pairs (sources) do
      local mousedOverTime = LootGain.recentMouseoverUnits[v.guid];
      LootGainPrint("Source: " .. v.guid .. " (" .. (v.unitReference.info and v.unitReference.info.name
                                                     or "Unknown Name") .. ") - " .. v.lootType .. " (" ..
                    (mousedOverTime.lastMouseoverTime or "Never") .. ")");
      for k2, v2 in pairs (v.slots) do
         LootGainPrint("  Slot: " .. (k2 or "nil") .. ": " ..
                    (v2.itemLink or "Coins") .. " - " .. v2.quantity);
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

local function PurgeOldMouseoverUnits(mouseoverUnits)
   local timeSinceMouseover;
   local currentTime = time();
   for k, v in pairs (mouseoverUnits) do
      if (v.lastMouseoverTime) then
         timeSinceMouseover = currentTime - v.lastMouseoverTime;
         if (timeSinceMouseover > LootGain.settings.unitTimeout) then
            LootGainPrint("Purging mouseover unit " .. k .. ".  Time since mouseover: " .. timeSinceMouseover .. ".");
            mouseoverUnits[k] = nil;
            LootGain.numRecentMouseoverUnits = LootGain.numRecentMouseoverUnits - 1;
         end
      end
   end
end

local function LoadSavedVariables()
   -- Global data
   LootGain_Data = LootGain_Data or {
      sources = { }
   };

   -- Character-specific data
   LootGain_CharacterData = LootGain_CharacterData or {
      recentUnits = { },
      settings = {
         verbose = LootGain.settings.verbose,
      },
   };
   LootGain.recentMouseoverUnits = LootGain_CharacterData.recentUnits;
end

local function Initialize()
   LootGainPrint("In Initialize function.");
   LootGain.initialized = true;

   -- fill in missing settings
   LootGain_CharacterData.settings = LootGain_CharacterData.settings or {
      verbose = LootGain.settings.verbose,
   };

   GetInventorySlotIds(INVENTORY_SLOTS, INVENTORY_SLOT_IDS);

   LootGain.player = { };
   GetStaticPlayerInfo(LootGain.player);
   GetVariablePlayerInfo(LootGain.player);

   PurgeOldMouseoverUnits(LootGain.recentMouseoverUnits)
end

function LootGain_OnEvent(self, event, ...)
   if event == "UPDATE_MOUSEOVER_UNIT" then
      local mouseoverGuid = UnitGUID("mouseover");
      --LootGainPrint("Mouseover GUID: " .. (UnitGUID("mouseover") or "nil"));

      if (not mouseoverGuid) then
         return;
      end

      if (not LootGain.recentMouseoverUnits[mouseoverGuid]) then
         LootGain.recentMouseoverUnits[mouseoverGuid] = {
            lastMouseoverTime = nil,
            loot = { }, -- keyed by loot type
         };

         LootGain.numRecentMouseoverUnits = LootGain.numRecentMouseoverUnits + 1;

         --for k, v in pairs(LootGain.recentMouseoverUnits[mouseoverGuid].info) do
         --   LootGainPrint("  " .. k .. ": " .. (v or "nil"));
         --end
      end

      LootGain.recentMouseoverUnits[mouseoverGuid].lastMouseoverTime = time();

      if (not LootGain.recentMouseoverUnits[mouseoverGuid].info) then
         LootGain.recentMouseoverUnits[mouseoverGuid].info = {
            guid = mouseoverGuid,
            name = UnitName("mouseover"),
            level = UnitLevel("mouseover"),
            class = UnitClass("mouseover"),
            race = UnitRace("mouseover"),
            sex = UnitSex("mouseover"),
            classification = UnitClassification("mouseover"),
            creatureFamily = UnitCreatureFamily("mouseover"),
            creatureType = UnitCreatureType("mouseover"),
            isPlayer = UnitIsPlayer("mouseover"),
         };

         for k, v in pairs (LootGain.recentMouseoverUnits[mouseoverGuid].loot) do
            if (not v.recorded) then
               RecordNewUnitSource(LootGain.recentMouseoverUnits[mouseoverGuid], k);
            end
         end
      end

      --LootGainPrint("Mouseover list (" .. LootGain.numRecentMouseoverUnits .. ")");
      --for k, v in pairs(LootGain.recentMouseoverUnits) do
      --   LootGainPrint("Mouseover: " .. k .. " - " .. date("%m/%d/%y %H:%M:%S", v));
      --end
   elseif event == "CHAT_MSG_OPENING" then
      local message = ...;

      local startIndex, endIndex, skill, target = string.find(message, 'You perform (.-) on (.*).');
      if (skill and target) then
         local skillUpper = strupper(skill);
         if (skillUpper == "SKINNING" or skillUpper == "MINING"
             or skillUpper == "HERB GATHERING" or skillUpper == "OPENING") then
            if (skillUpper == LootGain.recentLootActions.type) then
               --LootGainPrint("Found matching opening action " .. skillUpper);
               local messageTime = time();
               local timeElapsed = messageTime - LootGain.recentLootActions.time
               if (timeElapsed < 10) then
                  --LootGainPrint("Matching opening action has elapsed time " .. timeElapsed
                  --              .. " - within limit.  Using target " .. (target or "nil") .. ".");
                  LootGain.recentLootActions.target = target;
               else
                  LootGainPrint("Matching opening action has elapsed time " .. timeElapsed .. " - NOT within limit.")
               end
            else
               LootGainPrint("Found mismatching opening action: " .. (skillUpper or "nil")
                          .. " is not " .. (LootGain.recentLootActions.type or "nil"));
            end
         end
      end
   elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
      local castingUnit, spellName, extraArg, extraArg2, extraArg3, extraArg4 = ...;
      spellName = strupper(spellName);
      if castingUnit == "player" then
         if (spellName == "SKINNING" or spellName == "MINING"
             or spellName == "HERB GATHERING" or spellName == "OPENING") then
            LootGain.recentLootActions.type = spellName;
            LootGain.recentLootActions.time = time();
            --LootGainPrint("Recent loot action: " .. spellName .. " at " .. date("%m/%d/%y %H:%M:%S", LootGain.recentLootActions.time) .. ".");
         --elseif (spellName == "MILLING") then
         --elseif (spellName == "PROSPECTING") then
         end
      end
   elseif event == "LOOT_OPENED" then
      GetLootInformation();
   elseif event == "LOOT_CLOSED" then
      PurgeOldMouseoverUnits(LootGain.recentMouseoverUnits);
      LootGain.recentLootActions = { };
   elseif event == "ADDON_LOADED" then
      local addonName = select(1, ...);
      if (addonName == "LootGain") then
         LoadSavedVariables();
      end
   elseif event == "PLAYER_ENTERING_WORLD" then
      Initialize();
   end
end

local function RegisterEvents(self)
   self:RegisterEvent("ADDON_LOADED");
   self:RegisterEvent("PLAYER_ENTERING_WORLD");
   --this:RegisterEvent("PLAYER_ENTERING_WORLD");
   self:RegisterEvent("LOOT_OPENED");
   self:RegisterEvent("LOOT_CLOSED");
   --this:RegisterEvent("LOOT_SLOT_CLEARED");
   self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
   self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
   self:RegisterEvent("CHAT_MSG_OPENING");
end

function LootGain_OnLoad(self)
   DEFAULT_CHAT_FRAME:AddMessage("Loot Gain " .. LootGain.version .. " loaded.");

   JoinAddonChannel();

   RegisterEvents(self);
end

