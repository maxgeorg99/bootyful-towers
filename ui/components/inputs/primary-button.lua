local Flux = require "vendor.flux"
local Text = require "ui.components.text"
local DEFAULT_W = 240
local DEFAULT_H = 140

---@class components.PrimaryButton.Opts
---@field box? ui.components.Box
---@field interactable? boolean
---@field on_click fun(self: components.PrimaryButton): nil

---@class (exact) components.PrimaryButton : Element
---@field new fun(opts: components.PrimaryButton.Opts): components.PrimaryButton
---@field init fun(self: components.PrimaryButton, opts: components.PrimaryButton.Opts)
---@field on_click fun(): nil
---@field background vibes.Color
---@field _clickable_background vibes.Color
---@field _unclickable_background vibes.Color
---@field _clicked_background vibes.Color
---@field _focused_background vibes.Color
---@field _asset vibes.Texture
local PrimaryButton = class("ui.components.PrimaryButton", { super = Element })

function PrimaryButton:init(opts)
  local box = opts.box or Box.new(Position.zero(), DEFAULT_W, DEFAULT_H)
  Element.init(self, box, {
    interactable = opts.interactable,
  })

  self._asset = Asset.sprites.primary_btn
  self.on_click = opts.on_click

  local _, _, w, h = self:get_geo()

  local layout = Layout.col {
    box = Box.new(Position.zero(), w, h),
    els = {
      Text.new {
        "Confirm",
        font = Asset.fonts.typography.h3,
        box = Box.new(Position.zero(), w, h),
      },
    },
  }
  self:append_child(layout)

  self._clickable_background = Colors.gray:opacity(1)
  self._unclickable_background = Colors.gray:opacity(0.5)
  self._clicked_background = Colors.burgundy:opacity(1)
  self._focused_background = Colors.burgundy:opacity(1)

  if self:is_interactable() then
    self.background = self._clickable_background
  else
    self.background = self._unclickable_background
  end
end

function PrimaryButton:_render()
  local x, y, width, height = self:get_geo()

  love.graphics.setColor(self.background)

  local points_start = {
    x,
    y, -- Top-left
    x + 40,
    y + (height / 2), -- Right tip
    x,
    y + height, -- Bottom-left
  }
  local end_x = x - 40
  local points_end = {
    end_x + width,
    y, -- Top-left
    end_x + width + 40,
    y + (height / 2), -- Right tip
    end_x + width,
    y + height, -- Bottom-left
  }

  love.graphics.polygon("fill", points_end)
  love.graphics.clear(false, true, false)
  love.graphics.stencil(
    function() love.graphics.polygon("fill", points_start) end,
    "replace",
    1
  )
  love.graphics.setStencilTest("equal", 0) -- Only draw where polygon WAS drawn
  love.graphics.rectangle("fill", x, y, width - 40, height)
  love.graphics.setStencilTest()
end
function PrimaryButton:_update(dt) Flux.update(dt) end

function PrimaryButton:_animate_background(background)
  Animation:animate_property(
    self.background,
    { unpack(background) },
    { duration = 0.8 }
  )
end

function PrimaryButton:set_interactable(i)
  Element.set_interactable(self, i)
  if i then
    self:_animate_background(self._clickable_background)
  else
    self:_animate_background(self._unclickable_background)
  end
end

function PrimaryButton:_focus()
  if not self:is_interactable() then
    return
  end

  self:_animate_background(self._focused_background)
end

function PrimaryButton:_blur()
  if not self:is_interactable() then
    return
  end

  self:_animate_background(self._clickable_background)
end

function PrimaryButton:_click() self:on_click() end

return PrimaryButton
