local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"

---@class components.Card.Opts.Drag
---@field enable boolean
---@field on_drag_start function(evt:ui.components.UIMouseEvent)
---@field on_drag_end function(evt:ui.components.UIMouseEvent)
---@field on_drag function(evt:ui.components.UIMouseEvent)

---@class components.Card.Opts: Element.Opts
---@field box ui.components.Box
---@field card vibes.Card
---@field drag? components.Card.Opts.Drag
---@field on_use? function(card: components.Card)
---@field on_drag_start? function(card: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field on_drag? function(card: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field on_drag_end? function(card: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field on_focus? function(card: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field on_blur? function(card: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field on_click? function(card: components.Card): UIAction?
---@field on_update? function(card: components.Card, dt: number)

---@class components.Card : Element
---@field new fun(opts: components.Card.Opts)
---@field init fun(self:components.Card, opts:components.Card.Opts)
---@field card vibes.Card
---@field _canvas love.Canvas
---@field _create_canvas function(): love.Canvas
---@field _scale number
---@field hide_level boolean
---
---@field _on_use fun(self: components.Card)
---@field _on_drag_start fun(self: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field _on_drag fun(self: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field _on_drag_end fun(self: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field _on_focus fun(self: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field _on_blur fun(self: components.Card, evt: ui.components.UIMouseEvent): UIAction?
---@field _on_click fun(self: components.Card): UIAction?
---@field _on_update fun(self: components.Card, dt: number)
local Card = class("components.Card", { super = Element })

local CARD_W = Config.ui.card.new_width
local CARD_H = Config.ui.card.new_height
local LEVEL_DIMENSION = 40

function Card:init(opts)
  validate(opts, {
    box = Box,
    card = require "vibes.card.base",
    on_use = "function?",
    on_drag_start = "function?",
    on_drag = "function?",
    on_drag_end = "function?",
    on_focus = "function?",
    on_blur = "function?",
    on_click = "function?",
    on_update = "function?",
  })

  self._on_use = opts.on_use
  self._on_drag_start = opts.on_drag_start
  self._on_drag = opts.on_drag
  self._on_drag_end = opts.on_drag_end
  self._on_focus = opts.on_focus
  self._on_blur = opts.on_blur
  self._on_click = opts.on_click
  self._on_update = opts.on_update

  Element.init(self, opts.box, { interactable = true, draggable = true })

  self._scale = math.min(opts.box.width / CARD_W, opts.box.height / CARD_H)
  self.card = opts.card

  self._canvas = self:_create_canvas()

  self._tower_card = self.card:get_tower_card()

  if self._tower_card then
    self._tower_texture = ScaledImage.new {
      box = Box.new(Position.new(0, 5), CARD_W, CARD_H * 1 / 2),
      texture = self._tower_card.tower.texture,
      scale_style = "fit",
    }

    self._shader = ShaderBoundaryOutline.new {
      outline_color = { 0.0, 0.0, 0.0, 1.0 },
      texture_size = { self._tower_card.tower.texture:getDimensions() },
      feather_amount = 0.0,
    }

    self._tower_texture:add_shader(self._shader, "alpha")
  end

  -- self.shader = ShaderCard3DTilt.new {
  --   u_mouse = { -1, -1 },
  --   u_tilt_strength = 0.2,
  -- }
  -- self:add_shader(self.shader, "alpha")
end

function Card:_create_canvas()
  local _, _, width, height = self:get_geo()

  if width <= 0 or height <= 0 then
    return nil
  end

  return love.graphics.newCanvas(width, height)
end

function Card:_mouse_enter() end

function Card:_mouse_moved(evt, x, y)
  -- self.shader:send {
  --   u_mouse = { x, y },
  -- }

  -- local mx, my = State.mouse.x, State.mouse.y
  -- local card_x, card_y, w, h = self:get_geo()
  -- local relative_x = (mx - card_x) / w
  -- local relative_y = (my - card_y) / h

  -- -- Send normalized mouse coordinates (0-1 range) to the tilt shader
  -- local coords = { relative_x, relative_y }

  -- self.shader:send {
  --   u_mouse = coords,
  -- }

  return UIAction.HANDLED
end

function Card:_mouse_leave() end

function Card:close() end

function Card:_update(_dt) end

function Card:_render_backside(opts)
  opts = opts or {}

  local x, y, w, h = self:get_geo()

  local tower_card = self.card:get_tower_card()

  love.graphics.push "all"
  love.graphics.origin()

  love.graphics.setCanvas { self._canvas, stencil = true }

  love.graphics.scale(self._scale, self._scale)

  love.graphics.clear()

  love.graphics.setDefaultFilter("linear", "linear", 64)

  love.graphics.setColor(Colors.white:opacity(self:get_opacity()))

  self:with_color(Colors.white, function()
    love.graphics.rectangle("fill", 0, 0, CARD_W, CARD_H, 20, 20, 80)

    ScaledImage.new({
      box = Box.new(Position.zero(), CARD_W, CARD_H),
      texture = Asset.sprites.card_back,
      scale_style = "stretch",
    }):_render()

    love.graphics.draw(Asset.sprites.card.frame, 0, 0, 0)
    love.graphics.draw(Asset.sprites.card.title_banner, 28, 220)
  end)

  Text.new({
    self.card.rarity,
    font = Asset.fonts.typography.card_title,
    box = Box.new(Position.new(0, 232), CARD_W, 50),
    text_align = "center",
    padding = 0,
    vertical_align = "center",
    color = Colors.rarity[self.card.rarity],
  }):_render()

  love.graphics.setCanvas()
  love.graphics.pop()

  love.graphics.draw(self._canvas, x, y)
end

function Card:_render()
  local x, y, w, h = self:get_geo()

  local tower_card = self.card:get_tower_card()

  love.graphics.push "all"
  love.graphics.origin()

  love.graphics.setCanvas { self._canvas, stencil = true }

  love.graphics.scale(self._scale, self._scale)

  love.graphics.clear()

  local minFilter, magFilter, anisotropy = love.graphics.getDefaultFilter()
  love.graphics.setDefaultFilter("linear", "linear", 64)

  -- love.graphics.setColor(Colors.white:opacity(self:get_opacity()))

  self:with_color(
    Colors.white,
    function() love.graphics.rectangle("fill", 0, 0, CARD_W, CARD_H, 20, 20, 80) end
  )

  if tower_card then
    local element_kind = tower_card.tower.element_kind
    local element_texture = Asset.sprites.elemental_backgrounds[element_kind]
      or Asset.sprites.card_pasture_background

    local img = ScaledImage.new {
      box = Box.new(Position.zero(), CARD_W, CARD_H),
      texture = element_texture,
      scale_style = "stretch",
      shaders = {},
    }

    -- TODO: This part kind of sucks (we need to set the opacity or be smarer about calling get_opacity?)
    img._props.opacity = self:get_opacity()
    img:_render()

    if self._tower_texture then
      self._tower_texture:render()
    end
  else
    local img = ScaledImage.new {
      box = Box.new(Position.zero(), CARD_W, CARD_H),
      texture = self.card.texture,
      scale_style = "stretch",
    }

    img._props.opacity = self:get_opacity()
    img:_render()
  end

  self:with_color(
    Colors.black:opacity(0.7),
    function() love.graphics.rectangle("fill", 0, 260, CARD_W, 165) end
  )

  love.graphics.draw(Asset.sprites.card.frame, 0, 0, 0)

  love.graphics.draw(Asset.sprites.card.energy_backing, 5, 5)

  love.graphics.draw(Asset.sprites.card.title_banner, 28, 220)

  local kind_label = {
    [CardKind.ENHANCEMENT] = "Enhancement",
    [CardKind.TOWER] = "Tower",
    [CardKind.AURA] = "Aura",
  }

  local kind_font = Asset.fonts.typography.card_kind
  local kind_w = kind_font:getWidth(kind_label[self.card.kind])

  self:with_color(
    Colors.black,
    function()
      love.graphics.rectangle(
        "fill",
        CARD_W - kind_w - 70,
        10,
        (CARD_W / 2) - (CARD_W / 2 - kind_w - 70),
        28,
        16,
        16,
        1
      )
    end
  )

  love.graphics.draw(Asset.sprites.card.kind_banner, CARD_W - kind_w - 70, 10)

  local kind_color = Colors.rarity[self.card.rarity]
  love.graphics.setColor(kind_color)
  love.graphics.draw(Asset.sprites.card.kind_backing, 238, 5)
  love.graphics.setColor(Colors.white)
  local energy = State:get_modified_energy_cost(self.card)

  Text.new({
    kind_label[self.card.kind],
    font = Asset.fonts.typography.card_kind,
    box = Box.new(Position.new(CARD_W - kind_w - 55, 15), kind_w, 15),
    text_align = "center",
    vertical_align = "center",
    color = Colors.white:opacity(self:get_opacity()),
  }):_render()

  Text.new({
    tostring(energy),
    font = Asset.fonts.typography.card_description,
    box = Box.new(Position.new(6, 6), 46, 46),
    text_align = "center",
    vertical_align = "center",
    color = Colors.white:opacity(self:get_opacity()),
  }):_render()

  Text.new({
    self.card:get_name(),
    font = Asset.fonts.typography.card_title,
    box = Box.new(Position.new(0, 232), CARD_W, 50),
    text_align = "center",
    padding = 0,
    vertical_align = "center",
    color = Colors.white:opacity(self:get_opacity()),
  }):_render()

  Text.new({
    self.card:get_description(),
    font = Asset.fonts.typography.card_description,
    box = Box.new(Position.new(25, 285), CARD_W * 0.84, 130),
    text_align = "center",
    vertical_align = "top",
    color = Colors.white:opacity(self:get_opacity()),
  }):_render()

  self:with_color(Colors.black, function()
    if self.card.kind == CardKind.AURA then
      love.graphics.draw(Asset.sprites.card.aura_icon, CARD_W - 44, 13, 0, 2, 2)
    end

    if self.card.kind == CardKind.ENHANCEMENT then
      love.graphics.draw(
        Asset.sprites.card.enhancement_icon,
        CARD_W - 44,
        13,
        0,
        2,
        2
      )
    end

    if self.card.kind == CardKind.TOWER then
      love.graphics.draw(
        Asset.sprites.card.tower_icon,
        CARD_W - 44,
        13,
        0,
        2,
        2
      )
    end

    love.graphics.setDefaultFilter(minFilter, magFilter, anisotropy)
  end)

  love.graphics.setCanvas()
  love.graphics.pop()

  love.graphics.draw(self._canvas, x, y)
  if tower_card and not self.hide_level then
    self:_render_level_indicator(x, y, w, h)
  end
end

--- Render the level indicator
function Card:_render_level_indicator(x, y, w, h)
  love.graphics.push()

  local lvl_dim = LEVEL_DIMENSION * self._scale
  love.graphics.translate(x + self:get_width() / 2, y + 10)
  love.graphics.rotate(-0.40)

  love.graphics.setColor(Colors.black:opacity(0.3 * self:get_opacity()))
  love.graphics.rectangle("fill", -lvl_dim / 2, -lvl_dim / 2, lvl_dim, lvl_dim)

  love.graphics.setColor(Colors.red:opacity(self:get_opacity()))
  love.graphics.rectangle(
    "fill",
    -(lvl_dim - 5) / 2,
    -(lvl_dim + 10) / 2,
    lvl_dim,
    lvl_dim
  )

  love.graphics.pop()

  -- Level text
  love.graphics.setColor(Colors.white:opacity(self:get_opacity()))
  local lvl_x_offset = x + (self:get_width() / 2) - 20
  love.graphics.setFont(Asset.fonts.typography.sub)
  love.graphics.print("LV", lvl_x_offset, y)

  lvl_x_offset = lvl_x_offset + 28
  love.graphics.setFont(Asset.fonts.typography.h3)

  local tower_card = self.card:get_tower_card()
  if tower_card then
    love.graphics.print(tower_card.tower.level, lvl_x_offset, y - 8)
  end
end

function Card:_click()
  if self._on_click ~= nil then
    return self._on_click(self)
  end

  return UIAction.HANDLED
end

function Card:_drag_start(evt)
  print "Card:_drag_start"

  if self._on_drag_start then
    return self:_on_drag_start(evt)
  end
  return UIAction.HANDLED
end

function Card:_drag(evt)
  if self._on_drag then
    return self:_on_drag(evt)
  end

  return UIAction.HANDLED
end

---@param evt ui.components.UIMouseEvent
function Card:_drag_end(evt)
  if self._on_drag_end then
    return self:_on_drag_end(evt)
  end

  return UIAction.HANDLED
end

function Card:_focus(evt)
  if self._on_focus then
    self:_on_focus(evt)
  end

  if self:is_dragging() then
    return
  end

  return UIAction.HANDLED
end

function Card:_blur(evt)
  if self._on_blur then
    self:_on_blur(evt)
  end

  if self:is_dragging() then
    return
  end

  return UIAction.HANDLED
end

function Card:clone(opts)
  validate(opts, {
    on_use = "function?",
    on_drag_start = "function?",
    on_drag_end = "function?",
    on_focus = "function?",
    on_blur = "function?",
  })

  opts.card = self.card:clone()
  opts.box = self:get_box():clone()

  return Card.new(opts)
end

function Card:on_use()
  if self._on_use then
    return self:_on_use()
  end

  return UIAction.HANDLED
end
return Card
