local TowerEvolutionOption = require "vibes.tower.meta.tower-evolution-option"
local TowerUpgradeOption = require "vibes.tower.meta.tower-upgrade-option"

---@param number number
---@return string
local function number_to_percent(number)
  validate({
    number = number,
  }, {
    number = "number",
  })
  return tostring(math.floor(number * 100))
end

---@param number number
---@return string
local function number_to_string(number)
  validate({
    number = number,
  }, {
    number = "number",
  })

  if number < 1000 then
    return tostring(math.floor(number))
  end

  local scales = {
    { threshold = 1e18, suffix = "E" },
    { threshold = 1e15, suffix = "P" },
    { threshold = 1e12, suffix = "T" },
    { threshold = 1e9, suffix = "G" },
    { threshold = 1e6, suffix = "M" },
    { threshold = 1e3, suffix = "K" },
  }

  for _, scale in ipairs(scales) do
    if number >= scale.threshold then
      local scaled_value = math.floor(number / scale.threshold)
      local result = scaled_value .. scale.suffix
      return result
    end
  end

  local scale = scales[1]
  local scaled_value = math.floor(number / scale.threshold)
  local result = scaled_value .. scale.suffix
  return result
end

---@param upgrade tower.UpgradeOption|tower.EvolutionOption
---@param tower vibes.Tower
---@return string
local function base_upgrade_to_display(tower, upgrade)
  validate({
    upgrade = upgrade,
    tower = tower,
  }, {
    upgrade = Either { TowerUpgradeOption, TowerEvolutionOption },
    tower = "table", -- vibes.Tower
  })

  if TowerEvolutionOption.is(upgrade) then
    return ""
  end

  --- NOTE: Why are we doing it this way?  You maybe asking yourself if i am a bad programmer?
  --- Well that is an orthogonal question.  I am a bad programmer, but this isn't the reason why.
  ---
  --- What hapened is that an event goes off, which is upgrade applied, and then we display this.
  --- that means the upgrade has already been applied, so i inline undo the upgrade
  local operation = upgrade.operations[1]
  local value = operation.operation.value
  local base_field = tower:get_field_value(operation.field)
  local result = number_to_percent(value / (base_field - value))
  return result .. "%"
end

return {
  number_to_string = number_to_string,
  number_to_percent = number_to_percent,
  base_upgrade_to_display = base_upgrade_to_display,
}
