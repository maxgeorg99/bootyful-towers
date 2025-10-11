---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ModeName
local ModeName = {
  MAIN_MENU = "vibes.modes.main-menu",
  CHARACTER_SELECTION = "vibes.modes.character-selection",
  MAP = "vibes.modes.map",
  GAME = "vibes.modes.game",
  SHOP = "vibes.modes.shop",
  BEAT_GAME = "vibes.modes.beat-game",
  GAME_OVER = "vibes.modes.game-over",
  GEAR_MENU = "vibes.modes.gear-menu",
  CARD_COLLECTION = "vibes.modes.card-collection",
  TEST_GEAR_SELECT = "vibes.modes.test-gear-select",

  -- Test Screens, could be deleted later perhaps
  TEST_INVENTORY = "vibes.modes.test-inventory",
  TEST_UPGRADE_UI = "vibes.modes.test-upgrade-ui",
  TEST_CARD = "vibes.modes.test-card",
  TEST_UI = "vibes.modes.test-ui",
  TEST_TILESET = "vibes.modes.test-tileset",
  TEST_TOWER_DETAILS = "vibes.modes.test-tower-details",
  TEST_FORGE = "vibes.modes.test-forge",
  TEST_ED = "vibes.modes.test-ed",
  TEST_CANVAS = "vibes.modes.test-canvas",
  TEST_TEEJ_ANIMATION = "vibes.modes.test-teej-animation",
  TEST_ENEMY_VIEWER = "vibes.modes.test-enemy-viewer",

  -- TODO:
  -- TEXTURE_EDITOR = "texture-editor",
  -- EDITOR = "vibes.modes.editor",
}

---@diagnostic disable-next-line: duplicate-doc-alias
---@enum ModeName
return require("vibes.enum").new(
  "ModeName",
  ModeName,
  { skip_value_check = true }
)
