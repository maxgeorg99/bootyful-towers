---@class components.Hand : Element
---@field new fun(opts: components.Hand.Opts): components.Hand
---@field init fun(self: components.Hand, opts: components.Hand.Opts)
---@field cards components.Card[]
---@field children components.GameCardElement[]
local Hand = class("components.Hand", { super = Element })

local BASE_SCALE = 0.25

---@class components.Hand.Opts
---@field box ui.components.Box
---@field cards? components.Card[]
---@field create_card fun(card: components.Card): components.GameCardElement

---@param opts components.Hand.Opts
function Hand:init(opts)
  Element.init(self, opts.box, {
    interactable = false,
    draggable = false,
    z = F.if_nil(opts.z, Z.DECK),
  })

  self.cards = opts.cards or State.deck.hand
  self.element_lookup = {}
  self.create_card = opts.create_card
end

function Hand:add_card(card)
  table.insert(self.cards, card)
  self:update_card_base_positions()
end

function Hand:update_card_base_positions()
  -- Create a beautiful fan layout that handles both even and odd card counts perfectly
  local n = #self.cards
  if n == 0 then
    return
  end

  -- Configuration for the fan
  local new_height = 440
  local scale_factor_for_padding = 1.1

  local base_card_overlap = BASE_SCALE * new_height / 10 -- How much cards overlap each other (positive = more overlap)
  local max_angle = math.rad(10) -- Maximum rotation angle (in radians)
  local arc_height = new_height / 8 -- How much the cards arc down at the edges

  -- Calculate the center index (this is the key to handling even/odd properly!)
  local center_index = (n + 1) / 2 -- This works for both even and odd!
  local _, _, hand_width, hand_height = self:get_geo()

  --- Calculate the effective width of a card for hand layout based on drag distance
  ---@param card components.Card: The card to calculate width for
  ---@param index number: Card's index in the hand
  ---@param count number: Total number of cards
  ---@return number, number, number: left_padding, effective_width, right_padding
  local get_effective_width_for_layout = function(card, index, count)
    local cx, cy, cw, ch = card:get_geo()
    local c_scale = card:get_scale()

    -- Calculate base padding (existing logic)
    local additional_left_padding
    if index <= math.floor(count / 2) then
      additional_left_padding = base_card_overlap * 10
    else
      additional_left_padding = base_card_overlap * 15
    end

    local additional_right_padding = 0

    local base_left = (c_scale - BASE_SCALE)
      * (scale_factor_for_padding + additional_left_padding)
      / 2
    local base_right = (c_scale - BASE_SCALE)
      * (scale_factor_for_padding + additional_right_padding)
      / 2

    -- Calculate drag distance effect on width (always calculate, multiply by dragging param)
    local drag_width_reduction = 0
    local dragging = card._props.dragged or 0

    if dragging > 0 and card._drag_state.offset then
      local drag_offset = card._drag_state.offset

      -- Calculate distance from hand position to absolute drag position
      local hand_center_x = cx + cw / 2
      local hand_center_y = cy + ch / 2
      local drag_center_x = drag_offset.x + cw / 2
      local drag_center_y = drag_offset.y + ch / 2
      local dx = drag_center_x - hand_center_x
      local dy = drag_center_y - hand_center_y
      local drag_distance = math.sqrt(dx * dx + dy * dy)

      -- Define thresholds for width reduction
      local MIN_DRAG_DISTANCE = 200 -- Distance where width reduction starts
      local MAX_DRAG_DISTANCE = 1000 -- Distance where width becomes nearly zero

      if drag_distance > MIN_DRAG_DISTANCE then
        -- Calculate how far we are between min and max distance
        local distance_ratio = math.min(
          1.0,
          (drag_distance - MIN_DRAG_DISTANCE)
            / (MAX_DRAG_DISTANCE - MIN_DRAG_DISTANCE)
        )

        -- Use smooth easing for the width reduction
        local anim = require "vibes.anim"
        local eased_ratio = anim.Ease.easeInOutCubic(distance_ratio)

        -- Calculate maximum width reduction (0.9 = 90% reduction)
        drag_width_reduction = eased_ratio * 0.9
      end
    end

    -- Apply width reduction scaled by dragging parameter
    local width_multiplier = 1.0 - (drag_width_reduction * dragging)

    -- Apply width multiplier to all components
    local effective_left = base_left * width_multiplier
      + card._props.focused * 100
    local effective_width = cw * width_multiplier
    local effective_right = base_right * width_multiplier
      + card._props.focused * 100

    return effective_left * c_scale,
      effective_width * c_scale,
      effective_right * c_scale
  end

  -- First pass: collect all card widths (accounting for drag distance)
  local card_layouts = {}
  local total_cards_width = 0
  for i, card in ipairs(self.children) do
    local left, width, right = get_effective_width_for_layout(card, i, n)
    local spacing = left + width + right
    card_layouts[i] = {
      left = left,
      width = width,
      right = right,
      spacing = spacing,
    }
    total_cards_width = total_cards_width + spacing
  end

  -- Calculate total fan width with overlap (subtract overlap from total width)
  local total_overlap = (n - 1) * base_card_overlap
  local total_fan_width = math.max(total_cards_width - total_overlap, 0)
  local fan_width = math.min(total_fan_width, hand_width)
  if fan_width < total_fan_width then
    local compression_ratio = fan_width / total_fan_width
    for _, layout in ipairs(card_layouts) do
      layout.left = layout.left * compression_ratio
      layout.width = layout.width * compression_ratio
      layout.right = layout.right * compression_ratio
      layout.spacing = layout.spacing * compression_ratio
    end
    total_fan_width = fan_width
    base_card_overlap = base_card_overlap * compression_ratio
  end

  -- Center the fan properly within the hand bounds
  local fan_center_x = hand_width / 2
  local start_x = fan_center_x - total_fan_width / 2

  -- Second pass: position each card accounting for varying widths
  local current_x = start_x
  for i, card in ipairs(self.children) do
    local base_width = card._props.w
    local base_height = card._props.h
    local card_scale = card:get_scale()
    local scaled_height = base_height * card_scale

    -- Distance from center (negative for left side, positive for right side)
    local distance_from_center = i - center_index

    local card_layout = card_layouts[i]
    local left = card_layout.left
    local width = card_layout.width
    local right = card_layout.right

    -- Calculate target position - each card positioned with overlap
    local target_x = current_x + left
    current_x = current_x + card_layout.spacing - base_card_overlap

    -- Target rotation: smooth interpolation from -max_angle to +max_angle
    local normalized_distance = distance_from_center / (n / 2) -- Normalize to [-1, 1] range
    local target_rotation = normalized_distance * max_angle

    -- Y position: create a circular arc where all cards follow a circle
    -- Calculate the card's position relative to hand center
    local card_center_x = target_x + width / 2
    local hand_center_x = hand_width / 2
    local horizontal_distance = card_center_x - hand_center_x

    -- Create a circular arc using the distance from center
    local target_y
    local max_horizontal_distance = total_fan_width / 2
    if max_horizontal_distance > 0 then
      -- Normalize the horizontal distance to [-1, 1] range
      local normalized_x = horizontal_distance / max_horizontal_distance

      -- Calculate Y using circular arc formula: y = sqrt(1 - x^2)
      -- But we want the bottom of a circle, so we invert it
      local circle_y = 1
        - math.sqrt(math.max(0, 1 - normalized_x * normalized_x))

      -- Scale the arc by our desired arc height
      local arc_drop = arc_height * circle_y

      target_y = (hand_height - scaled_height) / 2 + arc_drop
    else
      -- Fallback for single card
      target_y = (hand_height - scaled_height) / 2
    end

    -- Set target positions for velocity-based movement
    local scale_offset_x = (card_scale - 1) * base_width / 2
    local scale_offset_y = (card_scale - 1) * base_height / 2

    card._props.x = target_x + scale_offset_x
    card._props.y = target_y + scale_offset_y
    -- card._props.rotation = target_rotation
    card:set_rotation(target_rotation)
  end
end

function Hand:_update(dt)
  local dirty = #self.cards ~= #self.children

  for i, card in ipairs(self.cards) do
    if not self.element_lookup[card.id] then
      dirty = true
      self.element_lookup[card.id] = self.create_card(card)
    end

    self.children[i] = self.element_lookup[card.id]
    self.children[i]:set_z(Z.BASE_CARD + 0.1 * i)
  end

  for i = #self.children, #self.cards do
    dirty = true
    self.children[i] = nil
  end

  if dirty and #self.cards > 0 then
    -- error(inspect { "Dirty", cards = self.cards, children = self.children })
    self:remove_all_children()
    for _, card in ipairs(self.cards) do
      self:append_child(self.element_lookup[card.id])
    end
  end

  if #self.cards == 0 and #self.children > 0 then
    self:remove_all_children()
  end

  self:update_card_base_positions()
end

function Hand:discard_hand()
  local animation_duration = 0.3
  for _, card_element in ipairs(self.children) do
    State.deck:discard_card(card_element.card)

    card_element:animate_to_absolute_position(
      Config.ui.deck.discard,
      { duration = animation_duration * 0.8 }
    )

    -- card_element:animate_style({ opacity = 0 }, {
    --   duration = animation_duration,
    --   on_complete = function() card_element:set_opacity(1) end,
    -- })
  end
end

function Hand:_render() end

return Hand
