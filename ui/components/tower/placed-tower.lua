local CaptchaPressure = require "ui.components.tower.elements.captcha-pressure"
local ClickOnTower = require "vibes.action.click-on-tower"
local DoubleClick = require "ui.mixins.double-click"
local DropZone = require "ui.mixins.drop-zone"
local GameCardElement = require "ui.components.card.game-card"
local TowerPlacementUtils = require "ui.components.tower_placement_utils"
local TowerTooltip = require "ui.components.tower.elements.tooltip"
local TowerUIXP = require "ui.components.tower.elements.base-xp"
local rect = require "utils.rectangle"

---@class components.PlacedTower : Element, mixin.DropZone
---@field new fun(tower: vibes.TowerCard)
---@field init fun(self: components.PlacedTower, card: vibes.TowerCard)
---@field is fun(any): self? Returns the object, cast as itself if it is the correct type
---@field card vibes.TowerCard
---@field xp_ui components.TowerUIXP
---@field tower_tooltip components.TowerTooltip
---@field animated_offset number
---@field focus_opacity number
---@field shader vibes.Shader
---@field previous_z_index number
---@field cell vibes.Cell
local PlacedTower = class(
  "components.PlacedTower",
  { super = Element, mixin = { DoubleClick, DropZone } }
)

---@param card vibes.TowerCard
---@return components.PlacedTower
function PlacedTower:init(card)
  self.card = card
  self.tower = card.tower
  self.cell = self.tower.cell
  local box = TowerPlacementUtils.tower_to_ui_box(self.tower)

  Element.init(self, box, { interactable = true })

  self.name = "PlacedTower"
  self.animated_offset = 0

  -- self.z = self.tower.cell.row
  self.previous_z_index = self.z

  self.shader = ShaderEdgeOutline.new {
    texture_size = { self.tower.texture:getDimensions() },
    outline_width = 0.4,
    outline_opacity = 0.6 * 3,
    edge_threshold = 0.1,
  }

  self.focus_opacity = 0.0

  self.xp_ui = TowerUIXP.new(self.tower)

  self.tower_tooltip = TowerTooltip.new {
    card = self.card,
    tower_box = box:clone(),
    hide_description = false,
  }

  -- self.tower_tooltip:set_scale(1.1)

  self:append_child(self.xp_ui)
  self:append_child(self.tower_tooltip)

  -- If this is a Captcha tower, append the pressure indicator UI
  if self.tower._type == "vibes.CaptchaTower" then
    self:append_child(CaptchaPressure.new(self.tower))
  end
end

function PlacedTower:_mouse_enter(_evt)
  if self:is_focused() then
    -- self.previous_z_index = self.z
    -- self.tower_tooltip:enter_from_tower()
    -- self.z = Z.MAX
    return UIAction.HANDLED
  end
end

function PlacedTower:_mouse_leave()
  -- self.z = self.previous_z_index
  -- self.tower_tooltip:exit_tower()
  return UIAction.HANDLED
end

function PlacedTower:_render_outline()
  if not self:dropzone_is_hovering() and not self:dropzone_is_accepting() then
    return
  end

  local x, y, w, h = self:get_geo()

  if self:dropzone_is_hovering() then
    love.graphics.setColor(1, 1, 1) --204 / 255, 50 / 255, 51 / 255, 255 / 255)
  else
    love.graphics.setColor(42 / 255, 77 / 255, 185 / 255, 255 / 255)
  end

  love.graphics.setLineWidth(4)

  rect.dashed_rectangle(
    x - 10,
    y - 10,
    w + 20,
    h + 20,
    8,
    13,
    self.animated_offset * 0.8
  )
end

function PlacedTower:_render_range()
  love.graphics.push()

  if #ActionQueue.items == 0 then
    love.graphics.setShader(self.shader.shader)
    love.graphics.setColor(Colors.slate:opacity(self.focus_opacity))

    self.shader:send { outline_opacity = self.focus_opacity * 3 }

    love.graphics.circle(
      "fill",
      self.tower.position.x,
      self.tower.position.y,
      self.tower:get_range_in_distance()
    )

    love.graphics.setLineWidth(4)
    love.graphics.setColor(Colors.slate:opacity(self.focus_opacity * 2))
    love.graphics.circle(
      "line",
      self.tower.position.x,
      self.tower.position.y,
      self.tower:get_range_in_distance()
    )
  end

  self.tower:draw {
    hide_xp = true,
    rejected = self:dropzone_is_rejected(),
    ignore_mouse = true,
  }

  love.graphics.setShader()

  love.graphics.pop()
end

function PlacedTower:_render()
  local color = { 1, 1, 1, 1 }

  if self:is_focused() then
    self.tower:draw {
      hide_range = true,
      hide_xp = true,
      overlay = color,
      rejected = self:dropzone_is_rejected(),
    }

    local alpha = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(self.animated_offset * 0.2))
    color = { 1, 0.5, 0.5, alpha }
  end

  -- TODO: Restore enhancement card hover effect with new local selection system
  -- This needs to be redesigned to work without global State.selected_cards

  self:_render_range()
  self:_render_outline()
  -- end
end

function PlacedTower:_focus()
  self.tower_tooltip:enter_from_tower()
  Animation:animate_property(self, { focus_opacity = 0.2 }, { duration = 0.5 })
  return UIAction.HANDLED
end

function PlacedTower:_blur()
  self.tower_tooltip:exit_tower()
  Animation:animate_property(self, { focus_opacity = 0.0 }, { duration = 0.5 })
  return UIAction.HANDLED
end

--- @param dt number
function PlacedTower:_update(dt)
  if self:get_box():contains(State.mouse.x, State.mouse.y) then
    self.z = Z.OVERLAY
  else
    self.z = self.previous_z_index
  end

  self.animated_offset = (self.animated_offset + dt * 10) % 30
end

function PlacedTower:_click()
  if #ActionQueue.items > 0 then
    return UIAction.HANDLED
  end
  -- Allow tower-specific click behavior to override default UI
  if self.tower.on_clicked and self.tower:on_clicked() then
    return UIAction.HANDLED
  end

  ActionQueue:add(ClickOnTower.new { tower = self })

  self:_blur()
end

function PlacedTower:_double_click()
  if #ActionQueue.items > 0 then
    return UIAction.HANDLED
  end

  -- Allow tower-specific click behavior to override default UI
  if self.tower.on_clicked and self.tower:on_clicked() then
    return UIAction.HANDLED
  end

  ActionQueue:add(ClickOnTower.new { tower = self })
end

--- @param element Element
function PlacedTower:_dropzone_accepts_element(element)
  if not GameCardElement.is(element) then
    return false
  end

  ---@cast element components.GameCardElement

  local card = element.card:get_enhancement_card()
  if not card then
    return false
  end

  return card
    and self.tower:has_free_card_slot()
    and card:can_apply_to_tower(self.tower)
    and State.player.energy >= card.energy
end

function PlacedTower:_dropzone_on_start(_)
  print "====== dropping start ======"
  return UIAction.HANDLED
end

function PlacedTower:_dropzone_on_drop(element)
  -- Try to play the card
  if GameCardElement.is(element) then
    ---@cast element components.GameCardElement
    return element:on_use()
  end

  return UIAction.HANDLED
end

function PlacedTower:_dropzone_on_finish(_)
  print "dropping finish"
  return UIAction.HANDLED
end

return PlacedTower
