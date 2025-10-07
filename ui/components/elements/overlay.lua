local Anim = require "vibes.anim"
local Text = require "ui.components.text"
local game = require "utils.user-interaction"

---@class (exact) ui.element.Overlay : Element
---@field new fun(opts: ui.element.Overlay.Options): ui.element.Overlay
---@field init fun(self: ui.element.Overlay, opts: ui.element.Overlay.Options)
---@field background? number[]
---@field on_close? fun()
---@field can_close boolean
---@field open fun(self: ui.element.Overlay,on_complete?:fun())
---@field close fun(self: ui.element.Overlay,on_complete?:fun())
local Overlay = class("ui.element.Overlay", { super = Element })

---@class (exact) ui.element.Overlay.Options
---@field background? number[]
---@field on_close? fun()
---@field can_close? boolean
---@field z? number
---@field hidden? boolean

---@param opts ui.element.Overlay.Options
function Overlay:init(opts)
  validate(opts, {
    background = "number[]?",
  })

  self.can_close = F.if_nil(opts.can_close, true)

  Element.init(self, Box.fullscreen(), {
    interactable = true,
    hidden = F.if_nil(opts.hidden, false),
  })

  if self.can_close then
    local cancel_action_label = Text.new {
      function()
        return {
          { icon = Asset.icons[IconType.ESCAPE_KEY], color = Colors.white },
          { text = "/", color = Colors.white },
          { icon = Asset.icons[IconType.RIGHT_CLICK], color = Colors.white },
          { text = "Close", color = Colors.white },
        }
      end,
      box = Box.new(
        Position.new(
          Config.window_size.width - 250,
          Config.window_size.height - 80
        ),
        300,
        50
      ),
      font = Asset.fonts.typography.paragraph_lg,
    }
    self:append_child(cancel_action_label)
  end

  self.on_close = opts.on_close or function() end
  self.background = opts.background or Colors.black:opacity(0.7)
  self._props.opacity = 0
  self:set_opacity(0)

  self:set_z(opts.z or Z.OVERLAY)
end

function Overlay:_focus() return UIAction.HANDLED end

function Overlay:_blur() return UIAction.HANDLED end

function Overlay:_click(evt)
  if self.can_close then
    self:close()
    self:on_close()
  end
  return UIAction.HANDLED
end

function Overlay:close(on_complete)
  self:animate_style({ opacity = 0 }, {
    duration = 0.3,
    on_complete = function()
      self:set_hidden(true)
      if on_complete then
        on_complete()
      end
    end,
  })
end

function Overlay:open(on_complete)
  self:set_opacity(0)
  self:set_hidden(false)

  self:animate_style({ opacity = 1 }, {
    duration = 0.3,
    on_complete = function()
      if on_complete then
        on_complete()
      end
    end,
  })
end

function Overlay:_update(dt)
  if
    game.is_action_canceled()
    and self.can_close
    and self:get_opacity() == 1
  then
    self:close()
    self:on_close()
  end
end

function Overlay:_render()
  local x, y, width, height = self:get_geo()

  self:with_color(
    self.background,
    function() love.graphics.rectangle("fill", x, y, width, height) end
  )
end

function Overlay:_keypressed(key) print "TRIGGER" end

return Overlay
