---@class (exact) ui.components.Icon : Element
---@field new fun(opts: ui.components.IconOptions, pos: vibes.Position?): ui.components.Icon
---@field init fun(self: ui.components.Icon, opts: ui.components.IconOptions, pos: vibes.Position?)
---@field super Element
---@field type IconType
---@field asset love.Drawable|love.Image
---@field label? {value: string|number , placement? :"top" | "right" | "bottom" | "left"}
---@field font? love.Font
---@field background? {red:number, green:number, blue:number, alpha:number}
---@field color? {red:number, green:number, blue:number, alpha:number}|table<number, number, number>
---@field scale? number
---@field rotation? number
---@field rounded? number
---@field padding? number
---@field on_click fun(): nil
local Icon = class("ui.components.Icon", { super = Element })

---@class ui.components.IconOptions
---@field type IconType
---@field label? {value: string|number , placement? :"top" | "right" | "bottom" | "left"}
---@field font? love.Font
---@field background? {red:number, green:number, blue:number, alpha:number}
---@field color? {red:number, green:number, blue:number, alpha:number}|table<number, number, number>
---@field scale? number
---@field rotation? number
---@field rounded? number
---@field padding? number
---@field interactable? boolean
---@field on_click? fun(self: ui.components.Icon): nil

--- @param opts ui.components.IconOptions
--- @param pos? vibes.Position
function Icon:init(opts, pos)
  if not pos then
    pos = Position.new(0, 0)
  end

  local box = Box.new(pos, 64, 64)
  Element.init(self, box, {
    interactable = F.if_nil(opts.interactable, false),
  })

  local x, y, width, height = self:get_geo()
  self.name = string.format("Icon(%d,%d)", x, y)
  self.z = 1
  self.on_click = opts.on_click

  self.label = opts.label

  self.type = opts.type
  self.asset = Asset.icons[opts.type]
  self.scale = opts.scale
  self.font = opts.font
  self.background = opts.background
  self.color = opts.color or { 1, 1, 1 }
  self.padding = F.if_nil(opts.padding, 20)
  self.rounded = F.if_nil(opts.rounded, 15)

  self:set_height(self.asset:getHeight())
  if not opts.font then
    self.font = Asset.fonts.default_14
    if self.label ~= nil and type(self.label.value) == "number" then
      self.font = Asset.fonts.bignumbers_16
    end
  end
  if not opts.scale then
    self.scale = 1
  end

  if not opts.rotation then
    self.rotation = 0
  end
end

function Icon:_render()
  love.graphics.push()

  love.graphics.setFont(self.font)

  local asset_w = self.asset:getWidth() * self.scale
  local asset_h = self.asset:getHeight() * self.scale

  local origin = { x = (asset_w * self.scale) / 2, y = 0 }

  local label_w = 0
  local align = "left"

  if self.label ~= nil then
    align = self.label.placement or "left"
    label_w = self.font:getWidth(self.label.value) + 10
  end

  if align == "right" or align == "left" then
    self:set_width(label_w + asset_w + self.padding)
    self:set_height(asset_h + self.padding)
  else
    self:set_width(label_w + self.padding)
    self:set_height(asset_h + self.font:getHeight() + self.padding + 10)
  end

  local x, y, w, h = self:get_geo()

  if self.background ~= nil then
    local color =
      Color.new(self.background[1], self.background[2], self.background[3])

    -- default to base opacity if any
    local opactiy = self:get_opacity()
    if opactiy == 1 then
      opactiy = self.background[4] or 1
    end

    love.graphics.setColor(color:opacity(opactiy))
    love.graphics.rectangle("fill", x, y, w, h, self.rounded, self.rounded, 80)
    love.graphics.setColor(
      self.color[1] or 1,
      self.color[2] or 1,
      self.color[3] or 1,
      self:get_opacity()
    )
    -- love.graphics.setColor(1, 1, 1, self:opacity())
  end

  local pos = Position.new(x + self.padding / 2, y + self.padding / 2)

  if self.label ~= nil and align == "left" then
    local ly = (asset_h / 2) - (self.font:getHeight() / 2)
    love.graphics.printf(self.label.value, pos.x, pos.y + ly, label_w, "left")
    pos = pos:add(Position.new(label_w, 0))
  end

  if self.label ~= nil and align == "top" then
    local _, _, self_w, _ = self:get_geo()
    love.graphics.printf(
      self.label.value,
      pos.x - ((self_w / 2) - (label_w / 2)) - 15,
      pos.y,
      label_w,
      "center"
    )
    pos = pos:add(Position.new(0, self.font:getHeight() + 10))
  end

  if align == "top" or align == "bottom" then
    pos = pos:add(Position.new(label_w / 2 - 5, 0))
  end

  love.graphics.push()
  love.graphics.setColor(
    self.color[1] or 1,
    self.color[2] or 1,
    self.color[3] or 1,
    self:get_opacity()
  )
  love.graphics.draw(
    self.asset,
    pos.x,
    pos.y,
    self.rotation,
    self.scale,
    self.scale,
    origin.x,
    origin.y
  )
  love.graphics.pop()

  if self.label ~= nil and align == "bottom" then
    pos = pos:add(Position.new(-label_w / 2, asset_h + 10))
    love.graphics.printf(self.label.value, pos.x, pos.y, label_w + 10, "center")
  end

  if self.label ~= nil and self.label.placement == "right" then
    pos =
      pos:add(Position.new(asset_w, asset_h / 2 - self.font:getHeight() / 2))
    love.graphics.printf(self.label.value, pos.x, pos.y, label_w, "right")
  end

  love.graphics.pop()
end

function Icon:_update() end
function Icon:focus() end
function Icon:blur() end

function Icon:_click()
  if self.on_click then
    self.on_click()
    return UIAction.HANDLED
  end

  return nil
end

return Icon
