local DiscardButton =
  class("ui.components.game.DiscardButton", { super = Button })

function DiscardButton:init(opts)
  opts.draw = "Discard"

  Button.init(self, opts)

  self.name = "DiscardButton"
  self.is_active = opts.is_active
end

function DiscardButton:_update(dt)
  Button._update(self, dt)

  local lifecycle = GAME.lifecycle

  if lifecycle ~= RoundLifecycle.PLAYER_TURN then
    self:set_hidden(true)
    return
  end

  self:set_hidden(false)
  self:set_interactable(self.is_active())
end

return DiscardButton
