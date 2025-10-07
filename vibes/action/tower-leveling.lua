--[[

TODO:
  -- Apply level-up stat bonuses (temporary implementation)
  -- TODO: Should probably have some base that always gets applied?
  -- local add_base_damage = TowerStatOperation.new {
  --   field = TowerStatField.DAMAGE,
  --   operation = StatOperation.new {
  --     kind = StatOperationKind.ADD_BASE,
  --     value = self.level,
  --   },
  -- }
  -- add_base_damage:apply_to_tower_stats(self.tower.stats_base)

--]]

local Action = require "vibes.action"
local Container = require "ui.components.container"
local DynamicDialog = require "ui.elements.dynamic-dialog"
local ReadOnlyThreeByThreeGear =
  require "ui.components.inventory.readonly-three-by-three-gear"
local TowerUpgradePopup = require "ui.components.tower.upgrade-popup"

---@class actions.TowerLeveling.Opts : actions.BaseOpts
---@field tower vibes.Tower

---@class actions.TowerLeveling : vibes.Action
---@field new fun(opts: actions.TowerLeveling.Opts): actions.TowerLeveling
---@field init fun(self: actions.TowerLeveling, opts: actions.TowerLeveling.Opts)
---@field tower vibes.Tower
---@field previous_lifecycle RoundLifecycle
local TowerLeveling = class("actions.TowerLeveling", { super = Action })

---@param opts actions.TowerLeveling.Opts
---@return vibes.Action
function TowerLeveling:init(opts)
  validate(opts, { tower = "vibes.Tower" })

  Action.init(self, {
    name = "TowerLeveling",
    on_cancel = opts.on_cancel,
    on_success = opts.on_success,
    on_complete = opts.on_complete,
  })

  self.tower = opts.tower
  self.previous_lifecycle = GAME.lifecycle
  self.previous_game_speed = 1
  self.dimmable = nil
end

function TowerLeveling:start()
  local placed_tower = GAME.ui:find_placed_tower(self.tower)
  if not placed_tower then
    return ActionResult.CANCEL
  end

  logger.debug "TowerLeveling:start"

  local tower = placed_tower
  local rewards = tower.tower:get_levelup_reward()

  logger.debug("TowerLeveling:start: rewards", rewards)

  if rewards.kind == LevelUpRewardKind.UPGRADE_TOWER then
    local upgrades = rewards:get_tower_upgrade_options()

    ---@cast upgrades tower.UpgradeOption[]

    self.dimmable = Element.new(Box.fullscreen(), {
      z = Z.MAX - 1,
      render = function()
        love.graphics.setColor(Colors.black:opacity(0.5))
        love.graphics.rectangle(
          "fill",
          0,
          0,
          Config.window_size.width,
          Config.window_size.height
        )
      end,
    })
    UI.root:append_child(self.dimmable)

    self.ui = TowerUpgradePopup.new {
      upgrades = upgrades,
      tower = tower.tower,
      on_confirm = function(selected_upgrade)
        selected_upgrade:apply(tower.tower)
        tower.tower.stats_manager:update(0)
        EventBus:emit_tower_upgrade_menu_closed { tower = tower.tower }
        EventBus:emit_tower_stat_upgrade {
          tower = tower.tower,
          upgrade = selected_upgrade,
        }
        self:resolve(ActionResult.COMPLETE)
        UI.root:remove_child(self.dimmable)
      end,
      z = Z.MAX,
    }
    self.dimmable:append_child(self.ui)

    local PlacedTower = require "ui.components.tower.placed-tower"
    local tower_placed = PlacedTower.new(tower.card)
    self.dimmable:append_child(tower_placed)

    EventBus:emit_tower_upgrade_menu_opened { tower = tower.tower }

    return ActionResult.ACTIVE
  elseif rewards.kind == LevelUpRewardKind.EVOLVE_TOWER then
    local TowerEvolutionMenu = require "ui.components.tower.evolution-menu"
    local TowerOverview = require "ui.components.tower.overview_bottom"

    local evolutions =
      assert(rewards:get_tower_evolution_options(), "No evolutions found")

    local cell_size = Config.grid.cell_size
    local x = 7 * cell_size
    local y = (Config.grid.grid_height - 2.9) * cell_size
    local pos = Position.new(x, y)

    local tower_overview = TowerOverview.new {
      tower = tower.tower,
      position = Position.zero(),
      z = Z.OVERLAY + 3,
    }

    local container = Container.new {
      name = "TowerLeveling",
      box = Box.new(
        Position.zero(),
        Config.window_size.width,
        Config.window_size.height
      ),
      z = Z.OVERLAY,
      background = Colors.black:opacity(0.8),
    }

    ---@cast evolutions tower.EvolutionOption[]

    local menu = TowerEvolutionMenu.new {
      tower = tower.tower,
      evolutions = evolutions,
      on_select = function(op)
        op:apply(tower.tower)
        EventBus:emit_tower_upgrade_menu_closed { tower = tower.tower }
        EventBus:emit_tower_stat_upgrade {
          tower = tower.tower,
          upgrade = op,
        }
        self:resolve(ActionResult.COMPLETE)
      end,
      z = Z.OVERLAY + 3,
    }

    self.ui = container

    local box = DynamicDialog.new {
      pos = pos,
      element = tower_overview,
      kind = "empty",
      z = Z.OVERLAY + 1,
    }

    container:append_child(ReadOnlyThreeByThreeGear.new {})
    container:append_child(box)
    container:append_child(menu)

    UI.root:append_child(self.ui)
    EventBus:emit_tower_upgrade_menu_opened { tower = tower.tower }

    return ActionResult.ACTIVE
  end

  return ActionResult.COMPLETE
end

function TowerLeveling:update() return ActionResult.ACTIVE end

function TowerLeveling:finish()
  logger.info "TowerLeveling:finish"
  -- Don't restore lifecycle since we never changed it

  if self.dimmable then
    UI.root:remove_child(self.dimmable)
    self.dimmable = nil
  end

  if not self.ui then
    return
  end

  -- Remove from the appropriate parent (could be UI.root or GAME.ui)
  if self.ui.parent then
    self.ui.parent:remove_child(self.ui)
  end
  self.ui = nil
end

return TowerLeveling
