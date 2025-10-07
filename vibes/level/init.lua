local Random = require "vibes.engine.random"
local TilesetOverdrawn = require "vibes.data.tileset-overdrawn"
local json = require "vendor.json"

local random = Random.new { name = "level-manager" }

local SpawnEntry = require "vibes.enemy.spawn-entry"
local Wave = require "vibes.enemy.wave"

---@alias DecorationName "water-tower" | "cave-down" | "cave-left" | "cave-right"

---@class vibes.LevelData.Decoration
---@field name DecorationName
---@field cell vibes.InlinedCell

---@class vibes.LevelData.PathSegment
---@field cell vibes.InlinedCell

---@class vibes.LevelData.Path
---@field segments vibes.LevelData.PathSegment[]
---@field id string
---@field type "hard"

---@class vibes.LevelData.NonPlaceableArea
---@field cell vibes.InlinedCell

---@class vibes.LevelData.EnhancementPercent
---@field enhancement string
---@field percent number

---@class vibes.LevelData.Spawn
---@field type EnemyType
---@field hp integer
---@field delay integer
---@field time_betwixt integer
---@field enhancements? vibes.LevelData.EnhancementPercent[]
---@field path_id string

---@class vibes.LevelData.Wave
---@field spawns vibes.LevelData.Spawn[]

---@class vibes.LevelData.Enhancement
---@field name string
---@field percent number

---@class vibes.LevelData.TextureCell
---@field tile "grass" | "path" | "empty"
---@field row integer
---@field col integer

---@class vibes.LevelData
---@field level integer
---@field name string
---@field textures vibes.LevelData.TextureCell[][]
---@field paths vibes.LevelData.Path[]
---@field non_placeable_areas vibes.LevelData.NonPlaceableArea[]
---@field waves vibes.LevelData.Wave[]
---@field decorations? vibes.LevelData.Decoration[]

---@class vibes.Level.Buff
---@field name string
---@field icon vibes.Texture
---@field value number

---@class vibes.Level.Opts
---@field level_data_path string
---@field fast_perlin_period? number
---@field slow_perlin_period? number

---@class (exact) vibes.Level
---@field new fun(opts: vibes.Level.Opts): vibes.Level
---@field init fun(self: vibes.Level, opts: vibes.Level.Opts)
---@field id string
---@field name string
---@field level_idx number
---@field paths vibes.Path[]
---@field cells vibes.Cell[][]
---@field waves enemy.Wave[]
---@field decorations vibes.LevelData.Decoration[]
---@field captcha_fail_stacks number
---@field fast_perlin_period number
---@field slow_perlin_period number
--
-- Fields that can be overridden by particular level instances
---@field on_start fun(self: vibes.Level)
---@field on_draw fun(self: vibes.Level)
---@field on_play fun(self: vibes.Level)
---@field on_wave fun(self: vibes.Level, wave: enemy.Wave)
---@field on_spawn fun(self: vibes.Level, wave: enemy.Wave, enemy: vibes.Enemy)
---@field on_end fun(self: vibes.Level)
---@field on_complete fun(self: vibes.Level)
---@field get_enemy_operations fun(self: vibes.Level, enemy: vibes.Enemy): enemy.StatOperation[]
---@field get_tower_operations fun(self: vibes.Level, tower: vibes.Tower): tower.StatOperation[]
---@field on_game_over fun(self: vibes.Level)
--
-- Parent methods, can be overridden by child classes if necessary
---@field init_map_data_from_file fun(self: self, file_path: string)
--
---@field _column_draw_order table<number, number[]>
local Level = class("vibes.Level", {})

---@param opts vibes.Level.Opts
function Level:init(opts)
  validate(opts, {
    level_data_path = "string",
    fast_perlin_period = "number?",
    slow_perlin_period = "number?",
  })

  self.id = "level-" .. opts.level_data_path
  self.captcha_fail_stacks = 0
  self:init_map_data_from_file(opts.level_data_path)
end

function Level:init_map_data_from_file(file_path)
  -- Load and parse the JSON file
  local level_json = assert(love.filesystem.read(file_path))
  -- Extract a clean level name like "7_level_7" from a path like
  -- "assets/level-json/7_level_7.json". Use Lua pattern escapes so we don't
  -- accidentally remove the "-json" substring from the directory.
  local level_name =
    file_path:gsub("^assets/level%-json/", ""):gsub("%.json$", "")

  --- @type vibes.LevelData
  local level_data = json.decode(level_json)
  local level_index = level_data.level

  -- Drive grass palette from level progression (1..10), greener to browner
  local texture_level_index = math.max(1, math.min(level_index, 10))
  local GrassGenerator = require "ui.components.grass-generator"
  local grass_generator = GrassGenerator.new {
    level_index = texture_level_index,
  }

  assert(
    #level_data.textures == Config.grid.grid_height,
    "textures must match grid height"
  )
  assert(
    #level_data.textures[1] == Config.grid.grid_width,
    "textures must match grid width"
  )

  ---@type vibes.Cell[][]
  local cells = {}
  for r = -4, Config.grid.grid_height + 5 do
    local row = {}
    cells[r] = row

    for c = -4, Config.grid.grid_width + 5 do
      local cell = Cell.new(r - 1, c - 1)
      --- @type vibes.LevelData.TextureCell
      local texture_info = (level_data.textures[r] or {})[c]
      if texture_info then
        if texture_info.tile == "path" then
          cell.texture = TilesetOverdrawn.get_random_tile_for_path()
          cell.is_path = true
          cell.is_placeable = false
        else
          cell.texture = grass_generator:texture(r, c)
        end
      end
      cells[r][c] = cell
    end
  end

  ---@type table<string, vibes.Path>
  local paths = {}

  for i, path in pairs(level_data.paths or {}) do
    local cells = {}
    for _, segment in ipairs(path.segments or {}) do
      -- local cell = assert(cells[segment.cell.row + 1][segment.cell.col + 1], "path must exist")
      table.insert(cells, Cell.new(segment.cell.row, segment.cell.col))
    end

    assert(#path.segments > 0, "path must have segments")
    paths[path.id] = Path.new {
      cells = cells,
      id = path.id,
    }
  end

  -- Mark all cells that enemies will actually traverse as non-placeable
  for _, path in pairs(paths) do
    local traversed_cells = path:get_all_traversed_cells()
    for _, traversed_cell in ipairs(traversed_cells) do
      local r = traversed_cell.row + 1
      local c = traversed_cell.col + 1
      if cells[r] and cells[r][c] then
        cells[r][c].is_placeable = false
        cells[r][c].is_path = true
      end
    end
  end

  for _, area in ipairs(level_data.non_placeable_areas or {}) do
    local cell_row = assert(cells[area.cell.row + 1], "row must exist")
    local cell = assert(cell_row[area.cell.col + 1], "col must exist")
    cell.is_placeable = false
  end

  -- Double check that all cells have a texture and are initialized
  for r = 1, Config.grid.grid_height do
    for c = 1, Config.grid.grid_width do
      assert(cells[r][c], "Cell not initialized")
      assert(cells[r][c].texture, "has texture")
    end
  end

  local decoration_data =
    assert(level_data.decorations, "decorations must exist")
  local decorations = {}
  for _, decor in ipairs(decoration_data) do
    local decoration = {
      cell = cells[decor.cell.row + 1][decor.cell.col + 1],
      name = decor.name,
    }
    table.insert(decorations, decoration)
  end

  local waves = {}
  for i = 1, Config.ui.level.wave_count do
    local wave = level_data.waves[i]
      or {
        spawns = {
          {
            type = "BAT",
            hp = 100,
            delay = 0,
            time_betwixt = 500,
            path_id = "path-1",
          },
        },
      }

    local spawns = {}
    for _, spawn in ipairs(wave.spawns) do
      local path = assert(paths[spawn.path_id], "path must exist")
      print("spawn entry", level_index)
      local spawn_entry = SpawnEntry.new {
        path = path,
        spawn = spawn,
        level_idx = level_index,
      }
      table.insert(spawns, spawn_entry)
    end

    table.insert(waves, Wave.new { spawns = spawns })
  end

  logger.info(
    "Level loaded: name=%s, waves_count=%d, level_idx=%d",
    level_name,
    #waves,
    level_data.level
  )

  self.name = level_name
  self.paths = paths
  self.cells = cells
  self.waves = waves
  self.decorations = decorations
  self.level_idx = level_data.level
end

local is_cave_texture = function(texture_name)
  return texture_name == "cave_grass_down"
    or texture_name == "cave_grass_side"
    or texture_name == "cave_grass_up"
    or texture_name == "cave_grass_down_left"
    or texture_name == "cave_grass_down_right"
    or texture_name == "cave-down"
    or texture_name == "cave-left"
    or texture_name == "cave-right"
end

function Level:draw()
  local minFilter, magFilter, anisotropy = love.graphics.getDefaultFilter()
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Grass Green
  love.graphics.setColor(0.4, 0.6, 0.4, 1)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    Config.grid.grid_width * Config.grid.cell_size,
    Config.grid.grid_height * Config.grid.cell_size
  )

  love.graphics.setColor(1, 1, 1, 1)

  -- Draw all non-path tiles first
  local rows = Config.grid.grid_height
  local cols = Config.grid.grid_width

  if not self._column_draw_order then
    self._column_draw_order = {}

    for rIdx = 1, rows do
      -- local available_columns = table.range(1, cols)
      -- table.shuffle(available_columns)
      -- self._column_draw_order[rIdx] = available_columns

      -- First, we need to get all the columns that are path tiles
      -- and separate them from the background tiles
      local path_columns, bg_columns = {}, {}
      for cIdx = 1, cols do
        if self.cells[rIdx][cIdx].is_path then
          table.insert(path_columns, cIdx)
        else
          table.insert(bg_columns, cIdx)
        end
      end

      -- Shuffle the background tiles, to give us a varied z-index look there
      table.shuffle(bg_columns)

      -- Put the path tiles first, then the background tiles
      -- This means the path tiles ALWAYS get drawn before the background tiles,
      -- which makes them creep OVER the path, which we think looks nice.
      table.list_extend(path_columns, bg_columns)

      -- Now save this order for later, so that we ALWAYS draw it the same
      -- way for this level (if you calculate it more often, it will be look scuffed)
      self._column_draw_order[rIdx] = path_columns
    end
  end

  local TilesetOverdrawn = require "vibes.data.tileset-overdrawn"
  for rIdx = 1, rows do
    for _, column in ipairs(self._column_draw_order[rIdx]) do
      local cell = self.cells[rIdx][column]
      if cell and cell.texture then
        TilesetOverdrawn.draw(cell)
      end
    end
  end

  -- Hours of debugging can save minutes of reading documents
  for _, cave in ipairs(self.decorations) do
    local x = cave.cell.col * Config.grid.cell_size
    local y = cave.cell.row * Config.grid.cell_size

    local texture_name = "water_tower"
    if is_cave_texture(cave.name) then
      local overscale = 1.5
      local animation = Asset.animations.spawn_portal
      -- local scale_x = texture:getWidth() / Config.grid.cell_size * overscale
      -- local scale_y = texture:getHeight() / Config.grid.cell_size * overscale

      -- if cave.name == "cave-left" then
      --   scale_x = -scale_x
      --   x = x + Config.grid.cell_size * overscale + 5
      --   y = y - Config.grid.cell_size * overscale - 20
      -- elseif cave.name == "cave-right" then
      --   -- scale_y = -scale_y
      --   x = x + Config.grid.cell_size * overscale + 5
      --   y = y - Config.grid.cell_size * overscale - 20
      -- elseif cave.name == "cave-down" then
      --   scale_x = -scale_x
      -- end
      -- love.graphics.draw(texture, x, y, 0, scale_x, scale_y)
      animation:draw(
        Position.new(
          x - Config.grid.cell_size / 2,
          y + Config.grid.cell_size * overscale
          -- 500,500
        ),
        overscale,
        false
      )
    else
      if cave.name == "rock" then
        texture_name = "rock"
      end

      --- @type vibes.Texture
      local texture = Asset.sprites[texture_name]

      if texture_name == "water_tower" then
        local overscale = 2
        local scale_x = texture:getWidth() / Config.grid.cell_size * overscale
        local scale_y = texture:getHeight() / Config.grid.cell_size * overscale
        local scale = math.max(scale_x, scale_y)

        x = x
        y = y - Config.grid.cell_size * 3 / 2

        love.graphics.draw(texture, x, y, 0, scale, scale)
      elseif texture_name == "rock" then
        local overscale = 2
        local scale_x = texture:getWidth() / Config.grid.cell_size * overscale
        local scale_y = texture:getHeight() / Config.grid.cell_size * overscale
        love.graphics.draw(texture, x, y, 0, scale_x, scale_y)
      end
    end
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.setDefaultFilter(minFilter, magFilter, anisotropy)
end

function Level:on_start() end
function Level:on_draw() end
function Level:on_play() end

function Level:on_end() end
function Level:on_complete() end

function Level:on_game_over() end

--- @param wave enemy.Wave
--- @param enemy vibes.Enemy
function Level:on_spawn(wave, enemy) end

--- @param wave enemy.Wave
function Level:on_wave(wave) end

--- @return enemy.StatOperation[]
function Level:get_enemy_operations(_enemy)
  local ops = {}

  if (self.captcha_fail_stacks or 0) > 0 then
    local EnemyStatOperation = require "vibes.data.enemy-stats-operation"
    local StatOperation = require "vibes.data.stat-operation"
    local EnemyStatField = require "vibes.enum.enemy-stat-field"

    local factor = 1.25 ^ (self.captcha_fail_stacks or 0)
    table.insert(
      ops,
      EnemyStatOperation.new {
        field = EnemyStatField.SPEED,
        operation = StatOperation.mul_mult(factor),
      }
    )
  end

  return ops
end

--- @return tower.StatOperation[]
function Level:get_tower_operations(_tower) return {} end

return Level
