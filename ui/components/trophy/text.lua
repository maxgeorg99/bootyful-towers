local Text = require "ui.components.text"

---@class components.trophy.Text.Opts
---@field text string
---@field placement? "start" | "center"

---@class (exact) components.trophy.Text : Element
---@field new fun(opts: components.trophy.Text.Opts): components.trophy.Text
---@field init fun(self: components.trophy.Text, opts: components.trophy.Text.Opts)
---@field layout Element
local TrophyText = class("components.trophy.Text", { super = Element })

---@param opts components.trophy.Text.Opts
function TrophyText:init(opts)
  validate(opts, {
    text = "string",
    placement = Optional { "string" },
  })

  local text_content = opts.text
  Element.init(self, Box.fullscreen(), {
    z = Z.TROPHY_SELECTION_TEXT,
    interactable = false,
  })

  -- Create a container to hold the text with specific layout
  local layout = Layout.col {
    name = "TrophyTextLayout",
    box = Box.fullscreen(),
    animation_duration = 0,
    created_offset = Position.new(0, Config.window_size.height),
    flex = {
      align_items = "center",
      justify_content = opts.placement or "start",
    },
    els = {
      Layout.rectangle {
        w = 100,
        h = 100,
      },
      Text.new {
        text_content,
        box = Box.new(Position.zero(), Config.window_size.width, 80),
        font = Asset.fonts.typography.h1,
      },
    },
  }

  self:append_child(layout)
  self.layout = layout
  layout:set_opacity(0)
end

function TrophyText:_update() self.layout:set_opacity(self._props.created) end

function TrophyText:_render() end

return TrophyText
