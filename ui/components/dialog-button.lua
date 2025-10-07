local TILE_SIZE = 8
local SCALE = 4

---@class  ui.components.DialogButton : Element
---@field new fun(text: string, width: number, height: number, pos: vibes.Position, callback: fun()): ui.components.DialogButton
---@field init fun(self: ui.components.DialogButton, text: string, width: number, height: number, pos: vibes.Position, callback: fun())
---@field super Element
---@field _type "ui.components.DialogButton"
---@field text string
---@field asset  love.Drawable|love.Image
---@field tiles ui.components.Dialog.UIDefs
---@field focues boolean
---@field callback fun()
local DialogButton = class("ui.components.DialogButton", { super = Element })

--- @param text string
--- @param width number
--- @param height number
--- @param pos vibes.Position
--- @param callback fun()
function DialogButton:init(text, width, height, pos, callback)
  Element.init(self, Box.new(pos, width, height), { interactable = true })

  -- self:set_x(self:get_x() + pos.x)
  -- self:set_y(self:get_y() + pos.y)

  self.name = "DialogButton"
  self.text = text
  self.asset = Asset.sprites.ui
  self.callback = callback

  self:set_width(width)
  self:set_height(height)

  self:_load_assets()
end

function DialogButton:_click() self:callback() end

function DialogButton:_update()
  -- prevent dialog from interfering with other ui element events
  self:set_interactable(not self:is_hidden())
end

function DialogButton:_blur() self.focused = false end
function DialogButton:_focus() self.focused = true end

function DialogButton:_render()
  local pos_x, pos_y, w, h = self:get_geo()
  local x_tiles = math.floor(w / TILE_SIZE - 3)
  local y_tiles = math.floor(h / TILE_SIZE - 4)
  love.graphics.push()

  if self.focused then
    --TODO: will be updated
    love.graphics.setColor(100 / 255, 100 / 255, 100 / 255, 100 / 255)
  end

  for layer = 1, 2, 1 do
    for x = 0, x_tiles, 1 do
      for y = 0, y_tiles, 1 do
        local quad = nil

        if layer == 1 then
          if x ~= 0 and y ~= 0 and y ~= y_tiles and x ~= x_tiles then
            quad = self.tiles.middle.center
          end
        elseif y == 0 then
          quad = self.tiles.top.center
        elseif y == y_tiles then
          quad = self.tiles.bottom.center
        elseif x == 0 and y ~= 0 then
          quad = self.tiles.middle.left
        elseif x == x_tiles and y ~= 0 then
          quad = self.tiles.middle.right
        end

        if quad ~= nil then
          love.graphics.draw(
            self.asset,
            quad,
            pos_x + (x * TILE_SIZE),
            pos_y + (y * TILE_SIZE),
            0,
            SCALE,
            SCALE
          )
        end
      end
    end
  end

  love.graphics.draw(
    self.asset,
    self.tiles.top.left,
    pos_x,
    pos_y,
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.asset,
    self.tiles.top.right,
    pos_x + (x_tiles * TILE_SIZE),
    pos_y,
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.asset,
    self.tiles.bottom.left,
    pos_x,
    pos_y + (y_tiles * TILE_SIZE),
    0,
    SCALE,
    SCALE
  )

  love.graphics.draw(
    self.asset,
    self.tiles.bottom.right,
    pos_x + (x_tiles * TILE_SIZE),
    pos_y + (y_tiles * TILE_SIZE),
    0,
    SCALE,
    SCALE
  )

  love.graphics.pop()
  love.graphics.setColor(0, 0, 0, 1)
  local font = Asset.fonts.insignia_22
  love.graphics.setFont(font)

  local padding = 30

  love.graphics.printf(
    self.text,
    pos_x + padding,
    pos_y + ((h / 2) - (font:getHeight() / 2)),
    w - (padding * 2),
    "center"
  )
end

function DialogButton:_load_assets()
  self.tiles = {
    top = {
      left = love.graphics.newQuad(
        TILE_SIZE * 0,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 2,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 3,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
    middle = {
      left = love.graphics.newQuad(
        TILE_SIZE * 0,
        TILE_SIZE * 1,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 2,
        TILE_SIZE * 1,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 3,
        TILE_SIZE * 1,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
    bottom = {
      left = love.graphics.newQuad(
        TILE_SIZE * 0,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 2,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 3,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
  }
end

return DialogButton
