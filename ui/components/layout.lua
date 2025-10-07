--[[
--
-- Todo: implement a way to force reload reactive list when object gets removed
-- but preferably when _force_update is called on reactive list
--
--]]
local Container = require "ui.components.container"

--- @class layout.Opts : Element.Opts
--- @field name string
--- @field box ui.components.Box
--- @field flex layout.Flex
--- @field z number?
--- @field background? number[]
--- @field rounded? number
--- @field els? Element[]
--- @field animation_duration number?

---@class layout.Flex
---@field direction "row" | "column"
---@field justify_content "start" | "center" | "end" | "space-evenly"
---@field align_items "start" | "center" | "end" | "space-evenly"
---@field gap number?

---@class layout.Layout : Element
---@field new fun(opts: layout.Opts): layout.Layout
---@field init fun(self: layout.Layout, opts: layout.Opts)
---@field flex layout.Flex
---@field animation_duration number?
---@field background? number[]
---@field rounded? number
local Layout = class("layout.Layout", { super = Element })

--- @param opts layout.Opts
function Layout:init(opts)
  opts.flex = opts.flex or {}
  opts.flex.direction = opts.flex.direction or "column"
  opts.flex.justify_content = opts.flex.justify_content or "space-evenly"
  opts.flex.align_items = opts.flex.align_items or "center"
  opts.flex.gap = opts.flex.gap or 0

  Element.init(self, opts.box, opts)
  self.name = opts.name or "Layout"

  self.flex = opts.flex
  self.background = opts.background
  self.rounded = opts.rounded
  self._layout_dirty = true -- Start with dirty layout since we may have children
  self._layout_timer = 0 -- Timer to force layout updates at least once per second

  self.animation_duration = F.if_nil(opts.animation_duration, 0.2)

  if opts.els then
    for idx, el in ipairs(opts.els) do
      self:append_child(el)
    end
  end
end

function Layout:_set_x_of_child(child, x)
  if self.animation_duration == 0 then
    child:set_x(x)
    return
  end

  child:animate_style({ x = x }, { duration = self.animation_duration })
end

function Layout:_set_y_of_child(child, y)
  if self.animation_duration == 0 then
    child:set_y(y)
    return
  end

  child:animate_style({ y = y }, { duration = self.animation_duration })
end

function Layout:_render()
  local x, y, w, h = self:get_geo()
  if self.background then
    local rounded = self.rounded or 0
    self:with_color(
      self.background,
      function()
        love.graphics.rectangle("fill", x, y, w, h, rounded, rounded, 80)
      end
    )
  end

  -- TODO: Something about this is weird at the moment.
  -- -- Force layout update at least once per second
  -- self._layout_timer = self._layout_timer + love.timer.getDelta()
  -- if self._layout_timer >= 1.0 then
  --   self._layout_dirty = true
  --   self._layout_timer = 0
  -- end

  -- Only recalculate layout if it's dirty
  if not self._layout_dirty then
    return
  end

  self._layout_dirty = false

  love.graphics.setColor(1, 1, 1, self:get_opacity())

  local num_children = #self.children
  if num_children == 0 then
    return
  end

  -- Helper to get child size
  local function get_child_size(child)
    local cx, cy, cw, ch = child:get_geo()
    return cw, ch
  end

  -- Calculate total child sizes and create size arrays
  local child_widths = {}
  local child_heights = {}
  local total_child_width = 0
  local total_child_height = 0
  local gap = self.flex.gap or 0

  for i, child in ipairs(self.children) do
    local cw, ch = get_child_size(child)
    child_widths[i] = cw
    child_heights[i] = ch
    total_child_width = total_child_width + cw
    total_child_height = total_child_height + ch
  end

  -- Add gap space to totals (gaps between items, so num_children - 1 gaps)
  local total_gap_width = gap * (num_children - 1)
  local total_gap_height = gap * (num_children - 1)
  total_child_width = total_child_width + total_gap_width
  total_child_height = total_child_height + total_gap_height

  -- Main axis positioning functions
  local function justify_start_row()
    local current_x = 0

    for i, child in ipairs(self.children) do
      self:_set_x_of_child(child, current_x)
      current_x = current_x + child_widths[i]
      if i < num_children then
        current_x = current_x + gap
      end
    end
  end

  local function justify_center_row()
    local remaining_space = w - total_child_width
    local current_x = remaining_space / 2
    for i, child in ipairs(self.children) do
      self:_set_x_of_child(child, current_x)
      current_x = current_x + child_widths[i]
      if i < num_children then
        current_x = current_x + gap
      end
    end
  end

  local function justify_end_row()
    local remaining_space = w - total_child_width
    local current_x = remaining_space
    for i, child in ipairs(self.children) do
      self:_set_x_of_child(child, current_x)
      current_x = current_x + child_widths[i]
      if i < num_children then
        current_x = current_x + gap
      end
    end
  end

  local function justify_space_evenly_row()
    local remaining_space = w - total_child_width
    local extra_gap = remaining_space / (num_children + 1)
    local current_x = extra_gap
    for i, child in ipairs(self.children) do
      self:_set_x_of_child(child, current_x)
      current_x = current_x + child_widths[i]
      if i < num_children then
        current_x = current_x + gap + extra_gap
      end
    end
  end

  local function justify_start_column()
    local current_y = 0
    for i, child in ipairs(self.children) do
      self:_set_y_of_child(child, current_y)
      current_y = current_y + child_heights[i]
      if i < num_children then
        current_y = current_y + gap
      end
    end
  end

  local function justify_center_column()
    local remaining_space = h - total_child_height
    local current_y = remaining_space / 2
    for i, child in ipairs(self.children) do
      self:_set_y_of_child(child, current_y)
      current_y = current_y + child_heights[i]
      if i < num_children then
        current_y = current_y + gap
      end
    end
  end

  local function justify_end_column()
    local remaining_space = h - total_child_height
    local current_y = remaining_space
    for i, child in ipairs(self.children) do
      self:_set_y_of_child(child, current_y)
      current_y = current_y + child_heights[i]
      if i < num_children then
        current_y = current_y + gap
      end
    end
  end

  local function justify_space_evenly_column()
    local remaining_space = h - total_child_height
    local extra_gap = remaining_space / (num_children + 1)
    local current_y = extra_gap
    for i, child in ipairs(self.children) do
      self:_set_y_of_child(child, current_y)
      current_y = current_y + child_heights[i]
      if i < num_children then
        current_y = current_y + gap + extra_gap
      end
    end
  end

  -- Cross axis positioning functions
  local function align_start_row()
    for _, child in ipairs(self.children) do
      self:_set_y_of_child(child, 0)
    end
  end

  local function align_center_row()
    for i, child in ipairs(self.children) do
      local child_y = (h - child_heights[i]) / 2
      self:_set_y_of_child(child, child_y)
    end
  end

  local function align_end_row()
    for i, child in ipairs(self.children) do
      local child_y = h - child_heights[i]
      self:_set_y_of_child(child, child_y)
    end
  end

  local function align_space_evenly_row()
    for i, child in ipairs(self.children) do
      local remaining_space = h - child_heights[i]
      local gap = remaining_space / (num_children + 1)
      local child_y = gap * i
      self:_set_y_of_child(child, child_y)
    end
  end

  local function align_start_column()
    for _, child in ipairs(self.children) do
      self:_set_x_of_child(child, 0)
    end
  end

  local function align_center_column()
    for i, child in ipairs(self.children) do
      local child_x = (w - child_widths[i]) / 2
      self:_set_x_of_child(child, child_x)
    end
  end

  local function align_end_column()
    for i, child in ipairs(self.children) do
      local child_x = w - child_widths[i]
      self:_set_x_of_child(child, child_x)
    end
  end

  local function align_space_evenly_column()
    for i, child in ipairs(self.children) do
      local remaining_space = w - child_widths[i]
      local gap = remaining_space / (num_children + 1)
      local child_x = gap * i
      self:_set_x_of_child(child, child_x)
    end
  end

  -- Apply main axis positioning
  if self.flex.direction == "row" then
    if self.flex.justify_content == "start" then
      justify_start_row()
    elseif self.flex.justify_content == "center" then
      justify_center_row()
    elseif self.flex.justify_content == "end" then
      justify_end_row()
    elseif self.flex.justify_content == "space-evenly" then
      justify_space_evenly_row()
    else
      error("invalid justify_content: " .. tostring(self.flex.justify_content))
    end
  else -- column
    if self.flex.justify_content == "start" then
      justify_start_column()
    elseif self.flex.justify_content == "center" then
      justify_center_column()
    elseif self.flex.justify_content == "end" then
      justify_end_column()
    elseif self.flex.justify_content == "space-evenly" then
      justify_space_evenly_column()
    else
      error("invalid justify_content: " .. tostring(self.flex.justify_content))
    end
  end

  -- Apply cross axis positioning
  if self.flex.direction == "row" then
    if self.flex.align_items == "start" then
      align_start_row()
    elseif self.flex.align_items == "center" then
      align_center_row()
    elseif self.flex.align_items == "end" then
      align_end_row()
    elseif self.flex.align_items == "space-evenly" then
      align_space_evenly_row()
    else
      align_start_row() -- default
    end
  else -- column
    if self.flex.align_items == "start" then
      align_start_column()
    elseif self.flex.align_items == "center" then
      align_center_column()
    elseif self.flex.align_items == "end" then
      align_end_column()
    elseif self.flex.align_items == "space-evenly" then
      align_space_evenly_column()
    else
      align_start_column() -- default
    end
  end
end

--- Override append_child to mark layout as dirty
--- @param el Element
function Layout:append_child(el)
  Element.append_child(self, el)
  self._layout_dirty = true

  -- self:update(0)
end

--- Override remove_child to mark layout as dirty
--- @param el Element
--- @param hint number?
function Layout:remove_child(el, hint)
  Element.remove_child(self, el, hint)
  self._layout_dirty = true
end

---@class layout.RectangleOpts
---@field box? ui.components.Box
---@field w number?
---@field h number?
---@field background? number[]
---@field position? vibes.Position
---@field name? string

---@param opts layout.RectangleOpts
function Layout.rectangle(opts)
  opts = opts or {}
  opts.position = opts.position or Position.zero()
  local el = Container.new {
    box = opts.box and opts.box:clone()
      or Box.new(opts.position, opts.w, opts.h),
    background = opts.background or { 0, 0, 0, 0 },
  }

  el.name = opts.name or "padding-element"
  return el
end

function Layout.row(opts)
  opts = opts or {}

  opts.flex = opts.flex or {}
  opts.flex.direction = "row"
  opts.flex.justify_content = opts.flex.justify_content or "space-evenly"
  opts.flex.align_items = opts.flex.align_items or "center"
  opts.flex.gap = opts.flex.gap or 0

  return Layout.new(opts)
end

function Layout.col(opts)
  opts = opts or {}

  opts.flex = opts.flex or {}
  opts.flex.direction = "column"
  opts.flex.justify_content = opts.flex.justify_content or "space-evenly"
  opts.flex.align_items = opts.flex.align_items or "center"
  opts.flex.gap = opts.flex.gap or 0

  return Layout.new(opts)
end

return Layout
