local Img = require "ui.components.img"
local Text = require "ui.components.text"

---@class components.shop.Pack.Opts
---@field box ui.components.Box
---@field pack vibes.ShopPack
---@field on_click? fun(pack: vibes.ShopPack): nil
---@field z number?
---@field interactable? boolean

---@class (exact) components.shop.Pack : Element
---@field new fun(opts: components.shop.Pack.Opts): components.shop.Pack
---@field init fun(self: components.shop.Pack, opts: components.shop.Pack.Opts)
---@field pack vibes.ShopPack
---@field on_click? fun(pack: vibes.ShopPack): nil
---@field _wiggle_timer number
---@field _is_wiggling boolean
local Pack = class("components.shop.Pack", { super = Element })

---@param opts components.shop.Pack.Opts
function Pack:init(opts)
  validate(opts, {
    box = Box,
    pack = "table", -- vibes.ShopPack
    on_click = "function?",
  })

  Element.init(self, opts.box, {
    interactable = F.if_nil(opts.interactable, true),
    z = F.if_nil(opts.z, Z.BUTTON_DEFAULT),
  })

  self.pack = opts.pack
  self.on_click = opts.on_click
  self.name = "Pack"
  self._wiggle_timer = 0
  self._is_wiggling = false

  self:_add_pack_image()
  self:_add_pack_name()
  self:_add_pack_cost()
end

function Pack:_add_pack_image()
  local x, y, width, height = self:get_geo()

  -- Scale the pack texture to fit the box
  local scale_w = width / self.pack.texture:getWidth()
  local scale_h = height / self.pack.texture:getHeight()
  local scale = math.min(scale_w, scale_h) * 0.8 -- Leave some padding

  local img = Img.new(self.pack.texture, scale, scale)

  -- Center the image in the box (relative to parent)
  local img_width = self.pack.texture:getWidth() * scale
  local img_height = self.pack.texture:getHeight() * scale
  local img_x = (width - img_width) / 2
  local img_y = (height - img_height) / 2

  img:set_pos(Position.new(img_x, img_y))
  self:append_child(img)
end

function Pack:_add_pack_name()
  local x, y, width, height = self:get_geo()

  -- local name_text = Text.new {
  --   self.pack.name,
  --   box = Box.new(Position.new(0, height * 0.75), width, height * 0.15),
  --   font = Asset.fonts.typography.paragraph_lg,
  --   color = Colors.white:get(),
  --   text_align = "center",
  -- }
  -- self:append_child(name_text)
end

function Pack:_add_pack_cost()
  local x, y, width, height = self:get_geo()

  local cost_font = Asset.fonts.typography.paragraph_md
  local cost_height = cost_font:getHeight()
  local cost_width = width * 0.6
  local cost_text = Text.new {
    function() return "{gold:" .. self.pack.cost .. "}" end,
    box = Box.new(
      Position.new((width - cost_width) / 2, height * 1.15),
      cost_width,
      cost_height
    ),
    font = cost_font,
    text_align = "center",
  }

  self:append_child(cost_text)
end

function Pack:_click(evt)
  if self.on_click then
    self.on_click(self.pack)
  end
end

function Pack:_focus(evt, x, y) self:_start_wiggle() end
function Pack:_blur(evt, x, y) self:_stop_wiggle() end

function Pack:_start_wiggle()
  if not self._is_wiggling then
    self._is_wiggling = true
    self._wiggle_timer = 0
  end
end

function Pack:_stop_wiggle()
  if self._is_wiggling then
    self._is_wiggling = false

    self:animate_style({
      scale = 1.0,
      rotation = 0,
    }, {
      duration = 0.5,
      easing = "easein",
    })
  end
end

function Pack:_update(dt)
  if self._is_wiggling then
    self._wiggle_timer = self._wiggle_timer + dt

    -- Create a subtle continuous wiggle while hovering
    local wiggle_frequency = 3 -- Hz
    local wiggle_amplitude = math.rad(1) -- 1 degree amplitude

    local wiggle_rotation = math.sin(
      self._wiggle_timer * wiggle_frequency * math.pi * 2
    ) * wiggle_amplitude
    self:set_rotation(wiggle_rotation)
  end
end

function Pack:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background
  local color = Colors.black:opacity(0.2)

  self:with_color(
    color,
    function() love.graphics.rectangle("fill", x, y, width, height, 8, 8) end
  )
end

function Pack:__tostring() return string.format("Pack(%s)", self.pack.name) end

return Pack
