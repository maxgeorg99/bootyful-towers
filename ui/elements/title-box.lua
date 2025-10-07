local NineSlice = require "utils.nine-slice"
local Text = require "ui.components.text"

---@class (exact) elements.TitleBox: Element
---@field new fun(opts: elements.TitleBox.Opts): elements.TitleBox
---@field init fun(self: elements.TitleBox, opts: elements.TitleBox.Opts)
---@field kind "filled" | "empty"
---@field quads vibes.NineSlice
---@field _layout layout.Layout
local TitleBox = class("elements.TitleBox", { super = Element })

---@class elements.TitleBox.Opts
---@field title string | fun(): string
---@field box ui.components.Box
---@field kind "filled" | "empty"
---@field flex? layout.Flex
---@field els? Element[]
---@field z? number

local SCALE = 2
local PADDING = 5

--- @param opts elements.TitleBox.Opts
function TitleBox:init(opts)
  validate(opts, {
    box = Box,
    kind = "string",
    flex = "layout.Flex?",
    title = Either { "string", "function" },
    els = Optional { "table" },
    z = Optional { "number" },
  })

  Element.init(self, opts.box, { z = opts.z or 0, interactable = true })

  self.kind = opts.kind

  if opts.kind == "filled" then
    self.quads = NineSlice.new(Asset.ui.title_box_filled)
  else
    self.quads = NineSlice.new(Asset.ui.title_box_empty)
  end

  local _, _, w, h = self:get_geo()

  local scale_w = self.quads.frame_width * SCALE
  local scale_h = self.quads.frame_height * SCALE
  local x_tiles = math.floor(w / scale_w)
  local y_tiles = math.floor(h / scale_h)
  local width = scale_w * x_tiles
  local height = scale_h * y_tiles

  local title = Text.new {
    opts.title,
    box = Box.new(
      Position.new(PADDING * SCALE, (2 * SCALE) + PADDING * SCALE),
      width - (PADDING * SCALE) - (5 * SCALE),
      13 * SCALE
    ),
    color = Colors.white,
    font = Asset.fonts.typography.title_box.title,
    vertical_align = "center",
  }

  Element.append_child(self, title)

  self._layout = Layout.new {
    name = "elements.TitleBox(Layout)",
    box = Box.new(
      Position.new(PADDING * SCALE, (21 * SCALE) + PADDING * SCALE),
      width - (PADDING * SCALE) - (5 * SCALE),
      height - (PADDING * SCALE) - (28 * SCALE)
    ),
    flex = opts.flex or {
      align_items = "center",
      justify_content = "center",
      direction = "column",
      gap = 0,
    },
    els = opts.els or {},
    animation_duration = 0,
  }

  self:set_width(width)
  self:set_height(height)

  Element.append_child(self, self._layout)
end

function TitleBox:append_child(el) self._layout:append_child(el) end
function TitleBox:remove_child(el) self._layout:remove_child(el) end

function TitleBox:_render()
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

function TitleBox:_update() end
function TitleBox:_focus() end
function TitleBox:_blur() end

return TitleBox
