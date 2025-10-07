---@class tower.EvolutionOption : vibes.Class
---@field new fun(opts: tower.EvolutionOption.Opts): tower.EvolutionOption
---@field init fun(self: tower.EvolutionOption, opts: tower.EvolutionOption.Opts)
---@field tower_name? string
---@field title string
---@field description ui.Text.Item[]
---@field texture vibes.Texture
---@field hints tower.EvolutionOption.Hint[]
---@field on_accept fun(self: tower.EvolutionOption, tower: vibes.Tower)
local TowerEvolutionOption = class "vibes.TowerEvolutionOption"

---@class tower.EvolutionOption.Hint
---@field field TowerStatField
---@field hint UpgradeHint

---@class tower.EvolutionOption.Opts
---@field title string
---@field description ui.Text.Item[]
---@field texture vibes.Texture
---@field hints tower.EvolutionOption.Hint[]
---@field tower_name? string
---@field on_accept fun(self: tower.EvolutionOption, tower: vibes.Tower)

function TowerEvolutionOption:init(opts)
  validate(opts, {
    title = "string",
    texture = "userdata",
    hints = "table",
    on_accept = "function",
    tower_name = "string?",
  })

  self.title = opts.title
  self.description = opts.description
  self.texture = opts.texture
  self.hints = opts.hints
  self.tower_name = opts.tower_name
  self.on_accept = opts.on_accept
end

---@param tower vibes.Tower
function TowerEvolutionOption:apply(tower)
  if self.tower_name then
    print(tower.name, " is now ", self.tower_name)
    tower.name = self.tower_name
  end

  self:on_accept(tower)
end

return TowerEvolutionOption
