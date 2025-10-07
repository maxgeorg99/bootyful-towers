local GameModes = require "vibes.enum.mode-name"

---@class vibes.CreditsMode : vibes.BaseMode
local credits_mode = { state = {} }

-- Credits text for Star Wars style crawl
local credits_text = [[
               Tower Of Mordoria

House - Water Tower
Vibes Lead - Beginbot
Vibes Manager / Late Night Talent - Teej
Senior Refuctor Engineer - Prime
Crisis Manager / Manager in crisis (same thing) - LowLevel
Pixel King - Adam C Younis
Staff Engineer + Gamer in Residence - Bashbunni
Begin's Manager / Vibes Mom - Big Z (Lindsey)
Product Manager - Krazam Ben
Scrum Mother - Madison
Live Fast Fry Young Meta - Esfand
Filmer - Chris @FlyRyde
Guest Judges - XXXX XXXX XXXX XXXX
Degenerates - Twitch Chat
Wishing To Be Degens - Youtube Chat
A Guy Who Showed Up - Trashdev
The Barber - Benny
Caterer - Primal Alchemy
IV Nurses - (TODO find company name)
Zanuss - The Clipper Extrodinaire
Booty God - Dan Vail
10x engineer - WarrenBuffering
Professional Florida Man - defyusall
Actual DJ - DJ Dave 
Josh - Josh

----- SUPPORT -----
Beastco
CodeGirl007 (Note to self: ban her)
Lithiumx4900
mono_cron
simtoonia
mirubaby
WaRP_TuX
Trev9065
De0m0n
Last_Lost_
Spr3ez
Ramtennae

]]

-- Split credits text into lines
local function split_string(str)
  local lines = {}
  for line in str:gmatch "([^\n]*)\n?" do
    table.insert(lines, line)
  end
  return lines
end

function credits_mode:enter()
  -- Create a background music source (comment out if no music file exists)
  -- credits_mode.music = love.audio.newSource("assets/music/credits_theme.mp3", "stream")

  credits_mode.state = {
    credits_lines = split_string(credits_text),
    scroll_position = 0, -- Starting position for scroll
    scroll_speed = 20, -- Pixels per second, adjusted for better effect
    title_font = Asset.fonts.insignia_48,
    credits_font = Asset.fonts.insignia_24,
    background_color = { 0, 0, 0 }, -- Black background
    text_color = { 1, 0.9, 0 }, -- Yellow text like Star Wars

    -- Star Wars crawl effect properties
    vanishing_point_y = -100, -- Where lines converge above the screen
    initial_y = Config.window_size.height, -- Starting position
    perspective_factor = 120, -- Controls the perspective effect strength

    -- Starfield background
    stars = {},
    num_stars = 300,
    star_speed_min = 10,
    star_speed_max = 200,

    -- Intro text
    show_intro = true,
    intro_alpha = 0,
    intro_fade_in_time = 1.0,
    intro_display_time = 3.0,
    intro_fade_out_time = 1.0,
    intro_timer = 0,

    -- View options
    flat_view = false, -- Toggle between perspective and flat view
    display_help = true, -- Show help text
    help_timer = 0, -- Timer for help text
    help_display_time = 5.0, -- How long to show help

    -- Debug info
    debug_info = false,
  }

  -- Initialize starfield
  for _ = 1, credits_mode.state.num_stars do
    table.insert(credits_mode.state.stars, {
      x = math.random(0, Config.window_size.width),
      y = math.random(0, Config.window_size.height),
      z = math.random(1, 10),
      size = math.random(1, 3),
      speed = math.random(
        credits_mode.state.star_speed_min,
        credits_mode.state.star_speed_max
      ),
      brightness = math.random(5, 10) / 10,
    })
  end

  -- Play background music (comment out if no music file exists)
  -- if credits_mode.music then
  --   credits_mode.music:setLooping(true)
  --   credits_mode.music:play()
  -- end
end

function credits_mode:update(dt)
  -- Update help timer
  if credits_mode.state.display_help then
    credits_mode.state.help_timer = credits_mode.state.help_timer + dt
    if credits_mode.state.help_timer > credits_mode.state.help_display_time then
      credits_mode.state.display_help = false
    end
  end

  -- Handle intro timing
  if credits_mode.state.show_intro then
    credits_mode.state.intro_timer = credits_mode.state.intro_timer + dt
    local total_intro_time = credits_mode.state.intro_fade_in_time
      + credits_mode.state.intro_display_time
      + credits_mode.state.intro_fade_out_time

    if credits_mode.state.intro_timer > total_intro_time then
      credits_mode.state.show_intro = false
      -- Reset scroll position after intro
      credits_mode.state.scroll_position = 0
    else
      -- Calculate alpha for fade effects
      if
        credits_mode.state.intro_timer < credits_mode.state.intro_fade_in_time
      then
        -- Fade in
        credits_mode.state.intro_alpha = credits_mode.state.intro_timer
          / credits_mode.state.intro_fade_in_time
      elseif
        credits_mode.state.intro_timer
        < credits_mode.state.intro_fade_in_time
          + credits_mode.state.intro_display_time
      then
        -- Full display
        credits_mode.state.intro_alpha = 1
      else
        -- Fade out
        local fade_out_progress = (
          credits_mode.state.intro_timer
          - credits_mode.state.intro_fade_in_time
          - credits_mode.state.intro_display_time
        ) / credits_mode.state.intro_fade_out_time
        credits_mode.state.intro_alpha = 1 - fade_out_progress
      end

      -- Don't scroll text while intro is showing
      return
    end
  end

  -- Update scroll position
  credits_mode.state.scroll_position = credits_mode.state.scroll_position
    + credits_mode.state.scroll_speed * dt

  -- If all credits have scrolled off screen, we can reset
  local total_height = #credits_mode.state.credits_lines * 60 -- Approximate height of all text
  if
    credits_mode.state.scroll_position
    > total_height + Config.window_size.height
  then
    -- Loop the credits by resetting position
    credits_mode.state.scroll_position = 0
    -- Show intro again
    credits_mode.state.show_intro = true
    credits_mode.state.intro_alpha = 0
    credits_mode.state.intro_timer = 0
  end

  -- Update starfield
  for _, star in ipairs(credits_mode.state.stars) do
    -- Move stars based on their speed and depth
    star.y = star.y + (star.speed * dt)

    -- Wrap stars that go offscreen
    if star.y > Config.window_size.height then
      star.y = 0
      star.x = math.random(0, Config.window_size.width)
      star.z = math.random(1, 10)
      star.size = math.random(1, 3)
      star.speed = math.random(
        credits_mode.state.star_speed_min,
        credits_mode.state.star_speed_max
      )
    end

    -- Make stars twinkle slightly
    star.brightness = star.brightness + (math.random() - 0.5) * 0.05
    if star.brightness < 0.3 then
      star.brightness = 0.3
    end
    if star.brightness > 1.0 then
      star.brightness = 1.0
    end
  end
end

function credits_mode:draw()
  -- Clear screen with background color
  love.graphics.setColor(credits_mode.state.background_color)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    Config.window_size.width,
    Config.window_size.height
  )

  -- Draw starfield
  for _, star in ipairs(credits_mode.state.stars) do
    -- Brighter stars in front, dimmer stars in back
    local depth_factor = (11 - star.z) / 10
    love.graphics.setColor(
      star.brightness * depth_factor,
      star.brightness * depth_factor,
      star.brightness * depth_factor
    )

    -- Larger stars in front, smaller stars in back
    local size = star.size * depth_factor

    -- Draw the star as a small rectangle
    love.graphics.rectangle("fill", star.x, star.y, size, size)

    -- Add a trail for faster/closer stars
    if star.speed > credits_mode.state.star_speed_max * 0.7 then
      local trail_length = (star.speed / credits_mode.state.star_speed_max) * 10
      love.graphics.setColor(
        star.brightness * depth_factor * 0.5,
        star.brightness * depth_factor * 0.5,
        star.brightness * depth_factor * 0.5
      )
      love.graphics.rectangle(
        "fill",
        star.x,
        star.y - trail_length,
        size * 0.8,
        trail_length
      )
    end
  end

  -- Draw intro text if in intro phase
  if credits_mode.state.show_intro then
    love.graphics.setColor(1, 1, 1, credits_mode.state.intro_alpha)
    love.graphics.setFont(credits_mode.state.title_font)
    love.graphics.printf(
      "A long time ago, in a tower far, far away...",
      0,
      Config.window_size.height / 2 - 24,
      Config.window_size.width,
      "center"
    )
    return
  end

  -- Draw the scrolling text (either in perspective or flat view)
  if credits_mode.state.flat_view then
    -- Simple flat scrolling view
    love.graphics.setColor(credits_mode.state.text_color)
    local y_pos = Config.window_size.height - credits_mode.state.scroll_position
    for i, line in ipairs(credits_mode.state.credits_lines) do
      if i == 1 then
        love.graphics.setFont(credits_mode.state.title_font)
      else
        love.graphics.setFont(credits_mode.state.credits_font)
      end
      love.graphics.printf(
        line,
        0,
        y_pos + (i - 1) * 40,
        Config.window_size.width,
        "center"
      )
    end
  else
    -- Star Wars style perspective crawl
    love.graphics.setColor(credits_mode.state.text_color)

    local center_x = Config.window_size.width / 2
    local text_width = 600 -- Base width of text block

    -- Loop through each line
    for i, line in ipairs(credits_mode.state.credits_lines) do
      -- Calculate position with perspective effect
      local lineY = Config.window_size.height
        - credits_mode.state.scroll_position
        + (i - 1) * 60

      -- Skip if line is offscreen
      if lineY > -50 and lineY < Config.window_size.height + 50 then
        -- Apply perspective math
        local distance = lineY - credits_mode.state.vanishing_point_y
        local scale = credits_mode.state.perspective_factor / distance

        -- Determine font
        if i == 1 then
          love.graphics.setFont(credits_mode.state.title_font)
        else
          love.graphics.setFont(credits_mode.state.credits_font)
        end

        -- Draw text centered
        local actualWidth = text_width * scale
        love.graphics.printf(
          line,
          center_x - actualWidth / 2,
          lineY,
          actualWidth,
          "center",
          0,
          scale,
          scale
        )
      end
    end
  end

  -- Draw help text if enabled
  if credits_mode.state.display_help then
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(Asset.fonts.default_16)
    love.graphics.printf(
      "Press SPACE to toggle between Star Wars and flat view",
      0,
      Config.window_size.height - 60,
      Config.window_size.width,
      "center"
    )
  end

  -- Draw footer instructions
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.setFont(Asset.fonts.default_16)
  love.graphics.printf(
    "Press ESC to return to the main menu",
    0,
    Config.window_size.height - 30,
    Config.window_size.width,
    "center"
  )

  -- Reset color
  love.graphics.setColor(1, 1, 1)
end

function credits_mode:mousepressed() end

function credits_mode:mousemoved() end

function credits_mode:mousereleased() end

function credits_mode:keypressed(key)
  if key == "escape" then
    -- Go back to main menu
    State.mode = GameModes.MAIN_MENU
  elseif key == "space" then
    -- Toggle between perspective and flat view
    credits_mode.state.flat_view = not credits_mode.state.flat_view
    -- Show help text again when toggling
    credits_mode.state.display_help = true
    credits_mode.state.help_timer = 0
  end
end

function credits_mode:exit()
  print "credits_mode.exit"
  -- Stop music when exiting
  -- if credits_mode.music then
  --   credits_mode.music:stop()
  -- end
end

function credits_mode:textinput() end

return require("vibes.base-mode").wrap(credits_mode)
