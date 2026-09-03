require 'common'

----------------------------------------------------------------------------------------------------
-- func: echo
-- desc: Prints out a message with the Itemwatch tag at the front.
----------------------------------------------------------------------------------------------------
function echo(label, msg)
   local txt = '\31\200[\31\05' .. label .. '\31\200] \31\130' .. msg;
   print(txt);
end

----------------------------------------------------------------------------------------------------
-- func: wait
-- desc: Waits for 1, or specified amount, of seconds.
----------------------------------------------------------------------------------------------------
local function wait(seconds)
   local time = seconds or 1;
   local start = os.time();
   repeat until os.time() == start + time;
end

----------------------------------------------------------------------------------------------------
-- func: tool_tip
-- desc: Shows a tooltip with ImGui.
----------------------------------------------------------------------------------------------------
function tool_tip(imgui, desc)
   if (imgui.IsItemHovered()) then imgui.SetTooltip(desc); end
end


----------------------------------------------------------------------------------------------------
-- from sam_lie
-- Compatible with Lua 5.0 and 5.1.
-- Disclaimer : use at own risk especially for hedge fund reports :-)
-- add comma to separate thousands
----------------------------------------------------------------------------------------------------
function comma_value(amount)
   local formatted = amount;
   while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2');
      if (k == 0) then break; end
   end
   return formatted;
end

----------------------------------------------------------------------------------------------------
-- func: format_time
-- desc: show time as #h #m #s.
----------------------------------------------------------------------------------------------------
function format_time(sec)
   sec = math.floor(sec or 0)

   local h = math.floor(sec / 3600)
   local m = math.floor((sec % 3600) / 60)
   local s = sec % 60

   local parts = {}
   if h > 0 then table.insert(parts, string.format("%dh", h)) end
   if m > 0 or h > 0 then table.insert(parts, string.format("%dm", m)) end
   table.insert(parts, string.format("%ds", s))

   return table.concat(parts, " ")
end

----------------------------------------------------------------------------------------------------
-- func: round
-- returns rounded number to specific decimal places
----------------------------------------------------------------------------------------------------
function round(num, decimals)
   local mult = 10^decimals
   return math.floor(num * mult + 0.5) / mult
end

----------------------------------------------------------------------------------------------------
-- func: get_percentile
-- Returns percentile p in [0,1] for value x
-- under the triangular distribution from averaging two Uniform(min, max).
----------------------------------------------------------------------------------------------------
function get_percentile(x, min_val, max_val)
   assert(min_val < max_val, "min_val must be < max_val");

   -- Clamp x into [min_val, max_val]
   if x < min_val then x = min_val; end
   if x > max_val then x = max_val; end

   local span = max_val - min_val;
   local mid  = (min_val + max_val) / 2;

   if x <= mid then
      local t = (x - min_val) / span;
      return (2 * t * t) * 100;
   else
      local t = (max_val - x) / span;
      return (1 - 2 * t * t) * 100;
   end
end

----------------------------------------------------------------------------------------------------
-- Helper functions borrowed from luashitacast
----------------------------------------------------------------------------------------------------
function GetTimestamp()
   local rawTime = GetVanaRawTime();
   local timestamp = {};
   timestamp.day = math.floor(rawTime / 3456);
   timestamp.hour = math.floor(rawTime / 144) % 24;
   timestamp.minute = math.floor((rawTime % 144) / 2.4);
   return timestamp;
end

----------------------------------------------------------------------------------------------------
-- func: HasFishingRodEquipped
-- desc: Returns true when a fishing rod is in the ranged slot.
--
--       Rods are identified by their weapon skill rather than an item id list, so every rod is
--       covered without maintaining one. Bait and lures share skill 48, but they are ammo-slot
--       items, so looking only at the ranged slot keeps them out.
----------------------------------------------------------------------------------------------------
FishingSkillId = 48;

function HasFishingRodEquipped()
   local ranged = GetEquipment().Range;
   if (ranged == nil or ranged.Resource == nil) then return false; end

   return ranged.Resource.Skill == FishingSkillId;
end

----------------------------------------------------------------------------------------------------
-- Vana'diel clock conversions. One Vana'diel hour is 144 real seconds, so the raw timestamp read
-- from the client is already a real-life second count and can be used for the countdown directly.
----------------------------------------------------------------------------------------------------
VanaHourSeconds = 144;
VanaDaySeconds  = 144 * 24;

local pVanaTime = nil;

----------------------------------------------------------------------------------------------------
-- func: GetVanaRawTime
-- desc: Returns the raw Vana'diel timestamp, in real-life seconds. (nil if it cannot be read.)
----------------------------------------------------------------------------------------------------
function GetVanaRawTime()
   if (pVanaTime == nil or pVanaTime == 0) then
      pVanaTime = ashita.memory.find('FFXiMain.dll', 0,
                                     'B0015EC390518B4C24088D4424005068', 0,
                                     0);
   end
   if (pVanaTime == nil or pVanaTime == 0) then return nil; end

   local pointer = ashita.memory.read_uint32(pVanaTime + 0x34);
   return ashita.memory.read_uint32(pointer + 0x0C) + 92514960;
end

----------------------------------------------------------------------------------------------------
-- func: GetVanaHourIndex
-- desc: Returns a monotonically increasing index of the current Vana'diel hour, used to detect
--       when an hour boundary has been crossed.
----------------------------------------------------------------------------------------------------
function GetVanaHourIndex()
   local rawTime = GetVanaRawTime();
   if (rawTime == nil) then return nil; end

   return math.floor(rawTime / VanaHourSeconds);
end

----------------------------------------------------------------------------------------------------
-- func: GetNextPoolRefresh
-- desc: Returns the next fishing pool restock as { hour, remaining }, where hour is the Vana'diel
--       hour of the restock and remaining is the real-life seconds until it happens.
----------------------------------------------------------------------------------------------------
function GetNextPoolRefresh(hours)
   local rawTime = GetVanaRawTime();
   if (rawTime == nil) then return nil; end

   local dayOffset = rawTime % VanaDaySeconds;
   local nextHour, nextRemaining;

   for _, hour in ipairs(hours) do
      local remaining = ((hour * VanaHourSeconds) - dayOffset) % VanaDaySeconds;

      -- Sitting exactly on a restock means that one just fired, so look ahead to the following one.
      if (remaining == 0) then remaining = VanaDaySeconds; end

      if (nextRemaining == nil or remaining < nextRemaining) then
         nextHour = hour;
         nextRemaining = remaining;
      end
   end

   if (nextHour == nil) then return nil; end

   return { hour = nextHour, remaining = nextRemaining };
end

function GetWeather()
   local pWeather = ashita.memory.find('FFXiMain.dll', 0,
                                     '66A1????????663D????72', 0, 0);
   local pointer = ashita.memory.read_uint32(pWeather + 0x02);
   return ashita.memory.read_uint8(pointer + 0);
end

function GetMoon(moon)
   local timestamp = GetTimestamp();
   local moon_index = ((timestamp.day + 26) % 84) + 1;
   local moon_table = {};
   moon_table.MoonIndex = moon_index;
   moon_table.MoonPhase = moon.Phase[moon_index];
   moon_table.MoonPhasePercent = moon.PhasePercent[moon_index];
   return moon_table;
end

--=============================================================================
-- Return equipment data
---@return table equipTable Current equipment information
--=============================================================================
-- based on code from LuAshitacast by Thorny
-- revised function taken from chains
--=============================================================================
-- Combined gData.GetEquipment and gEquip.GetCurrentEquip
--=============================================================================
GetEquipment = function()
    local inventoryManager = AshitaCore:GetMemoryManager():GetInventory();
    local equipTable = {};

    for k, v in pairs(EquipSlotNames) do
        local equippedItem = inventoryManager:GetEquippedItem(k - 1);
        local index = bit.band(equippedItem.Index, 0x00FF);
        local eqEntry = {};
        if (index == 0) then
            eqEntry.Container = 0;
            eqEntry.Item = nil;
        else
            eqEntry.Container = bit.band(equippedItem.Index, 0xFF00) / 256;
            eqEntry.Item = inventoryManager:GetContainerItem(eqEntry.Container, index);
            if (eqEntry.Item.Id == 0) or (eqEntry.Item.Count == 0) then
                eqEntry.Item = nil;
            end
        end
        if (type(eqEntry) == 'table') and (eqEntry.Item ~= nil) then
            local resource = AshitaCore:GetResourceManager():GetItemById(eqEntry.Item.Id);
            if (resource ~= nil) then
                local singleTable = {};
                singleTable.Container = eqEntry.Container;
                singleTable.Item = eqEntry.Item;
                singleTable.Name = resource.Name[1];
                singleTable.Resource = resource;
                equipTable[v] = singleTable;
            end
        end
    end

    return equipTable;
end