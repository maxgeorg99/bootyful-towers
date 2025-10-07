---@class (exact) ui.components.Img : Element
---@field new fun(img: vibes.Texture,scale_x: number, scale_y? :number, origin?: [number,number], background?:[number,number,number,number], rounded?:number, parallax?: boolean): ui.components.Img
---@field init fun(self: ui.components.Img, img: vibes.Texture, scale_x: number, scale_y? :number, origin?: [number,number], background?:[number,number,number,number], rounded?:number, parallax?: boolean)
---@field super Element
---@field img vibes.Texture
---@field scale_x number
---@field scale_y number
---@field origin [number,number]
---@field background? [number,number,number,number]
--- @field rounded? number
--- @field parallax? boolean
--- @field offset vibes.Position
local Img = class("ui.components.Img", { super = Element })

--- @param img vibes.Texture
--- @param scale_x number
--- @param scale_y? number
--- @param origin? [number,number]
--- @param background? [number,number,number,number]
--- @param rounded? number
--- @param parallax? boolean
function Img:init(img, scale_x, scale_y, origin, background, rounded, parallax)
  local scale_x = scale_x or 1
  local scale_y = scale_y or scale_x

  Element.init(
    self,
    Box.new(
      Position.new(0, 0),
      img:getWidth() * scale_x,
      img:getHeight() * scale_y
    )
  )

  self.img = img
  self.name = "Image"
  self.scale_x = scale_x
  self.scale_y = scale_y or scale_x
  self.origin = F.if_nil(origin, { 0, 0 })
  self.background = background
  self.rounded = rounded
  self.parallax = F.if_nil(parallax, false)
  self.offset = Position.new(0, 0)

  if self.parallax then
    self.scale_x = scale_x * 1.5
    self.scale_y = self.scale_y * 1.5
  end
end

function Img:_update(dt) end
function Img:_mouse_moved(_, _, _)
  if self.parallax then
    local mx, my = State.mouse.x, State.mouse.y
    -- self.offset = Position.new((mx * 0.1), (my * 0.1))
  end
end

function Img:_render()
  love.graphics.push()
  local x, y, w, h = self:get_geo()
  local function mask() love.graphics.rectangle("fill", x, y, w, h) end
  love.graphics.stencil(mask, "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  if self.background then
    local rounded = self.rounded or 0
    love.graphics.setColor(
      self.background[1],
      self.background[2],
      self.background[3],
      self:get_opacity()
    )
    love.graphics.rectangle("fill", x, y, w, h, rounded, rounded, 80)
  end

  love.graphics.setColor(1, 1, 1, self:get_opacity())
  love.graphics.draw(
    self.img,
    x - self.offset.x,
    y - self.offset.y,
    0,
    self.scale_x,
    self.scale_y or self.scale_x,
    self.origin[1],
    self.origin[2]
  )
  love.graphics.setStencilTest()
  love.graphics.pop()
end

return Img
