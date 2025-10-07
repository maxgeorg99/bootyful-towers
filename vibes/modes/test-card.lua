---@class vibes.TestCard : vibes.BaseMode
---@field card vibes.TowerCard
local test_card = {
  name = "test-card",
}

function test_card:update(_dt) end
function test_card:draw() end

local CARD_W = 590
local CARD_H = 830

function test_card:enter()
  local Text = require "ui.components.text"

  local card = require("vibes.card.card-tower-archer").new {}
  local down_size = 1
  local ui_card = require("ui.components.card").new {
    card = card,
    box = Box.new(
      Position.new(100, 200),
      CARD_W / down_size,
      CARD_H / down_size
    ),
    on_use = function() end,
  }
  UI.root:append_child(ui_card)

  ui_card = require("ui.components.card").new {
    card = card,
    box = Box.new(
      Position.new(750, 500),
      CARD_W / down_size / 2,
      CARD_H / down_size / 2
    ),
    on_use = function() end,
  }
  UI.root:append_child(ui_card)

  local new_card =
    require("vibes.card.enhancement.damage").new { rarity = Rarity.COMMON }
  ui_card = require("ui.components.card").new {
    card = new_card,
    box = Box.new(
      Position.new(1200, 500),
      CARD_W / down_size / 3,
      CARD_H / down_size / 3
    ),
    on_use = function() end,
  }
  UI.root:append_child(ui_card)

  -- local CanvasElement = require "ui.components.canvas-element"
  -- local canvas_element = CanvasElement.new {
  --   box = Box.new(Position.new(500, 500), 100, 100),
  -- }
  -- UI.root:append_child(canvas_element)

  -- canvas_element._drag_end = function()
  --   print "drag end"
  --   local scale = canvas_element:get_scale()
  --   canvas_element:animate_style(
  --     { scale = scale + 1, rotation = 0 },
  --     { duration = 0.1 }
  --   )
  -- end

  -- button to rotate the canvas
  local button = require("ui.components.inputs.button").new {
    draw = "Rotate",
    box = Box.new(Position.new(0, 0), 100, 100),
    on_click = function()
      print "rotate:start"
      ui_card:animate_style({
        rotation = ui_card:get_rotation() + 1,
        opacity = 1,
        scale = ui_card:get_scale() + 0.1,
      }, { duration = 0.1 })
    end,
  }
  button.z = Z.MAX
  UI.root:append_child(button)

  -- local frame = require("ui.components.card.frame").new {
  --   box = Box.new(Position.new(0, 0), 100, 100),
  --   rarity = Rarity.COMMON,
  --   kind = CardKind.TOWER,
  -- }
  -- canvas_element:append_child(frame)
  -- local count = 0
  -- canvas_element:append_child(Text.new {
  --   function()
  --     count = count + 1
  --     return string.format("Hello, world! %d", count)
  --   end,
  --   box = Box.new(Position.new(0, 0), 100, 100),
  -- })

  local c = require("ui.components.container").new {
    box = Box.new(Position.new(0, 0), 100, 100),
    background = Colors.red,
  }
  c:set_interactable(true)
  UI.root:append_child(c)

  c:animate_to_absolute_position(Position.new(250, 250), { duration = 0.1 })
end

function test_card:keypressed() end
function test_card:exit() end
function test_card:mousemoved() end
function test_card:mousepressed() end
function test_card:mousereleased() end

return require("vibes.base-mode").wrap(test_card)
