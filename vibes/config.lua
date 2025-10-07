---@class vibes.config.Soundsconfig
---@field master number The volume of the music, 0 to 1
---@field music_volume number The volume of the music, 0 to 1
---@field sfx_volume number The volume of the sfx, 0 to 1

---@enum vibes.config.WindowMode
local WindowMode = {
  Windowed = "windowed",
  WindowedBorderless = "windowed_borderless",
  Fullscreen = "fullscreen",
}

---@class vibes.config.Tower
---@field experience_per_damage number
---@field experience_level_multiplier number
---@field scale number
local tower = {
  experience_per_damage = 0.25,
  experience_level_multiplier = 1.5,
  scale = 2.0,
}

--- @class vibes.config.WindowSize
--- @field mode vibes.config.WindowMode
--- @field width number
--- @field height number
--- @field scissor {x:number, y:number, width:number, height:number}
local window_size = {
  mode = WindowMode.Windowed,
  width = 1920,
  height = 1080,
  scissor = { x = 0, y = 0, width = 1920, height = 1080 },
  padding = {
    left = 50,
    right = 50,
    bottom = 50,
  },
  sidebar = {
    width = 200,
  },
}

--- @class vibes.config.Speeds
--- @field normal number
--- @field fast number
--- @field fastest number
local speeds = {
  normal = 1,
  fast = 8,
  fastest = 16,
}

--- @class vibes.config.Deck
--- @field x number
--- @field y number
local deck = {
  default_hand_size = 6,
  max_hand_size = 10,
}

--- @class vibes.config.Grid
--- @field cell_size number
--- @field grid_width number
--- @field grid_height number Number of rows in the grid
local grid = {
  native_cell_size = 24,
  cell_text_scale = 72 / 48 * 2,
  cell_size = 72,
  grid_width = 27,
  grid_height = 15,
}

---@class (exact) vibes.config.Debug
---@field enabled boolean
---@field show_path_types boolean
---@field show_mouse_position boolean
local debug = {
  enabled = false,
  show_path_types = false,
  show_mouse_position = false,
}

--- @class (exact) ui.forge.ForgeConfig
--- @field upgrade_duration number
--- @field upgrade_open_duration number
--- @field upgrade_rarity_distance_max number
local forge = {
  upgrade_duration = 0.5,
  upgrade_open_duration = 0.5,
  upgrade_rarity_distance_max = 2,
}

--- @class (exact) ui.deck.DeckConfig
--- @field discard vibes.Position
--- @field exhausted vibes.Position
--- @field draw vibes.Position
--- @field hand_middle vibes.Position
--- @field height number
--- @field width number

--- @class (exact) ui.Config
--- @field debug boolean
--- @field minimum_drag_amount number
--- @field long_press_duration number
--- @field double_click_duration number
--- @field deck ui.deck.DeckConfig
--- @field card ui.config.Card
--- @field message ui.config.UI.Message
--- @field forge ui.forge.ForgeConfig
--- @field level {wave_count: number, empty_replacement: vibes.LevelData.TextureCell}
--- @field tile_overdrawn {path_length: number, grass_length: number, grass_height_max: number, scale: number}
--- @field menu_buttons {height: number, width: number, spacing: number}
--- @field time_multiplier_button {width: number, height: number}
--- @field next_wave_preview {width: number, height: number, padding: number, gap_from_button: number}
local ui_config = {
  debug = false,
  minimum_drag_amount = 10,
  long_press_duration = 750,
  double_click_duration = 250,
  forge = forge,
  tile_overdrawn = {
    path_length = 4,
    grass_length = 30,
    grass_height_max = 6,
    scale = 2,
  },
  level = {
    empty_replacement = {
      tile = "grass",
      row = 1,
      col = 0,
    },
    wave_count = 8,
  },
  menu_buttons = {
    height = 80,
    width = 240,
    spacing = 40,
  },
  time_multiplier_button = {
    width = 120,
    height = 40,
  },
  next_wave_preview = {
    width = 200,
    height = 150,
    padding = 20,
    gap_from_button = 10,
  },
}

--- @class (exact) ui.config.Card
--- @field scaling {blur:number, focus:number, selected:number}
--- @field width number
--- @field height number
--- @field new_width number
--- @field new_height number
--- @field spacing number
--- @field selected_scale number

ui_config.card = {
  scaling = {
    blur = 0.4,
    focus = 0.5,
    selected = 0.51,
  },
  width = 590,
  height = 830,
  new_width = 290,
  new_height = 440,
  spacing = 0.3,
  selected_scale = 1.07,
}

---@class (exact) ui.config.UI.Message
---@field mouse_move_to_close number
---@field time_to_close number

ui_config.message = {
  mouse_move_to_close = 150,
  time_to_close = 0.8, -- Auto-dismiss after 0.8 seconds
}

local right_side_offset = 350
local bottom_side_offset = window_size.height * 0.2
local card_margin = 100

ui_config.deck = {
  width = 80,
  height = 80,
  draw = Position.new(
    right_side_offset,
    window_size.height - bottom_side_offset - card_margin * 2
  ),
  discard = Position.new(
    right_side_offset,
    window_size.height - bottom_side_offset - card_margin
  ),
  exhausted = Position.new(
    right_side_offset,
    window_size.height - bottom_side_offset
  ),
  hand_middle = Position.new(
    window_size.width / 2,
    math.floor(window_size.height * 0.9)
  ),
}

---@class (exact) vibes.config.Player
---@field default_health number
---@field default_energy number
---@field max_energy number
---@field default_discards number
---@field default_hand_size number
---@field starting_gold number
---@field default_block number

---@class (exact) vibes.config.Sounds
---@field master number
---@field music_volume number
---@field sfx_volume number

---@class (exact) vibes.config.Config
---@field max_loop_count number
---@field init fun(self: vibes.config.Config)
---@field new fun(): vibes.config.Config
---@field rows number
---@field cols number
---@field window_size vibes.config.WindowSize
---@field card ui.config.Card
---@field deck vibes.config.Deck
---@field grid vibes.config.Grid
---@field speeds vibes.config.Speeds
---@field debug vibes.config.Debug
---@field sounds vibes.config.Sounds
---@field scale_ui boolean Marks if UI should scale with window size
---@field player vibes.config.Player
---@field enemy {health_multiplier: number}
---@field tower vibes.config.Tower
---@field starting_mode ModeName
---@field starting_character CharacterKind
---@field starting_level number
---@field selected_levels string[]?
---@field test_wave number?
---@field test_level number?
---@field tower_level number?
---@field gc_timing number
---@field seed number The seed to use for RNG (TODO: Could be in the gamestate?)
---@field ui ui.Config
local Config = class "vibes.config.Config"

function Config:init()
  self.seed = os.time() % (16 ^ 8)
  self.starting_mode = ModeName.MAIN_MENU
  self.starting_character = CharacterKind.BLACKSMITH
  self.gc_timing = 40

  self.enemy = {
    health_multiplier = 1.5,
  }

  self.max_loop_count = 10000
  self.rows = window_size.height / grid.cell_size
  self.cols = window_size.width / grid.cell_size
  self.window_size = window_size
  self.deck = deck
  self.grid = grid
  self.player = {
    default_health = 100,
    default_energy = 4,
    max_energy = 8,
    default_discards = 1,
    default_hand_size = 6,
    starting_gold = 0,
    default_block = 0,
  }
  self.speeds = speeds
  self.debug = debug
  self.sounds = {
    master = 0.0,
    music_volume = 0.1,
    sfx_volume = 0.5,
  }
  self.scale_ui = false
  self.tower = tower

  self.ui = ui_config
end

--- Calculate starting energy for a given level
--- Starts at 3 energy for level 1, scales to 5 energy by level 5
---@param level_idx number The current level index (1-based)
---@return number The starting energy for that level
function Config:get_starting_energy_for_level(level_idx)
  -- Level 1: 3 energy
  -- Level 2: 4 energy
  -- Level 3: 4 energy
  -- Level 4: 4 energy
  -- Level 5+: 5 energy
  if level_idx == 1 then
    return 3
  elseif level_idx <= 4 then
    return 4
  else
    return 5
  end
end

---@param mode vibes.config.WindowMode
function Config:set_window_settings(mode)
  local _, _, flags = love.window:getMode()
  if mode == WindowMode.Windowed then
    love.window.setMode(window_size.width, window_size.height, {
      fullscreen = false,
      borderless = false,
      centered = true,
      resizable = true,
    })
  end

  if mode == WindowMode.WindowedBorderless then
    local w, h = love.window.getDesktopDimensions()
    love.window.setMode(w, h, {
      fullscreen = false,
      borderless = true,
      centered = true,
    })
  end

  if mode == WindowMode.Fullscreen and not flags.fullscreen then
    love.window.setMode(
      window_size.width,
      window_size.height,
      { fullscreen = true, borderless = false, centered = true }
    )
  end
  self:resize()
end

function Config:resize()
  local w, h = love.graphics.getDimensions()
  local w1, h1 = WINDOW_STATUS.width, WINDOW_STATUS.height -- target rendering resolution
  local scale = math.min(w / w1, h / h1)
  WINDOW_STATUS.translateX, WINDOW_STATUS.translateY, WINDOW_STATUS.scale =
    (w - w1 * scale) / 2, (h - h1 * scale) / 2, scale

  if not Config.window_size then
    Config.window_size = window_size
  end

  local screenX = 0 * WINDOW_STATUS.scale + WINDOW_STATUS.translateX
  local screenY = 0 * WINDOW_STATUS.scale + WINDOW_STATUS.translateY
  local screenW = self.window_size.width * WINDOW_STATUS.scale
  local screenH = self.window_size.height * WINDOW_STATUS.scale

  Config.window_size.scissor.x = screenX
  Config.window_size.scissor.y = screenY
  Config.window_size.scissor.width = screenW
  Config.window_size.scissor.height = screenH
end

return Config.new()
