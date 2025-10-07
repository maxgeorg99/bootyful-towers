local CARD_HEIGHT = Config.ui.card.new_height * 0.35

local Action = require "vibes.action"
local CardKindList = require "ui.components.card-kind-list"
local Overlay = require "ui.components.elements.overlay"
local ScaledImage = require "ui.components.scaled-img"
local TitleBox = require "ui.elements.title-box"

---@class (exact) actions.ViewPile.Opts : actions.BaseOpts
---@field name string
---@field cards vibes.Card[]
---@field on_card_select? fun(vibes.Card)

---@class actions.ViewPile : vibes.Action
---@field new fun(opts: actions.ViewPile.Opts): actions.ViewPile
---@field init fun(self: actions.ViewPile, opts: actions.ViewPile.Opts)
---@field title_box elements.TitleBox
---@field overlay ui.element.Overlay
---@field _cards_reference vibes.Card[]
---@field _on_card_select? fun(card:vibes.Card)
local ViewPile = class("actions.ViewPile", { super = Action })

---@param opts actions.ViewPile.Opts
function ViewPile:init(opts)
  Action.init(self, {
    name = "ViewPile",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self._cards_reference = opts.cards
  self._on_card_select = opts.on_card_select

  self.overlay = Overlay.new {
    z = Z.OVERLAY,
    on_close = function() self:resolve(ActionResult.COMPLETE) end,
    background = Colors.black:opacity(0.7),
  }

  self.title_box = TitleBox.new {
    box = Box.new(
      Position.new(
        Config.window_size.width / 2 - 650,
        Config.window_size.height / 2 - 450
      ),
      1300,
      700
    ),
    title = opts.name,
    kind = "empty",
    flex = {
      align_items = "space-evenly",
      justify_content = "space-evenly",
      direction = "row",
      gap = 0,
    },
    els = {},
    z = Z.OVERLAY + 1,
  }

  self.title_box._props.opacity = 0
  self.title_box.animator.param_configs["opacity"].rate = 9
  UI.root:append_child(self.overlay)
  UI.root:append_child(self.title_box)

  self:setup_card_containers()
end

function ViewPile:start()
  self.overlay:open(function() self.title_box.targets.opacity = 1 end)

  return ActionResult.ACTIVE
end

function ViewPile:update() return ActionResult.ACTIVE end

function ViewPile:finish()
  self.title_box:animate_style({ opacity = 0 }, {
    duration = 0.2,
    on_complete = function()
      UI.root:remove_child(self.overlay)
      UI.root:remove_child(self.title_box)
    end,
  })
  self.overlay:close(function() end)
  return ActionResult.COMPLETE
end

function ViewPile:setup_card_containers()
  local content_width = 1200 -- Account for stats panel
  local content_height = 570

  -- Create main container for all card lists
  local container_box =
    Box.new(Position.new(0, 0), content_width, content_height)

  self.card_container = Layout.new {
    name = "PileCardContainer",
    box = container_box,
    flex = {
      direction = "column",
      justify_content = "start",
      align_items = "start",
      gap = 40,
    },
  }

  local card_kinds = { CardKind.TOWER, CardKind.ENHANCEMENT, CardKind.AURA }
  local card_lists = {}
  local kinds_icons = {
    [CardKind.TOWER] = Asset.icons[IconType.TOWER],
    [CardKind.AURA] = Asset.icons[IconType.AURA],
    [CardKind.ENHANCEMENT] = Asset.icons[IconType.ENHANCE],
  }

  for _, kind in ipairs(card_kinds) do
    local kind_box =
      Box.new(Position.new(0, 0), content_width - 80, CARD_HEIGHT)

    local card_list = CardKindList.new {
      cards = self._cards_reference,
      kind = kind,
      box = kind_box,
      on_card_select = function(card)
        if self._on_card_select then
          self._on_card_select(card)
          self:resolve(ActionResult.COMPLETE)
        end
      end,
    }

    local kind_list_layout = Layout.row {
      box = Box.new(Position.new(0, 0), content_width, CARD_HEIGHT),
      els = {
        ScaledImage.new {
          box = Box.new(Position.zero(), 50, CARD_HEIGHT),
          texture = kinds_icons[kind],
          scale_style = "fit",
        },
        card_list,
      },
    }

    table.insert(card_lists, kind_list_layout)

    if kind == CardKind.TOWER then
      self.tower_list = card_list
    elseif kind == CardKind.ENHANCEMENT then
      self.enhancement_list = card_list
    elseif kind == CardKind.AURA then
      self.aura_list = card_list
    end
  end

  for _, card_list in ipairs(card_lists) do
    self.card_container:append_child(card_list)
  end

  self.title_box:append_child(self.card_container)
end

return ViewPile
