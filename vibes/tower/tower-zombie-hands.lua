local Tower = require "vibes.tower.base"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites
local anim = require "vibes.anim"

local susceptible_enemies = {
  [EnemyType.GOBLIN] = true,
  [EnemyType.MINE_GOBLIN] = true,
  [EnemyType.ORC] = true,
  [EnemyType.WOLF] = true,
}

---@alias vibes.ZombieHandsTower.HandState "open" | "closed" | "descending" | "cooldown" | "ready"

---@class vibes.ZombieHandsTower : vibes.Tower
---@field new fun(): vibes.ZombieHandsTower
---@field init fun(self: vibes.ZombieHandsTower)
---@field _type "vibes.ZombieHandsTower"
---@field grasp_duration number Duration to hold enemies in place
---@field grasp_cooldown number Cooldown between grasps
---@field last_grasp_time number Last time a grasp occurred
---@field previous_y_offset number Previous Y offset to determine direction
---@field hand_y_offset number Current Y offset for hand animation
---@field hand_state vibes.ZombieHandsTower.HandState
---@field closed_wrist_texture vibes.Texture
---@field closed_fingers_texture vibes.Texture
---@field hand_open_texture vibes.Texture
---@field dirt_mound_texture vibes.Texture
---@field enemy_sprite vibes.Texture?
---@field hand_animator table Animation system for hand movement
---@field animation_finish_time number Time when the descending animation finished
local ZombieHandsTower = class("vibes.ZombieHandsTower", { super = Tower })

--- Zombie Hands Tower - Grasps enemies and holds them in place
function ZombieHandsTower:init()
  local stats = TowerStats.new {
    range = Stat.new(1, 1), -- 1 cell range to cover the same cell
    damage = Stat.new(2, 1),
    attack_speed = Stat.new(0.5, 1),
    enemy_targets = Stat.new(1, 1),
    durability = Stat.new(5, 1),
  }

  Tower.init(
    self,
    stats,
    sprites.dirt_mound,
    { kind = TowerKind.DOT, element_kind = ElementKind.ZOMBIE }
  )

  self.grasp_duration = 3.0
  self.grasp_cooldown = 5.0
  self.last_grasp_time = 0
  self.dirt_mound_texture = sprites.dirt_mound
  self.closed_wrist_texture = sprites.grasping_hand_closed_wrist
  self.closed_fingers_texture = sprites.grasping_hand_closed_fingers
  self.hand_open_texture = sprites.grasping_hand_open

  -- Animation state
  self.hand_state = "ready" -- "open" or "closed" or "descending" or "cooldown" or "ready"
  self.animation_timer = 0
  self.hand_y_offset = 0 -- Current Y offset for hand animation
  self.previous_y_offset = 0 -- Previous Y offset to determine direction

  -- Initialize hand animator for smooth up/down movement
  self.hand_animator = anim.new {
    y_offset = { initial = 0, rate = 8.0 },
  }

  -- Initialize animation finish time
  self.animation_finish_time = 0
end

function ZombieHandsTower:can_place(cell)
  if not cell.is_path then
    return false
  end

  for _, tower in ipairs(State.towers) do
    if tower.cell == cell then
      return false
    end
  end

  return true
end

--- Immobilize an enemy by grasping it
---@param enemy vibes.Enemy
function ZombieHandsTower:immobilize_enemy(enemy)
  -- Only check for grasping when in ready state
  if self.hand_state ~= "ready" then
    return
  end

  if not susceptible_enemies[enemy.enemy_type] then
    return
  end

  -- Check if THIS specific enemy is in the same cell as the tower
  local tower_cell = Cell.from_position(self.position)
  local enemy_cell = Cell.from_position(enemy.position)

  if tower_cell.row == enemy_cell.row and tower_cell.col == enemy_cell.col then
    local current_time = TIME.now()
    if current_time - self.last_grasp_time >= self.grasp_cooldown then
      -- Grasp the enemy - immobilize them
      enemy:update_position(self.position)
      enemy:freeze()
      self.enemy_sprite = enemy.texture
      -- Mark that we just grasped
      self.last_grasp_time = current_time
      self.hand_state = "open"
      self.animation_timer = 0
      -- Reset hand position to bottom for new animation
      anim.drive(self.hand_animator, { y_offset = 0 }, 0)

      -- Trigger proper enemy death event for cleanup
      EventBus:emit_enemy_death {
        enemy = enemy,
        tower = self,
        position = enemy.position,
        kind = "zombie_grasp",
      }
    end
  end
end

--- Update the tower animation and state
---@param dt number
function ZombieHandsTower:update(dt)
  Tower.update(self, dt)

  -- Update hand animator
  anim.update(self.hand_animator, dt)
  local y_offset_value = anim.get(self.hand_animator, "y_offset")
  self.previous_y_offset = self.hand_y_offset
  self.hand_y_offset = (type(y_offset_value) == "number") and y_offset_value
    or 0

  -- Handle hand animation
  if self.hand_state ~= "ready" then -- "open" or "closed" or "descending" or "cooldown" or "ready"
    self.animation_timer = self.animation_timer + dt
  end

  self.animation_timer = self.animation_timer + dt

  -- Switch hand state based on animation timing
  -- <<<<<<< Updated upstream
  --     self.hand_state == "closed"
  --     and self.animation_timer >= self.grasp_duration * 0.5
  --   then
  --     self.hand_state = "open"
  --     self.animation_timer = 0
  --   elseif
  --     self.hand_state == "open"
  --     and self.animation_timer >= self.grasp_cooldown * 0.8
  -- =======
  if
    self.hand_state == "open"
    and self.animation_timer >= 0.5 -- Open for 0.5 seconds
  then
    self.hand_state = "closed"
    self.animation_timer = 0
  elseif
    self.hand_state == "closed"
    and self.animation_timer >= self.grasp_duration * 0.5
  then
    self.hand_state = "descending"
    self.animation_timer = 0
  elseif
    self.hand_state == "descending"
    and self.animation_timer >= 1.0 -- Descend for 1 second
  then
    -- Animation finished - clean up and start cooldown
    self.enemy_sprite = nil
    self.animation_timer = 0
    self.animation_finish_time = TIME.now()
    self.hand_state = "cooldown"
  elseif
    self.hand_state == "cooldown"
    and (TIME.now() - self.animation_finish_time) >= self.grasp_cooldown
  then
    -- Ready to grasp again
    self.hand_state = "ready"
  end

  -- Only create continuous up/down movement animation when ready
  if self.hand_state == "ready" then
    local current_time = TIME.now()
    local cycle_duration = 2.0 -- 2 seconds for full up/down cycle
    local cycle_progress = (current_time % cycle_duration) / cycle_duration

    -- Calculate target Y offset using sine wave for smooth up/down movement
    local max_offset = 15 -- Maximum pixels to move up/down
    local target_offset = math.sin(cycle_progress * math.pi * 2) * max_offset

    -- Drive the animator towards the target offset
    anim.drive(self.hand_animator, { y_offset = target_offset }, dt)
  else
    -- When not ready, keep hand at bottom (no movement)
    anim.drive(self.hand_animator, { y_offset = 0 }, dt)
  end
end

--- Draw the tower with hand animation
function ZombieHandsTower:draw(_)
  -- ALWAYS Draw the dirt mound base
  local scale = 1.0
  local x = self.position.x
  local y = self.position.y - self.texture:getHeight() / 2

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(
    self.dirt_mound_texture,
    x,
    y + (Config.grid.cell_size * 0.3),
    0,
    scale,
    scale,
    self.dirt_mound_texture:getWidth() / 2,
    self.dirt_mound_texture:getHeight() / 2
  )

  if self.hand_state == "ready" or self.hand_state == "cooldown" then
    return
  end

  -- Draw hand based on state
  local hand_x = x
  local hand_y = y + (Config.grid.cell_size * 0.3) + self.hand_y_offset -- Apply animation offset

  if
    self.hand_state == "open"
    or self.hand_state == "closed"
    or self.hand_state == "descending"
  then
    -- Draw wrist at the back (behind enemy)
    love.graphics.draw(
      self.closed_wrist_texture,
      hand_x,
      hand_y,
      0,
      scale,
      scale,
      self.closed_wrist_texture:getWidth() / 2,
      self.closed_wrist_texture:getHeight() / 2
    )

    -- Draw enemy sprite if it exists
    if self.enemy_sprite then
      love.graphics.draw(
        self.enemy_sprite,
        hand_x,
        hand_y,
        0,
        scale,
        scale,
        self.enemy_sprite:getWidth() / 2,
        self.enemy_sprite:getHeight() / 2
      )
    end

    -- Draw fingers on top (in front of enemy)
    local fingers_texture = self.hand_open_texture
    if self.hand_state == "closed" or self.hand_state == "descending" then
      fingers_texture = self.closed_fingers_texture
    end

    love.graphics.draw(
      fingers_texture,
      hand_x,
      hand_y,
      0,
      scale,
      scale,
      fingers_texture:getWidth() / 2,
      fingers_texture:getHeight() / 2
    )
  end
end

function ZombieHandsTower:render_hand()
  if self.hand_state == "open" then
    return self.hand_open_texture
  elseif self.hand_state == "closed" or self.hand_state == "descending" then
    return self.closed_fingers_texture
  end
  return self.hand_open_texture
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 5, 10, 20, 40, 80 },
  [TowerStatField.RANGE] = TowerUtils.range_by_list { 0.5, 0.75, 1.25, 2.5, 5.0 },
  [TowerStatField.ATTACK_SPEED] = TowerUtils.attack_speed_by_list {
    0.25,
    0.5,
    0.75,
    1.5,
    3.0,
  },
  [TowerStatField.ENEMY_TARGETS] = TowerUtils.enemy_targets_by_list {
    1,
    2,
    3,
    5,
    10,
  },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

local upgrades = {
  [Rarity.COMMON] = {
    TowerUpgradeOption.new {
      name = "Stronger Grasp",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_damage(2) },
    },

    TowerUpgradeOption.new {
      name = "Extended Reach",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_range(0.5) },
    },

    TowerUpgradeOption.new {
      name = "Quicker Recovery",
      rarity = Rarity.COMMON,
      operations = { TowerStatOperation.base_attack_speed(0.25) },
    },
  },

  [Rarity.UNCOMMON] = {
    TowerUpgradeOption.new {
      name = "Deep Grasp",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_damage(3),
        TowerStatOperation.base_range(0.25),
      },
    },

    TowerUpgradeOption.new {
      name = "Rapid Grasping",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_attack_speed(0.5),
      },
    },

    TowerUpgradeOption.new {
      name = "Multi-Grasp",
      rarity = Rarity.UNCOMMON,
      operations = {
        TowerStatOperation.base_enemy_targets(1),
      },
    },
  },

  [Rarity.RARE] = {
    TowerUpgradeOption.new {
      name = "Bone Crusher Grasp",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_damage(5),
      },
    },

    TowerUpgradeOption.new {
      name = "Extended Immobilization",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_range(0.5),
        TowerStatOperation.base_enemy_targets(1),
      },
    },

    TowerUpgradeOption.new {
      name = "Swift Hands",
      rarity = Rarity.RARE,
      operations = {
        TowerStatOperation.base_attack_speed(0.75),
      },
    },
  },

  [Rarity.EPIC] = {
    TowerUpgradeOption.new {
      name = "Zombie Horde Grasp",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_damage(8),
        TowerStatOperation.base_enemy_targets(2),
        TowerStatOperation.base_range(0.5),
      },
    },

    TowerUpgradeOption.new {
      name = "Unrelenting Grasp",
      rarity = Rarity.EPIC,
      operations = {
        TowerStatOperation.base_attack_speed(1.0),
      },
    },
  },

  [Rarity.LEGENDARY] = {
    TowerUpgradeOption.new {
      name = "Necromantic Grasp",
      rarity = Rarity.LEGENDARY,
      operations = {
        TowerStatOperation.base_damage(15),
        TowerStatOperation.base_enemy_targets(3),
        TowerStatOperation.base_range(1.0),
        TowerStatOperation.base_attack_speed(1.5),
      },
    },
  },
}

-- Merge base enhancements with custom upgrades
for rarity, rarity_upgrades in pairs(upgrades) do
  for _, upgrade in ipairs(rarity_upgrades) do
    table.insert(enhancements_by_rarity[rarity], upgrade)
  end
end

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function ZombieHandsTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function ZombieHandsTower:get_upgrade_options() return enhancements_by_rarity end

function ZombieHandsTower:set_hand_state(state)
  if
    state ~= "open"
    and state ~= "closed"
    and state ~= "descending"
    and state ~= "cooldown"
    and state ~= "ready"
  then
    error("Invalid hand state: " .. state)
  end
  self.hand_state = state
end

function ZombieHandsTower:attack(_) end

return ZombieHandsTower
