local BoxUI = require "ui.elements.box"
local Img = require "ui.components.img"
local NumberToString = require "ui.components.number_to_string"
local Text = require "ui.components.text"

local width = Config.window_size.width / 3
local height = math.floor(Config.window_size.height * 0.9)
local stat_width = math.floor(width * 0.9)
local stat_icon = math.floor(stat_width * 0.1)
local stat_label = math.floor(stat_width * 0.65)
local stat_value = math.floor(stat_width * 0.25)
local label_height = Config.grid.cell_size

---@class ui.components.TotalStatsElement.Stat
---@field label string
---@field value number
---@field icon IconType

---@class ui.components.StatLineElement.Opts : Element.Opts
---@field stat ui.components.TotalStatsElement.Stat

---@class ui.components.StatLineElement : Element
---@field new fun(opts?: ui.components.StatLineElement.Opts): ui.components.StatLineElement
---@field init fun(self: ui.components.StatLineElement, opts?: ui.components.StatLineElement.Opts)
---@field layout layout.Layout
---@field icon IconType
---@field value string
---@field label string
local StatLineElement = class("ui.components.StatLineElement", {
  super = Element,
})

function StatLineElement:init(opts)
  Element.init(
    self,
    Box.new(Position.new(0, 0), stat_width, label_height),
    opts
  )
  self.label = opts.stat.label
  self.value = NumberToString.number_to_string(opts.stat.value)
  self.icon = opts.stat.icon
  self:_layout()
end

function StatLineElement:_layout()
  local asset = Asset.icons[self.icon]
  local s = label_height / asset:getHeight()
  self.layout = Layout.row {
    box = Box.new(Position.new(0, 0), stat_width + 100, label_height),
    flex = {
      align_items = "start",
      justify_content = "start",
      gap = 0,
    },
    els = {
      Layout.row {
        box = Box.new(Position.new(0, 0), stat_icon, label_height),
        flex = {
          align_items = "end",
          justify_content = "end",
          gap = 0,
        },
        els = {
          Img.new(asset, s, s),
        },
      },
      Text.new {
        self.label,
        box = Box.new(Position.new(0, 0), stat_label, label_height),
        font = Asset.fonts.typography.paragraph_lg,
      },
      Text.new {
        self.value,
        box = Box.new(Position.new(0, 0), stat_value, label_height),
        font = Asset.fonts.typography.paragraph_lg,
      },
    },
  }
  self:append_child(self.layout)
end

function StatLineElement:_render() end

---@class ui.components.TotalStatsElement.Opts : Element.Opts
---@field stats ui.components.TotalStatsElement.Stat[]
---@field on_main_menu fun(): nil
---@field on_new_game fun(): nil
---
---@class ui.components.TotalStatsElement : Element
---@field new fun(opts?: ui.components.TotalStatsElement.Opts): ui.components.TotalStatsElement
---@field init fun(self: ui.components.TotalStatsElement, opts?: ui.components.TotalStatsElement.Opts)
---@field layout layout.Layout
---@field stats ui.components.TotalStatsElement.Stat[]
local TotalStatsElement = class("ui.components.TotalStatsElement", {
  super = Element,
})

---@class ui.components.TotalStatsElement.Opts : Element.Opts
---@field on_main_menu fun(): nil
---@field on_new_game fun(): nil

--- Creates a new TotalStatsElement that is centered and sized to 1/3 width, 2/3 height
---@param opts ui.components.TotalStatsElement.Opts
function TotalStatsElement:init(opts)
  validate(opts, {
    stats = "table",
    on_main_menu = "function",
    on_new_game = "function",
  })

  Element.init(self, Box.fullscreen(), opts)

  self.name = "TotalStatsElement"
  self.stats = opts.stats
  self.on_main_menu = opts.on_main_menu
  self.on_new_game = opts.on_new_game
  self:_layout()
end

function TotalStatsElement:_layout()
  local stats = {}
  for _, stat in ipairs(self.stats) do
    table.insert(
      stats,
      StatLineElement.new {
        stat = stat,
      }
    )
  end

  local buttons = Layout.row {
    box = Box.new(Position.new(0, 0), stat_width, label_height),
    flex = {
      align_items = "center",
      justify_content = "center",
      gap = 10,
    },
    els = {
      Button.new {
        box = Box.new(Position.new(0, 0), stat_value, label_height),
        label = "Main Menu",
        on_click = self.on_main_menu,
      },
      Button.new {
        box = Box.new(Position.new(0, 0), stat_value, label_height),
        label = "New Game",
        on_click = self.on_new_game,
      },
    },
  }

  table.insert(stats, buttons)

  local results_layout = Layout.col {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    flex = {
      align_items = "center",
      justify_content = "start",
      gap = 10,
    },
    els = {
      Layout.rectangle {
        h = 100,
        w = 100,
      },
      Text.new {
        "You " .. State.game_results.status .. "!",
        box = Box.new(Position.new(0, 0), stat_label, label_height),
        font = Asset.fonts.typography.paragraph_lg,
      },
    },
  }

  self.layout = Layout.col {
    box = Box.new(Position.new(0, 0), width, height),
    flex = {
      align_items = "center",
      justify_content = "center",
      gap = 10,
    },
    els = stats,
  }

  local box = BoxUI.new {
    name = "TotalStatsElement",
    kind = "empty",
    box = Box.new(Position.new(0, 0), width, height),
    els = {
      self.layout,
    },
  }

  local layout_container = Layout.col {
    box = Box.new(
      Position.new(0, 0),
      Config.window_size.width,
      Config.window_size.height
    ),
    flex = {
      align_items = "center",
      justify_content = "center",
    },
    els = {
      box,
    },
  }

  self:append_child(layout_container)
  self:append_child(results_layout)
end

function TotalStatsElement:_render() end

return TotalStatsElement
