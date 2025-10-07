local TILE_SIZE = 8
local SCALE = 4
local PADDING = 30

---@class ui.components.Dialog.TileDef
---@field left  love.Quad
---@field center love.Quad
---@field right love.Quad

---@class ui.components.Dialog.UIDefs
---@field top ui.components.Dialog.TileDef
---@field middle ui.components.Dialog.TileDef
---@field bottom ui.components.Dialog.TileDef

---@class (exact) ui.components.Dialog : Element
---@field new fun(width: number, height: number, pos: vibes.Position, overlay: boolean?): ui.components.Dialog
---@field init fun(self: ui.components.Dialog, width: number, height: number, pos: vibes.Position, overlay: boolean?)
---@field super Element
---@field _type "ui.components.Dialog"
---@field font love.Font
---@field tiles ui.components.Dialog.UIDefs
---@field asset  love.Image|love.Drawable
---@field width number
---@field height number
---@field overlay boolean
--
-- Helper Methods
---@field fullscreen fun(): ui.components.Dialog
---@field fullscreen_no_overlap_hud fun(): ui.components.Dialog
local Dialog = class("ui.components.Dialog", { super = Element })

function Dialog.fullscreen()
  return Dialog.new(
    Config.window_size.width - (PADDING * 2),
    Config.window_size.height - (PADDING * 2),
    Position.new(PADDING, PADDING),
    true
  )
end

function Dialog.fullscreen_no_overlap_hud()
  local offset_x = 40
  local offset_y = 156
  return Dialog.new(
    Config.window_size.width - (PADDING * 2) - offset_x,
    Config.window_size.height - (PADDING * 2) - offset_y,
    Position.new(40, 156),
    true
  )
end

--- @param width number
--- @param height number
--- @param pos vibes.Position
--- @param overlay? boolean
function Dialog:init(width, height, pos, overlay)
  local box = Box.new(Position.new(pos.x, pos.y), width, height)
  Element.init(self, box)

  if overlay == nil then
    overlay = true
    self.z = Z.DIALOG_OVERLAY
  end

  self.name = "Dialog"
  self.font = Asset.fonts.insignia_24
  self.asset = Asset.sprites.ui
  self.width = width
  self.height = height
  self.overlay = overlay

  self:set_width(width)
  self:set_height(height)

  self:_load_assets()
end

function Dialog:_click() end

function Dialog:_update()
  -- TODO: THIS MIGHT NEED TO COME BACK, BUT SEEMS SO DUMB
  -- self:set_interactable(not self.style.hidden)
end

function Dialog:_render()
  local pos_x, pos_y, _, _ = self:get_geo()
  local x_tiles = math.floor((self.width - PADDING) / TILE_SIZE)
  local y_tiles = math.floor((self.height - PADDING) / TILE_SIZE)

  if self.overlay then
    -- transparent overlay
    love.graphics.push()
    love.graphics.setColor(0, 0, 0, 200 / 255)
    love.graphics.rectangle(
      "fill",
      0,
      0,
      love.graphics:getWidth(),
      love.graphics:getHeight()
    )
    love.graphics.pop()
  end
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 255 / 255)

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

        if quad then
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
end

function Dialog:_load_assets()
  self.tiles = {
    middle = {
      left = love.graphics.newQuad(
        TILE_SIZE * 4,
        TILE_SIZE * 2,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 5,
        TILE_SIZE * 2,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 7,
        TILE_SIZE * 2,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
    top = {
      left = love.graphics.newQuad(
        TILE_SIZE * 4,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 6,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 7,
        TILE_SIZE * 0,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
    bottom = {
      left = love.graphics.newQuad(
        TILE_SIZE * 4,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      center = love.graphics.newQuad(
        TILE_SIZE * 6,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
      right = love.graphics.newQuad(
        TILE_SIZE * 7,
        TILE_SIZE * 3,
        TILE_SIZE,
        TILE_SIZE,
        self.asset:getWidth(),
        self.asset:getHeight()
      ),
    },
  }
end

return Dialog
