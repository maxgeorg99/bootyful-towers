local Text = require "ui.components.text"

---@class (exact) components.CurrentWaveIndicator.Opts

---@class components.CurrentWaveIndicator : Element
---@field new fun(opts: components.CurrentWaveIndicator.Opts): components.CurrentWaveIndicator
---@field init fun(self: components.CurrentWaveIndicator, opts: components.CurrentWaveIndicator.Opts)
local CurrentWaveIndicator =
  class("components.CurrentWaveIndicator", { super = Element })

---@param opts components.CurrentWaveIndicator.Opts
function CurrentWaveIndicator:init(opts)
  validate(opts, {})

  Element.init(self, Box.fullscreen(), {
    name = "CurrentWaveIndicator",
    z = Z.TOOLTIP,
    interactable = false,
  })

  self.name = "CurrentWaveIndicator"
  self.current_wave_text = Text.new {
    function()
      return {
        text = tostring(State.levels.current_wave),
        color = Colors.white:opacity(self:get_opacity()),
      }
    end,
    box = Box.new(Position.new(1405, 935), 50, 100),
    font = Asset.fonts.typography.h4,
    text_align = "left",
    vertical_align = "top",
  }
  self:append_child(self.current_wave_text)

  self.max_wave_text = Text.new {
    function()
      return {
        text = tostring(#State.levels:get_current_level().waves),
        color = Colors.white:opacity(self:get_opacity()),
      }
    end,
    box = Box.new(Position.new(1445, 935), 50, 100),
    font = Asset.fonts.typography.h4,
    text_align = "left",
    vertical_align = "top",
  }
  self:append_child(self.max_wave_text)
end

function CurrentWaveIndicator:_render() end

return CurrentWaveIndicator
