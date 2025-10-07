local Action = require "vibes.action"
local Overlay = require "ui.components.elements.overlay"

---@class actions.GearPackOpening.Opts : actions.BaseOpts
---@field pack vibes.GearPack

---@class actions.GearPackOpening : vibes.Action
---@field new fun(opts: actions.GearPackOpening.Opts): actions.GearPackOpening
---@field init fun(self: actions.GearPackOpening, opts: actions.GearPackOpening.Opts)
---@field pack vibes.GearPack
local GearPackOpening = class("actions.GearPackOpening", { super = Action })

---@param opts actions.GearPackOpening.Opts
---@return vibes.Action
function GearPackOpening:init(opts)
  validate(opts, { pack = "table" }) -- vibes.GearPack

  Action.init(self, {
    name = "GearPackOpening",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.pack = opts.pack
end

function GearPackOpening:start()
  -- TODO: Create a specialized gear selection UI component
  -- For now, create a placeholder that shows gear items differently than cards
  local GearSelection = require "ui.components.pack.gear-selection"

  logger.info(
    "GearPackOpening:start - Opening gear pack with %d items",
    #self.pack.gear
  )

  self.ui = GearSelection.new {
    pack = self.pack,
    on_confirm = function(selected_gear)
      -- This callback is no longer used since we use drag-and-drop
      -- But keeping for potential future use
      logger.info("Selected gear: %s", selected_gear.name)
      self:resolve(ActionResult.COMPLETE)
    end,
    on_cancel = function()
      logger.info "Gear pack opening cancelled"
      self:resolve(ActionResult.CANCEL)
    end,
    on_gear_added = function(gear)
      -- New callback for when gear is successfully added via drag-and-drop
      logger.info("Gear successfully added to inventory: %s", gear.name)
      self:resolve(ActionResult.COMPLETE)
    end,
  }
  UI.root:append_child(self.ui)

  return ActionResult.ACTIVE
end

function GearPackOpening:update() return ActionResult.ACTIVE end

function GearPackOpening:finish()
  logger.info "GearPackOpening:finish"

  if not self.ui then
    logger.warn "GearPackOpening:finish: no ui?"
    return
  end

  UI.root:remove_child(self.ui)
  self.ui = nil
end

return GearPackOpening
