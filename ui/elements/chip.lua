---@class (exact) elements.Chip : Element
---@field new fun(opts: elements.Chip.Opts): elements.Chip
---@field init fun(self: elements.Chip, opts: elements.Chip.Opts)
---@field asset vibes.Texture
---@field icon vibes.Texture
---@field value fun():string
---@field _on_click fun()
local Chip = class("elements.Chip", { super = Element })

---@class elements.Chip.Props : Element.Props

---@class elements.Chip.Opts
---@field position vibes.Position
---@field icon_type IconType
---@field value fun():string
---@field on_click fun()

local SCALE = 2

--- @param opts elements.Chip.Opts
function Chip:init(opts)
  validate(opts, {
    position = Position,
    icon_type = IconType,
    value = "function",
    on_click = "function",
  })
  Element.init(
    self,
    Box.new(opts.position, 43 * SCALE, 24 * SCALE),
    { interactable = true }
  )
  self.asset = Asset.ui.chip_wide
  self.icon = Asset.icons[opts.icon_type]
  self.value = opts.value
  self._on_click = opts.on_click
end

function Chip:_render()
  local pressed_offset_y = 8

  local x, y = self:get_geo()

  local button_y = y + self._props.pressed * pressed_offset_y

  love.graphics.setFont(Asset.fonts.typography.hud.numbers)
  self:with_color(Colors.white, function()
    love.graphics.draw(self.asset, x, button_y, 0, SCALE, SCALE)
    love.graphics.draw(self.icon, x, button_y - (7 * SCALE), 0, SCALE, SCALE)
    love.graphics.printf(
      self:value(),
      x + 31 * SCALE,
      button_y + 5 * SCALE,
      14 * SCALE,
      "left"
    )
  end)
end

function Chip:_click() self._on_click() end
function Chip:_update() end
function Chip:_focus() end
function Chip:_blur() end

return Chip
