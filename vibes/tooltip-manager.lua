---@class vibes.TooltipManager
---@field new fun(): vibes.TooltipManager
---@field init fun(self: vibes.TooltipManager)
---@field _persistent_tooltips table<number, components.EnemyTooltip>
local TooltipManager = class "vibes.TooltipManager"

function TooltipManager:init() self._persistent_tooltips = {} end

---@param tooltip components.EnemyTooltip
function TooltipManager:add_persistent_tooltip(tooltip)
  local id = #self._persistent_tooltips + 1
  self._persistent_tooltips[id] = tooltip
  return id
end

---@param tooltip components.EnemyTooltip
function TooltipManager:remove_persistent_tooltip(tooltip)
  for id, persistent_tooltip in pairs(self._persistent_tooltips) do
    if persistent_tooltip == tooltip then
      self._persistent_tooltips[id] = nil
      break
    end
  end
end

function TooltipManager:clear_all_persistent_tooltips()
  for _, tooltip in pairs(self._persistent_tooltips) do
    if tooltip and not tooltip:is_hidden() then
      tooltip.targets.hidden = 1
      UI.root:remove_child(tooltip)
    end
  end
  self._persistent_tooltips = {}
end

function TooltipManager:handle_escape_key() self:clear_all_persistent_tooltips() end

function TooltipManager:handle_click_away(x, y)
  -- Check if click is on any persistent tooltip
  local clicked_on_tooltip = false
  for _, tooltip in pairs(self._persistent_tooltips) do
    if
      tooltip
      and not tooltip:is_hidden()
      and tooltip:contains_absolute_x_y(x, y)
    then
      clicked_on_tooltip = true
      break
    end
  end

  -- If click is not on a tooltip, clear all persistent tooltips
  if not clicked_on_tooltip then
    self:clear_all_persistent_tooltips()
  end
end

return TooltipManager.new()
