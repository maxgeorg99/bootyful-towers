local ScaledImage = require "ui.components.scaled-img"
local Text = require "ui.components.text"
local TowerStatsTable = require "ui.components.tower.overview.stats-table"

local DEFAULT_W = 560
local DEFAULT_H = 380

---@class (exact) components.TowerOverview.Opts
---@field box? ui.components.Box
---@field card vibes.TowerCard
---@field upgrade? tower.StatOperation

---@class (exact) components.TowerOverview : Element
---@field new fun(opts: components.TowerOverview.Opts): components.TowerOverview
---@field card vibes.TowerCard
---@field upgrade? tower.UpgradeOption
---@field reset fun(self:components.TowerOverview)
---@field _layout layout.Layout
---@field _stats_table components.TowerStatsTable
local TowerOverview = class("components.TowerOverview", { super = Element })

function TowerOverview:init(opts)
  validate(opts, {
    card = "vibes.TowerCard",
    upgrade = "tower.StatOperation?",
    box = "ui.components.Box?",
  })

  self.card = opts.card
  self.upgrade = opts.upgrade

  local box = opts.box
    or Box.new(
      Position((Config.window_size.width / 2) - (DEFAULT_W / 2), -10),
      DEFAULT_W,
      140 -- DEFAULT_H
    )

  Element.init(self, box, { z = Z.TOWER_OVERVIEW })

  self:_setup_layout()
end

function TowerOverview:_render() end

function TowerOverview:reset()
  self._stats_table:reset()
  self.upgrade = nil
end

function TowerOverview:_setup_layout()
  local _, _, width, height = self:get_geo()

  self._stats_table = TowerStatsTable.new {
    box = Box.new(Position.zero(), width / 1.5, 0),
    tower = self.card.tower,
    upgrade = self.upgrade,
  }
  -- print()
  local card_desc_w = (width * 0.80) - 30

  local card_desc_layout = Layout.col {
    box = Box.new(Position.zero(), card_desc_w, 100),
    els = {
      Layout.rectangle {
        w = card_desc_w,
        h = 20,
      },
      Text.new {
        self.card.name,
        box = Box.new(Position.zero(), card_desc_w, 30),
        font = Asset.fonts.typography.h3,
        color = Colors.white,
        text_align = "left",
      },
      Layout.rectangle {
        w = card_desc_w,
        h = 1,
        background = Colors.white,
      },
      Text.new {
        self.card.description,
        box = Box.new(Position.zero(), card_desc_w, 30),
        font = Asset.fonts.typography.paragraph,
        color = Colors.white,
        text_align = "left",
      },
    },
  }

  local level_dim = width * 0.15
  local level_layout = Layout.row {
    box = Box.new(Position.zero(), level_dim, level_dim),
    background = Colors.red,
    rounded = 5,
    els = {
      Text.new {
        "LV",
        box = Box.new(Position.zero(), level_dim / 2, level_dim / 2),
        font = Asset.fonts.typography.sub,
        color = Colors.white,
        text_align = "right",
        padding = 0,
        scale = 0.9,
      },
      Text.new {
        function()
          return {
            { text = self.card.tower.level },
          }
        end,
        box = Box.new(Position.zero(), level_dim / 2, level_dim / 2),
        font = Asset.fonts.typography.h3,
        color = Colors.white,
        text_align = "left",
        padding = 0,
      },
    },
  }

  local header_layout = Layout.new {
    name = "TowerOverview(HeaderLayout)",
    box = Box.new(Position.zero(), width, 100),
    els = {
      Layout.rectangle {
        w = 35,
        h = 100,
      },
      card_desc_layout,
      Layout.col {
        box = Box.new(Position.zero(), level_dim, level_dim),
        els = {
          Layout.rectangle {
            w = 10,
            h = 60,
          },
          level_layout,
        },
      },
    },
    flex = {
      justify_content = "start",
      align_items = "start",
      direction = "row",
      gap = 0,
    },
  }

  height = self._stats_table:get_height() + 40

  local content_layout = Layout.row {
    box = Box.new(Position.zero(), width, height),
    els = {
      Layout.rectangle {
        w = 5,
        h = 10,
      },
      ScaledImage.new {
        box = Box.new(Position.zero(), (width / 4) - 10, height - 65),
        texture = self.card.tower.texture,
        scale_style = "fill",
      },
      Layout.rectangle {
        w = 0,
        h = 10,
      },
      self._stats_table,
      Layout.rectangle {
        w = 7,
        h = 10,
      },
    },
  }

  -- print(content_layout:get_height())

  self._layout = Layout.new {
    name = "TowerOverview(Layout)",
    box = Box.new(
      Position.zero(),
      width,
      height + card_desc_layout:get_height() - 10
    ),
    background = Colors.gray,
    rounded = 10,
    els = {
      Layout.rectangle {
        w = width,
        h = 10,
      },
      header_layout,
      content_layout,
    },
    flex = {
      align_items = "start",
      justify_content = "start",
      direction = "column",
      gap = 0,
    },
  }

  -- self._layout:set_debug(true)
  self:append_child(self._layout)

  self:set_height(self._layout:get_height())
end

return TowerOverview
