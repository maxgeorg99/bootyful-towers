local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyCatTatus.Properties : enemy.Properties
---@field cat_tatus_teleport_cells { start_row: number, start_col: number, end_row: number, end_col: number }[]

---@class vibes.EnemyCatTatus : vibes.Enemy
---@field new fun(path: vibes.Path): vibes.EnemyCatTatus
---@field init fun(self: vibes.EnemyCatTatus, path: vibes.Path)
---@field super vibes.Enemy
---@field _properties vibes.EnemyCatTatus.Properties
local EnemyCatTatus = class("vibes.EnemyCatTatus", { super = Enemy })

---@diagnostic disable-next-line: assign-type-mismatch
EnemyCatTatus._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.CAT_TATUS]

---@param opts vibes.EnemyOptions
function EnemyCatTatus:init(opts) Enemy.init(self, opts) end

function EnemyCatTatus:update(dt)
  Enemy.update(self, dt)

  for _, cell in ipairs(self._properties.cat_tatus_teleport_cells) do
    if self.cell.row == cell.start_row and self.cell.col == cell.start_col then
      self:teleport_to_cell(cell.end_col, cell.end_row)
    end
  end
end

function EnemyCatTatus:teleport_to_cell(end_col, end_row)
  self.cell = Cell.new(end_row, end_col)
  self.position = Position.new(
    end_col * Config.grid.cell_size + Config.grid.cell_size / 2,
    end_row * Config.grid.cell_size + Config.grid.cell_size / 2
  )
end

return EnemyCatTatus
