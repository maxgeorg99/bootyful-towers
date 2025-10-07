local ButtonElement = require "ui.elements.button"
local GameFunctions = require "vibes.data.game-functions"
local Tower = require "vibes.tower.base"
local TowerUtils = require "vibes.tower.tower-utils"
local sprites = require("vibes.asset").sprites
local Text = require "ui.components.text"

local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

-- Specialized captcha grid button that extends the new button system
local CaptchaGridButton =
  class("vibes.tower.CaptchaGridButton", { super = ButtonElement })

function CaptchaGridButton:init(opts)
  ButtonElement.init(self, {
    box = opts.box,
    label = "",
    on_click = opts.on_click,
  })

  self.grid_states = opts.grid_states
  self.index = opts.index
  self.current_question = opts.current_question
  self.draw_pixel_pizza = opts.draw_pixel_pizza
  self.draw_tool_icon = opts.draw_tool_icon
  self.draw_sub_item_icon = opts.draw_sub_item_icon
  self.draw_centered_label_two_lines = opts.draw_centered_label_two_lines
end

function CaptchaGridButton:_render()
  local x, y, width, height = self:get_geo()

  -- Draw background using parent render
  ButtonElement._render(self)

  local opacity = 1
  local bx, by, bw, bh = x, y, width, height

  -- Draw selection state
  if self.grid_states[self.index] then
    love.graphics.setColor(0.2, 0.6, 0.8, opacity or 1)
    love.graphics.rectangle("fill", bx, by, bw, bh)
  end

  if self.current_question.type == "pizza" then
    -- Draw pizza
    self.draw_pixel_pizza(
      bx + 6,
      by + 6,
      bw - 12,
      bh - 12,
      assert(self.current_question.pizza_counts)[self.index],
      opacity
    )
  elseif self.current_question.type == "tools" then
    -- Draw tool icon and label
    local label = assert(self.current_question.tools)[self.index]
    self.draw_tool_icon(label, bx + 6, by + 6, bw - 12, bh - 30, opacity)
    self.draw_centered_label_two_lines(label, bx, by, bw, bh, opacity)
  else
    -- Sub item icon and label
    local label = assert(self.current_question.sub_items)[self.index]
    self.draw_sub_item_icon(label, bx + 6, by + 6, bw - 12, bh - 30, opacity)
    self.draw_centered_label_two_lines(label, bx, by, bw, bh, opacity)
  end
end

-- Utility function
local function table_contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

---@class vibes.CaptchaTower : vibes.Tower
---@field new fun(): vibes.CaptchaTower
---@field init fun(self: vibes.CaptchaTower)
---@field _base_stats tower.Stats
---@field _tags { }
---@field _click_times number[]
---@field _captcha_locked boolean
---@field _overlay ui.element.Overlay?
---@field _captcha_phase "waiting" | "showing_warning" | "showing_captcha"
---@field _captcha_start_time number
---@field _grid_states boolean[]
---@field _current_question { type: "pizza"|"tools"|"sub", question: string, correct_index?: number, pizza_counts?: number[], correct_indices?: number[], tools?: string[], sub_items?: string[] }
---@field _last_captcha_type string?
---@field _regenerate_same_type boolean
---@field _show_fail_speed_message boolean
local CaptchaTower = class("vibes.CaptchaTower", { super = Tower })

-- Draw a pixel-style pizza with pepperonis
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@param pepperoni_count number
---@param opacity number|nil
local function draw_pixel_pizza(bx, by, bw, bh, pepperoni_count, opacity)
  local alpha = opacity or 1
  local cx = bx + bw / 2
  local cy = by + bh / 2
  local radius = math.min(bw, bh) * 0.42

  -- Crust
  love.graphics.setColor(0.78, 0.55, 0.23, alpha)
  love.graphics.circle("fill", cx, cy, radius)

  -- Cheese
  local cheese_radius = radius * 0.82
  love.graphics.setColor(1, 0.92, 0.45, alpha)
  love.graphics.circle("fill", cx, cy, cheese_radius)

  -- Pepperonis (constrain fully within cheese area)
  local r = math.max(3, math.floor(math.min(bw, bh) * 0.07))
  local inner = math.max(0, cheese_radius - r - 2)

  local positions = {}
  for row = 0, 2 do
    for col = 0, 2 do
      local dx = (col - 1) * inner
      local dy = (row - 1) * inner
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist > 0 and dist + r > inner then
        local scale = (inner - r) / dist
        dx = dx * scale
        dy = dy * scale
      end
      positions[#positions + 1] = { x = cx + dx, y = cy + dy }
    end
  end

  local max_peps = math.max(1, math.min(9, math.floor(pepperoni_count)))
  love.graphics.setColor(0.75, 0.08, 0.08, alpha)
  for i = 1, max_peps do
    local p = positions[i]
    love.graphics.rectangle("fill", p.x - r, p.y - r, r * 2, r * 2)
  end
end

-- Draw a simple icon for a tool using vector primitives
---@param name string
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@param opacity number|nil
local function draw_tool_icon(name, bx, by, bw, bh, opacity)
  local alpha = opacity or 1
  local key = string.lower(name)

  local cx = bx + bw / 2
  local cy = by + bh / 2
  local w = bw * 0.75
  local h = bh * 0.75
  local left = cx - w / 2
  local top = cy - h / 2

  if key == "hammer" then
    -- Handle
    love.graphics.setColor(0.55, 0.27, 0.07, alpha)
    love.graphics.rectangle(
      "fill",
      cx - w * 0.06,
      top + h * 0.25,
      w * 0.12,
      h * 0.55
    )
    -- Head
    love.graphics.setColor(0.75, 0.75, 0.78, alpha)
    love.graphics.rectangle(
      "fill",
      cx - w * 0.3,
      top + h * 0.18,
      w * 0.6,
      h * 0.15
    )
    love.graphics.rectangle(
      "fill",
      cx + w * 0.15,
      top + h * 0.05,
      w * 0.15,
      h * 0.25
    )
  elseif key == "crowbar" then
    love.graphics.setColor(0.86, 0.15, 0.15, alpha)
    love.graphics.setLineWidth(math.max(2, math.floor(bw * 0.06)))
    love.graphics.line(left + w * 0.2, top + h * 0.8, cx, top + h * 0.5)
    love.graphics.arc(
      "line",
      "open",
      cx,
      top + h * 0.35,
      w * 0.25,
      math.pi * 1.1,
      math.pi * 1.9
    )
  elseif key == "baseball bat" then
    love.graphics.setColor(0.76, 0.6, 0.34, alpha)
    love.graphics.rectangle(
      "fill",
      cx - w * 0.06,
      top + h * 0.1,
      w * 0.12,
      h * 0.65
    )
    love.graphics.circle("fill", cx, top + h * 0.08, w * 0.12)
    love.graphics.setColor(0.4, 0.2, 0.1, alpha)
    love.graphics.rectangle(
      "fill",
      cx - w * 0.08,
      top + h * 0.7,
      w * 0.16,
      h * 0.12
    )
  elseif key == "feather" then
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.setLineWidth(1)
    love.graphics.polygon(
      "fill",
      cx,
      top + h * 0.15,
      cx + w * 0.25,
      cy,
      cx,
      top + h * 0.85,
      cx - w * 0.15,
      cy
    )
    love.graphics.setColor(0.8, 0.8, 0.9, alpha)
    love.graphics.line(cx, top + h * 0.2, cx, top + h * 0.8)
  elseif key == "pillow" then
    love.graphics.setColor(0.9, 0.9, 1, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.15,
      top + h * 0.25,
      w * 0.7,
      h * 0.5,
      10,
      10
    )
    love.graphics.setColor(0.8, 0.8, 0.95, alpha)
    love.graphics.rectangle(
      "line",
      left + w * 0.15,
      top + h * 0.25,
      w * 0.7,
      h * 0.5,
      10,
      10
    )
  elseif key == "spoon" then
    love.graphics.setColor(0.75, 0.75, 0.78, alpha)
    love.graphics.rectangle(
      "fill",
      cx - w * 0.05,
      top + h * 0.35,
      w * 0.1,
      h * 0.45
    )
    love.graphics.ellipse("fill", cx, top + h * 0.25, w * 0.18, h * 0.12)
  elseif key == "banana" then
    love.graphics.setColor(1, 0.92, 0.2, alpha)
    love.graphics.setLineWidth(math.max(2, math.floor(bw * 0.05)))
    love.graphics.arc(
      "line",
      "open",
      cx,
      cy + h * 0.05,
      w * 0.35,
      math.pi * 0.2,
      math.pi * 0.9
    )
  elseif key == "book" then
    love.graphics.setColor(0.9, 0.9, 0.9, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.2,
      top + h * 0.2,
      w * 0.6,
      h * 0.6
    )
    love.graphics.setColor(0.5, 0.1, 0.1, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.2,
      top + h * 0.2,
      w * 0.08,
      h * 0.6
    )
  elseif key == "balloon" then
    love.graphics.setColor(1, 0, 0, alpha)
    love.graphics.circle("fill", cx, top + h * 0.35, math.min(w, h) * 0.22)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.polygon(
      "fill",
      cx - 4,
      top + h * 0.52,
      cx + 4,
      top + h * 0.52,
      cx,
      top + h * 0.58
    )
    love.graphics.setColor(0.9, 0.9, 0.9, alpha)
    love.graphics.setLineWidth(1)
    love.graphics.line(cx, top + h * 0.58, cx, top + h * 0.8)
  else
    -- Fallback box
    love.graphics.setColor(0.3, 0.3, 0.35, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.2,
      top + h * 0.2,
      w * 0.6,
      h * 0.6
    )
  end
end

--- Draw a centered label; if two words, put the second word below the first
---@param label string
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@param opacity number|nil
local function draw_centered_label_two_lines(label, bx, by, bw, bh, opacity)
  local alpha = opacity or 1
  love.graphics.setColor(1, 1, 1, alpha)
  local font = Asset.fonts.insignia_14 or Asset.fonts.insignia_16
  love.graphics.setFont(font)

  local first = label
  local second = nil
  local space_pos = string.find(label, " ")
  if space_pos then
    first = string.sub(label, 1, space_pos - 1)
    second = string.sub(label, space_pos + 1)
  end

  local th = font:getHeight()
  if second then
    local tw1 = font:getWidth(first)
    local tw2 = font:getWidth(second)
    local y_start = by + bh - th * 2 - 6
    love.graphics.print(first, bx + (bw - tw1) / 2, y_start)
    love.graphics.print(second, bx + (bw - tw2) / 2, y_start + th)
  else
    local tw = font:getWidth(first)
    love.graphics.print(first, bx + (bw - tw) / 2, by + bh - th - 6)
  end
end

-- Draw a simple icon for a sub topping
---@param name string
---@param bx number
---@param by number
---@param bw number
---@param bh number
---@param opacity number|nil
local function draw_sub_item_icon(name, bx, by, bw, bh, opacity)
  local alpha = opacity or 1
  local key = string.lower(name)
  local cx = bx + bw / 2
  local cy = by + bh / 2
  local w = bw * 0.78
  local h = bh * 0.78
  local left = cx - w / 2
  local top = cy - h / 2

  if key == "prosciutto" then
    love.graphics.setColor(0.86, 0.54, 0.54, alpha)
    love.graphics.ellipse("fill", cx, cy, w * 0.35, h * 0.22)
    love.graphics.setColor(0.92, 0.72, 0.72, alpha)
    love.graphics.ellipse("line", cx, cy, w * 0.35, h * 0.22)
  elseif key == "salami" then
    love.graphics.setColor(0.75, 0.2, 0.2, alpha)
    love.graphics.circle("fill", cx, cy, math.min(w, h) * 0.28)
    love.graphics.setColor(1, 1, 1, alpha)
    for i = 1, 5 do
      local a = i * (2 * math.pi / 5)
      love.graphics.circle(
        "fill",
        cx + math.cos(a) * w * 0.15,
        cy + math.sin(a) * h * 0.15,
        2
      )
    end
  elseif key == "capicola" then
    love.graphics.setColor(0.8, 0.3, 0.3, alpha)
    love.graphics.ellipse("fill", cx, cy, w * 0.32, h * 0.2)
  elseif key == "mortadella" then
    love.graphics.setColor(0.96, 0.78, 0.7, alpha)
    love.graphics.circle("fill", cx, cy, math.min(w, h) * 0.28)
    love.graphics.setColor(0.98, 0.9, 0.85, alpha)
    love.graphics.circle("fill", cx - w * 0.12, cy - h * 0.05, 3)
    love.graphics.circle("fill", cx + w * 0.08, cy + h * 0.06, 3)
  elseif key == "provolone" then
    love.graphics.setColor(1, 0.98, 0.8, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.2,
      top + h * 0.3,
      w * 0.6,
      h * 0.35,
      4,
      4
    )
  elseif key == "mozzarella" then
    love.graphics.setColor(0.98, 0.98, 0.95, alpha)
    love.graphics.ellipse("fill", cx, cy, w * 0.32, h * 0.22)
  -- Non-Italian weirdo choices
  elseif key == "peanut butter" then
    love.graphics.setColor(0.8, 0.6, 0.3, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.25,
      top + h * 0.35,
      w * 0.5,
      h * 0.28
    )
  elseif key == "jelly" then
    love.graphics.setColor(0.6, 0, 0.6, alpha)
    love.graphics.ellipse("fill", cx, cy, w * 0.28, h * 0.2)
  elseif key == "gummy bears" then
    love.graphics.setColor(1, 0, 0, alpha)
    love.graphics.circle("fill", left + w * 0.3, cy, 5)
    love.graphics.setColor(0, 1, 0, alpha)
    love.graphics.circle("fill", cx, cy, 5)
    love.graphics.setColor(0, 0, 1, alpha)
    love.graphics.circle("fill", left + w * 0.7, cy, 5)
  elseif key == "marshmallow" then
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.3,
      top + h * 0.35,
      w * 0.4,
      h * 0.3,
      6,
      6
    )
  else
    love.graphics.setColor(0.3, 0.3, 0.35, alpha)
    love.graphics.rectangle(
      "fill",
      left + w * 0.2,
      top + h * 0.2,
      w * 0.6,
      h * 0.6
    )
  end
end

CaptchaTower._base_stats = TowerStats.new {
  range = Stat.new(3, 1),
  damage = Stat.new(10, 1),
  attack_speed = Stat.new(0.0, 1), -- does not auto-attack
  enemy_targets = Stat.new(0, 1), -- unused
}

function CaptchaTower:init()
  Tower.init(
    self,
    self._base_stats:clone(),
    sprites.tower_captcha,
    { kind = TowerKind.EFFECT, element_kind = ElementKind.PHYSICAL }
  )

  self._tags = {}
  self._click_times = {}
  self._captcha_locked = false
  self._captcha_phase = "waiting"
  self._captcha_start_time = 0
  self._grid_states =
    { false, false, false, false, false, false, false, false, false }
  self._current_question =
    { question = "", correct_index = 1, pizza_counts = {} }
  self._last_captcha_type = nil
  self._regenerate_same_type = false
  self._show_fail_speed_message = false
end

---@type table<TowerStatField, table<Rarity, tower.UpgradeOption>>
local base_enhancements = {
  [TowerStatField.DAMAGE] = TowerUtils.damage_by_list { 3, 5, 8, 16, 32 },
  [TowerStatField.RANGE] = TowerUtils.range_by_list { 0.5, 0.75, 1.25, 2.5, 5.0 },
  [TowerStatField.ATTACK_SPEED] = TowerUtils.attack_speed_by_list {
    0.25,
    0.5,
    0.75,
    1.5,
    3.0,
  },
  [TowerStatField.CRITICAL] = TowerUtils.critical_by_list {
    0.05,
    0.1,
    0.15,
    0.25,
    0.5,
  },
}

---@type table<Rarity, tower.UpgradeOption[]>
local enhancements_by_rarity =
  TowerUtils.convert_enhancement_by_type_to_rarity(base_enhancements)

--- Utility: shuffle a table in-place
---@param t any[]
local function shuffle_table(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

--- Generate a captcha: either pizza (pick max pepperonis) or tools (pick all kneecap-breakers)
function CaptchaTower:_generate_captcha_question()
  -- Decide captcha type: avoid repeating the last one; on retry keep same type
  local selected_type
  if
    self._regenerate_same_type
    and self._current_question
    and self._current_question.type
  then
    selected_type = self._current_question.type
  else
    local types = { "pizza", "tools", "sub" }
    local candidates = {}
    for _, t in ipairs(types) do
      if t ~= self._last_captcha_type then
        candidates[#candidates + 1] = t
      end
    end
    selected_type = candidates[math.random(#candidates)]
  end

  if selected_type == "tools" then
    -- Tools captcha: 3 breakable, 6 safe
    local breakable = { "HAMMER", "CROWBAR", "BASEBALL BAT" }
    local safe = { "FEATHER", "PILLOW", "SPOON", "BANANA", "BOOK", "BALLOON" }
    local items = {}
    for i = 1, #breakable do
      items[#items + 1] = breakable[i]
    end
    for i = 1, #safe do
      items[#items + 1] = safe[i]
    end
    shuffle_table(items)

    local correct_indices = {}
    for i = 1, #items do
      if table_contains(breakable, items[i]) then
        correct_indices[#correct_indices + 1] = i
      end
    end

    self._current_question = {
      type = "tools",
      question = "Pick all tools Tony could use to break kneecaps",
      correct_indices = correct_indices,
      tools = items,
    }
  elseif selected_type == "sub" then
    -- Sub toppings: 5 Italian meats/cheeses vs 4 weird non-Italian
    local italian = {
      "PROSCIUTTO",
      "SALAMI",
      "CAPICOLA",
      "MORTADELLA",
      "PROVOLONE",
      "MOZZARELLA",
    }
    shuffle_table(italian)
    local right = { italian[1], italian[2], italian[3], italian[4], italian[5] }
    local weird = { "PEANUT BUTTER", "JELLY", "GUMMY BEARS", "MARSHMALLOW" }
    local items = {}
    for i = 1, #right do
      items[#items + 1] = right[i]
    end
    for i = 1, #weird do
      items[#items + 1] = weird[i]
    end
    shuffle_table(items)

    local correct_indices = {}
    for i = 1, #items do
      if table_contains(right, items[i]) then
        correct_indices[#correct_indices + 1] = i
      end
    end

    self._current_question = {
      type = "sub",
      question = "Pick all the things Tony likes on his sub",
      correct_indices = correct_indices,
      sub_items = items,
    }
  else
    -- Pizza captcha: single max pepperoni
    local counts = {}
    local max_index = math.random(9)
    local max_count = math.random(6, 9)
    for i = 1, 9 do
      if i == max_index then
        counts[i] = max_count
      else
        counts[i] = math.random(1, max_count - 1)
      end
    end

    self._current_question = {
      type = "pizza",
      question = "Click the pizza Fat Tony would like to eat the most",
      correct_index = max_index,
      pizza_counts = counts,
    }
  end

  -- Update last type and clear retry flag after generation
  self._last_captcha_type = self._current_question.type
  self._regenerate_same_type = false
end

--- Open a captcha popup with 3x3 grid
function CaptchaTower:_open_captcha_overlay()
  if self._overlay then
    return
  end

  self._captcha_phase = "showing_warning"
  self._captcha_start_time = TIME.now()

  local Overlay = require "ui.components.elements.overlay"
  local Button = require "ui.components.inputs.button"

  self._overlay = Overlay.new {
    background = Colors.black:opacity(0.85),
    can_close = false,
    on_close = function() end,
  }

  -- Show "Bot activity detected." first
  local warning_text = Text.new {
    "Bot activity detected.",
    box = Box.new(
      Position.new(
        Config.window_size.width / 2 - 150,
        Config.window_size.height / 2 - 50
      ),
      300,
      100
    ),
    font = Asset.fonts.insignia_36,
    color = Colors.red,
    align = "center",
  }

  self._overlay:append_child(warning_text)
  UI.root:append_child(self._overlay)

  -- After 2 seconds, show the actual captcha
  State:add_callback(function()
    if self._overlay and self._captcha_phase == "showing_warning" then
      self:_show_captcha_grid()
    end
  end, 2.0)
end

--- Show the actual captcha grid after the warning
function CaptchaTower:_show_captcha_grid()
  if not self._overlay then
    return
  end

  self._captcha_phase = "showing_captcha"
  self:_generate_captcha_question()

  -- Clear existing children
  self._overlay.children = {}

  local Button = require "ui.components.inputs.button"

  -- Question text
  local question_text = Text.new {
    self._current_question.question,
    box = Box.new(
      Position.new(Config.window_size.width / 2 - 200, 150),
      400,
      50
    ),
    font = Asset.fonts.insignia_24,
    color = Colors.white,
    align = "center",
  }
  self._overlay:append_child(question_text)

  -- Persistent failure notice (until success or next failure)
  if self._show_fail_speed_message then
    local notice = Text.new {
      "Captcha failed: Enemies sped up by 25%!",
      box = Box.new(
        Position.new(Config.window_size.width / 2 - 225, 110),
        450,
        30
      ),
      font = Asset.fonts.insignia_20 or Asset.fonts.insignia_24,
      color = Colors.red,
      align = "center",
    }
    self._overlay:append_child(notice)
  end

  -- 3x3 Grid of items
  local grid_size = 80
  local grid_spacing = 10
  local start_x = Config.window_size.width / 2
    - (3 * grid_size + 2 * grid_spacing) / 2
  local start_y = 220

  for i = 1, 9 do
    local row = math.floor((i - 1) / 3)
    local col = (i - 1) % 3
    local x = start_x + col * (grid_size + grid_spacing)
    local y = start_y + row * (grid_size + grid_spacing)

    local grid_button = CaptchaGridButton.new {
      box = Box.new(Position.new(x, y), grid_size, grid_size),
      on_click = function()
        if self._current_question.type == "pizza" then
          for j = 1, 9 do
            self._grid_states[j] = false
          end
          self._grid_states[i] = true
        else
          self._grid_states[i] = not self._grid_states[i]
        end
      end,
      grid_states = self._grid_states,
      index = i,
      current_question = self._current_question,
      draw_pixel_pizza = draw_pixel_pizza,
      draw_tool_icon = draw_tool_icon,
      draw_sub_item_icon = draw_sub_item_icon,
      draw_centered_label_two_lines = draw_centered_label_two_lines,
    }

    self._overlay:append_child(grid_button)
  end

  -- Finish button
  local finish_button = ButtonElement.new {
    box = Box.new(
      Position.new(
        Config.window_size.width / 2 - 100,
        start_y + 3 * (grid_size + grid_spacing) + 20
      ),
      200,
      50
    ),
    label = "VERIFY",
    on_click = function() self:_verify_captcha() end,
  }

  self._overlay:append_child(finish_button)

  -- Fade in the captcha
  self._overlay:set_opacity(0)
  self._overlay:animate_style({ opacity = 1 }, { duration = 0.5 })
end

--- Verify the captcha solution
function CaptchaTower:_verify_captcha()
  -- Check if selected squares match correct answers
  local selected_indices = {}
  for i = 1, 9 do
    if self._grid_states[i] then
      table.insert(selected_indices, i)
    end
  end

  local correct = false
  if self._current_question.type == "pizza" then
    -- Must select exactly one and it must be the max-pepperoni pizza
    correct = (#selected_indices == 1)
      and (selected_indices[1] == assert(self._current_question.correct_index))
  else
    -- Tools: must select all and only the breakable tools
    local expected = assert(self._current_question.correct_indices)
    if #selected_indices == #expected then
      correct = true
      for _, idx in ipairs(selected_indices) do
        local found = false
        for _, e in ipairs(expected) do
          if e == idx then
            found = true
            break
          end
        end
        if not found then
          correct = false
          break
        end
      end
    end
  end

  if correct then
    -- Success! Reset and close
    self._captcha_locked = false
    self._click_times = {}
    self._captcha_phase = "waiting"
    self._show_fail_speed_message = false
    self._grid_states =
      { false, false, false, false, false, false, false, false, false }

    if self._overlay then
      local overlay = assert(self._overlay)
      self._overlay = nil
      overlay:close(function() UI.root:remove_child(overlay) end)
    end
  else
    -- Failed! Generate new question
    self._grid_states =
      { false, false, false, false, false, false, false, false, false }
    -- Keep the same captcha type on retry within the same overlay
    self._regenerate_same_type = true
    -- Increase global enemy speed by stacking 25% per failure
    local level = State.levels:get_current_level()
    level.captcha_fail_stacks = (level.captcha_fail_stacks or 0) + 1
    -- Ensure persistent failure notice is shown
    self._show_fail_speed_message = true
    self:_show_captcha_grid()
  end
end

--- Trigger an AOE when clicked, damaging enemies within range.
---@return boolean handled
function CaptchaTower:on_clicked()
  -- Only allow attack/captcha during active wave phases
  local lifecycle = GAME.lifecycle
  local during_wave = lifecycle == RoundLifecycle.ENEMIES_SPAWN_START
    or lifecycle == RoundLifecycle.ENEMIES_SPAWNING
  if not during_wave then
    -- Return false so default UI opens Tower Info instead
    return false
  end

  -- If currently locked, ensure the overlay is present and suppress normal behavior
  if self._captcha_locked then
    if not self._overlay then
      self:_open_captcha_overlay()
    end
    return true
  end

  -- Track click timestamps, prune beyond 3 seconds
  local now = TIME.now()
  table.insert(self._click_times, now)
  local i = 1
  while i <= #self._click_times do
    if now - self._click_times[i] > 3 then
      table.remove(self._click_times, i)
    else
      i = i + 1
    end
  end

  -- If more than 5 clicks within 3 seconds, lock and show popup
  if #self._click_times > 5 then
    self._captcha_locked = true
    self:_open_captcha_overlay()
    return true
  end

  local enemies = {}
  for _, enemy in ipairs(State.enemies) do
    if
      enemy.position:distance(self.position) <= self:get_range_in_distance()
    then
      table.insert(enemies, enemy)
    end
  end

  if #enemies == 0 then
    return true
  end

  local damage = self:get_damage()
  for _, enemy in ipairs(enemies) do
    State:damage_enemy {
      source = self,
      enemy = enemy,
      damage = damage,
      kind = DamageKind.PHYSICAL,
    }
  end

  GameAnimationSystem:play_explosion(self.position)
  self.state.last_attack_time = TIME.now()
  return true
end

--- Get whether the captcha is currently locked (overlay required)
---@return boolean
function CaptchaTower:is_captcha_locked() return self._captcha_locked == true end

--- Get progress toward triggering the captcha lock based on recent clicks.
--- Returns a value in [0, 1], where 1 means the next click will (or has) triggered.
---@return number
function CaptchaTower:get_captcha_progress()
  -- If already locked, show full progress
  if self._captcha_locked then
    return 1
  end

  -- Mirror pruning logic used on click so UI remains consistent over time
  local now = TIME.now()
  local recent = 0
  for i = 1, #self._click_times do
    if now - self._click_times[i] <= 3 then
      recent = recent + 1
    end
  end

  -- Threshold is > 5 clicks in a 3s window. Map 0..5 to 0..1
  local threshold = 5
  local progress = math.max(0, math.min(1, recent / threshold))
  return progress
end

---@return table<TowerStatField, table<Rarity, tower.UpgradeOption>>
function CaptchaTower:get_tower_stat_enhancements() return base_enhancements end

---@return table<Rarity, tower.UpgradeOption[]>
function CaptchaTower:get_upgrade_options() return enhancements_by_rarity end

return CaptchaTower
