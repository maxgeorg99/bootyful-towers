--- @class (exact) ui.components.TextBox : Element
--- @field new fun(opts: ui.components.TextBox.Options): ui.components.TextBox
--- @field init fun(self: ui.components.TextBox, opts: ui.components.TextBox.Options)
--- @field super Element
--- @field _type "ui.components.TextBox"
--- @field z number
--- @field text string
--- @field placeholder string
--- @field font love.Font
--- @field font_color number[]
--- @field background_color number[]
--- @field border_color number[]
--- @field cursor_pos number
--- @field is_focused boolean
--- @field character_limit? number
--- @field validate_input? function
--- @field dispatch function
local TextBox = class("ui.components.TextBox", { super = Element })

--- @class ui.components.TextBox.Options
--- @field box ui.components.Box
--- @field dispatch function
--- @field placeholder? string
--- @field font love.Font
--- @field font_color? number[]
--- @field background_color? number[]
--- @field border_color? number[]
--- @field hidden? boolean
--- @field is_focused? boolean
--- @field character_limit? number
--- @field validate_input? function

---@param opts ui.components.TextBox.Options
function TextBox:init(opts)
  validate(opts, {
    box = Box,
    dispatch = "function",
    font = "userdata",
    placeholder = "string?",
    font_color = "table?",
    background_color = "table?",
    border_color = "table?",
    hidden = "boolean?",
    is_focused = "boolean?",
    character_limit = "number?",
    validate_input = "function?",
  })
  Element.init(self, opts.box)
  self.text = ""
  self.placeholder = opts.placeholder or "Placeholder text!"
  self.font = opts.font
  self.font_color = opts.font_color or { 0, 0, 0 }
  self.text = ""
  self.placeholder = opts.placeholder or "Placeholder text!"
  self.font = opts.font
  self.font_color = opts.font_color or { 0, 0, 0 }
  self.background_color = opts.background_color or { 255, 255, 255 }
  self.border_color = opts.border_color or { 0.5, 0.5, 0.5 }
  self.cursor_pos = 0
  self.is_focused = opts.is_focused or false
  self:set_hidden(opts.hidden or false)
  self.character_limit = opts.character_limit or 200
  self.validate_input = opts.validate_input or nil
  self.name = "TextBox"
  self.z = 99999
  self.dispatch = opts.dispatch
  if self.is_focused and not State.focused_text_box then
    State.focused_text_box = self
  end
  self.character_limit = opts.character_limit or 200
  self.validate_input = opts.validate_input or nil
  self.name = "TextBox"
  self.z = 99999
  self.dispatch = opts.dispatch
end

function TextBox:_render()
  local padding = 40
  local x, y, w, h = self:get_geo()

  -- Cursor
  if self.is_focused then
    local cursor_x = x
      + padding
      + self.font:getWidth(self.text:sub(1, self.cursor_pos))
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(cursor_x, y + 4, cursor_x, y + h - 4)
  end
  -- Background
  love.graphics.setColor(self.background_color)
  love.graphics.rectangle("fill", x, y, w, h, 5, 5)

  -- Border (thicker when focused)
  local border_width = self.is_focused and 2 or 1
  love.graphics.setColor(
    self.is_focused and { 0.4, 0.6, 1 } or self.border_color
  )
  love.graphics.setLineWidth(border_width)
  love.graphics.rectangle("line", x, y, w, h, 5, 5)

  -- Text
  love.graphics.setFont(self.font)
  if #self.text > 0 then
    love.graphics.setColor(
      self.font_color[1],
      self.font_color[2],
      self.font_color[3]
    )
    love.graphics.print(
      self.text,
      x + padding,
      y + h / 2 - self.font:getHeight() / 2 + 3
    )
  else
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(
      self.placeholder,
      x + padding,
      y + h / 2 - self.font:getHeight() / 2 + 3
    )
  end
end

---@param text string
function TextBox:textinput(text)
  if self.is_focused and #self.text < self.character_limit then
    if not self.validate_input(text) then
      return
    end
    local before = self.text:sub(1, self.cursor_pos)
    local after = self.text:sub(self.cursor_pos + 1)
    self.text = before .. string.upper(text) .. after
    self.cursor_pos = self.cursor_pos + #text
    return UIAction.HANDLED
  else
  end
end

function TextBox:keypressed(key)
  if not self.is_focused then
    logger.debug "TextBox:keypressed called when TextBox is not in focus"
    return
  end

  if key == "escape" then
    logger.debug "escape pressed in TextBox but no behavior implemented."
    return
  elseif key == "backspace" and self.cursor_pos > 0 then
    local before = self.text:sub(1, self.cursor_pos - 1)
    local after = self.text:sub(self.cursor_pos + 1)
    self.text = before .. after
    self.cursor_pos = self.cursor_pos - 1
  elseif key == "left" and self.cursor_pos > 0 then
    self.cursor_pos = self.cursor_pos - 1
  elseif key == "right" and self.cursor_pos < #self.text then
    self.cursor_pos = self.cursor_pos + 1
  elseif key == "home" then
    self.cursor_pos = 0
  elseif key == "end" then
    self.cursor_pos = #self.text
  elseif key == "return" then
    self.dispatch(self.text)
  elseif key == "space" then
    self:textinput " "
  else
    self:textinput(key)
  end

  return UIAction.HANDLED
end

return TextBox
