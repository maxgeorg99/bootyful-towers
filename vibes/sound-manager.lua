-- instance.sound:setVolume(config.sounds.sfx_volume)

-- Local sound sources - not accessible globally to prevent accidental usage
local sounds = {
  -- Main Menu Screen
  primary_theme = love.audio.newSource("assets/sounds/full.wav", "static"),
  shaman_spawn = love.audio.newSource("assets/sounds/orked1.wav", "static"),
  round_end = love.audio.newSource("assets/sounds/round-end.wav", "static"),
  round_music = love.audio.newSource("assets/sounds/round-music.wav", "static"),
  boss_music = love.audio.newSource("assets/sounds/boss-music.wav", "static"),

  character_selection_default = love.audio.newSource(
    "assets/sounds/serf2.wav",
    "static"
  ),
  blacksmith_theme = love.audio.newSource("assets/sounds/serf1.wav", "static"),
  mage_theme = love.audio.newSource("assets/sounds/wizard.wav", "static"),
  futurist_theme = love.audio.newSource("assets/sounds/futurist.wav", "static"),

  shoot_arrow1 = love.audio.newSource("assets/sounds/shot1.wav", "static"),
  shoot_arrow2 = love.audio.newSource("assets/sounds/shot2.wav", "static"),
  shoot_arrow3 = love.audio.newSource("assets/sounds/shot3.wav", "static"),
  shoot_arrow4 = love.audio.newSource("assets/sounds/shot4.wav", "static"),

  -- Game events
  game_over = love.audio.newSource("assets/sounds/death.wav", "static"),

  -- Special gear sounds
  pointcrow_crying = love.audio.newSource(
    "assets/sounds/pointcrow.wav",
    "static"
  ),
}

---@enum sound.Kind
local SoundKind = {
  THEME = "THEME",
  BACKGROUND = "BACKGROUND",
  SFX = "SFX",
}

---@class sound.Pool.Opts
---@field id string
---@field source love.Source
---@field pool_size number
---@field kind sound.Kind

--- Create a new sound pool
---@param opts sound.Pool.Opts
---@return vibes.SoundPool
local create_pool = function(opts)
  validate(opts, {
    id = "string",
    source = "userdata",
    pool_size = "number",
    kind = "string",
  })

  local sounds = {}
  for i = 1, opts.pool_size do
    sounds[i] = {
      sound = opts.source:clone(),
      in_use = false,
      id = i,
    }
  end

  return {
    current_index = 1,
    pool_size = opts.pool_size,
    sounds = sounds,
    kind = opts.kind,
  }
end

local pools = {
  archer_shoot = create_pool {
    id = "archer_shoot",
    source = sounds.shoot_arrow1,
    pool_size = 10,
    kind = SoundKind.SFX,
  },
  game_over = create_pool {
    id = "game_over",
    source = sounds.game_over,
    pool_size = 1,
    kind = SoundKind.SFX,
  },
  pointcrow_crying = create_pool {
    id = "pointcrow_crying",
    source = sounds.pointcrow_crying,
    pool_size = 1,
    kind = SoundKind.SFX,
  },
  shaman_spawn = create_pool {
    id = "shaman_spawn",
    source = sounds.shaman_spawn,
    pool_size = 2,
    kind = SoundKind.SFX,
  },
  round_end = create_pool {
    id = "round_end",
    source = sounds.round_end,
    pool_size = 1,
    kind = SoundKind.SFX,
  },
  boss_music = create_pool {
    id = "boss_music",
    source = sounds.boss_music,
    pool_size = 1,
    kind = SoundKind.BACKGROUND,
  },
  primary_theme = create_pool {
    id = "primary_theme",
    source = sounds.primary_theme,
    pool_size = 1,
    kind = SoundKind.THEME,
  },
  character_selection_default = create_pool {
    id = "character_selection_default",
    source = sounds.character_selection_default,
    pool_size = 1,
    kind = SoundKind.THEME,
  },
}

local groups = {
  -- Character Themes
  themes = {
    [CharacterKind.BLACKSMITH] = create_pool {
      id = "blacksmith_theme",
      source = sounds.blacksmith_theme,
      pool_size = 1,
      kind = SoundKind.THEME,
    },
    [CharacterKind.MAGE] = create_pool {
      id = "mage_theme",
      source = sounds.mage_theme,
      pool_size = 1,
      kind = SoundKind.THEME,
    },
    [CharacterKind.FUTURIST] = create_pool {
      id = "futurist_theme",
      source = sounds.futurist_theme,
      pool_size = 1,
      kind = SoundKind.THEME,
    },
  },

  background = {
    round_music = create_pool {
      id = "round_music",
      source = sounds.round_music,
      pool_size = 1,
      kind = SoundKind.BACKGROUND,
    },
  },
}

---@class vibes.SoundInstance
---@field sound love.Source
---@field in_use boolean
---@field id number

---@class vibes.SoundPool
---@field sounds vibes.SoundInstance[]
---@field source love.Source
---@field pool_size number
---@field current_index number
---@field kind sound.Kind

---@class vibes.SoundManager
---@field new fun(): vibes.SoundManager
---@field init fun(self: vibes.SoundManager)
local SoundManager = class "vibes.SoundManager"

--- Create a new sound manager
function SoundManager:init() end

---@class sound.Play.Opts
---@field pitch? number
---@field loop? boolean

--- Play a sound from the specified pool
---@param pool vibes.SoundPool
---@param opts? sound.Play.Opts
---@return vibes.SoundInstance|nil The sound instance being played, or nil if none available
function SoundManager:play(pool, opts)
  opts = opts or {}
  validate(opts, {
    pitch = "number?",
    loop = "boolean?",
  })

  -- Find next available sound instance using round-robin
  local start_index = pool.current_index
  local sound_instance = nil

  repeat
    local instance = pool.sounds[pool.current_index]

    -- If this instance isn't playing or is finished playing, use it
    if not instance.in_use or not instance.sound:isPlaying() then
      sound_instance = instance
      break
    end

    -- Move to next index
    pool.current_index = pool.current_index % pool.pool_size + 1
  until pool.current_index == start_index

  -- If all sounds are in use, reuse the current one anyway
  if not sound_instance then
    sound_instance = pool.sounds[pool.current_index]
    pool.current_index = pool.current_index % pool.pool_size + 1
  end

  -- Set as in use
  sound_instance.in_use = true

  sound_instance.sound:stop() -- Stop in case it was already playing

  -- Apply sound settings based on config and pool kind
  local volume = self:_get_volume_for_kind(pool.kind)
  sound_instance.sound:setVolume(volume)

  if opts.pitch then
    sound_instance.sound:setPitch(opts.pitch)
  end

  if opts.loop then
    sound_instance.sound:setLooping(true)
  end

  -- Play the sound
  sound_instance.sound:play()

  return sound_instance
end

--- Get volume for a sound kind based on config
---@param kind sound.Kind
---@return number
function SoundManager:_get_volume_for_kind(kind)
  local base_volume = 1.0

  if kind == SoundKind.SFX then
    base_volume = Config.sounds.sfx_volume
  elseif kind == SoundKind.THEME or kind == SoundKind.BACKGROUND then
    base_volume = Config.sounds.music_volume
  end

  return base_volume * Config.sounds.master
end

--- Update all sound volumes based on current config
function SoundManager:update_all_volumes()
  -- Update pool sounds
  for _, pool in pairs(pools) do
    local volume = self:_get_volume_for_kind(pool.kind)
    for _, instance in ipairs(pool.sounds) do
      instance.sound:setVolume(volume)
    end
  end

  -- Update grouped pool sounds
  for _, group in pairs(groups) do
    for _, pool in pairs(group) do
      local volume = self:_get_volume_for_kind(pool.kind)
      for _, instance in ipairs(pool.sounds) do
        instance.sound:setVolume(volume)
      end
    end
  end
end

function SoundManager:stop()
  for _, pool in pairs(pools) do
    self:stop_all(pool)
  end
  for _, group in pairs(groups) do
    self:stop_all(group)
  end

  -- Ensure special sounds are also stopped
  self:stop_pointcrow_crying()
end

--- Stop all sounds in a pool
---@param pool vibes.SoundPool
function SoundManager:stop_all(pool)
  for _, instance in ipairs(pool.sounds) do
    instance.sound:stop()
    instance.in_use = false
  end
end

--- Initialize common sound pools at startup
function SoundManager:init_common_pools()
  -- Initialize all sound volumes based on current config
  self:update_all_volumes()
end

function SoundManager:play_shaman_spawn() return self:play(pools.shaman_spawn) end

function SoundManager:play_round_end() return self:play(pools.round_end) end

function SoundManager:play_round_music()
  return self:play(groups.background.round_music, { loop = true })
end

function SoundManager:stop_round_music()
  self:stop_all(groups.background.round_music)
end

function SoundManager:play_boss_music() return self:play(pools.boss_music) end

function SoundManager:play_game_start() end

--- Play the primary theme sound effect
---@param loop? boolean Whether to loop the theme (defaults to true)
---@return vibes.SoundInstance?
function SoundManager:play_primary_theme(loop)
  local should_loop = loop == nil and true or loop
  return self:play(pools.primary_theme, { loop = should_loop })
end

--- Play the character selection default sound effect
---@return vibes.SoundInstance?
function SoundManager:play_character_selection_default()
  return self:play(pools.character_selection_default)
end

--- Play a sound from the specified pool
---@param group table<string, vibes.SoundPool>
function SoundManager:_play_exclusive_from_group(group, key)
  for id, pool in pairs(group) do
    if id == key then
      self:stop_all(pool)
      self:play(pool)
    else
      self:stop_all(pool)
    end
  end
end
--- Play the character theme sound effect
---@param kind CharacterKind
function SoundManager:play_character_theme(kind)
  self:_play_exclusive_from_group(groups.themes, kind)
end

--- Play the game over sound effect
---@return vibes.SoundInstance?
function SoundManager:play_game_over() return self:play(pools.game_over) end

--- Play the shoot arrow sound effect
---@param pitch? number Optional pitch value (defaults to random between 0.9-1.1)
---@return vibes.SoundInstance?
function SoundManager:play_shoot_arrow(pitch)
  local actual_pitch = TrueRandom:decimal_range(0.95, 1.00)
  local volume_scale = TrueRandom:decimal_range(0.7, 1.2)

  local pool = pools.archer_shoot

  local which_instance = math.random(1, pool.pool_size)
  local sound_instance = pool.sounds[which_instance] -- Only one instance in pool

  -- Stop any existing playback
  sound_instance.sound:stop()

  -- Calculate special volume
  local base_volume = 1.0

  -- Set volume directly, ignoring normal volume calculations
  sound_instance.sound:setVolume(base_volume * volume_scale)
  sound_instance.sound:setPitch(actual_pitch)

  -- Play the sound
  -- sound_instance.sound:play()

  return sound_instance
end

--- Play the pointcrow crying sound with special volume logic
--- Ignores game volume settings and plays at 2x volume if game volume is 0
---@return vibes.SoundInstance?
function SoundManager:play_pointcrow_crying_special()
  local pool = pools.pointcrow_crying
  local sound_instance = pool.sounds[1] -- Only one instance in pool

  -- Stop any existing playback
  sound_instance.sound:stop()

  -- Calculate special volume
  local base_volume = 1.0
  local master_volume = Config.sounds.master
  local sfx_volume = Config.sounds.sfx_volume

  -- Special logic: if ANY volume is 0, play at 2x volume, otherwise ignore volume settings completely
  local special_volume = base_volume
  if master_volume == 0 or sfx_volume == 0 then
    special_volume = 2.0
  end

  -- Set volume directly, ignoring normal volume calculations
  sound_instance.sound:setVolume(special_volume)
  sound_instance.sound:setLooping(true)
  sound_instance.in_use = true

  -- Play the sound
  sound_instance.sound:play()

  return sound_instance
end

--- Stop the pointcrow crying sound
function SoundManager:stop_pointcrow_crying()
  local pool = pools.pointcrow_crying
  self:stop_all(pool)
end

return SoundManager.new()
