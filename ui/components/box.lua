local _id = 0
local get_next_id = function()
  _id = _id + 1
  return _id
end

---@class (exact) ui.components.BoxOptions
---@field position vibes.Position
---@field width number
---@field height number

---@class ui.components.Box : vibes.Class
---@field new fun(position: vibes.Position, width: number, height: number): ui.components.Box
---@field init fun(self, position: vibes.Position, width: number, height: number)
---@field id number
---@field position vibes.Position
---@field width number
---@field height number
local Box = class "ui.components.Box"

---@param position vibes.Position
---@param width number
---@param height number
function Box:init(position, width, height)
  validate({
    position = position,
    width = width,
    height = height,
  }, {
    position = Position,
    width = "number",
    height = "number",
  })

  self.id = get_next_id()
  self.position = position
  self.width = width
  self.height = height
end

---@return ui.components.Box
function Box.empty() return Box.new(Position.new(0, 0), 0, 0) end

---@return ui.components.Box
function Box.fullscreen()
  return Box.new(
    Position.zero(),
    Config.window_size.width,
    Config.window_size.height
  )
end

---@class Box.RelativeChildOpts
---@field parent ui.components.Box
---@field width number
---@field height number
---@field vertical "top" | "center" | "bottom" | number
---@field horizontal "left" | "center" | "right" | number

---@param opts Box.RelativeChildOpts
function Box.relative_child(opts)
  opts = opts or {}
  validate(opts, {
    parent = Box,
    width = "number",
    height = "number",
    vertical = Either { "string", "number" },
    horizontal = Either { "string", "number" },
  })

  local x
  if opts.horizontal == "center" then
    x = opts.parent.width / 2 - opts.width / 2
  elseif opts.horizontal == "right" then
    x = opts.parent.width - opts.width
  elseif opts.horizontal == "left" then
    x = 0
  elseif type(opts.horizontal) == "number" then
    if opts.horizontal < 1 then
      x = opts.parent.width * opts.horizontal
    else
      x = opts.horizontal
    end
  else
    error("unknown horizontal: " .. tostring(opts.horizontal))
  end

  local y
  if opts.vertical == "center" then
    y = opts.parent.height / 2 - opts.height / 2
  elseif opts.vertical == "bottom" then
    y = opts.parent.height - opts.height
  elseif opts.vertical == "top" then
    y = 0
  elseif type(opts.vertical) == "number" then
    if opts.vertical < 1 then
      y = opts.parent.height * opts.vertical
    else
      y = opts.vertical
    end
  else
    error("unknown vertical: " .. tostring(opts.vertical))
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  return Box.new(Position.new(x, y), opts.width, opts.height)
end

---@param x number
---@param y number
---@param width number
---@param height number
---@return ui.components.Box
function Box.from(x, y, width, height)
  return Box.new(Position.new(x, y), width, height)
end

---@param asset love.Drawable | love.Image
function Box.from_asset(asset)
  return Box.new(Position.zero(), asset:getWidth(), asset:getHeight())
end

function Box:eq(box)
  return self.position:eq(box.position)
    and self.width == box.width
    and self.height == box.height
end

function Box:string()
  return string.format(
    "Box(%s, %s, %s)",
    self.position,
    self.width,
    self.height
  )
end

---@return number
---@return number
---@return number
---@return number
function Box:geo()
  return self.position.x, self.position.y, self.width, self.height
end

--- @param x number
--- @param y number
--- @return boolean
function Box:contains(x, y)
  x = x - self.position.x
  y = y - self.position.y

  return x >= 0 and y >= 0 and x < self.width and y < self.height
end

--- @param other ui.components.Box
--- @return boolean
function Box:intersects(other)
  if self.position.x > other.position.x + other.width then
    return false
  end

  if self.position.x + self.width < other.position.x then
    return false
  end

  if self.position.y > other.position.y + other.height then
    return false
  end

  if self.position.y + self.height < other.position.y then
    return false
  end

  return true
end

---@param box ui.components.Box
function Box:set(box)
  self.width = box.width
  self.height = box.height
  self.position.x = box.position.x
  self.position.y = box.position.y
end

function Box:clone()
  return Box.new(self.position:clone(), self.width, self.height)
end

--- @param s number
--- @return self
function Box:scale(s)
  local w = self.width * s
  local h = self.height * s

  local w_diff = w - self.width
  local h_diff = h - self.height

  self.position.x = self.position.x - w_diff / 2
  self.position.y = self.position.y - h_diff / 2
  self.width = w
  self.height = h
  return self
end

--- @param other ui.components.Box
--- @return ui.components.Box
function Box:sub(other)
  local pos = self.position:sub(other.position)
  return Box.new(pos, self.width - other.width, self.height - other.height)
end

function Box:__tostring() return self:string() end

return Box
