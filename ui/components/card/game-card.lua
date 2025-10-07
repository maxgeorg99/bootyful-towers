local CardElement = require "ui.components.card"
local TowerTooltip = require "ui.components.tower.elements.tooltip"

local BASE_SCALE = 0.25
local FOCUSED_SCALE = 0.5
local DRAGGED_SCALE = 0.20

---@class components.GameCard.Opts : components.Card.Opts
---@field on_selection_change? fun(card: components.GameCardElement, selected: boolean)

---@class (exact) components.GameCardElement : components.Card
---@field new fun(opts: components.GameCard.Opts): components.GameCardElement
---@field init fun(self: components.GameCardElement, opts: components.GameCard.Opts)
---@field _is_selected boolean
---@field _index number?
---@field _on_selection_change? fun(card: components.GameCardElement, selected: boolean)
---@field _tower_tooltip? components.TowerTooltip
---@field _tower_card? vibes.TowerCard
---@field set_selected fun(self: components.GameCardElement, selected: boolean)
---@field is_selected fun(self: components.GameCardElement): boolean
---@field toggle_selection fun(self: components.GameCardElement)
local GameCard = class("components.GameCardElement", { super = CardElement })

---@param opts components.GameCard.Opts
function GameCard:init(opts)
  validate(opts, {
    on_selection_change = "function?",
  })

  -- Initialize parent first
  CardElement.init(self, opts)

  -- Then set up our custom GameCard state
  self._on_selection_change = opts.on_selection_change
  self._is_selected = false
  self.name = "GameCardElement"
  self.targets.scale = BASE_SCALE

  -- Set up tower tooltip if this is a tower card
  local tower_card = self.card:get_tower_card()
  if tower_card then
    -- We'll create the tooltip when needed, not in init
    -- Store the tower card reference for later
    self._tower_card = tower_card
  end
end

--- Set the selection state of the card
---@param selected boolean
function GameCard:set_selected(selected)
  if self._is_selected == selected then
    return
  end

  self._is_selected = selected

  -- Update visual state
  if selected then
    -- self:set_z(self:get_z() + 20)
    -- self:animate_style({ scale = 1 }, { duration = 0.1 })
    self.targets.scale = FOCUSED_SCALE
  else
    self.targets.scale = BASE_SCALE

    -- self:set_z(self:get_z() - 20)
    -- self:animate_style({ scale = 0.5 }, { duration = 0.1 })
  end

  -- Notify parent component of selection change
  if self._on_selection_change then
    self._on_selection_change(self, selected)
  end
end

--- Check if the card is currently selected
---@return boolean
function GameCard:is_selected() return self._is_selected end

--- Toggle the selection state of the card
function GameCard:toggle_selection() self:set_selected(not self._is_selected) end

--- Override the click handler to manage selection
function GameCard:_click()
  -- Handle our selection logic first
  self:toggle_selection()

  -- Then call the parent's click handler if it exists
  -- Note: BaseCard._click handles the _on_click callback if present
  -- BaseCard._click(self)

  return UIAction.HANDLED
end

--- Override focus to call parent and handle tooltip
function GameCard:_focus(evt)
  -- Call parent focus handler first
  CardElement._focus(self, evt)

  -- Show tower tooltip on focus
  if self._tower_card and not self._tower_tooltip and false then
    -- Create tooltip positioned above the card
    local _, _, card_w, card_h = self:get_geo()
    local card_box = Box.new(Position.new(0, 0), card_w, card_h)

    self._tower_tooltip = TowerTooltip.new {
      card = self._tower_card,
      tower_box = card_box,
      hide_description = true,
    }
    self._tower_tooltip:set_opacity(0)
    self._tower_tooltip.pointer_placement = TooltipPlacement.BOTTOM

    -- Override the tooltip's automatic positioning to place it above the card
    local _, _, tooltip_w, tooltip_h = self._tower_tooltip:get_geo()
    local tooltip_x = 0 + (card_w - tooltip_w) / 2
    local tooltip_y = 0 - tooltip_h - 40

    self._tower_tooltip:set_pos(Position.new(tooltip_x, tooltip_y))
  end

  if self._tower_tooltip then
    Element.append_child(self, self._tower_tooltip)
    self._tower_tooltip:enter_from_tower()
  end

  return UIAction.HANDLED
end

function GameCard:_get_drag_offset()
  return {
    x = self._props.w / 2,
    y = self._props.h / 2 - 85,
  }
end

function GameCard:_blur(evt)
  CardElement._blur(self, evt)
  self.targets.scale = BASE_SCALE
  -- self:animate_style({ scale = 0.5 }, { duration = 0.2 })

  -- if not self:is_selected() then
  --   self:animate_style({ scale = 0.5 }, { duration = 0.1 })

  --   self:set_z(self:get_z() - 20)

  --   self:animate_style({ scale = 0.5 }, { duration = 0.2 })
  -- end

  -- if self._tower_tooltip then
  --   self._tower_tooltip:exit_tower()
  --   Element.remove_child(self, self._tower_tooltip)
  --   self._tower_tooltip = nil
  -- end

  return UIAction.HANDLED
end

-- function GameCard:_get_drag_position(drag_offset)
--   local ox, oy = self:_get_root_geo()
--   return {
--     x = ox,
--     y = oy,
--   }
-- end

function GameCard:get_opacity()
  local base_opacity = CardElement.get_opacity(self)
  return (1 - self._props.dragged) * base_opacity + self._props.dragged * 0.5
end

function GameCard:__tostring()
  return string.format(
    "GameCardElement(%s, %s)",
    CardElement.__tostring(self),
    self._is_selected
  )
end

function GameCard:get_scale()
  local focused = E.quadOut(self._props.focused)

  -- When focused, want to move to FOCUSED_SCALE
  -- when not focused, want to move to BASE_SCALE
  local default = (1 - focused) * BASE_SCALE + focused * FOCUSED_SCALE

  -- When starting the level, we really want to start TINY and move to BIG
  -- for COOL effects and STYLISH cards.
  local base = self._props.created * default + (1 - self._props.created) * 0.001

  -- When DRAGGED we want to go to DRAGGED_SCALE
  local dragged = self._props.dragged
  return (1 - dragged) * base + dragged * DRAGGED_SCALE
end

function GameCard:get_geo()
  local created = E.quadOut(self._props.created)

  local x, y, w, h = Element.get_geo(self)
  local parent_x, parent_y = 0, 0
  if self.parent then
    parent_x, parent_y = self.parent:get_geo()
  else
    print("no parent", self)
  end

  local offset_raw = (-100 + 3 * math.sin(TIME.frame / 60))

  -- NOT A ZERO OR ONE (BOOLEAN) ITS A SPECTRUM (BEGINS FAVORITE WORD) FROM 0 TO 1
  local y_focused_offset = self._props.focused * offset_raw
  y = y + y_focused_offset

  local deck_x = Config.ui.deck.draw.x - parent_x
  local deck_y = Config.window_size.height - 65 * 3 - parent_y + 425

  local exhausted_x = deck_x
  local exhausted_y = deck_y + 65

  x = created * x + (1 - created) * deck_x
  y = created * y + (1 - created) * deck_y

  x = (1 - self._props.removed) * x + self._props.removed * exhausted_x
  y = (1 - self._props.removed) * y + self._props.removed * exhausted_y

  -- w = w
  -- h = self._props.created * h + (1 - self._props.created) * 0.001
  -- print(x, y)

  return x, y, w, h
end

function GameCard:get_rotation()
  local base_rotation = Element.get_rotation(self)
    + math.sin(self.id + TIME.frame / 60) * 0.05
  local normal = 0 * self._props.focused
    + base_rotation * (1 - self._props.focused)

  local created = self._props.created
  return created * normal + (1 - created) * math.sin(-90)
end

function GameCard:_mouse_moved(evt, x, y)
  CardElement._mouse_moved(self, evt, x, y)
end

---@return "playable" | "unplayable"
function GameCard:card_in_hand_status()
  if State.player.energy < self.card.energy then
    return "unplayable"
  end

  local enhancement = self.card:get_enhancement_card()
  if enhancement then
    if #State.towers == 0 then
      return "unplayable"
    end

    local found_viable_tower = false
    for _, tower in ipairs(State.towers) do
      if
        tower:has_free_card_slot()
        and enhancement:can_apply_to_tower(tower)
      then
        found_viable_tower = true
        break
      end
    end

    if not found_viable_tower then
      return "unplayable"
    end
  end

  return "playable"
end

function GameCard:_render()
  local status = self:card_in_hand_status()
  if status == "unplayable" then
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
  elseif status == "playable" then
    love.graphics.setColor(1, 1, 1, 1)
  else
    print("unknown status", status)
    love.graphics.setColor(1, 1, 1, 1)
  end

  CardElement._render(self)
end

return GameCard
