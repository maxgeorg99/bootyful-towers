local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"
local Tooltip = require "ui.components.tooltip"
---@class (exact) elements.UpgradeButton : Element
---@field new fun(opts: elements.UpgradeButton.Opts): elements.UpgradeButton
---@field init fun(self: elements.UpgradeButton, opts: elements.UpgradeButton.Opts)
---@field asset vibes.Texture
---@field button_bottom component.ScaledImg
---@field icon vibes.Texture
---@field value fun():string
---@field _on_click fun()
---@field tooltip ui.components.Tooltip?
---@field description string?
---@field font love.Font
---@field description_w number
local UpgradeButton = class("elements.UpgradeButton", { super = Element })

---@class elements.UpgradeButton.Props : Element.Props

---@class elements.UpgradeButton.Opts
---@field position vibes.Position
---@field icon_type IconType
---@field rarity Rarity
---@field description? string
---@field value fun():string
---@field on_click fun()

local SCALE = 2

--- @param opts elements.UpgradeButton.Opts
function UpgradeButton:init(opts)
  validate(opts, {
    position = Position,
    icon_type = IconType,
    rarity = Rarity,
    description = "string",
    value = "function",
    on_click = "function",
  })
  Element.init(
    self,
    Box.new(opts.position, 62 * SCALE, 28 * SCALE),
    { interactable = true }
  )
  self.description = opts.description or "No description provided"
  self.asset = Asset.ui.upgrade_button[opts.rarity]
  self.icon = Asset.icons[opts.icon_type]
  self.value = opts.value
  self._on_click = opts.on_click
  self.description = opts.description
  self.tooltip = nil
  if self.description then
    self.font = Asset.fonts.typography.h5
    self.description_w = self.font:getWidth(self.description)
  end
end

function UpgradeButton:_render()
  local pressed_offset_y = 8

  local x, y = self:get_geo()

  local button_y = y + self._props.pressed * pressed_offset_y

  ScaledImage.new({
    box = Box.new(Position.new(x, y + 26 * SCALE), 62 * SCALE, 4 * SCALE),
    texture = Asset.ui.button_bottom,
    scale_style = "fill",
  }):_render()
  love.graphics.setFont(Asset.fonts.typography.hud.numbers)

  self:with_color(Colors.white, function()
    love.graphics.draw(self.asset, x, button_y, 0, SCALE, SCALE)
    love.graphics.draw(
      self.icon,
      x + (5 * SCALE),
      button_y + (6 * SCALE),
      0,
      SCALE,
      SCALE
    )

    love.graphics.printf(
      self:value(),
      x + 31 * SCALE,
      button_y + 7.5 * SCALE,
      25 * SCALE,
      "center"
    )
  end)

  if
    self:get_box():contains(State.mouse.x, State.mouse.y) and self.description
  then
    Text.new({
      self.description,
      box = Box.new(
        Position.new(x, y + 40 * SCALE),
        self.description_w + 30,
        60
      ),
      background = Colors.dark_red,
      rounded = 10,
      font = self.font,
    }):_render()
  end
end

function UpgradeButton:_mouse_enter()
  -- self.tooltip = Tooltip.new(self.description, self, 200, "NEAR_ELEMENT")
  -- UI.root:append_child(self.tooltip)
  return UIAction.HANDLED
end

function UpgradeButton:_mouse_leave()
  logger.debug "UpgradeButton:_mouse_leave called"
  -- Hide and clean up tooltip
  if self.tooltip then
    if self.tooltip.parent then
      self.tooltip.parent:remove_child(self.tooltip)
    end
    self.tooltip = nil
  end
  return UIAction.HANDLED
end

function UpgradeButton:_click()
  -- Hide tooltip when clicked
  if self.tooltip then
    if self.tooltip.parent then
      self.tooltip.parent:remove_child(self.tooltip)
    end
    self.tooltip = nil
  end

  self._on_click()
end
function UpgradeButton:_update() end
function UpgradeButton:_focus() end
function UpgradeButton:_blur() end

return UpgradeButton
