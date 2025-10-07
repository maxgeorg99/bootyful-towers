local EnemyTooltip = require "ui.components.enemy.tooltip"
local Text = require "ui.components.text"

-- Smaller row height for compact design
local COMPACT_ROW_HEIGHT = 50

---@class (exact) components.PathWavePreview.Opts
---@field box ui.components.Box
---@field path_id string

---@class components.PathWavePreview : Element
---@field new fun(opts: components.PathWavePreview.Opts): components.PathWavePreview
---@field init fun(self: components.PathWavePreview, opts: components.PathWavePreview.Opts)
---@field path_id string
---@field _layout layout.Layout
---@field _enemy_counts table<EnemyType, number>
---@field _enemy_textures table<EnemyType, vibes.Texture|vibes.SpriteAnimation>
---@field _target_opacity number
local PathWavePreview = class("components.PathWavePreview", { super = Element })

---@param opts components.PathWavePreview.Opts
function PathWavePreview:init(opts)
  validate(opts, {
    box = Box,
    path_id = "string",
  })

  Element.init(self, opts.box)

  self.name = "PathWavePreview"
  self.path_id = opts.path_id
  self._enemy_counts = {}
  self._enemy_textures = {}
  self._target_opacity = 1.0

  self:_build_enemy_lookup_table()
  self:_setup_layout()
  self:_update_enemy_counts()
end

--- Build lookup table for enemy classes and their textures/animations
function PathWavePreview:_build_enemy_lookup_table()
  local enemy_classes = {
    require "vibes.enemy.enemy-bat",
    require "vibes.enemy.enemy-goblin",
    require "vibes.enemy.enemy-elite-bat",
    require "vibes.enemy.enemy-boss-king",
    require "vibes.enemy.enemy-mine-goblin",
    require "vibes.enemy.enemy-orc",
    require "vibes.enemy.enemy-elite-orc-shaman",
    require "vibes.enemy.enemy-boss-orca",
    require "vibes.enemy.enemy-elite-snail",
    require "vibes.enemy.enemy-wolf",
    require "vibes.enemy.enemy-boss-wyvern",
    require "vibes.enemy.enemy-orc-chief",
    require "vibes.enemy.enemy-orc-wheeler",
    require "vibes.enemy.enemy-boss-tauntoise",
    require "vibes.enemy.enemy-boss-cat-tatus",
  }

  for _, enemy_class in ipairs(enemy_classes) do
    local enemy_type = enemy_class._properties.enemy_type
    -- Prefer animation over texture if available
    local visual = enemy_class._properties.animation
      or enemy_class._properties.texture
    self._enemy_textures[enemy_type] = visual
  end
end

function PathWavePreview:_setup_layout()
  local _, _, w, h = self:get_geo()

  self._layout = Layout.new {
    name = "PathWavePreview(Layout)",
    box = Box.new(Position.new(5, 5), w - 10, h - 10), -- Smaller padding
    els = {
      (function()
        local parent = self
        return Text.new {
          function()
            return {
              text = "Next",
              color = Colors.white:opacity(parent:get_opacity()),
            }
          end,
          box = Box.new(Position.zero(), w - 10, 20),
          font = Asset.fonts.typography.h4,
          text_align = "center",
          padding = 4,
        }
      end)(),
    },
    flex = {
      justify_content = "start",
      gap = 2,
      align_items = "center",
      direction = "column",
    },
  }

  self:append_child(self._layout)
end

--- Get the next wave and calculate enemy counts filtered by path_id
---@return table<EnemyType, number>?
function PathWavePreview:_get_next_wave_enemy_counts()
  local level = State.levels:get_current_level()
  local next_wave_idx = State.levels.current_wave

  -- Check if there is a next wave
  if next_wave_idx > #level.waves then
    return nil
  end

  local next_wave = level.waves[next_wave_idx]
  local enemy_counts = {}

  logger.debug(
    "PathWavePreview: Looking for path_id=%s, wave=%d, total_spawns=%d",
    self.path_id,
    next_wave_idx,
    #next_wave.spawns
  )

  -- Filter spawns by path_id
  for i, spawn_entry in ipairs(next_wave.spawns) do
    logger.debug(
      "  Spawn %d: type=%s, path.id=%s, matches=%s, remaining=%d",
      i,
      spawn_entry.type,
      spawn_entry.path and spawn_entry.path.id or "nil",
      tostring(spawn_entry.path and spawn_entry.path.id == self.path_id),
      spawn_entry.remaining_spawns
    )

    -- Check if this spawn entry belongs to our path
    if spawn_entry.path and spawn_entry.path.id == self.path_id then
      local enemy_type = spawn_entry.type
      local count = spawn_entry.remaining_spawns

      if enemy_counts[enemy_type] then
        enemy_counts[enemy_type] = enemy_counts[enemy_type] + count
      else
        enemy_counts[enemy_type] = count
      end
    end
  end

  local count = 0
  for _ in pairs(enemy_counts) do
    count = count + 1
  end

  logger.debug(
    "PathWavePreview: Found %d enemy types for path %s",
    count,
    self.path_id
  )

  return enemy_counts
end

function PathWavePreview:_update_enemy_counts()
  local enemy_counts = self:_get_next_wave_enemy_counts()

  if not enemy_counts or next(enemy_counts) == nil then
    -- No next wave or no enemies for this path, hide the preview
    self:set_hidden(true)
    return
  end

  self:set_hidden(false)
  self._enemy_counts = enemy_counts

  -- Clear existing enemy elements (keep the title)
  while #self._layout.children > 1 do
    self._layout:remove_child(self._layout.children[#self._layout.children])
  end

  -- Add enemy preview elements
  local _, _, w, _ = self:get_geo()

  local line = 0
  for enemy_type, count in pairs(enemy_counts) do
    line = line + 1

    local visual = self._enemy_textures[enemy_type]
    if visual then
      self._layout:append_child(
        self:_create_enemy_row(line, enemy_type, count, visual, w)
      )
    end
  end

  -- Update layout height based on content
  local content_height = 20 + #self._layout.children * COMPACT_ROW_HEIGHT + 12 -- title + enemy rows + padding
  self._layout:set_height(content_height)
  self:set_height(content_height)
end

--- Create a visual element for enemy (texture or animation)
---@param visual vibes.Texture|vibes.SpriteAnimation
---@param enemy_type EnemyType
---@return Element
function PathWavePreview:_create_enemy_visual(visual, enemy_type)
  local SpriteAnimation = require "vibes.sprite-animation"

  -- Create a mock enemy for tooltip
  local mock_enemy = self:_create_mock_enemy(enemy_type)

  if SpriteAnimation.is and SpriteAnimation.is(visual) then
    ---@cast visual vibes.SpriteAnimation

    -- Smaller size for compact design
    local COMPACT_SIZE = 50
    local element =
      Element.new(Box.new(Position.zero(), COMPACT_SIZE, COMPACT_SIZE), {
        animation = visual,
        enemy_type = enemy_type,
        mock_enemy = mock_enemy,
        render = function(self)
          local x, y, _, _ = self:get_geo()
          y = y - COMPACT_SIZE / 2
          love.graphics.setColor(1, 1, 1, 1)

          -- Draw the current frame of the animation at standardized scale
          local current_time = love.timer.getTime()
          local frame_duration = 1 / visual.framerate
          local current_frame_index = math.floor(current_time / frame_duration)
              % visual.frame_count
            + 1
          local current_frame = visual.frames[current_frame_index]

          -- Calculate scale to fit in COMPACT_SIZE
          local scale = COMPACT_SIZE / visual.frame_width
          love.graphics.draw(visual.image, current_frame, x, y, 0, scale, scale)
        end,
      })

    return element
  else
    -- It's a texture - standardize to same size
    local COMPACT_SIZE = 50
    local element = require("ui.components.scaled-img").new {
      box = Box.new(Position.zero(), COMPACT_SIZE, COMPACT_SIZE),
      texture = visual --[[@as vibes.Texture]],
      scale_style = "fit",
    }

    element.enemy_type = enemy_type
    element.mock_enemy = mock_enemy
    return element
  end
end

---@param line number
---@param enemy_type EnemyType
---@param count number
---@param visual vibes.Texture|vibes.SpriteAnimation
---@param width number
---@return layout.Layout
function PathWavePreview:_create_enemy_row(
  line,
  enemy_type,
  count,
  visual,
  width
)
  local mock_enemy = self:_create_mock_enemy(enemy_type)

  local row = Layout.row {
    box = Box.new(Position.new(0, line * COMPACT_ROW_HEIGHT), width - 30, 150), -- Compact sizing
    flex = {
      gap = 6,
      align_items = "center",
      justify_content = "start",
    },
    els = {
      -- Enemy sprite or animation
      self:_create_enemy_visual(visual, enemy_type),
      -- Enemy count
      (function()
        local parent = self
        local count_value = count
        return Text.new {
          function()
            return {
              text = " x " .. count_value,
              color = Colors.white:opacity(parent:get_opacity()),
            }
          end,
          box = Box.new(Position.zero(), width, 200),
          font = Asset.fonts.typography.h4,
          text_align = "left",
          vertical_align = "top",
        }
      end)(),
    },
  }

  -- Add tooltip functionality to the entire row
  if mock_enemy then
    self:_add_tooltip_to_element(row, mock_enemy)
  end

  return row
end

function PathWavePreview:_update(dt)
  -- Update enemy counts when wave changes
  self:_update_enemy_counts()

  -- Handle fade based on wave state
  local mode = State:get_mode()
  if mode and mode.lifecycle then
    -- Fade out during active waves, full opacity between waves
    if mode.lifecycle == RoundLifecycle.ENEMIES_SPAWNING then
      self._target_opacity = 0.2
    else
      self._target_opacity = 1.0
    end
  end

  -- Smooth opacity transition
  local current_opacity = self:get_opacity()
  local opacity_diff = self._target_opacity - current_opacity
  local transition_speed = 3.0 -- Adjust for faster/slower fade
  local new_opacity = current_opacity + opacity_diff * transition_speed * dt
  self:set_opacity(new_opacity)
end

--- Create a mock enemy object for tooltip display
---@param enemy_type EnemyType
---@return table
function PathWavePreview:_create_mock_enemy(enemy_type)
  local enemy_classes = {
    require "vibes.enemy.enemy-bat",
    require "vibes.enemy.enemy-goblin",
    require "vibes.enemy.enemy-elite-bat",
    require "vibes.enemy.enemy-boss-king",
    require "vibes.enemy.enemy-mine-goblin",
    require "vibes.enemy.enemy-orc",
    require "vibes.enemy.enemy-elite-orc-shaman",
    require "vibes.enemy.enemy-boss-orca",
    require "vibes.enemy.enemy-elite-snail",
    require "vibes.enemy.enemy-wolf",
    require "vibes.enemy.enemy-boss-wyvern",
    require "vibes.enemy.enemy-orc-chief",
    require "vibes.enemy.enemy-orc-wheeler",
    require "vibes.enemy.enemy-boss-tauntoise",
    require "vibes.enemy.enemy-boss-cat-tatus",
  }

  -- Find the enemy class for this type
  local enemy_class = nil
  for _, cls in ipairs(enemy_classes) do
    if cls._properties.enemy_type == enemy_type then
      enemy_class = cls
      break
    end
  end

  if not enemy_class then
    return nil
  end

  -- Create a mock enemy with the properties from the class
  local mock_enemy = {
    enemy_type = enemy_type,
    max_health = enemy_class._properties.health,
    gold_reward = enemy_class._properties.gold_reward,
    xp_reward = enemy_class._properties.xp_reward,
    get_damage = function() return 1 end, -- Default damage
    get_speed = function() return enemy_class._properties.speed end,
    get_shield = function() return 0 end,
    get_shield_capacity = function() return 0 end,
  }

  return mock_enemy
end

--- Add tooltip functionality to an element
---@param element Element
---@param mock_enemy table
function PathWavePreview:_add_tooltip_to_element(element, mock_enemy)
  if not mock_enemy then
    return
  end

  -- Create tooltip as a child component (following the tower/enemy pattern)
  local _, _, element_w, element_h = element:get_geo()
  local element_box = Box.new(Position.zero(), element_w, element_h)

  local tooltip = EnemyTooltip.new {
    enemy = mock_enemy,
    enemy_box = element_box,
    z = Z.TOOLTIP,
  }

  -- Position tooltip in the top middle of the screen (special case for wave preview)
  local screen_width = love.graphics.getWidth()
  local _, _, tooltip_w, tooltip_h = tooltip:get_geo()

  -- Position tooltip in top middle of screen with proper centering
  local tooltip_x = math.max(20, (screen_width - tooltip_w) / 2)
  local tooltip_y = math.max(20, 50)

  -- Ensure tooltip doesn't go off the right edge
  if tooltip_x + tooltip_w > screen_width - 20 then
    tooltip_x = screen_width - tooltip_w - 20
  end

  tooltip:set_x(tooltip_x)
  tooltip:set_y(tooltip_y)

  element.enemy_tooltip = tooltip
  element:append_child(tooltip)

  function element:_mouse_enter(evt, x, y)
    self.enemy_tooltip:enter_from_enemy()
    return UIAction.HANDLED
  end

  function element:_mouse_leave(evt, x, y)
    self.enemy_tooltip:exit_enemy()
    return UIAction.HANDLED
  end
end

function PathWavePreview:_render()
  local x, y, w, h = self:get_geo()

  -- Background similar to tower tooltip
  love.graphics.setColor(Colors.gray:opacity(self:get_opacity()))
  love.graphics.rectangle("fill", x, y, w, h, 15, 15, 60)

  -- Border
  love.graphics.setColor(Colors.white:opacity(0.3 * self:get_opacity()))
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, w, h, 15, 15, 60)

  love.graphics.setColor(1, 1, 1, 1)
end

return PathWavePreview
