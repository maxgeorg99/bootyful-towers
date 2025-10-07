local Action = require "vibes.action"

---@class actions.OpenForge.Opts : actions.BaseOpts

---@class actions.OpenForge : vibes.Action
local OpenForge = class("actions.OpenForge", { super = Action })

---@param opts actions.OpenForge.Opts
function OpenForge:init(opts)
  opts = opts or {}
  Action.init(self, {
    name = "OpenForge",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })
end

function OpenForge:start()
  -- Create forge UI (it will add itself to UI.root)
  ---@type components.ForgeUI
  self.forge_ui = require("ui.components.forge").new {
    return_to_shop = function() self:resolve(ActionResult.COMPLETE) end,
  }
  UI.root:append_child(self.forge_ui)

  return ActionResult.ACTIVE
end

function OpenForge:update()
  -- Handle escape key to close forge
  if love.keyboard.isDown "escape" then
    self:resolve(ActionResult.CANCEL)
    return ActionResult.COMPLETE
  end

  return ActionResult.ACTIVE
end

function OpenForge:finish() UI.root:remove_child(self.forge_ui) end

return OpenForge
