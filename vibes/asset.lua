local SpriteAnimation = require "vibes.sprite-animation"
local TilesetOverdrawn = require "vibes.data.tileset-overdrawn"

---@alias vibes.Texture love.Image|love.Drawable

love.graphics.setDefaultFilter("nearest", "nearest")

local h_base = 98
-- First create all fonts to avoid duplication
local typography = {
  h1 = love.graphics.newFont("assets/fonts/Insignia.ttf", h_base, "normal"),
  h2 = love.graphics.newFont("assets/fonts/Insignia.ttf", h_base / 2, "normal"),
  h3 = love.graphics.newFont("assets/fonts/Apollo.ttf", h_base / 3, "normal"),
  h4 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    h_base / 3.5,
    "normal"
  ),
  h5 = love.graphics.newFont("assets/fonts/Insignia.ttf", h_base / 4, "normal"),
  -- paragraph = love.graphics.newFont(29, "normal"),
  paragraph = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    25,
    "normal"
  ),
  paragraph_sm = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    24,
    "normal"
  ),
  paragraph_md = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    32,
    "none"
  ),
  paragraph_lg = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    55,
    "normal"
  ),
  bold = love.graphics.newFont(29, "mono"),
  text = love.graphics.newFont("assets/fonts/Armin2.ttf", 72, "mono"),
  tooltip_stat = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    32,
    "normal"
  ),
  evolution_button_font = love.graphics.newFont(
    "assets/fonts/Armin2.ttf",
    32,
    "mono"
  ),
  sub = love.graphics.newFont("assets/fonts/TinyPixel.ttf", 10, "normal"),
  card_kind = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    16 * 2,
    "normal"
  ),
  card_title = love.graphics.newFont(
    "assets/fonts/Apollo.ttf",
    16 * 2,
    "normal"
  ),
  card_description = love.graphics.newFont(
    "assets/fonts/Ohrenstead.ttf",
    16 * 2,
    "light"
  ),
  title_box = {
    title = love.graphics.newFont("assets/fonts/Apollo.ttf", 16 * 2, "normal"),
    body = love.graphics.newFont(
      "assets/fonts/Ohrenstead.ttf",
      16 * 2,
      "normal"
    ),
  },
  hud = {
    numbers = love.graphics.newFont(
      -- "assets/fonts/Apollo.ttf",
      "assets/fonts/BigNumbers.ttf",
      16 * 2,
      "normal"
    ),
  },
}
typography.paragraph:setLineHeight(1.5)

local fonts = {
  typography = typography,
  bignumbers_16 = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    16,
    "normal"
  ),
  bignumbers_24 = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    24,
    "normal"
  ),
  bignumbers_32 = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    32,
    "normal"
  ),
  bignumbers_48 = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    48,
    "normal"
  ),
  bignumbers_64 = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    64,
    "normal"
  ),
  damage_number = love.graphics.newFont(
    "assets/fonts/BigNumbers.ttf",
    16,
    "normal"
  ),
  insignia_48 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    48,
    "normal"
  ),
  insignia_40 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    40,
    "normal"
  ),
  insignia_36 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    36,
    "normal"
  ),
  insignia_24 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    24,
    "normal"
  ),
  insignia_22 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    22,
    "normal"
  ),
  insignia_20 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    20,
    "normal"
  ),
  insignia_18 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    18,
    "normal"
  ),
  insignia_16 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    16,
    "normal"
  ),
  insignia_14 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    14,
    "normal"
  ),
  insignia_12 = love.graphics.newFont(
    "assets/fonts/Insignia.ttf",
    12,
    "normal"
  ),
  default_48 = love.graphics.newFont(48),
  default_20 = love.graphics.newFont(20),
  default_18 = love.graphics.newFont(18),
  default_16 = love.graphics.newFont(16),
  default_14 = love.graphics.newFont(14),
  default_12 = love.graphics.newFont(12),
  mono_12 = love.graphics.newFont(32, "light"),
}

---@param path string
---@return vibes.Texture
local load_texture = function(path)
  return love.graphics.newImage(path, { linear = false })
end

---@class vibes.AssetShader
---@field shader love.Shader
---@field init fun(shader: vibes.AssetShader, opts?:table) ---(TODO(defyus) create
---proper definition)
---@field send fun(shader: vibes.AssetShader, ...)

return {
  fonts = fonts,
  tilesets = {
    overdrawn_sprites = TilesetOverdrawn.load_overdrawn_spritesheet "tileset-36.png",
    grass_full = load_texture "assets/sprites/grass-tileset.png",
    grass = require("vibes.data.tileset").load_spritesheet "grass-tileset.png",
    volcano = require("vibes.data.tileset").load_spritesheet "volcano-tileset.png",
  },
  shaders = {
    shine = ShaderShine.new {},
    map_fadeout = ShaderMapFadeOut.new {},
    edge_outline = ShaderEdgeOutline.new { texture_size = { 0, 0 } },
    edge_glow_throb = ShaderEdgeGlowThrob.new { texture_size = { 0, 0 } },
    cloud = ShaderCloud.new {},
    color_swap = ShaderColorSwap.new {},
    rewind = ShaderRewind.new {},
    grass_noise = ShaderGrassNoise.new {},
  },
  animations = {
    death_coin = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/coin-drop-spin.png",
      frame_count = 4,
      framerate = 1,
    },

    frog_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/frog-walk.png",
      frame_count = 6,
      framerate = 24,
    },

    orc_shaman_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orc-shaman-walk.png",
      frame_count = 4,
      framerate = 16,
    },

    orc_warrior = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orc-warrior-idle.png",
      frame_count = 2,
      framerate = 8,
    },

    orc_warrior_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orc-warrior-Walk.png",
      frame_count = 4,
      framerate = 8,
    },

    bat_fly = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/bat-enemy-fly.png",
      frame_count = 6,
      framerate = 32,
    },

    orc_chief_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orc-chief-walk.png",
      frame_count = 4,
      framerate = 8,
    },

    orc_wheeler_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orc-wheeler-walk.png",
      frame_count = 4,
      framerate = 8,
    },

    mine_goblin_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/mine-goblin-walk.png",
      frame_count = 4,
      framerate = 4,
    },

    explosion = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/death-explode-burst.png",
      frame_count = 8,
      framerate = 32,
    },

    wolf_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/wolf-walk.png",
      frame_count = 6,
      framerate = 16,
    },

    wyvern_fly = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/wyvern-fly.png",
      frame_count = 7,
      framerate = 16,
    },

    frog = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/wyvern-fly.png",
      frame_count = 7,
      framerate = 16,
    },

    orca_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/orca-walk.png",
      frame_count = 4,
      framerate = 16,
    },

    king_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/king-walk.png",
      frame_count = 8,
      framerate = 16,
    },

    cat_tatus_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/cat-tatus-walk.png",
      frame_count = 6,
      framerate = 12,
    },

    tauntoise_walk = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/tauntoise-walk.png",
      frame_count = 8,
      framerate = 16,
    },

    fire_1 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/fire-1.png",
      frame_count = 8,
      framerate = 4,
    },

    fire_2 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/fire-2.png",
      frame_count = 8,
      framerate = 4,
    },

    fire_3 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/fire-3.png",
      frame_count = 8,
      framerate = 4,
    },

    poison_1 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/poison-1.png",
      frame_count = 11,
      framerate = 16,
    },

    poison_2 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/poison-2.png",
      frame_count = 11,
      framerate = 16,
    },

    poison_3 = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/effect/poison-3.png",
      frame_count = 11,
      framerate = 16,
    },

    spawn_portal = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/ui/portal-loop.png",
      frame_count = 11,
      framerate = 16,
    },
  },
  icons = {
    [IconType.SWORD] = load_texture "assets/icons/sword.png",
    [IconType.SKULL] = load_texture "assets/icons/skull.png",
    [IconType.HEADS] = load_texture "assets/icons/flip_tails.png",
    [IconType.TAILS] = load_texture "assets/icons/flip_head.png",
    [IconType.UPGRADE] = load_texture "assets/icons/pawn_up.png",
    [IconType.DOWNGRADE] = load_texture "assets/icons/pawn_down.png",
    [IconType.DICE] = load_texture "assets/icons/dice_3D_detailed.png",
    [IconType.REROLL] = load_texture "assets/icons/dice_out.png",
    [IconType.CROWN] = load_texture "assets/icons/crown_a.png",
    [IconType.SHIELD] = load_texture "assets/icons/shield.png",
    [IconType.HEART] = load_texture "assets/icons/suit_hearts.png",
    [IconType.BROKEN_HEART] = load_texture "assets/icons/suit_hearts_broken.png",
    [IconType.BOW] = load_texture "assets/icons/bow.png",
    [IconType.ESCAPE_KEY] = load_texture "assets/icons/keyboard_escape_outline.png",
    [IconType.RIGHT_CLICK] = load_texture "assets/icons/mouse_right_outline.png",
    [IconType.DISCARD] = load_texture "assets/icons/card_subtract.png",
    [IconType.NOCARD] = load_texture "assets/icons/card_outline_remove.png",
    [IconType.DOWNARROW] = load_texture "assets/icons/down-arrow.png",
    [IconType.UP_ARROW] = load_texture "assets/icons/arrowUp.png",
    [IconType.DOWN_ARROW] = load_texture "assets/icons/arrowDown.png",
    [IconType.AURA] = load_texture "assets/sprites/icon-aura.png",
    [IconType.ENHANCE] = load_texture "assets/sprites/icon-enhance.png",
    [IconType.TOWER] = load_texture "assets/sprites/icon-tower.png",
    [IconType.ENERGY] = load_texture "assets/sprites/icon-energy.png",
    [IconType.CHANCE] = load_texture "assets/sprites/icon-chance.png",
    [IconType.DAMAGE] = load_texture "assets/sprites/icon-damage.png",
    [IconType.FIRE] = load_texture "assets/sprites/icon-fire.png",
    [IconType.GOLD] = load_texture "assets/sprites/icon-gold.png",
    [IconType.MULTI] = load_texture "assets/sprites/icon-multi.png",
    [IconType.POISON] = load_texture "assets/sprites/icon-poison.png",
    [IconType.RANGE] = load_texture "assets/sprites/icon-range.png",
    [IconType.ATTACKSPEED] = load_texture "assets/sprites/icon-speed.png",
    [IconType.SPEED] = load_texture "assets/sprites/icon-speed.png",
    [IconType.DURABILITY] = load_texture "assets/sprites/icon-pierce.png",
    [IconType.DECK] = load_texture "assets/sprites/deck-deck.png",
    [IconType.DECKDISCARD] = load_texture "assets/sprites/deck-discard.png",
    [IconType.DECKEXHAUST] = load_texture "assets/sprites/deck-exhaust.png",
  },
  ui = {
    hud = load_texture "assets/sprites/ui/hud.png",
    button = load_texture "assets/sprites/ui/button.png",
    button_bottom = load_texture "assets/sprites/ui/button-bottom.png",
    button_bottom_gold = load_texture "assets/sprites/ui/button-bottom-gold.png",
    chip = load_texture "assets/sprites/ui/chip.png",
    upgrade_button = {
      [Rarity.RARE] = load_texture "assets/sprites/ui/upgrade-button-rare.png",
      [Rarity.COMMON] = load_texture "assets/sprites/ui/upgrade-button-common.png",
      [Rarity.LEGENDARY] = load_texture "assets/sprites/ui/upgrade-button-legendary.png",
      [Rarity.UNCOMMON] = load_texture "assets/sprites/ui/upgrade-button-uncommon.png",
      [Rarity.EPIC] = load_texture "assets/sprites/ui/upgrade-button-epic.png",
    },
    chip_wide = load_texture "assets/sprites/ui/chip-wide.png",
    arrow_down = load_texture "assets/sprites/ui/arrow-down.png",
    arrow_up = load_texture "assets/sprites/ui/arrow-up.png",
    box_empty = load_texture "assets/sprites/ui/box-empty.png",
    box_filled = load_texture "assets/sprites/ui/box-filled.png",
    gilding = load_texture "assets/sprites/ui/gilding.png",
    gilding_dot = load_texture "assets/sprites/ui/gilding-dot.png",
    title_box_empty = load_texture "assets/sprites/ui/title-box-empty.png",
    title_box_filled = load_texture "assets/sprites/ui/title-box-filled.png",
    button_forward_default_small = load_texture "assets/sprites/ui/button-forward-default-small.png",
    button_forward_default = load_texture "assets/sprites/ui/button-forward-default.png",
    button_forward_hovered_small = load_texture "assets/sprites/ui/button-forward-hovered-small.png",
    button_forward_hovered = load_texture "assets/sprites/ui/button-forward-hovered.png",
    button_upgrade_default = load_texture "assets/sprites/ui/button-forward-default.png",
    button_upgrade_hovered = load_texture "assets/sprites/ui/button-upgrade-hovered.png",

    title_screen = load_texture "assets/sprites/ui/New Title Screen.png",

    speed_toggle_button = {
      play = load_texture "assets/sprites/ui/speed-toggle-play.png",
      pause = load_texture "assets/sprites/ui/speed-toggle-pause.png",
    },

    speed_button_bottom = load_texture "assets/sprites/ui/speed-button-bottom.png",
    speed_pause_button = {
      load_texture "assets/sprites/ui/speed-pause-1.png",
      load_texture "assets/sprites/ui/speed-pause-2.png",
      load_texture "assets/sprites/ui/speed-pause-3.png",
      load_texture "assets/sprites/ui/speed-pause-4.png",
    },

    speed_play_button = {
      load_texture "assets/sprites/ui/speed-play-1.png",
      load_texture "assets/sprites/ui/speed-play-2.png",
      load_texture "assets/sprites/ui/speed-play-3.png",
      load_texture "assets/sprites/ui/speed-play-4.png",
    },

    tower_upgrade_menu_start = load_texture "assets/sprites/ui/button-upgrade/button-upgrade-left.png",
    tower_upgrade_menu_middle = load_texture "assets/sprites/ui/button-upgrade/button-upgrade-middle.png",
    tower_upgrade_menu_end = load_texture "assets/sprites/ui/button-upgrade/button-upgrad-right.png",
  },
  sprites = {
    card = {
      frame = load_texture "assets/sprites/card/frame.png",
      title_banner = load_texture "assets/sprites/card/title-banner.png",
      energy_backing = load_texture "assets/sprites/card/energy-icon-backing.png",
      kind_banner = load_texture "assets/sprites/card/kind-banner.png",
      kind_backing = load_texture "assets/sprites/card/kind-icon-backing.png",
      aura_icon = load_texture "assets/sprites/card/card-icon-aura.png",
      enhancement_icon = load_texture "assets/sprites/card/card-icon-enhance.png",
      tower_icon = load_texture "assets/sprites/card/card-icon-tower.png",
    },
    elemental_backgrounds = {
      [ElementKind.PHYSICAL] = load_texture "assets/sprites/card-vibe-pasture.png",

      -- Elements
      [ElementKind.FIRE] = load_texture "assets/sprites/card/elemental-frame-fire.png",
      [ElementKind.WATER] = load_texture "assets/sprites/card/elemental-frame-water.png",
      [ElementKind.POISON] = load_texture "assets/sprites/card/elemental-frame-poison.png",
      [ElementKind.AIR] = load_texture "assets/sprites/card/elemental-frame-air.png",
      [ElementKind.EARTH] = load_texture "assets/sprites/card/elemental-frame-earth.png",
      [ElementKind.ZOMBIE] = load_texture "assets/sprites/card-vibe-zombie.png",

      -- [ElementKind.MONEY] = load_texture "assets/sprites/card/elemental-frame-money.png",
    },
    generated = {
      card_frames = {
        [Rarity.LEGENDARY] = load_texture "assets/generated/card_frame_legendary.png",
        [Rarity.EPIC] = load_texture "assets/generated/card_frame_epic.png",
        [Rarity.RARE] = load_texture "assets/generated/card_frame_rare.png",
        [Rarity.UNCOMMON] = load_texture "assets/generated/card_frame_uncommon.png",
        [Rarity.COMMON] = load_texture "assets/generated/card_frame_common.png",
      },
    },
    primary_btn = load_texture "assets/sprites/primary-btn.png",
    card_energy_org = load_texture "assets/sprites/card-energy-orb.png",
    temp_card_frame = load_texture "assets/sprites/temp_card_frame.png",

    -- Deck UI
    ui = load_texture "assets/sprites/ui-spritesheet.png",
    skull_card_r = load_texture "assets/sprites/cards_skull.png",
    deck_r = load_texture "assets/sprites/deck_icon_r.png",
    deck_l = load_texture "assets/sprites/deck_icon_l.png",

    -- Energy UI
    energy_light_filled = load_texture "assets/sprites/ui/energy-light-filled.png",
    energy_light_empty = load_texture "assets/sprites/ui/energy-light-empty.png",

    -- Orb Sword, very pog
    orb_sword = load_texture "assets/sprites/orb-sword.png",

    -- Orbs
    orb_basic = load_texture "assets/sprites/chaos-orb-basic.png",
    orb_fire = load_texture "assets/sprites/chaos-orb-fire.png",
    orb_ice = load_texture "assets/sprites/chaos-orb-ice.png",
    orb_radiant = load_texture "assets/sprites/chaos-orb-radiant.png",
    orb_violet = load_texture "assets/sprites/chaos-orb-violet.png",
    orb_damage = load_texture "assets/sprites/chaos-orb-damage.png",
    orb_attack_speed = load_texture "assets/sprites/chaos-orb-speed.png",

    -- Energy Orb
    energy_orb = load_texture "assets/sprites/energy-orb.png",

    orb_energy = load_texture "assets/sprites/chaos-orb-energy.png",
    orb_range = load_texture "assets/sprites/chaos-orb-range.png",
    -- Characters
    blacksmith_character_full = load_texture "assets/sprites/character-blacksmith-full.png",
    blacksmith_character_card = load_texture "assets/sprites/character-card-blacksmith.png",
    mage_character_card = load_texture "assets/sprites/character-card-mage.png",
    mage_character_full = load_texture "assets/sprites/character-mage-full.png",
    futurist_character_card = load_texture "assets/sprites/character-card-futurist.png",
    futurist_character_full = load_texture "assets/sprites/character-futurist-full.png",

    -- Maps
    world_map = load_texture "assets/sprites/world-map.png",

    -- Cave textures
    cave_grass_down = load_texture "assets/sprites/cave-grass-down.png",
    cave_grass_side = load_texture "assets/sprites/cave-grass-side.png",
    water_tower = load_texture "assets/sprites/tower-water-tower.png",
    rock = load_texture "assets/sprites/unplaceables/rock.png",

    -- Towers
    tower_archer = load_texture "assets/sprites/tower-archer.png",
    tower_archer_crossbow = load_texture "assets/sprites/tower-crossbow.png",
    tower_archer_longbow = load_texture "assets/sprites/tower-longbow.png",
    tower_tar = load_texture "assets/sprites/tower-tar.png",
    tower_poisoned_arrow = load_texture "assets/sprites/tower-poison.png",
    tower_captcha = load_texture "assets/sprites/tower-captcha.png",
    tower_emberwatch = load_texture "assets/sprites/tower-fire.png",
    tower_dj = load_texture "assets/sprites/tower-dj.png",
    tower_water = load_texture "assets/sprites/tower-water.png",

    tower_windmill = load_texture "assets/sprites/tower-windmill.png",
    tower_windmill_animated = SpriteAnimation.new {
      image = love.graphics.newImage "assets/sprites/tower-windmill-anim.png",
      frame_count = 4,
      framerate = 4,
    },

    tower_catapault = load_texture "assets/sprites/catapult.png",
    tower_catapault_loaded = load_texture "assets/sprites/catapult-loaded.png",
    tower_catapault_shoot = load_texture "assets/sprites/catapult-shoot.png",

    tower_trebuchet = load_texture "assets/sprites/trebuchet-loaded.png",
    tower_trebuchet_loaded = load_texture "assets/sprites/trebuchet-loaded.png",
    tower_trebuchet_shoot = load_texture "assets/sprites/trebuchet-shoot.png",

    tower_ballista_shoot = load_texture "assets/sprites/ballista-shoot.png",
    tower_ballista_loaded = load_texture "assets/sprites/ballista-loaded.png",

    -- New Card background
    card_pasture_background = load_texture "assets/sprites/card-pasture-background.png",
    -- Cards: Towers
    card_back = load_texture "assets/sprites/card-back.png",
    card_tower_archer = load_texture "assets/sprites/card-archer.png",
    card_tower_archer_crossbow = load_texture "assets/sprites/card-crossbow.png",
    card_tower_archer_longbow = load_texture "assets/sprites/card-longbow.png",
    card_tower_tar = load_texture "assets/sprites/card-tar.png",
    card_tower_catapault = load_texture "assets/sprites/catapult.png",
    card_tower_zombie_hands = load_texture "assets/sprites/card-vibe-zombie.png",

    -- Cards: Auras
    card_aura_crit = load_texture "assets/sprites/card-aura-crit.png",
    card_aura_bunnis_wrath = load_texture "assets/sprites/card-aura-bunnis-wrath.png",
    card_aura_range = load_texture "assets/sprites/card-aura-range.png",
    card_aura_damage = load_texture "assets/sprites/card-aura-damage.png",
    card_aura_speed = load_texture "assets/sprites/card-aura-speed.png",
    card_aura_danger_zone = load_texture "assets/sprites/card-aura-danger-zone.png",
    card_aura_overdrive = load_texture "assets/sprites/card-aura-overdrive.png",
    card_aura_overdrive_light = load_texture "assets/sprites/card-aura-overdrive-light.png",
    card_aura_live_fast_die_young = load_texture "assets/sprites/card/live-fast-die-young.png",
    card_aura_hot_feet = load_texture "assets/sprites/card/hot-feet.png",
    card_aura_health = load_texture "assets/sprites/card-aura-health.png",

    -- Cards: Vibes
    card_vibe_golden_harvest = load_texture "assets/sprites/card-vibe-golden-harvest.png",
    card_vibe_hoard = load_texture "assets/sprites/card/hoarding-dragon.png",
    card_vibe_pasture = load_texture "assets/sprites/card-vibe-pasture.png",
    card_vibe_lonely_tower = load_texture "assets/sprites/card-vibe-lonely-tower.png",
    card_vibe_go_fish = load_texture "assets/sprites/card-vibe-go-fish.png",
    card_vibe_git_stash = load_texture "assets/sprites/card-vibe-git-stash.png",
    card_vibe_shooting_the_breeze = load_texture "assets/sprites/card-vibe-shooting-the-breeze.png",
    card_vibe_leaky_stein = load_texture "assets/sprites/gear/gear-leaky-stein.png",

    -- Cards: Effects
    card_effect_target_enriched = load_texture "assets/sprites/card-vibe-target-enriched-enviroment.png",

    -- Cards: Frames
    card_frame_uncommon = load_texture "assets/sprites/card-frame-uncommon.png",
    card_frame_common = load_texture "assets/sprites/card-frame-common.png",
    card_frame_rare = load_texture "assets/sprites/card-frame-rare.png",
    card_frame_epic = load_texture "assets/sprites/card-frame-epic.png",

    -- Enhancements
    card_enhancement_dam = load_texture "assets/sprites/card-vibe-dam.png",
    card_enhancement_unlikely_meeting = load_texture "assets/sprites/card/unlikely-meeting.png",
    card_enhancement_burndown = load_texture "assets/sprites/card/burn-down.png",

    -- Cards: Deck
    card_deck_background = load_texture "assets/sprites/card-test-back.png",

    -- Cards: Base
    card_base_background = load_texture "assets/sprites/card-face.png",

    -- Packs
    pack_orb = load_texture "assets/sprites/booster-pack-orb.png",
    pack_tower = load_texture "assets/sprites/booster-pack-tower.png",
    pack_vibe = load_texture "assets/sprites/booster-pack-vibe.png",

    -- Frames
    level_frame_grass = load_texture "assets/sprites/level-frame-grass.png",
    level_frame_volcano = load_texture "assets/sprites/level-frame-volcano.png",

    -- Projectiles
    projectile_arrow = load_texture "assets/sprites/arrow.png",
    projectile_boulder = load_texture "assets/sprites/boulder.png",
    projectile_fire = load_texture "assets/sprites/arrow.png",
    projectile_fireball = load_texture "assets/sprites/arrow.png",

    -- Shop
    shop_background = load_texture "assets/sprites/shop-background.png",
    shop_forge = load_texture "assets/sprites/forge-anvil.png",

    -- Forge
    forge_anvil = load_texture "assets/sprites/forge-icon.png",
    forge_anvil_in_place = load_texture "assets/sprites/forge/forge_anvil-in-place.png",
    forge_furnace = load_texture "assets/sprites/forge/forge_furnace.png",
    forge_background = load_texture "assets/sprites/forge.png",

    -- Card Upgrade (Mage)
    upgrade_icon = load_texture "assets/sprites/upgrade-icon.png",

    -- Armory
    armory_background = load_texture "assets/sprites/armory-background.png",

    -- Enemy
    enemy_orc = load_texture "assets/sprites/orc-warrior.png",
    enemy_wyvern = load_texture "assets/sprites/wyvern.png",
    enemy_bat = load_texture "assets/sprites/bat-enemy-default.png",
    enemy_bat_red = load_texture "assets/sprites/bat-enemy-red.png",
    enemy_wolf = load_texture "assets/sprites/wolf.png",
    enemy_mine_goblin = load_texture "assets/sprites/balloon-Blue.png",
    enemy_orca = load_texture "assets/sprites/orca.png",
    enemy_snail = load_texture "assets/sprites/snail-enemy.png",
    enemy_orc_shaman = load_texture "assets/sprites/orc-shaman.png",
    enemy_king = load_texture "assets/sprites/king-walk.png",
    enemy_cat_tatus = load_texture "assets/sprites/cat-tatus-walk.png",
    enemy_tauntoise = load_texture "assets/sprites/tauntoise-idle.png",

    -- Bossses
    enemy_orc_chief = load_texture "assets/sprites/orc-chief-idle.png",
    enemy_orc_wheeler = load_texture "assets/sprites/orc-wheeler-Idle.png",

    -- Misc
    shadow = load_texture "assets/sprites/enemy-shadow.png",
    logo = load_texture "assets/logo.png",

    -- Mouse
    cursor_up = load_texture "assets/sprites/cursor-up.png",
    cursor_down = load_texture "assets/sprites/cursor-down.png",

    -- Shop
    coin_icon = load_texture "assets/sprites/coin-icon.png",
    dice_icon = load_texture "assets/sprites/dice-icon.png",

    -- Player
    player_hud = load_texture "assets/sprites/player-hud.png",
    player_hud_zero_energy = load_texture "assets/sprites/player-hud-zero-energy.png",
    player_health_bar_three_slice = load_texture "assets/sprites/player-health-bar.png",
    player_hud_portrait_default = load_texture "assets/sprites/player-hud-portrait-default.png",

    -- Button
    button_fill_nine_slice = load_texture "assets/sprites/button-sprite-fill.png",

    game_victory = load_texture "assets/goodjob.jpg",

    -- Gear
    gear_moustache_comb = load_texture "assets/sprites/gear-moustache-comb.png",
    gear_potato = load_texture "assets/sprites/gear-potato.png",
    gear_rubiks_cube = load_texture "assets/sprites/gear-rubiks-cube.png",
    gear_spinner_hat = load_texture "assets/sprites/gear-spinner-hat.png",
    gear_split_keyboard = load_texture "assets/sprites/gear-split-keyboard.png",
    gear_top_hat = load_texture "assets/sprites/gear-top-hat.png",
    gear_snakeskin_boots = load_texture "assets/sprites/gear/gear-snake-skin-boots.png",
    gear_heavy_boots = load_texture "assets/sprites/gear/gear-heavy-boots.png",
    gear_strong_tearaway_pants = load_texture "assets/sprites/gear/gear-strong-tearaway-pants.png",
    gear_tearaway_pants = load_texture "assets/sprites/gear/gear-tearaway-pants.png",
    gear_second_wind_pants = load_texture "assets/sprites/gear/gear-second-wind-pants.png",
    gear_baby = load_texture "assets/sprites/gear/gear-baby.png",
    gear_tax_write_off = load_texture "assets/sprites/gear/gear-tax-writeoff.png",
    gear_wine = load_texture "assets/sprites/gear/gear-wine.png",
    gear_chips = load_texture "assets/sprites/gear/gear-chips.png",
    gear_sunflower = load_texture "assets/sprites/gear/gear-sunflower.png",
    gear_water_pollution = load_texture "assets/sprites/gear/gear-water-pollution.png",

    -- Zombie Hands Tower
    grasping_hand_open = load_texture "assets/sprites/grasping-hand-open.png",
    grasping_hand_closed_wrist = load_texture "assets/sprites/grasping-hand-closed-wrist.png",
    grasping_hand_closed_fingers = load_texture "assets/sprites/grasping-hand-closed-fingers.png",
    card_zombie_hands = load_texture "assets/sprites/card-vibe-zombie.png",
    dirt_mound = load_texture "assets/sprites/dirt-mound.png",

    -- Gear Slots
    gear_slot_helmet = load_texture "assets/sprites/gear-slot/gear-slot-helmet.png",
    gear_slot_necklace = load_texture "assets/sprites/gear-slot/gear-slot-necklace.png",
    gear_slot_ring_left = load_texture "assets/sprites/gear-slot/gear-slot-ring-left.png",
    gear_slot_ring_right = load_texture "assets/sprites/gear-slot/gear-slot-ring-right.png",
    gear_slot_tool_left = load_texture "assets/sprites/gear-slot/gear-slot-tool-left.png",
    gear_slot_tool_right = load_texture "assets/sprites/gear-slot/gear-slot-tool-right.png",
    gear_slot_shirt = load_texture "assets/sprites/gear-slot/gear-slot-shirt.png",
    gear_slot_pants = load_texture "assets/sprites/gear-slot/gear-slot-pants.png",
    gear_slot_shoes = load_texture "assets/sprites/gear-slot/gear-slot-shoes.png",
    inventory_slot = load_texture "assets/sprites/gear-slot/inventory-slot.png",

    gear_energy_ring = load_texture "assets/sprites/gear/gear-energy-ring.png",
    gear_health_ring = load_texture "assets/sprites/gear/gear-health-ring.png",
    gear_defense_ring = load_texture "assets/sprites/gear/gear-defense-ring.png",
    gear_silk_shirt = load_texture "assets/sprites/gear/gear-silk-shirt.png",
    gear_chaos_crown = load_texture "assets/sprites/gear/gear-chaos-crown.png",
    gear_fire_hat = load_texture "assets/sprites/gear/gear-fire-hat.png",
    -- gear_attack_speed_ring = load_texture "assets/sprites/gear-slot/gear-slot-attack-speed-ring.png",
    -- Zombie
    grapsing_hand_open = load_texture "assets/sprites/grasping-hand-open.png",
    grapsing_hand_closed_fingers = load_texture "assets/sprites/grasping-hand-closed-fingers.png",
    grapsing_hand_closed_wrist = load_texture "assets/sprites/grasping-hand-closed-wrist.png",

    -- Readonly Three By Three Gear
    gear_display = load_texture "assets/sprites/ui/gear-display.png",

    lower_third = load_texture "assets/sprites/ui/lower-third.png",
  },

  frames = {
    [Rarity.COMMON] = load_texture "assets/sprites/card-frame-common.png",
    [Rarity.UNCOMMON] = load_texture "assets/sprites/card-frame-uncommon.png",
    [Rarity.RARE] = load_texture "assets/sprites/card-frame-rare.png",
    [Rarity.EPIC] = load_texture "assets/sprites/card-frame-epic.png",
  },
}
