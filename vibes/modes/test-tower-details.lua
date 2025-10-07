require "ui.components.ui"

---@class vibes.TestTowerDetails : vibes.BaseMode
local TestTowerDetails = {
  name = "TestTowerDetails",
}

function TestTowerDetails:update() end

function TestTowerDetails:draw() end

function TestTowerDetails:keypressed() end
function TestTowerDetails:enter()
  local TowerOverview = require "ui.components.tower.overview"
  local TowerEvolution = require "ui.components.tower.evolve"
  local CardSlots = require "ui.components.tower.elements.card-slots"

  --#region Testing Tower StatTable
  local tower = require("vibes.card.card-tower-archer").new {}
  local stat_op = StatOperation.new {
    kind = "ADD_BASE",
    value = 3,
  }

  local upgrade = TowerStatOperation.new {
    field = "damage",
    operation = stat_op,
  }

  --#region Testing Tower StatTable

  self.ui = TowerOverview.new { card = tower, upgrade = upgrade }

  tower.tower.level = 3

  local enhancement_card =
    require("vibes.card.enhancement.damage").new { rarity = "LEGENDARY" }
  table.insert(tower.tower.enhancements, enhancement_card)

  local evolutions =
    tower.tower:get_levelup_reward():get_tower_evolution_options()

  self.tower_evolution = TowerEvolution.new {
    tower = tower.tower,
    evolutions = evolutions or {},
    on_confirm = function(evolve)
      evolve:apply(tower.tower)
      -- self.ui:reset()
      -- UI.root:remove_child(self.tower_upgrades)
    end,
    on_skip = function()
      self.ui:reset()
      -- UI.root:remove_child(self.tower_upgrades)
    end,
  }

  local PlacedTower = require "ui.components.tower.placed-tower"
  local placed_tower = PlacedTower.new(tower)
  local card_slots = CardSlots.new {
    box = Box.new(Position.new(0, 500), 500, 200),
    card = tower,
    placed_tower = placed_tower,
  }

  UI.root:append_child(card_slots)
  UI.root:append_child(self.ui)
  -- self.tower_upgrades = TowerUpgrades.new {
  --   upgrades = { upgrades, upgrades_2, upgrades_3 },
  --   on_confirm = function(op)
  --     op:apply(tower.tower)
  --     self.ui:reset()
  --     UI.root:remove_child(self.tower_upgrades)
  --   end,
  --   on_skip = function()
  --     self.ui:reset()
  --     UI.root:remove_child(self.tower_upgrades)
  --   end,
  -- }
  -- local tooltip = TowerTooltip.new { card = tower }
  -- UI.root:append_child(tooltip)
  -- UI.root:append_child(self.tower_evolution)
  -- UI.root:append_child(self.tower_upgrades)

  -- self.button = Button.new {
  --   box = Box.new(Position.new(100, 100), 100, 100),
  --   on_click = function()
  --     -- UI.root:remove_child(self.button)
  --     self.button:animate_to_absolute_position(
  --       self.button:get_pos():add(Position.new(100, 100))
  --     )
  --   end,
  --   clickable = true,
  --   draw = "Move this bad boy",
  -- }
  -- UI.root:append_child(self.button)
end

function TestTowerDetails:exit() UI.root:remove_child(self.ui) end

function TestTowerDetails:mousemoved() end

return require("vibes.base-mode").wrap(TestTowerDetails)
