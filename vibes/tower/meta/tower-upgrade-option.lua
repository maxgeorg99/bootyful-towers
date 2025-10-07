local _id = 0

---@return number
local function next_id()
  local id = _id
  _id = _id + 1
  return id
end

---@class tower.UpgradeOption : vibes.Class
---@field new fun(opts: tower.UpgradeOption.Opts): tower.UpgradeOption
---@field init fun(self: tower.UpgradeOption, opts: tower.UpgradeOption.Opts)
---@field equal fun(self: tower.UpgradeOption, other: tower.UpgradeOption): boolean
---@field clone fun(self: tower.UpgradeOption): tower.UpgradeOption
---@field name string
---@field _id number
---@field rarity Rarity
---@field operations tower.StatOperation[]
---@field description? string
local TowerUpgradeOption = class "vibes.TowerUpgradeOptions"

function TowerUpgradeOption:__tostring()
  local name_and_rarity = string.format(
    "TowerUpgradeOption(name=%s, rarity=%s, operations=%s)",
    self.name,
    self.rarity,
    inspect(self.operations)
  )

  return name_and_rarity
end

---@class tower.UpgradeOption.Opts
---@field name string
---@field rarity Rarity
---@field operations tower.StatOperation[]
function TowerUpgradeOption:init(opts)
  opts.description = opts.description or "No description provided"
  validate(opts, {
    name = "string",
    rarity = Rarity,
    operations = List { TowerStatOperation },
    description = "string",
  })

  self.name = opts.name
  self.rarity = opts.rarity
  self.operations = opts.operations
  self._id = next_id()
end

function TowerUpgradeOption:clone()
  local operations = {}
  for _, operation in ipairs(self.operations) do
    table.insert(operations, operation:clone())
  end
  return TowerUpgradeOption.new {
    name = self.name,
    rarity = self.rarity,
    operations = operations,
  }
end

---Apply modifier stats
---@param tower vibes.Tower
function TowerUpgradeOption:apply(tower)
  for _, operation in ipairs(self.operations) do
    operation:apply_to_tower_stats(tower.stats_base)
  end
end

return TowerUpgradeOption
