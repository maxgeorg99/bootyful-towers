local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

-- TODO: Consider making computed private? Don't like depending on it from other
-- places... not sure yet.
--
-- TODO: `range` and `range_distance` are so dumb. Why are we squaring the
-- distance to do anything? Shoudln't we just compare magnitudes? Why worry
-- about this?

local GameFunctions = require "vibes.data.game-functions"

---@class vibes.TowerState
---@field last_attack_time number
---@field sprite_orientation "left" | "right" | "default"

---@class vibes.Tower.Opts
---@field kind? TowerKind
---@field element_kind ElementKind

---@class vibes.Tower : vibes.Class
---@field new fun(stats: tower.Stats, texture: vibes.Texture, opts: vibes.Tower.Opts): vibes.Tower
---@field init fun(self: vibes.Tower, stats: tower.Stats, texture: vibes.Texture, opts: vibes.Tower.Opts)
---@field get_upgrade_options fun(self: vibes.Tower): table<Rarity, tower.UpgradeOption[]>
---@field initial_experience fun(self: vibes.Tower): number
---@field tower_type TowerKind
---@field cell vibes.Cell
---@field position vibes.Position
---@field state vibes.TowerState
---@field level number Current tower level
---@field card_slots number available card_slots
---@field max_card_slots number max card_slots
---@field experience_manager tower.ExperienceManager Experience management system
---@field focused boolean
---@field stats_base tower.Stats
---@field stats_manager tower.StatsManager
---@field enhancements vibes.EnhancementCard[]
---@field name? string
---@field description? string
---@field hooks? vibes.Hooks
---@field element_kind ElementKind
---@field _tags {}
---@field source_tower_card vibes.TowerCard? The tower card that created this tower
--
-- Textures
---@field texture vibes.Texture
---@field animated_texture vibes.SpriteAnimation
--
-- Stat Management
---@field get_tower_stat_enhancements fun(self: vibes.Tower): table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local Tower = class "vibes.Tower"

---@param tower vibes.Tower
---@return tower.LevelUpReward
function Tower.get_levelup_reward(tower)
  local TowerLevelUpReward = require "vibes.tower.meta.tower-levelup-reward"
  local rewards = State:get_tower_upgrade_options(tower)

  return TowerLevelUpReward.new {
    kind = LevelUpRewardKind.UPGRADE_TOWER,
    reward = rewards,
  }
end

--- Creates a new Tower
---@param stats tower.Stats
---@param texture vibes.Texture
---@param opts? { kind?: TowerKind, element_kind: ElementKind }
function Tower:init(stats, texture, opts)
  opts = opts or {}
  opts.kind = opts.kind or TowerKind.SHOOTER
  opts.element_kind = opts.element_kind or ElementKind.PHYSICAL

  validate(opts, {
    kind = TowerKind,
    element_kind = ElementKind,
  })

  -- assert(Stat.is(stats.range), "Tower.range must be a vibes.Stat")
  -- assert(Stat.is(stats.damage), "Tower.damage must be a vibes.Stat")
  -- assert(Stat.is(stats.attack_speed), "Tower.attack_speed must be a vibes.Stat")
  assert(texture, "Tower.texture must be a love.Image")

  -- Create the tower instance
  self.texture = texture
  self.animated_texture = opts.animated_texture
  self.position = Position.new(0, 0)
  self.tower_type = opts.kind
  self.element_kind = opts.element_kind
  self.stats_base = stats
  self.state = {
    last_attack_time = 0,
    sprite_orientation = "default",
  }
  self.level = 1
  self.card_slots = 3
  self.max_card_slots = 12
  self.enhancements = {}

  self.focused = false

  self.stats_manager =
    require("vibes.data.tower-stats-manager").new { tower = self }
  self.experience_manager =
    require("vibes.data.tower-experience-manager").new { tower = self }
end

function Tower:place(cell)
  self.cell = cell
  self.position = cell:center()
end

---@param cell vibes.Cell
function Tower:can_place(cell)
  if not cell.is_placeable then
    return false
  end

  if cell.row >= Config.grid.grid_height - 3 then
    return false
  end

  for _, tower in ipairs(State.towers) do
    if tower.cell == cell then
      return false
    end
  end

  return true
end

---@return number
function Tower:initial_experience() return 100 end

function Tower:apply_experience_for_damage(damage)
  self.experience_manager:apply_damage_experience(damage)
end

---@param enemy vibes.Enemy
function Tower:apply_experience_for_kill(enemy)
  self.experience_manager:apply_kill_experience(enemy)
end

---@return table<Rarity, tower.UpgradeOption[]>
function Tower:get_upgrade_options()
  assert(false, "Your tower does not implement get_upgrade_options")
  return {}
end

---@return boolean
function Tower:has_free_card_slot() return #self.enhancements < self.card_slots end

---stylua: ignore start
function Tower:get_range_stat() return self.stats_manager.result.range end
function Tower:get_damage_stat() return self.stats_manager.result.damage end
function Tower:get_attack_speed_stat()
  return self.stats_manager.result.attack_speed
end
function Tower:get_enemy_targets_stat()
  return self.stats_manager.result.enemy_targets
end
function Tower:get_durability_stat() return self.stats_manager.result.durability end
function Tower:get_aoe_stat() return self.stats_manager.result.aoe end
function Tower:get_critical_stat() return self.stats_manager.result.critical end
function Tower:get_range_in_distance()
  return self:get_range_stat().value * Config.grid.cell_size
end
function Tower:get_range_in_cells() return self:get_range_stat().value end
function Tower:get_damage() return self:get_damage_stat().value end
function Tower:get_attack_speed() return self:get_attack_speed_stat().value end
function Tower:get_enemy_targets() return self:get_enemy_targets_stat().value end
function Tower:get_durability() return self:get_durability_stat().value end
function Tower:get_aoe() return self:get_aoe_stat().value end
function Tower:get_critical() return self:get_critical_stat().value end
---stylua: ignore end

---@param field TowerStatField
---@return number
function Tower:get_field_value(field)
  return self.stats_manager.result[field].value
end

---@class vibes.Tower.DrawOpts
---@field ignore_mouse? boolean
---@field preview? boolean
---@field hide_xp? boolean
---@field hide_range? boolean
---@field overlay? {r:number,g:number,b:number,a:number}
---@field rejected? boolean

---@param opts? vibes.Tower.DrawOpts
function Tower:draw(opts)
  -- TODO: This should all move into PlacedTower, IMO.
  opts = opts or {}
  if opts.preview == nil then
    opts.preview = false
  end

  local mouse_cell = GameFunctions.get_cell_from_mouse()
  local placeable = self:can_place(mouse_cell)

  -- Draw shadow under the tower
  if not opts.preview then
    love.graphics.setColor(1, 1, 1, 0.5)
  end

  local shadow = Asset.sprites.shadow
  local shadow_scale = 1.8

  love.graphics.draw(
    shadow,
    self.position.x,
    self.position.y - (Config.grid.cell_size * 0.3 - self.cell.height),
    0,
    shadow_scale,
    shadow_scale * 0.6,
    shadow:getWidth() / 2,
    shadow:getHeight() / 2
  )

  -- Reset color for tower texture
  if not opts.preview then
    love.graphics.setColor(1, 1, 1)
  end

  if opts.overlay ~= nil then
    love.graphics.setColor(opts.overlay)
  end

  -- Draw tower texture from bottom-center
  local tower_scale = 2

  local scale_x = tower_scale
  -- TODO: Gotta think this through more programmatically later, but that's OK
  if self.state.sprite_orientation == "left" then
    scale_x = -scale_x
  elseif self.state.sprite_orientation == "right" then
    scale_x = scale_x
  end

  local scale_y = tower_scale

  if opts.rejected then
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end

  if not opts.ignore_mouse and not placeable then
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
  end

  if self.animated_texture then
    self.animated_texture:draw(self.position, tower_scale, false)
  else
    love.graphics.draw(
      self.texture,
      self.position.x,
      self.position.y - self.cell.height,
      0, -- rotation
      scale_x, -- scale X
      scale_y, -- scale Y
      self.texture:getWidth() / 2, -- origin offset X (center)
      self.texture:getHeight() -- origin offset Y (bottom)
    )
  end

  if opts.preview then
    return
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

function Tower:_mouse_enter() end
function Tower:_mouse_leave() end

---@param enhancement vibes.EnhancementCard
function Tower:add_enhancement(enhancement)
  table.insert(self.enhancements, enhancement)

  -- local upgrade_option = enhancement:as_upgrade_option(self)
  -- if upgrade_option then
  --   EventBus:emit_tower_stat_upgrade {
  --     tower = self,
  --     upgrade = upgrade_option.operations,
  --   }
  -- end

  self:_update_stats()
end

function Tower:has_mouse_collided()
  -- current offsets needed for grid setup
  local mouse_x, mouse_y = love.mouse.getPosition()
  local scale = 2
  local width = self.texture:getWidth() * scale
  local height = self.texture:getHeight() * scale
  local y_start = (self.position.y + Config.grid.cell_size / 2) - height
  local y_end = y_start + height
  local x_start = self.position.x - width / 2
  local x_end = x_start + width

  return (mouse_x >= x_start and mouse_x <= x_end)
    and (mouse_y >= y_start and mouse_y <= y_end)
end

function Tower:_update_stats()
  -- Make sure that stats have now recalculated
  self.stats_manager:update()
end

---@param _dt number
function Tower:update(_dt)
  -- local is_collided = self:has_mouse_collided()

  -- if is_collided and self.focused == false then
  --   self.focused = true
  --   ActionQueue:add(TowerMouseOver.new { tower = self })
  -- elseif not is_collided and self.focused then
  --   self.focused = false
  -- end

  -- logger.trace "Updating tower"

  self:_update_stats()

  if
    self.tower_type == TowerKind.SHOOTER or self.tower_type == TowerKind.DOT
  then
    local current_time = TIME.now()
    local time_since_last_attack = current_time
      - (self.state.last_attack_time or 0)
    local attack_cooldown = 1 / self:get_attack_speed()

    if time_since_last_attack >= attack_cooldown then
      local targets, all_targets = self:find_targets()

      -- Search for taunting enemies
      for _, enemy in ipairs(all_targets) do
        if enemy.statuses.taunting then
          targets = { enemy }
          break
        end
      end

      if #targets > 0 then
        -- Attack each target
        for _, target in ipairs(targets) do
          self:attack(target)
        end

        State:for_each_active_hook(function(hook)
          if hook.hooks.after_tower_attack then
            hook.hooks.after_tower_attack(hook, self)
          end
        end)

        -- Remember our latest target and attack time
        self.state.last_attack_time = current_time
      end
    end
  end
end

--- Get all cells within the tower's range
---@return table Array of cells within range
function Tower:get_cells_within_range()
  local cells_in_range = {}

  -- Check each cell in the map
  for _, row in ipairs(State.levels:get_current_level().cells) do
    for _, cell in ipairs(row) do
      local cell_center = cell:center()
      local distance_squared = cell_center:distance_squared(self.position)
      local range = self:get_range_in_distance()
      if distance_squared <= (range * range) then
        table.insert(cells_in_range, cell)
      end
    end
  end

  return cells_in_range
end

--- Find enemies within range
--- @return vibes.Enemy[] targets Array of enemies in range, up to the tower's enemy_targets limit
--- @return vibes.Enemy[] all_enemies Array of all enemies in range
function Tower:find_targets()
  if #State.enemies == 0 then
    return {}, {}
  end

  local max_targets = self:get_enemy_targets()
  local enemies_in_range = {}

  -- First gather all enemies in range
  for _, enemy in ipairs(State.enemies) do
    local distance = enemy.position:distance(self.position)
    if distance <= self:get_range_in_distance() then
      table.insert(enemies_in_range, {
        enemy = enemy,
        percent_complete = enemy.pathing_state.percent_complete,
        segment_complete = enemy.pathing_state.segment_complete,
      })
    end
  end

  -- Sort by progress on the path (target furthest enemies first)
  table.sort(enemies_in_range, function(a, b)
    if a.percent_complete ~= b.percent_complete then
      return a.percent_complete > b.percent_complete
    end

    return a.segment_complete > b.segment_complete
  end)

  -- Return limited number of targets
  local targets, all_enemies = {}, {}
  for i, enemy in ipairs(enemies_in_range) do
    table.insert(all_enemies, enemy.enemy)

    if i <= max_targets then
      table.insert(targets, enemy.enemy)
    end
  end

  return targets, all_enemies
end

--- Attack an enemy
---@param _enemy vibes.Enemy
function Tower:attack(_enemy) error "Tower:attack(enemy) not implemented" end

---@param amount number Amount of experience to grant
function Tower:gain_experience(amount)
  self.experience_manager:gain_experience(amount)
end

--- Get the tower's current level progress as a percentage
---@return number Percentage from 0 to 1
function Tower:get_level_progress()
  return self.experience_manager:get_level_progress()
end

function Tower:reset_level_state()
  -- Reset applied towers effects, all slots need to be emptied
  self.enhancements = {}
end

function Tower:get_enemy_operations(enemy)
  local operations = {}

  -- Check all enhancements for enemy operations
  for _, enhancement in ipairs(self.enhancements) do
    if enhancement.get_enemy_operations then
      local enhancement_operations = enhancement:get_enemy_operations(enemy)
      table.list_extend(operations, enhancement_operations)
    end
  end

  return operations
end

--- Overridable function for getting the offset of the projectile, used
--- for determining the starting position of the projectile.
---@return vibes.Position
function Tower:get_projectile_starting_position() return self.position:clone() end

--- Handle a click on this tower. Default behavior does nothing and returns false.
---@return boolean handled Returns true if the click was handled and default UI should be suppressed
function Tower:on_clicked() return false end

-- SUPPORT TOWER STUFF
function Tower:is_supporting_tower(tower) return false end
function Tower:get_support_tower_operations(tower) return {} end

-- ENHANCEMENT STUFF
function Tower:get_tower_operations() return {} end
function Tower:get_tower_stat_enhancements() return {} end

return Tower
