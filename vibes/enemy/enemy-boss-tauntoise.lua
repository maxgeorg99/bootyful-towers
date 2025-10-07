local Enemy = require "vibes.enemy.base"

---@class vibes.EnemyTauntoise.Properties : enemy.Properties
---@field tauntoise_taunt_cells { row: number, col: number }[]
---@field tauntoise_taunt_duration number

---@class vibes.EnemyTauntoise : vibes.Enemy
---@field new fun(opts: vibes.EnemyOptions): vibes.EnemyTauntoise
---@field init fun(self: vibes.EnemyTauntoise, opts: vibes.EnemyOptions)
---@field _properties vibes.EnemyTauntoise.Properties
local EnemyTauntoise = class("vibes.EnemyTauntoise", { super = Enemy })

---@diagnostic disable-next-line: assign-type-mismatch
EnemyTauntoise._properties =
  require("vibes.enemy.all-enemy-stats")[EnemyType.TAUNTOISE]

function EnemyTauntoise:init(opts) Enemy.init(self, opts) end

function EnemyTauntoise:get_speed()
  if self.standing_still then
    return 0
  end

  return Enemy.get_speed(self)
end

function EnemyTauntoise:update(dt)
  Enemy.update(self, dt)

  for _, cell in ipairs(self._properties.tauntoise_taunt_cells) do
    if self.cell.row == cell.row and self.cell.col == cell.col then
      self.statuses.taunting = true
      self.standing_still = true

      Timer.oneshot_gametime(
        self._properties.tauntoise_taunt_duration,
        function()
          self.statuses.taunting = false
          self.standing_still = false
        end
      )
    end
  end
end

return EnemyTauntoise
