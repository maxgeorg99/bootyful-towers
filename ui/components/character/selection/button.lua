---@class components.CharacterSelectionButton.Opts
---@field avatar vibes.Character.Avatar
---@field callback fun()
---@field selected? boolean

---@class components.CharacterSelectionButton: Element
---@field new fun(opts: components.CharacterSelectionButton.Opts)
---@field init fun(self:components.CharacterSelectionButton, opts: components.CharacterSelectionButton.Opts)
---@field set_selected fun(self:components.CharacterSelectionButton, bool:boolean)
---@field avatar vibes.Character.Avatar
---@field selected boolean
---@field focus_opacity number
---@field canvas love.Canvas
---@field callback fun()
local CharacterSelectionButton =
  class("components.CharacterSelectionButton", { super = Element })

function CharacterSelectionButton:init(opts)
  local size = (((Config.window_size.width / 2) / 3) - 30)
  local box = Box.new(Position.zero(), size, size)

  Element.init(self, box, { interactable = true })
  self.selected = F.if_nil(opts.selected, false)
  self.avatar = opts.avatar
  self.callback = opts.callback
  self.focus_opacity = 0.0
end

function CharacterSelectionButton:set_selected(bool) self.selected = false end

function CharacterSelectionButton:_click()
  self.selected = true
  self.callback()
end
function CharacterSelectionButton:_focus() end
function CharacterSelectionButton:_blur() end
function CharacterSelectionButton:_mouse_enter()
  Animation:animate_property(self, { focus_opacity = 1 }, { duration = 0.5 })
end

function CharacterSelectionButton:_mouse_leave()
  Animation:animate_property(self, { focus_opacity = 0.1 }, { duration = 0.5 })
end

function CharacterSelectionButton:_update() end

function CharacterSelectionButton:_render()
  local x, y, w, h = self:get_geo()
  love.graphics.push()

  if self.selected then
    love.graphics.setColor(Colors.dark_burgundy:get())
  else
    love.graphics.setColor(Colors.gray:get())
  end

  love.graphics.setLineWidth(8)

  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.rectangle("line", x, y, w, h)

  if self:is_focused() then
    love.graphics.setColor(Colors.dark_burgundy:opacity(self.focus_opacity))
  end

  love.graphics.rectangle("fill", x, y, w, h)

  local function avatarMask() love.graphics.rectangle("fill", x, y, w, h) end

  love.graphics.stencil(avatarMask, "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  love.graphics.setColor(Colors.white:get())

  local ch_asset = self.avatar.full
  local ch_w_percent = w / ch_asset:getWidth()

  love.graphics.draw(self.avatar.full, x, y, 0, ch_w_percent, ch_w_percent)

  love.graphics.setStencilTest()

  if self.selected then
    love.graphics.setColor(Colors.burgundy:get())
  else
    love.graphics.setColor(Colors.light_gray:get())
  end

  if self:is_focused() then
    love.graphics.setColor(Colors.burgundy:opacity(self.focus_opacity))
  end

  love.graphics.rectangle("line", x, y, w, h)
  love.graphics.pop()
end

return CharacterSelectionButton
