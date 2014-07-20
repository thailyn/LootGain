local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
 end

local function LootGain_log2(x)
   return log(x) / log(2);
end

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

local function ParseItemString(itemString)
   local _, _, color, linkType, id, enchant, gem1, gem2, gem3, gem4, suffix,
   unique, linkLvl, reforgeId, upgradeId, name =
   string.find(itemString,
               "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");

   return { color = color, linkType = linkType, id = id, enchant = enchant,
            gem1 = gem1, gem2 = gem2, gem3 = gem3, gem4 = gem4, suffix = suffix,
            unique = unique, linkLvl = linkLvl, reforgeId = reforgeId,
            upgradeId = upgradeId, name = name };
end

local function LootGain_GetAttributes()
   local attributes = { };
   attributes.versions = { };
   attributes.characters = { };
   attributes.races = { };
   attributes.classes = { };
   attributes.zones = { };
   attributes.subZones = { };
   attributes.quests = { };
   attributes.sourceNames = { };
   attributes.lootTypes = { };
   attributes.items = { };

   local counts = { versions = 0, characters = 0 , races = 0, classes = 0, zones = 0,
                 subZones = 0, quests = 0, sourceNames = 0, lootTypes = 0, items = 0,
                 sources = 0};

   for k, source in ipairs (LootGain_Data.sources) do
      if source[1] == 6 then
         if attributes.versions[source[2]] == nil then
            attributes.versions[source[2]] = true;
            counts.versions = counts.versions + 1
         end

         if attributes.characters[source[4]] == nil then
            attributes.characters[source[4]] = true;
            counts.characters = counts.characters + 1;
         end

         if attributes.races[source[6]] == nil then
            attributes.races[source[6]] = true;
            counts.races = counts.races + 1;
         end

         if attributes.classes[source[8]] == nil then
            attributes.classes[source[8]] = true;
            counts.classes = counts.classes + 1;
         end

         if attributes.zones[source[12]] == nil then
            attributes.zones[source[12]] = true;
            counts.zones = counts.zones + 1;
         end

         if attributes.subZones[source[13]] == nil then
            attributes.subZones[source[13]] = true;
            counts.subZones = counts.subZones + 1;
         end

         for j, questId in ipairs (source[17]) do
            if attributes.quests[questId] == nil then
               attributes.quests[questId] = true;
               counts.quests = counts.quests + 1;
            end
         end

         if attributes.sourceNames[source[23]] == nil then
            attributes.sourceNames[source[23]] = true;
            counts.sourceNames = counts.sourceNames + 1;
         end

         if attributes.lootTypes[source[32]] == nil then
            attributes.lootTypes[source[32]] = true;
            counts.lootTypes = counts.lootTypes + 1;
         end

         for j, item in ipairs (source[33]) do
            if (item.itemLink) then
               local _, _, color, linkType, id, enchant, gem1, gem2, gem3, gem4, suffix,
               unique, linkLvl, reforgeId, upgradeId, name =
               string.find(item.itemLink,
                             "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");

               if (linkType == "item") then
                  if attributes.items[id] == nil then
                     attributes.items[id] = name;
                     counts.items = counts.items + 1;
                  end
               end
            end
         end

         counts.sources = counts.sources + 1;
      end
   end

   --LootGainPrint("Versions: " .. counts.versions);
   --for k in pairs (attributes.versions) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Characters: " .. counts.characters);
   --for k in pairs (attributes.characters) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Races: " .. counts.races);
   --for k in pairs (attributes.races) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Classes: " .. counts.classes);
   --for k in pairs (attributes.classes) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Zones: " .. counts.zones);
   --for k in pairs (attributes.zones) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Subzones: " .. counts.subZones);
   --for k in pairs (attributes.subZones) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Quests: " .. counts.quests);
   --for k in pairs (attributes.quests) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Source Names: " .. counts.sourceNames);
   --for k in pairs (attributes.sourceNames) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Loot Types: " .. counts.lootTypes);
   --for k in pairs (attributes.lootTypes) do
   --   LootGainPrint("  " .. k);
   --end

   --LootGainPrint("Items: " .. counts.items);
   --local i = 0;
   --for k in pairs (attributes.items) do
   --   if (i < 100) then
   --      LootGainPrint("  " .. gsub(k, "\124", "\124\124") .. ": " .. attributes.items[k]);
   --      i = i + 1;
   --   end
   --end

   LootGainPrint("Sources: " .. counts.sources);

   return attributes, counts;
end

local function LootGain_NumSlotsOfItem(source, itemId)
   local numSlots = 0;

   for j, item in ipairs (source[33]) do
      if (item.itemLink) then
         local itemDetails = ParseItemString(item.itemLink);
         if (itemDetails.linkType == "item") then
            if (itemDetails.id == itemId) then
               numSlots = numSlots + 1;
            end
         end
      end
   end

   return numSlots;
end

-- Given a list of sources and an item id, calculate
-- the entropy for that item.
local function LootGain_Entropy(sources, numSources, itemId)
   local splits = { };
   splits.pos = true;
   splits.neg = true;

   local splitSources = { pos = { }, neg = { } };

   for k, source in ipairs (sources) do
      if source[1] == 6 then
         local numSlots = LootGain_NumSlotsOfItem(source, itemId);
         if (numSlots > 0) then
            splitSources.pos[#splitSources.pos + 1] = source;
         else
            splitSources.neg[#splitSources.neg + 1] = source;
         end
      end
   end

   LootGainPrint("Pos: " .. #splitSources.pos);
   LootGainPrint("Neg: " .. #splitSources.neg);

   local sum = 0;
   for k in pairs(splits) do
      local prob = #splitSources[k] / numSources;
      sum = sum + prob * LootGain_log2(prob);
   end
   local entropy = -1 * sum;

   return entropy;
end

local function LootGain_GetSourceDatum(source, datumName)
   if (source[1] < 6) then
      return nil;
   end

   if (datumName == "version" or datumName == "versions") then
      return source[2];
   end

   if (datumName == "character" or datumName == "characters") then
      return source[4];
   end

   if (datumName == "race" or datumName == "races") then
      return source[6];
   end

   if (datumName == "class" or datumName == "classes") then
      return source[8];
   end

   if (datumName == "zone" or datumName == "zones") then
      return source[12];
   end

   if (datumName == "subZone" or datumName == "subZones") then
      return source[13];
   end

   if (datumName == "quest" or datumName == "quests") then
      return source[17];
   end

   if (datumName == "sourceName" or datumName == "sourceNames") then
      return source[23];
   end

   if (datumName == "lootType" or datumName == "lootTypes") then
      return source[32];
   end
end

local function LootGain_SourceHasQuest(source, questId)
   local quests = LootGain_GetSourceDatum(source, "quests");
   if (quests == nil) then
      return nil
   end

   for k, v in ipairs (quests) do
      if (v == questId) then
         return true;
      end
   end

   return false;
end

local function LootGain_SplitSourcesOnAttribute(sources, attributeType, attributeName, attributeValues)
   local splitSources = { };

   if (attributeType == "versions" or attributeType == "characters" or attributeType == "races"
       or attributeType == "classes" or attributeType == "zones" or attributeType == "subZones"
       or attributeType == "lootTypes" or attributeType == "sourceNames") then
      for k, v in pairs (attributeValues) do
         splitSources[k] = { };
      end
   elseif (attributeType == "quests") then
      for k, v in pairs (attributeValues) do
         splitSources.pos = { };
         splitSources.neg = { };
         splitSources.unk = { };
      end
   end

   for k, source in ipairs (sources) do
      if (attributeType == "quests") then
         local hasQuest = LootGain_SourceHasQuest(source, attributeName);
         if (hasQuest == true) then
            splitSources.pos[#splitSources.pos + 1] = source;
         elseif (hasQuest == false) then
            splitSources.neg[#splitSources.neg + 1] = source;
         --else
         --   splitSources.unk[#splitSources.neg + 1] = source;
         end
      else
         local datum = LootGain_GetSourceDatum(source, attributeType);
         if (datum ~= nil) then
            splitSources[datum][#splitSources[datum] + 1] = source;
         end
      end
   end

   return splitSources;
end

function LootGain_Test()
   local attributes, counts = LootGain_GetAttributes();

   --local splitSources = LootGain_SplitSourcesOnAttribute(LootGain_Data.sources,
   --                                                      "lootTypes", nil, attributes.lootTypes);

   local splitSources = LootGain_SplitSourcesOnAttribute(LootGain_Data.sources,
                                                         "quests", 31472, attributes.lootTypes);


   for k, v in pairs (splitSources) do
      LootGainPrint(k .. ": " .. #v);
   end

   --[[
   local i = 0;
   for k in pairs (attributes.items) do
      if (i > 10) then break end;

      item = k;
      itemName = attributes.items[k];

      LootGainPrint("Item: " .. item .. " / " .. itemName);
      local entropy = LootGain_Entropy(LootGain_Data.sources, counts.sources, item);
      LootGainPrint("Entropy: " .. entropy);

      i = i + 1;
   end
   --]]
end


