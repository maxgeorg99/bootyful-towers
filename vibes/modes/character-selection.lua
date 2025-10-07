require "ui.components.ui"

---@class vibes.CharacterSelection : vibes.BaseMode
local CharacterSelection = {
  name = "CharacterSelection",
}

---@param key string
function CharacterSelection:keypressed(key)
  if key == "left" or key == "right" then
    local delta = key == "right" and 1 or -1
    if self.ui and self.ui.action_buttons then
      UI:cycle_focus(self.ui.action_buttons, delta)
      return true
    end
  elseif key == "return" or key == "kpenter" then
    if UI.state.selected then
      UI:activate_element(UI.state.selected)
      return true
    end
  end
end
function CharacterSelection:enter()
  logger.debug "CharacterSelection:enter() called"
  local CharacterSelectionView =
    require "ui.components.character.selection.view"

  logger.debug "Creating CharacterSelectionView"
  self.ui = CharacterSelectionView.new {}
  logger.debug "CharacterSelectionView created, appending to UI.root"
  UI.root:append_child(self.ui)
  logger.debug "CharacterSelectionView appended to UI.root"
end

function CharacterSelection:exit() UI.root:remove_child(self.ui) end
function CharacterSelection:draw() end
function CharacterSelection:update(_) end
function CharacterSelection:mousemoved() end

return require("vibes.base-mode").wrap(CharacterSelection)
