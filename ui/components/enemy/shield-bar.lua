local BarGauge = require "ui.components.bar-gauge"
local Enemy = require "vibes.enemy.base"

---@class (exact) enemy.component.ShieldBar : components.BarGauge
---@field new fun(opts: enemy.component.ShieldBar.Opts): enemy.component.ShieldBar
---@field init fun(self: enemy.component.ShieldBar, opts: enemy.component.ShieldBar.Opts)
local EnemyShieldBar = class("enemy.component.ShieldBar", { super = BarGauge })

---@class enemy.component.ShieldBar.Opts
---@field box ui.components.Box
---@field enemy vibes.Enemy

---@param opts enemy.component.ShieldBar.Opts
function EnemyShieldBar:init(opts)
  validate(opts, {
    enemy = Enemy,
  })

  BarGauge.init(self, {
    box = opts.box,
    color = { 0.1, 0.1, 0.1, 1 },
    get_current_value = function() return opts.enemy:get_shield() end,
    get_maximum_value = function() return opts.enemy:get_shield_capacity() end,
  })

  self.name = "EnemyShieldBar"
end

function EnemyShieldBar:_render()
  local capacity = self.get_maximum_value()
  if capacity == 0 then
    return
  end

  if self.get_current_value() == 0 then
    return
  end

  BarGauge._render(self)
end

return EnemyShieldBar
