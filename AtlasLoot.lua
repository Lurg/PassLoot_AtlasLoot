-- Don't load if there is no AtlasLoot
local AL = AtlasLoot
if not AL then return end

-- Don't load if there's no AtlasLoot Favourites addon
local ALF = AtlasLoot.Addons:GetAddon("Favourites")
if not ALF then return end

local PassLoot = LibStub("AceAddon-3.0"):GetAddon("PassLoot")
local L = LibStub("AceLocale-3.0"):GetLocale("PassLoot_AtlasLoot")
local module = PassLoot:NewModule("AtlasLoot")
if not module then return end

module.Choices = {
  {
    ["Name"] = L["Any"],
    ["Value"] = 1,
  },
  {
    ["Name"] = L["Listed"],
    ["Value"] = 2,
  },
  {
    ["Name"] = L["Not Listed"],
    ["Value"] = 3,
  }
};

module.ConfigOptions_RuleDefaults = {
  -- { VariableName, Default },
  {
    "AtlasLoot",
    -- {
      -- [1] = { Value, Exception }
    -- },
  },
};

module.NewFilterValue = 2;

function module:OnEnable()
  self:RegisterDefaultVariables(self.ConfigOptions_RuleDefaults);
  self:AddWidget(self.Widget);
  self:CheckDBVersion(1, "UpgradeDatabase");
end

function module:OnDisable()
  self:UnregisterDefaultVariables();
  self:RemoveWidgets();
end

function module:UpgradeDatabase(FromVersion, Rule)
  return;
end

function module:CreateWidget()
  local Widget = CreateFrame("Frame", "PassLoot_Frames_Widgets_AtlasLoot", nil, "UIDropDownMenuTemplate");
  Widget:EnableMouse(true);
  Widget:SetHitRectInsets(15, 15, 0 ,0);
  _G[Widget:GetName().."Text"]:SetJustifyH("CENTER");
  UIDropDownMenu_SetWidth(Widget, 120);
  Widget:SetScript("OnEnter", function() self:ShowTooltip(L["FilterListName"], L["FilterListDesc"]) end);
  Widget:SetScript("OnLeave", function() GameTooltip:Hide() end);

  local Button = _G[Widget:GetName().."Button"];
  Button:SetScript("OnEnter", function() self:ShowTooltip(L["FilterListName"], L["FilterListDesc"]) end);
  Button:SetScript("OnLeave", function() GameTooltip:Hide() end);

  local Title = Widget:CreateFontString(Widget:GetName().."Title", "BACKGROUND", "GameFontNormalSmall");
  Title:SetParent(Widget);
  Title:SetPoint("BOTTOMLEFT", Widget, "TOPLEFT", 20, 0);
  Title:SetText(L["FilterListName"]);

  Widget:SetParent(nil);
  Widget:Hide();
  Widget.initialize = function(...) self:DropDown_Init(...) end;
  Widget.YPaddingTop = Title:GetHeight();
  Widget.Height = Widget:GetHeight() + Widget.YPaddingTop;
  Widget.XPaddingLeft = -15;
  Widget.XPaddingRight = -15;
  Widget.Width = Widget:GetWidth() + Widget.XPaddingLeft + Widget.XPaddingRight;
  Widget.PreferredPriority = 4;
  Widget.Info = {
    L["FilterListName"],
    L["FilterListDesc"],
  };

  return Widget;
end
module.Widget = module:CreateWidget();

-- Local function to get the data and make sure it's valid data
function module.Widget:GetData(RuleNum)
  local Data = module:GetConfigOption("AtlasLoot", RuleNum);
  local Changed = false;
  if ( Data ) then
    if ( type(Data) == "table" and #Data > 0 ) then
      for Key, Value in ipairs(Data) do
        if ( type(Value) ~= "table" or type(Value[1]) ~= "number" ) then
          Data[Key] = { module.NewFilterValue, false };
          Changed = true;
        end
      end
    else
      Data = nil;
      Changed = true;
    end
  end
  if ( Changed ) then
    module:SetConfigOption("AtlasLoot", Data);
  end
  return Data or {};
end

function module.Widget:GetNumFilters(RuleNum)
  local Value = self:GetData(RuleNum);
  return #Value;
end

function module.Widget:AddNewFilter()
  local Value = self:GetData();
  table.insert(Value, { module.NewFilterValue, false });
  module:SetConfigOption("AtlasLoot", Value);
end

function module.Widget:RemoveFilter(Index)
  local Value = self:GetData();
  table.remove(Value, Index);
  if ( #Value == 0 ) then
    Value = nil;
  end
  module:SetConfigOption("AtlasLoot", Value);
end

function module.Widget:DisplayWidget(Index)
  if ( Index ) then
    module.FilterIndex = Index;
  end
  local Value = self:GetData();
  UIDropDownMenu_SetText(module.Widget, module:GetAtlasLootText(Value[module.FilterIndex][1]));
end

function module.Widget:GetFilterText(Index)
  local Value = self:GetData();
  return module:GetAtlasLootText(Value[Index][1]);
end

function module.Widget:IsException(RuleNum, Index)
  local Data = self:GetData(RuleNum);
  return Data[Index][2];
end

function module.Widget:SetException(RuleNum, Index, Value)
  local Data = self:GetData(RuleNum);
  Data[Index][2] = Value;
  module:SetConfigOption("AtlasLoot", Data);
end

function module.Widget:ColorCheck(Red, Green, Blue)
  Red = math.floor(Red * 255 + 0.5);
  Green = math.floor(Green * 255 + 0.5);
  Blue = math.floor(Blue * 255 + 0.5);
  return ( Red == 255 and Green == 32 and Blue == 32 );
end

function module:GetAtlasLootText(ID)
  for Key, Value in ipairs(self.Choices) do
    if ( Value.Value == ID ) then
      return Value.Name;
    end
  end
  return "";
end

function module:DropDown_Init(Frame, Level)
  Level = Level or 1;
  local info = {};
  info.checked = false;
  info.notCheckable = true;
  info.func = function(...) self:DropDown_OnClick(...) end;
  info.owner = Frame;
  for Key, Value in ipairs(self.Choices) do
    info.text = Value.Name;
    info.value = Value.Value;
    UIDropDownMenu_AddButton(info, Level);
  end
end

function module:DropDown_OnClick(Frame)
  local Value = self.Widget:GetData();
  Value[self.FilterIndex][1] = Frame.value;
  self:SetConfigOption("AtlasLoot", Value);
  UIDropDownMenu_SetText(Frame.owner, Frame:GetText());
end

function module.Widget:SetMatch(ItemLink, Tooltip)
  local Listed = 2;  -- Choice 2 is listed
  local Unlisted = 3;

  local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
    linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", ItemLink)

  itemId = tonumber(itemId) or 0
  if (itemId > 0) then
    local isFavourite = (not not ALF:IsFavouriteItemID(itemId, false))

    if (isFavourite == true) then
      module.CurrentMatch = Listed
    else
      module.CurrentMatch = Unlisted
    end
  else
    print("Failed to extract itemID from link")
    module.CurrentMatch = Unlisted
  end
end

function module.Widget:GetMatch(RuleNum, Index)
  local RuleValue = self:GetData(RuleNum);
  if ( RuleValue[Index][1] > 1 ) then
    if ( RuleValue[Index][1] ~= module.CurrentMatch ) then
      return false;
    end
  end
  return true;
end
