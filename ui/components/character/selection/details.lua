local PileElement = require "ui.components.pile"

local Image = require "ui.components.img"
local Text = require "ui.components.text"

---@class components.CharacterSelectionDetails.Opts
---@field character vibes.Character
---@field color number[]

---@class components.CharacterSelectionDetails: Element
---@field new fun(opts: components.CharacterSelectionDetails.Opts)
---@field init fun(self:components.CharacterSelectionDetails, opts: components.CharacterSelectionDetails.Opts)
---@field character vibes.Character
---@field background ui.components.Img
---@field _mouse_coords {x:number, y:number}
local CharacterSelectionDetails =
  class("components.CharacterSelectionDetails", { super = Element })

function CharacterSelectionDetails:init(opts)
  validate(opts, {
    character = "vibes.Character",
    color = "number[]",
  })

  local box = Box.fullscreen()
  Element.init(self, box)

  self.name =
    string.format("CharacterSelectionDetails(%s)", opts.character.name)
  self.character = opts.character
  self.color = opts.color
  self._shader = Asset.shaders.rewind
  self._shader_time = 0
  self._mouse_coords = { x = 0, y = 0 }

  local screen_w = Config.window_size.width
  local screen_h = Config.window_size.height
  local half_screen_w = (screen_w / 2) * 0.99

  -- local seed_btn = PileElement.new {
  --   name = self.character.name .. "'s Deck",
  --   cards = State.deck,
  --   box = Box.new(Position.zero(), screen_w * 0.10, 70),
  --   icon = Asset.sprites.deck_l,
  -- }
  -- -- UI.root:append_child(pile)
  -- -- pile:toggle_overlay()

  local starter_labels = Text.new {
    "{gold:gold}  {energy:energy}",
    env = {
      gold = " " .. self.character.starter.gold,
      energy = " " .. self.character.starter.energy,
    },
    font = Asset.fonts.typography.h2,
    vertical_align = "center",
    color = Colors.white:get(),
    text_align = "left",
    box = Box.new(Position.zero(), half_screen_w / 2, 70),
  }

  local _, _, starter_labels_w, _ = starter_labels:get_geo()
  local starter_info_spacer = Layout.rectangle {
    name = "spacer",
    w = half_screen_w - (starter_labels_w + 20),
    h = 70,
  }

  local starter_info = Layout.row {
    name = "starter_info",
    box = Box.new(Position.zero(), half_screen_w, 70),
    flex = { gap = 10, justify_content = "end" },
    els = {
      starter_labels,
      starter_info_spacer,
      -- Layout.rectangle { w = 50, h = 70 },
    },
    animation_duration = 0,
  }

  local name = Text.new {
    self.character.name,
    font = Asset.fonts.typography.h1,
    vertical_align = "center",
    color = Colors.white:get(),
    text_align = "left",
    box = Box.new(Position.zero(), half_screen_w, 100),
  }

  local description = Text.new {
    self.character.description,
    font = Asset.fonts.typography.paragraph_md,
    vertical_align = "top",
    color = Colors.white:get(),
    text_align = "left",
    box = Box.new(Position.zero(), half_screen_w, 100),
  }

  local layout = Layout.row {
    box = Box.new(Position.zero(), screen_w, screen_h),
    els = {
      Layout.rectangle {
        w = (screen_w / 2) * 0.975,
        h = screen_h,
      },
      Layout.col {
        box = Box.new(Position.zero(), half_screen_w, screen_h),
        flex = { justify_content = "start", align_items = "start" },
        els = {
          Layout.rectangle { w = half_screen_w, h = 50 },
          name,
          Layout.rectangle { w = half_screen_w, h = 10 },
          description,
          Layout.rectangle { w = half_screen_w, h = 40 },
          starter_info,
        },
        animation_duration = 0,
      },
    },
    flex = { justify_content = "start" },
    animation_duration = 0,
  }

  local bg_asset = self.character.avatar.background
  local bg_h = bg_asset:getHeight()
  self.background = Image.new(bg_asset, 40, 40, { 1, (bg_h / 2) })
  self.background:set_opacity(0.3)
  self.background:set_interactable(false)

  local ch_asset = self.character.avatar.full
  local ch_w_percent = (screen_w / 2) / ch_asset:getWidth()
  local character = Image.new(ch_asset, ch_w_percent)

  character:set_interactable(false)

  self:append_child(layout)
  self:append_child(self.background)
  self:append_child(character)
end

function CharacterSelectionDetails:_update(_)
  local x, y = self:get_geo()
  local mx, my = love.mouse.getPosition()
  self.background:set_pos(Position.new(x - (mx * 0.1), y - (my * 0.1)))
end

function CharacterSelectionDetails:_render()
  love.graphics.push()
  local x, y, w, h = self:get_geo()

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.pop()
end

return CharacterSelectionDetails
