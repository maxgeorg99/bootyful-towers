-- STATUS: I'm not sure this will work or not, it was just an idea that I'm trying out.

---@class components.ScaledContainer : Element
--- Class that scales its children to fit inside of the box. Useful for things like a card where we always want the card to be the
--- same size in it's internal render, but then this will handle auto-scaling the card down to fit inside of the box.
---
---@field new fun(opts: components.ScaledContainer.Opts): components.ScaledContainer
---@field init fun(self: components.ScaledContainer, opts: components.ScaledContainer.Opts)
local ScaledContainer =
  class("ui.components.ScaledContainer", { super = Element })

---@class components.ScaledContainer.Opts
---@field box ui.components.Box
---@field component Element

---@param opts components.ScaledContainer.Opts
function ScaledContainer:init(opts)
  Element.init(self, opts.box)

  local _, _, cw, ch = opts.component:get_geo()
  local component = opts.component
  self:append_child(component)

  -- TODO: Could make this so it stretches a bit more, but I think this is the nicer option
  -- for now and will prevent some annoyances with how things might look.
  local scale = math.min(opts.box.width / cw, opts.box.height / ch)
  self:set_scale(scale)
end

function ScaledContainer:_render() end

return ScaledContainer
