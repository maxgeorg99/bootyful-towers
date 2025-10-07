local ButtonElement = require "ui.elements.button"
local Label = require "ui.components.label"
local TextBox = require "ui.components.text-box"

--- @class (exact) ui.components.TextInputPopUp : Element
--- @field new fun(opts: ui.components.TextInputPopUpOpts): ui.components.TextInputPopUp
--- @field init fun(self: ui.components.TextInputPopUp, opts: ui.components.TextInputPopUpOpts)
--- @field super Element
--- @field _type "ui.components.TextInputPopUp"
--- @field on_enter function
--- @field height number
--- @field width number
--- @field placeholder_text string
--- @field button_text string
--- @field prompt_text ui.components.Label
--- @field font_color number[]
--- @field background_color number[]
--- @field character_limit number
--- @field ui_root ui.components.UIRootElement
--- @field background_box ui.components.Box
--- @field text_box ui.components.TextBox
--- @field enter_button elements.Button
local TextInputPopUp =
  class("ui.components.TextInputPopUp", { super = Element })

--- @class ui.components.TextInputPopUpOpts
--- @field pos_x number
--- @field pos_y number
--- @field on_enter function
--- @field prompt_text string
--- @field validate_input function?
--- @field height number?
--- @field width number?
--- @field placeholder_text string?
--- @field button_text string?
--- @field font_color? number[]
--- @field background_color? number[]
--- @field character_limit number?
--- @field hidden boolean?
local TextInputPopUpOpts = {}

local default_validate = function(_) return true end

--- @param opts ui.components.TextInputPopUpOpts
function TextInputPopUp:init(opts)
  validate(opts, {
    pos_x = "number",
    pos_y = "number",
    on_enter = "function",
    validate_input = "function?",
    height = "number?",
    width = "number?",
    placeholder_text = "string?",
    button_text = "string?",
    prompt_text = "string",
    font_color = "table?",
    background_color = "table?",
    character_limit = "number?",
    hidden = "boolean?",
  })
  opts.height = opts.height or Config.window_size.height / 3
  opts.width = opts.width or Config.window_size.width / 3
  local box =
    Box.new(Position.new(opts.pos_x, opts.pos_y), opts.width, opts.height)
  Element.init(self, box, { interactable = true })
  self.z = 99999
  self.super = Element
  self._type = TextInputPopUp._type
  self.name = "TextInputPopUp"
  self.on_enter = opts.on_enter
  self.height = opts.height or Config.window_size.height / 3
  self.width = opts.width or Config.window_size.width / 3
  self.placeholder_text = opts.placeholder_text or "Enter text, boyo"
  self.button_text = opts.button_text or "Enter"
  self.font_color = opts.font_color or { 0, 0, 0 }
  self.background_color = opts.background_color or { 0, 0, 0 }
  self.character_limit = opts.character_limit or 80

  -- Background
  self:set_hidden(F.if_nil(opts.hidden, true))

  local _, _, w, h = self:get_geo()
  local input_width = self.width - 20
  -- Input box
  self.text_box = TextBox.new {
    box = Box.from(
      (w / 2) - (input_width / 2),
      75,
      self.width - 20,
      self.height / 5
    ),
    dispatch = opts.on_enter,
    font = Asset.fonts.insignia_48,
    placeholder = self.placeholder_text,
    is_focused = true,
    character_limit = self.character_limit,
    validate_input = opts.validate_input or default_validate,
  }

  self:append_child(self.text_box)

  local prompt_font = Asset.fonts.insignia_48
  local prompt_label_w = prompt_font:getWidth(opts.prompt_text)

  self.prompt_text =
    Label.new(Asset.fonts.insignia_48, opts.prompt_text, nil, "center")

  self.prompt_text:set_x((w / 2) - (prompt_label_w / 2))
  self:append_child(self.prompt_text)

  local label_h = self.height / 6
  local label_w = self.width / 3

  self.enter_button = ButtonElement.new {
    box = Box.from((w / 2) - (label_w / 2), h - label_h - 20, label_w, label_h),
    label = "Enter",
    on_click = function() opts.on_enter(self) end,
  }
  self:append_child(self.enter_button)
  self:hide()
end

function TextInputPopUp:_render()
  -- Darken that background boi
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle(
    "fill",
    0,
    0,
    love.graphics.getWidth(),
    love.graphics.getHeight()
  )

  local center_x = (Config.window_size.width - self.width) / 2
  local center_y = (Config.window_size.height - self.height) / 2
  love.graphics.setColor(self.background_color)
  love.graphics.rectangle("fill", center_x, center_y, self.width, self.height)
end

function TextInputPopUp:show()
  print("[DEBUG] TextInputPopUp:show() called on", self._type or "unknown")
  -- print(
  --   "[DEBUG] Before show - hidden:",
  --   self:get_hidden(),
  --   "interactable:",
  --   self:get_interactable()
  -- )
  self:set_interactable(true)
  self:set_hidden(false)
  State.focused_text_box = self.text_box
  -- print(
  --   "[DEBUG] After show - hidden:",
  --   self:get_hidden(),
  --   "interactable:",
  --   self:get_interactable()
  -- )
end

function TextInputPopUp:hide()
  self:set_interactable(false)
  self:set_hidden(true)
  if State.focused_text_box == self.text_box then
    State.focused_text_box = nil
  end
end

function TextInputPopUp:close() self:hide() end

return TextInputPopUp
