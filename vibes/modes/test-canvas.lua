require "ui.components.ui"
local CanvasElement = require "ui.components.canvas-element"
local CanvasTest = require "ui.components.canvas-test"
local CardElement = require "ui.components.card"
local Text = require "ui.components.text"

---@class vibes.TestCanvas : vibes.BaseMode
---@field canvas_one components.CanvasTest
---@field canvas_two components.CanvasTest
---@field canvas_three components.CanvasTest
local TestCanvas = {
  name = "TestCanvas",
}

function TestCanvas:update() end

function TestCanvas:draw()
  -- love.graphics.setColor(Colors.burgundy)
  -- love.graphics.rectangle(
  --   "fill",
  --   0,
  --   0,
  --   Config.window_size.width,
  --   Config.window_size.height
  -- )
end

function TestCanvas:keypressed() end

function TestCanvas:enter()
  self.canvas_one = CanvasTest.new {
    box = Box.new(Position.new(500, 0), 300, 500),
  }

  self.canvas_two = CanvasTest.new {
    box = Box.new(Position.new(250 * 2, 210), 300, 500),
  }

  self.canvas_three = CanvasTest.new {
    box = Box.new(Position.new(250 * 4.5, 210 * 2), 300, 500),
  }

  local layout = Layout.new {
    name = "",
    box = Box.new(Position.new(0, 0), 300, 500),
    background = Colors.white,
    rounded = 20,
    els = {
      Text.new {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut nisl lectus, hendrerit eu gravida sit amet, consequat non nunc. Praesent vehicula sed turpis vel suscipit.",
        box = Box.new(Position.zero(), 300, 80),
        font = Asset.fonts.typography.card_description,
        color = Colors.black,
        padding = 20,
      },
    },
    flex = {
      justify_content = "center",
      align_items = "center",
      direction = "column",
      gap = 0,
    },
  }

  self.canvas_one:append_canvas_child(layout)

  local enhancement_card = require("vibes.card.aura.golden-harvest").new()

  local CARD_W = 290 * 1.3

  local CARD_H = 440 * 1.3

  self.card = CardElement.new {
    box = Box.new(Position.new(200, 0), CARD_W, CARD_H),
    card = enhancement_card,
  }
  -- self.card:set_scale(0.8)
  self.canvas_one:set_scale(1.2)

  UI.root:append_child(self.card)

  -- self.canvas_two:append_canvas_child(layout)
  -- self.canvas_three:append_canvas_child(layout)
  --
  -- self.canvas_two._canvas_element:set_scale(1.5)
  -- self.canvas_three._canvas_element:set_scale(2)
  -- self.canvas_one:animate_style({ rotation = 1 }, { duration = 5 })
  -- self.canvas_two:animate_style({ rotation = 1 }, { duration = 5 })
  -- self.canvas_three:animate_style({ rotation = 1 }, { duration = 5 })
  -- UI.root:append_child(self.canvas_one)
  -- UI.root:append_child(self.canvas_two)
  -- UI.root:append_child(self.canvas_three)
end

function TestCanvas:exit() --UI.root:remove_child(self.canvas_one) end
end
function TestCanvas:mousemoved() end

return require("vibes.base-mode").wrap(TestCanvas)
