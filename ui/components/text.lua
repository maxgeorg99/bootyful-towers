--[[

Text.new { "A string", MyClass, function() return State.player.gold end, " gold", box = Box.fullscreen() }
Text.new { "Gold: {gold:gold}", env = { gold = State.player.gold }, box = Box.fullscreen(), color = { 1, 0, 0, 1 } }

--]]

local ICON_PADDING = 10

---@alias ui.Text.Item string | ui.Text.ItemWithOptions | (fun(): ui.Text.Item) | ui.Text.Printable | ui.Text.Icon

---@class ui.Text.Printable
---@field to_text fun(self: self): ui.Text.Item

---@class ui.Text.ItemWithOptions
---@field text string
---@field font? love.Font
---@field color? number[]
---@field scale? number

---@class ui.Text.Icon
---@field icon vibes.Texture
---@field color number[]

---@alias ui.Text.Resolved ui.Text.ItemWithOptions | ui.Text.Icon

---@alias ui.Text.TextAlign "left" | "center" | "right"
---@alias ui.Text.VerticalAlign "top" | "center" | "bottom"

---@class ui.Text.Param
---@field [number] ui.Text.Item
---@field box ui.components.Box
---@field env? table<string, any>
---@field text_align? ui.Text.TextAlign Defaults to "center"
---@field vertical_align? ui.Text.VerticalAlign Defaults to "center"
---@field background? number[]
---@field rounded? number
---@field font? love.Font
---@field color? number[]
---@field scale? number
---@field border? number[]
---@field padding? number

---@class component.Text : Element
---@field new fun(opts: ui.Text.Param): component.Text
---@field init fun(self: component.Text, opts: ui.Text.Param)
---@field refresh fun(self: component.Text)
---@field items ui.Text.Item[]
---@field box ui.components.Box
---@field env table<string, any>
---@field text_align ui.Text.TextAlign
---@field vertical_align ui.Text.VerticalAlign
---@field background number[]
---@field rounded number
---@field border number[]
---@field padding number
---@field default_font love.Font
---@field default_color number[]
---@field default_scale number
local Text = class("ui.Text", { super = Element })

---@param opts ui.Text.Param
function Text:init(opts)
  -- opts = {
  --   "hello: {gold:37}",
  --   { text = "  smaller", font = Asset.fonts.default_16 },
  --   " again it's big {range:7}",
  --   function()
  --     return {
  --       text = tostring(os.time() % 10),
  --       color = Colors.red:opacity((os.time() % 10 / 10)),
  --     }
  --   end,
  --
  --   box = Box.fullscreen(),
  --   font = Asset.fonts.default_48,
  --   scale = 2,
  -- }

  assert(not opts["text"], "textbox used text, pass as arguments in the list")

  validate(opts, {
    box = Box,
    -- color = List { "number" },
    -- border = List { "number" },
    -- background = List { "number" },
    font = "userdata?",
    scale = "number?",
    text_align = "string?",
    vertical_align = "string?",
    padding = "number?",
  })

  Element.init(self, opts.box)
  self.text_align = F.if_nil(opts.text_align, "center")
  self.vertical_align = F.if_nil(opts.vertical_align, "center")
  self.env = opts.env or {}
  self.box = opts.box
  self.background = opts.background or { 0, 0, 0, 0 }
  self.rounded = opts.rounded or 0
  self.border = opts.border or { 0, 0, 0, 0 }
  self.padding = opts.padding or 0
  self.items = table.copy_list(opts)
  self.name = "Text"

  -- Set defaults for items
  self.default_font = opts.font or Asset.fonts.default_16

  self.default_font:setFilter("linear", "linear", 16)

  self.default_color = opts.color or { 1, 1, 1, 1 }
  self.default_scale = opts.scale or 1
end

---@return nil
---Refreshes the text element so layout dependent values are recalculated.
function Text:refresh() end

local formatters = setmetatable({
  tower = function(amount)
    return {
      { icon = Asset.icons[IconType.TOWER], color = Colors.white:get() },
      { text = tostring(amount), color = { 1, 1, 0, 1 } },
    }
  end,
  enhance = function(amount)
    return {
      { icon = Asset.icons[IconType.ENHANCE], color = Colors.white:get() },
      { text = tostring(amount), color = { 1, 1, 0, 1 } },
    }
  end,
  durability = function(amount)
    return {
      { icon = Asset.icons[IconType.DURABILITY], color = Colors.white:get() },
      { text = tostring(amount), color = { 1, 1, 0, 1 } },
    }
  end,
  multi = function(amount)
    return {
      { icon = Asset.icons[IconType.MULTI], color = Colors.white:get() },
      { text = tostring(amount), color = { 1, 1, 0, 1 } },
    }
  end,
  gold = function(amount)
    return {
      { icon = Asset.icons[IconType.GOLD], color = Colors.white:get() },
      { text = tostring(amount), color = { 1, 1, 0, 1 } },
    }
  end,
  energy = function(amount)
    return {
      { icon = Asset.icons[IconType.ENERGY], color = Colors.white:get() },
      { text = tostring(amount), color = { 0, 0.5, 1, 1 } },
    }
  end,
  damage = function(amount)
    return {
      { icon = Asset.icons[IconType.DAMAGE], color = Colors.white:get() },
      { text = amount, color = { 1, 0, 0, 1 } },
    }
  end,
  critical = function(amount)
    return {
      { icon = Asset.icons[IconType.CHANCE], color = Colors.white:get() },
      { text = amount, color = { 1, 0, 0, 1 } },
    }
  end,
  range = function(amount)
    return {
      { icon = Asset.icons[IconType.RANGE], color = Colors.white:get() },
      { text = amount, color = { 0, 0.5, 1, 1 } },
    }
  end,
  value = function(amount)
    return {
      { text = amount, color = Colors.white:get() },
    }
  end,
  enemy_targets = function(amount)
    return {
      { icon = Asset.icons[IconType.MULTI], color = Colors.white:get() },
      { text = amount, color = Colors.white:get() },
    }
  end,
  attack_speed = function(amount)
    return {
      {
        icon = Asset.icons[IconType.ATTACKSPEED],
        color = Colors.white:get(),
      },
      { text = amount, color = Colors.white:get() },
    }
  end,
  increase = function(amount)
    return {
      { text = amount, color = Colors.green:get(), scale = 0.5 },
    }
  end,
  decrease = function(amount)
    return {
      { text = amount, color = Colors.red:get() },
    }
  end,
  poison = function(amount)
    return {
      {
        icon = Asset.icons[IconType.POISON],
        color = Colors.white:get(),
      },
      { text = amount, color = Colors.green:get(), scale = 0.5 },
    }
  end,
  poison_growth = function(amount)
    return {
      { icon = Asset.icons[IconType.POISON], color = Colors.white:get() }, -- Green poison color with skull icon
      { text = "+" .. amount, color = { 0, 0.8, 0, 1 } },
    }
  end,
  fire = function(amount)
    return {
      { icon = Asset.icons[IconType.FIRE], color = Colors.white:get() }, -- Orange fire color
      { text = amount, color = { 1, 0.5, 0, 1 } },
    }
  end,
  fire_growth = function(amount)
    return {
      { icon = Asset.icons[IconType.FIRE], color = Colors.white:get() }, -- Orange fire color
      { text = "+" .. amount, color = { 1, 0.5, 0, 1 } },
    }
  end,
  energy_cost_reduction = function(amount)
    return {
      { icon = Asset.icons[IconType.ENERGY], color = Colors.white:get() }, -- Blue energy color
      { text = "-" .. amount, color = { 0, 0.5, 1, 1 } },
    }
  end,
  energy_bonus = function(amount)
    return {
      { icon = Asset.icons[IconType.ENERGY], color = Colors.white:get() }, -- Blue energy color
      { text = "+" .. amount, color = { 0, 0.5, 1, 1 } },
    }
  end,
  damage_reduction = function(amount)
    return {
      { icon = Asset.icons[IconType.SHIELD], color = { 0.7, 0.7, 1, 1 } }, -- Light blue shield color
      { text = "-" .. amount .. "%", color = { 0.7, 0.7, 1, 1 } },
    }
  end,
  health_bonus = function(amount)
    return {
      { icon = Asset.icons[IconType.HEART], color = { 1, 0.2, 0.2, 1 } }, -- Red heart color
      { text = "+" .. amount, color = { 1, 0.2, 0.2, 1 } },
    }
  end,
}, {
  __index = function()
    return function(val) return { text = val } end
  end,
})

---@param item ui.Text.ItemWithOptions
---@param text string
---@return ui.Text.ItemWithOptions|TextControl
local with_text = function(item, text)
  if text == TextControl.NewLine then
    return TextControl.NewLine
  end

  local copy = table.copy(item)
  copy.text = text
  return copy
end

local merge_items = function(item1, item2)
  local copy = table.copy(item1)
  for k, v in pairs(item2) do
    if copy[k] == nil then
      copy[k] = v
    end
  end
  return copy
end

local split_on_new_lines = function(text)
  local out = {}
  for line in string.gmatch(text, "[^\n]+") do
    table.insert(out, line)
  end
  return out
end

---@param acc ui.Text.ItemWithOptions[]
---@param parent ui.Text.ItemWithOptions
function Text:_process_string_substitutions(acc, parent)
  local lines = split_on_new_lines(parent.text)

  for i, text in ipairs(lines) do
    if i > 1 then
      table.insert(acc, TextControl.NewLine)
    end

    while #text > 0 do
      local start, stop = string.find(text, "{([^:]+):([^}]+)}")
      if not start then
        break
      end

      local prefix = string.sub(text, 1, start - 1)
      table.insert(acc, with_text(parent, prefix))

      -- Transform the inner text,
      local fmt, key = string.match(text, "{([^:]+):([^}]+)}")

      -- TODO: May want to split the key on `.`, so that we can access nested fields.
      --       so that we can do things like `{range:stats.range}`, would very useful.
      local result = table.flatten(formatters[fmt](self.env[key] or key))
      for _, item in ipairs(result) do
        table.insert(acc, merge_items(item, parent))
      end

      text = string.sub(text, stop + 1)
    end
    table.insert(acc, with_text(parent, text))
  end
end

---@param acc ui.Text.Resolved[]
---@param item ui.Text.Item|ui.Text.Resolved
function Text:_resolve_one_item(acc, item)
  if type(item) == "string" then
    self:_process_string_substitutions(acc, { text = item })
    return
  elseif type(item) == "function" then
    self:_resolve_one_item(acc, item())
    return
  elseif type(item) == "table" then
    if item.to_text then
      ---@cast item ui.Text.Printable
      self:_resolve_one_item(acc, table.flatten(item:to_text()))
      return
    end

    ---@diagnostic disable-next-line: undefined-field
    if item.text then
      ---@cast item ui.Text.ItemWithOptions
      self:_process_string_substitutions(acc, item)
      return
    end

    ---@diagnostic disable-next-line: undefined-field
    if item.icon then
      ---@cast item ui.Text.Icon
      table.insert(acc, item)
      return
    end

    if table.is_list(item) then
      for _, child in ipairs(item) do
        self:_resolve_one_item(acc, child)
      end
      return
    end
  end

  error("unknown item type: " .. type(item) .. " " .. inspect(item))
end

---@class ui.Text.State
---@field box_x number
---@field box_y number
---@field box_w number
---@field box_h number
---@field current_x number
---@field current_y number
---@field max_height number
---@field total_width number

---@param font love.Font
---@param text string
---@param remaining number
---@return string?, string?
local split_at_space_given_remaining = function(font, text, remaining)
  if remaining <= 0 then
    return nil, text
  end

  -- Short circuit: if the whole text doesn't fit, try to split, else return all as prefix
  local text_width = font:getWidth(text)
  if text_width <= remaining then
    return text, nil
  end

  -- Only split at spaces, not at arbitrary character boundaries.
  local last_space = nil
  local i = 1
  while i <= #text do
    local c = text:sub(i, i)
    if c == " " then
      local candidate = text:sub(1, i)
      local width = font:getWidth(candidate)
      if width <= remaining then
        last_space = i
      else
        break
      end
    end
    i = i + 1
  end

  if last_space then
    -- Split at the last space that fits
    local prefix = text:sub(1, last_space)
    local suffix = text:sub(last_space + 1)

    return prefix, suffix
  else
    -- No space found that fits, so don't split, return empty prefix and all as suffix
    return nil, text
  end
end

---@param state ui.Text.State
---@param icon ui.Text.Icon
function Text:_render_icon(state, icon)
  -- TODO: For now, the icon is never the thing that wraps the line...
  --       Maybe want to make it so that the next thing coming with the icon checks,
  --       but for now we can just try to avoid or use TextControl.NewLine if necessary.

  local scale = state.max_height / icon.icon:getHeight()
  icon.icon:setFilter("nearest", "nearest")
  self:with_color(
    icon.color,
    function()
      love.graphics.draw(
        icon.icon,
        state.current_x,
        state.current_y,
        0,
        scale,
        scale
      )
    end
  )

  state.current_x = state.current_x
    + icon.icon:getWidth() * scale
    + ICON_PADDING
end

function Text:_render()
  -- TODO: handle parent scaling!
  local _scale = self:get_scale()

  local box_x, box_y, box_w, box_h = self:get_geo()

  -- love.graphics.setColor(1, 1, 1, 1)

  if self.border then
    self:with_color(
      self.border,
      function() love.graphics.rectangle("line", box_x, box_y, box_w, box_h) end
    )
  end

  self:with_color(
    self.background,
    function()
      love.graphics.rectangle(
        "fill",
        box_x,
        box_y,
        box_w,
        box_h,
        self.rounded,
        self.rounded,
        80
      )
    end
  )

  -- Apply padding to the text rendering area
  local text_x = box_x + self.padding
  local text_y = box_y + self.padding
  local text_w = box_w - (self.padding * 2)
  local text_h = box_h - (self.padding * 2)

  love.graphics.setFont(self.default_font)

  ---@type ui.Text.Resolved[]
  local pieces = {}
  for _, item in ipairs(self.items) do
    self:_resolve_one_item(pieces, item)
  end

  pieces = table.flatten(pieces)

  ---@type ui.Text.State
  local state = {
    box_x = text_x,
    box_y = text_y,
    box_w = text_w,
    box_h = text_h,
    current_x = text_x,
    current_y = text_y,
    max_height = 0,
    total_width = 0,
  }

  -- if Config.debug.enabled then
  --   love.graphics.setColor(0, 1, 0, 1)
  --   love.graphics.rectangle("line", text_x, text_y, text_w, text_h)
  -- end

  for _, piece in ipairs(pieces) do
    local font = piece.font or self.default_font

    if piece.text then
      state.max_height = math.max(state.max_height or 0, font:getHeight() - 5)
      state.total_width = state.total_width + font:getWidth(piece.text)
    elseif piece.icon then
      state.total_width = state.total_width
        + piece.icon:getWidth()
        + ICON_PADDING
    end
  end

  ---@type ui.Text.Resolved[][]
  local pieces_with_newlines = {}
  if state.total_width <= text_w then
    pieces_with_newlines = pieces
  else
    -- Split the pieces into lines based on the width of the box
    local line_width = 0

    for _, piece in ipairs(pieces) do
      if piece == TextControl.NewLine then
        table.insert(pieces_with_newlines, piece)
        line_width = 0
      elseif piece.icon then
        local scale = state.max_height / piece.icon:getHeight()
        line_width = line_width + piece.icon:getWidth() * scale + ICON_PADDING
        table.insert(pieces_with_newlines, piece)
      elseif piece.text then
        ---@cast piece ui.Text.ItemWithOptions

        local font = piece.font or self.default_font
        if line_width + font:getWidth(piece.text) > text_w then
          local text_to_split = piece.text

          -- Keep splitting until the suffix is empty
          while text_to_split and #text_to_split > 0 do
            local prefix, suffix = split_at_space_given_remaining(
              font,
              text_to_split,
              text_w - line_width
            )

            if prefix then
              table.insert(pieces_with_newlines, with_text(piece, prefix))

              -- Only insert newline if there's more text to process
              if suffix and #suffix > 0 then
                table.insert(pieces_with_newlines, TextControl.NewLine)
                text_to_split = suffix
                line_width = 0
              else
                -- No more text to split, we're done
                break
              end
            else
              -- No prefix could fit, move entire text to next line
              -- But if we're already at the start of a line and still can't fit,
              -- we need to force-break to avoid infinite loop
              if line_width == 0 then
                -- Force break: take at least one character to ensure progress
                local forced_break = text_to_split:sub(1, 1)
                table.insert(
                  pieces_with_newlines,
                  with_text(piece, forced_break)
                )
                text_to_split = text_to_split:sub(2)
                if #text_to_split > 0 then
                  table.insert(pieces_with_newlines, TextControl.NewLine)
                  line_width = 0
                end
              else
                table.insert(pieces_with_newlines, TextControl.NewLine)
                line_width = 0
                -- Don't change text_to_split here - let it retry on the new line
              end
            end
          end
        else
          line_width = line_width + font:getWidth(piece.text)
          table.insert(pieces_with_newlines, piece)
        end
      else
        error("unknown piece type (split): " .. inspect(piece))
      end
    end
  end

  state.current_x = self:_get_initial_x(state)
  state.current_y = self:_get_initial_y(state)

  for _, piece in ipairs(pieces_with_newlines) do
    if piece == TextControl.NewLine then
      state.current_x = self:_get_initial_x(state)
      state.current_y = state.current_y + state.max_height
    elseif type(piece) == "table" and rawget(piece, "icon") then
      ---@cast piece ui.Text.Icon
      self:_render_icon(state, piece)
    else
      ---@cast piece ui.Text.ItemWithOptions
      if not piece.text then
        error("text is required" .. inspect(piece))
      end

      local text = assert(piece.text, "text is required")
      local font = piece.font or self.default_font
      local color = piece.color or self.default_color

      love.graphics.setFont(font)

      -- Try to write as much of the text on the same line as we can
      -- If we can't fit it, move to the next line
      local width = font:getWidth(text)
      local height = font:getHeight()

      local centered_y = state.current_y + (state.max_height - height) / 2

      self:with_color(
        color,
        function()
          love.graphics.print(
            text,
            state.current_x,
            centered_y,
            0,
            self.default_scale,
            self.default_scale
          )
        end
      )

      state.current_x = state.current_x + width
    end
  end

  -- love.graphics.setColor(1, 1, 1, 1)
end

---@param state ui.Text.State
function Text:_get_initial_x(state)
  if self.text_align == "left" then
    return state.box_x
  elseif self.text_align == "right" then
    return math.max(
      state.box_x + (state.box_w - state.total_width),
      state.box_x
    )
  elseif self.text_align == "center" then
    return state.box_x
      + (state.box_w - math.min(state.total_width, state.box_w)) / 2
  else
    error("unknown text align: " .. self.text_align)
  end
end

---@param state ui.Text.State
function Text:_get_initial_y(state)
  if self.vertical_align == "top" then
    return state.box_y
  elseif self.vertical_align == "center" then
    return state.box_y + (state.box_h - state.max_height) / 2
  elseif self.vertical_align == "bottom" then
    return state.box_y + (state.box_h - state.max_height)
  else
    error("unknown vertical align: " .. self.vertical_align)
  end
end

return Text
