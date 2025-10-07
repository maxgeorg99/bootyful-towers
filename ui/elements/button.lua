local NineSlice = require "utils.nine-slice"
local anim = require "vibes.anim"
---@class (exact) elements.Button : Element
---@field new fun(opts: elements.Button.Opts): elements.Button
---@field init fun(self: elements.Button, opts: elements.Button.Opts)
---@field label string
---@field quads vibes.NineSlice
---@field font love.Font
---@field _on_click fun()
---@field _background vibes.Color
local Button = class("elements.Button", { super = Element })

---@class elements.Button.Opts
---@field box ui.components.Box
---@field label string
---@field on_click fun()

local SCALE = 2

--- @param opts elements.Button.Opts
function Button:init(opts)
  validate(opts, {
    box = Box,
    label = "string",
    on_click = "function",
  })

  Element.init(self, opts.box, { interactable = true, z = Z.GAME_UI })

  self.label = opts.label
  self._on_click = opts.on_click
  self.font = Asset.fonts.typography.h5
  self.quads = NineSlice.new(Asset.ui.button)
  self._background = Colors.white

  local _, _, w, h = self:get_geo()

  local scale_w = self.quads.frame_width * SCALE
  local scale_h = self.quads.frame_height * SCALE
  local x_tiles = math.floor(w / scale_w)
  local y_tiles = math.floor(h / scale_h)
  local width = scale_w * x_tiles
  local height = scale_h * y_tiles

  self:set_width(width)
  self:set_height(height)
end

function Button:_render()
  local pressed_offset_x = 2
  local pressed_offset_y = 5
  local pos_x, pos_y, w, h = self:get_geo()
  local button_x, button_y =
    pos_x + (1 - self._props.pressed) * pressed_offset_x,
    pos_y + (self._props.pressed - 1) * pressed_offset_y

  self:with_color(
    Colors.button_brown:opacity(0.9 * self:get_opacity()),
    function()
      love.graphics.rectangle(
        "fill",
        pos_x - pressed_offset_x,
        pos_y + pressed_offset_y,
        w,
        h - 5
      )
    end
  )

  local corner_width = self.quads.frame_width * SCALE
  local corner_height = self.quads.frame_height * SCALE

  local middle_width = w - (2 * corner_width)
  local middle_height = h - (2 * corner_height)

  local middle_width_scale = middle_width / self.quads.frame_width
  local middle_height_scale = middle_height / self.quads.frame_height

  self:with_color(self._background, function()
    love.graphics.draw(
      self.quads.image,
      self.quads.top_left,
      pos_x,
      button_y,
      0,
      SCALE,
      SCALE
    )

    love.graphics.draw(
      self.quads.image,
      self.quads.top_right,
      pos_x + w - corner_width,
      button_y,
      0,
      SCALE,
      SCALE
    )

    love.graphics.draw(
      self.quads.image,
      self.quads.bottom_left,
      pos_x,
      button_y + h - corner_height,
      0,
      SCALE,
      SCALE
    )

    love.graphics.draw(
      self.quads.image,
      self.quads.bottom_right,
      pos_x + w - corner_width,
      button_y + h - corner_height,
      0,
      SCALE,
      SCALE
    )

    if middle_width > 0 then
      love.graphics.draw(
        self.quads.image,
        self.quads.top_center,
        pos_x + corner_width,
        button_y,
        0,
        middle_width_scale,
        SCALE
      )

      love.graphics.draw(
        self.quads.image,
        self.quads.bottom_center,
        pos_x + corner_width,
        button_y + h - corner_height,
        0,
        middle_width_scale,
        SCALE
      )
    end

    if middle_height > 0 then
      love.graphics.draw(
        self.quads.image,
        self.quads.middle_left,
        pos_x,
        button_y + corner_height,
        0,
        SCALE,
        middle_height_scale
      )

      love.graphics.draw(
        self.quads.image,
        self.quads.middle_right,
        pos_x + w - corner_width,
        button_y + corner_height,
        0,
        SCALE,
        middle_height_scale
      )
    end

    if middle_width > 0 and middle_height > 0 then
      love.graphics.draw(
        self.quads.image,
        self.quads.middle_center,
        pos_x + corner_width,
        button_y + corner_height,
        0,
        middle_width_scale,
        middle_height_scale
      )
    end
    love.graphics.setFont(self.font)

    local label_h = self.font:getHeight()

    love.graphics.printf(
      self.label,
      button_x,
      button_y + (h / 2) - (label_h / 2),
      w,
      "center"
    )
  end)
end
function Button:_click() self:_on_click() end
function Button:_update() end
function Button:_focus() end
function Button:_blur() end

return Button
