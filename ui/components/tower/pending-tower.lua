local GameFunctions = require "vibes.data.game-functions"
local Text = require "ui.components.text"
local game = require "utils.user-interaction"

---@class (exact) components.PendingTower.Opts
---@field tower vibes.Tower: The tower to show as pending placement
---@field on_place fun(cell: vibes.Cell, previous_lifecycle: RoundLifecycle): boolean
---@field on_cancel fun(previous_lifecycle: RoundLifecycle): nil
---@field previous_lifecycle RoundLifecycle

---@class (exact) components.PendingTower : Element
---@field new fun(opts: components.PendingTower.Opts): components.PendingTower
---@field init fun(self: components.PendingTower, opts: components.PendingTower.Opts)
---@field tower vibes.Tower
---@field on_place fun(cell: vibes.Cell, previous_lifecycle: RoundLifecycle): boolean
---@field on_cancel fun(previous_lifecycle: RoundLifecycle): nil
---@field previous_lifecycle RoundLifecycle
local PendingTower = class("components.PendingTower", { super = Element })

---@param opts components.PendingTower.Opts
function PendingTower:init(opts)
  validate(opts, {
    tower = "vibes.Tower",
    on_place = "function",
    on_cancel = "function",
  })

  Element.init(self, Box.fullscreen(), {
    z = Z.PENDING_TOWER,
    interactable = true,
  })

  self.tower = opts.tower
  self.on_place = opts.on_place
  self.on_cancel = opts.on_cancel
  self.previous_lifecycle = opts.previous_lifecycle

  local font = Asset.fonts.typography.h3
  local width = font:getWidth "to cancel press __ or  __"
  self:append_child(Text.new {
    "to cancel press",
    { icon = Asset.icons[IconType.RIGHT_CLICK], color = Colors.white },
    "or",
    { icon = Asset.icons[IconType.ESCAPE_KEY], color = Colors.white },
    font = font,
    box = Box.new(
      -- Bottom right of screen
      Position.new(
        Config.window_size.width / 2 - (width / 2),
        Config.window_size.height - 400
      ),
      width * 1.2,
      font:getHeight() * 1.2
    ),
  })
end

function PendingTower:_render()
  local cell = GameFunctions.get_cell_from_mouse()
  if not cell then
    return
  end

  -- Draw tower range
  GameFunctions.draw_tower_range(cell, self.tower)

  -- Draw tower preview
  GameFunctions.draw_tower_preview(cell, self.tower)

  local pos = Position.from_cell_to_top_left(cell)
  love.graphics.setColor(Colors.gray:opacity(0.2))
  love.graphics.rectangle(
    "fill",
    pos.x,
    pos.y,
    Config.grid.cell_size,
    Config.grid.cell_size
  )
end

function PendingTower:_update(_dt)
  self.tower.stats_manager:update()

  -- Handle cancellation
  if game.is_action_canceled() then
    if self.on_cancel then
      self.on_cancel(self.previous_lifecycle)
    end

    self:remove_from_parent()
  end
end

function PendingTower:_click(_evt, _x, _y)
  -- Handle placement confirmation
  local cell = GameFunctions.get_cell_from_mouse()
  if cell then
    if self.on_place(cell, self.previous_lifecycle) then
      self:remove_from_parent()
    end
  end

  return UIAction.HANDLED
end

return PendingTower
