local NineSlice = require "utils.nine-slice"
---@class (exact) elements.DynamicDialog : Element
---@field new fun(opts: elements.DynamicDialog.Opts): elements.DynamicDialog
---@field init fun(self: elements.DynamicDialog, opts: elements.DynamicDialog.Opts)
---@field kind "filled" | "empty"
---@field quads vibes.NineSlice
---@field _layout layout.Layout
local DynamicDialog = class("elements.Box", { super = Element })

---@class elements.DynamicDialog.Opts : Element.Opts
---@field kind "filled" | "empty"
---@field element Element
---@field pos? vibes.Position

local SCALE = 2
local PADDING = 5

--- @param opts elements.DynamicDialog.Opts
function DynamicDialog:init(opts)
  validate(opts, {
    kind = "string",
  })

  Element.init(self, opts.element:get_box(), opts)

  if opts.pos then
    self:set_pos(opts.pos)
  end

  self:set_width(self:get_width() + 20)
  self:set_height(self:get_height() + 25)

  self.kind = opts.kind

  if opts.kind == "filled" then
    self.quads = NineSlice.new(Asset.ui.box_filled)
  else
    self.quads = NineSlice.new(Asset.ui.box_empty)
  end

  local _, _, w, h = self:get_geo()

  self._layout = Layout.new {
    name = "elements.Box(Layout)",
    box = Box.new(
      Position.new(PADDING * SCALE, PADDING * SCALE),
      w - (PADDING * SCALE) - (5 * SCALE),
      h - (PADDING * SCALE) - (7 * SCALE)
    ),
    flex = {
      align_items = "center",
      justify_content = "center",
      direction = "column",
      gap = 0,
    },
    els = { opts.element },
    animation_duration = 0,
  }

  Element.append_child(self, self._layout)
end
function DynamicDialog:append_child(el) self._layout:append_child(el) end
function DynamicDialog:remove_child(el) self._layout:remove_child(el) end

function DynamicDialog:_render()
  local pos_x, pos_y, w, h = self:get_geo()
  local corner_width = self.quads.frame_width * SCALE
  local corner_height = self.quads.frame_height * SCALE

  local middle_width = w - (2 * corner_width)
  local middle_height = h - (2 * corner_height)

  local middle_width_scale = middle_width / self.quads.frame_width
  local middle_height_scale = middle_height / self.quads.frame_height

  love.graphics.draw(
    self.quads.image,
    self.quads.top_left,
    pos_x,
    pos_y,
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.quads.image,
    self.quads.top_right,
    pos_x + w - corner_width,
    pos_y,
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.quads.image,
    self.quads.bottom_left,
    pos_x,
    pos_y + h - corner_height,
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.quads.image,
    self.quads.bottom_right,
    pos_x + w - corner_width,
    pos_y + h - corner_height,
    0,
    SCALE,
    SCALE
  )

  if middle_width > 0 then
    love.graphics.draw(
      self.quads.image,
      self.quads.top_center,
      pos_x + corner_width,
      pos_y,
      0,
      middle_width_scale,
      SCALE
    )

    love.graphics.draw(
      self.quads.image,
      self.quads.bottom_center,
      pos_x + corner_width,
      pos_y + h - corner_height,
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
      pos_y + corner_height,
      0,
      SCALE,
      middle_height_scale
    )

    love.graphics.draw(
      self.quads.image,
      self.quads.middle_right,
      pos_x + w - corner_width,
      pos_y + corner_height,
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
      pos_y + corner_height,
      0,
      middle_width_scale,
      middle_height_scale
    )
  end
end
function DynamicDialog:_update() end
function DynamicDialog:_focus() end
function DynamicDialog:_blur() end

return DynamicDialog
