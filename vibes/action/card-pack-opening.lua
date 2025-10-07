local Action = require "vibes.action"
local Container = require "ui.components.container"

---@class actions.CardPackOpening.Opts : actions.BaseOpts
---@field pack vibes.CardPack

---@class actions.CardPackOpening : vibes.Action
---@field new fun(opts: actions.CardPackOpening.Opts): actions.CardPackOpening
---@field init fun(self: actions.CardPackOpening, opts: actions.CardPackOpening.Opts)
---@field pack vibes.CardPack
local CardPackOpening = class("actions.CardPackOpening", { super = Action })

---@param opts actions.CardPackOpening.Opts
---@return vibes.Action
function CardPackOpening:init(opts)
  validate(opts, { pack = "table" }) -- vibes.CardPack

  Action.init(self, {
    name = "CardPackOpening",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.pack = opts.pack
end

function CardPackOpening:start()
  local PackSelection = require "ui.components.pack.selection"

  self.ui = Container.new {
    box = Box.fullscreen(),
    background = { 0, 0, 0, 0.7 },
    z = Z.SHOP_PACK_OVERLAY,
  }

  UI.root:append_child(self.ui)

  local pack_selection = PackSelection.new {
    pack = self.pack,
    on_confirm = function(selected_card)
      logger.info("Selected card: %s", selected_card.name)
      -- TODO: Add card to player's deck
      State.deck:add_card(selected_card)
      self:resolve(ActionResult.COMPLETE)
    end,
    on_cancel = function()
      logger.info "Pack opening cancelled"
      self:resolve(ActionResult.CANCEL)
    end,
  }
  self.ui:append_child(pack_selection)

  logger.info("CardPackOpening:start - Opening pack: %s", self.pack.name)

  return ActionResult.ACTIVE
end

function CardPackOpening:update() return ActionResult.ACTIVE end

function CardPackOpening:finish()
  logger.info "CardPackOpening:finish"

  if not self.ui then
    logger.warn "CardPackOpening:finish: no ui?"
    return
  end

  UI.root:remove_child(self.ui)
  self.ui = nil
end

return CardPackOpening
