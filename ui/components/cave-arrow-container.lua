local BouncingArrow = require "vibes.engine.graphics.bouncing-arrow"

---@class ui.components.CaveArrowContainer : Element
---@field new fun(): ui.components.CaveArrowContainer
---@field init fun(self: ui.components.CaveArrowContainer)
local CaveArrowContainer =
  class("ui.components.CaveArrowContainer", { super = Element })

function CaveArrowContainer:init()
  -- Create a fullscreen container
  Element.init(self, Box.fullscreen())
  self.name = "CaveArrowContainer"
  self.z = 5 -- Below UI elements but above game world
end

---@param level vibes.Level
function CaveArrowContainer:create_arrows_for_level(level)
  -- Clear existing arrows
  self:remove_all_children()

  -- Create arrows for each cave
  for _, decor in ipairs(level.decorations) do
    local function process_decoration()
      local cave_pos = Position.from_cell(decor.cell)
      if decor.name == "cave-left" then
        cave_pos = cave_pos:sub(
          Position.new(
            1.25 * Config.grid.cell_size,
            2.5 * Config.grid.cell_size
          )
        )
      elseif decor.name == "cave-right" then
        cave_pos = cave_pos:sub(
          Position.new(
            -1.25 * Config.grid.cell_size,
            2.5 * Config.grid.cell_size
          )
        )
      elseif decor.name == "cave-down" then
        cave_pos = cave_pos:sub(Position.new(0, 2.5 * Config.grid.cell_size))
      else
        return -- Skip this decoration, continue to next iteration
      end

      local arrow = BouncingArrow.new {
        target_pos = cave_pos,
      }

      self:append_child(arrow)
    end

    process_decoration()
  end
end

function CaveArrowContainer:_render() end
function CaveArrowContainer:_update(dt) end

return CaveArrowContainer
