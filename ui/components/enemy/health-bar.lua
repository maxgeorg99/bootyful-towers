local BarGauge = require "ui.components.bar-gauge"
local Enemy = require "vibes.enemy.base"

---@class (exact) enemy.component.HealthBar : components.BarGauge
---@field new fun(opts: enemy.component.HealthBar.Opts): enemy.component.HealthBar
---@field init fun(self: enemy.component.HealthBar, opts: enemy.component.HealthBar.Opts)
local EnemyHealthBar = class("enemy.component.HealthBar", { super = BarGauge })

---@class enemy.component.HealthBar.Opts
---@field box ui.components.Box
---@field enemy vibes.Enemy

---@param opts enemy.component.HealthBar.Opts
function EnemyHealthBar:init(opts)
  validate(opts, {
    enemy = Enemy,
  })

  BarGauge.init(self, {
    box = opts.box,
    color = { 1, 0, 0, 1 },
    get_current_value = function() return opts.enemy.health end,
    get_maximum_value = function() return opts.enemy.max_health end,
  })

  self.name = "EnemyHealthBar"
end

return EnemyHealthBar
